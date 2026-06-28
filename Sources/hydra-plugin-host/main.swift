// Hydra Audio — GPL-3.0
// hydra-plugin-host — SHARED out-of-process VST host.
//
// ONE of these runs for the whole app and hosts EVERY strip's plugin chain, so
// all plugin editors live in a single process — opening a plugin replaces the
// shared editor window (the daemon enforces one-at-a-time; editors always open
// at the same screen position), and Shift-open adds a window. A plugin crash
// takes down this one process (all chains go dry + relaunch), but the main Hydra
// app stays safe.
//
// Control plane: the daemon writes one JSON command per line to our stdin:
//   {"cmd":"add","chain":"<uuid>","shm":"<name>","channels":2,"maxFrames":4096,
//    "rate":48000,"plugins":[{"spec":"<path>#<idx>","title":"<name>"}, ...]}
//   {"cmd":"remove","chain":"<uuid>"}
// Audio + editor/param commands flow through each chain's own shared-memory
// region (unchanged ABI), so the realtime path is identical to before.
//
// Threading: one high-QoS audio thread per chain; the main thread runs the AppKit
// run loop (editor windows) and a 30 ms timer that drains every chain's command
// ring and exits if the parent (Hydra) is gone.

import Foundation
import AppKit
import Darwin
import HydraPluginHostABI
import HydraVST

// Diagnostics → stderr (inherited from Hydra, so visible in the Xcode console).
func hlog(_ s: String) { FileHandle.standardError.write(Data("hydra-plugin-host: \(s)\n".utf8)) }

// MARK: - Control messages (daemon → host, one JSON line each)

struct PluginSpec: Codable { let spec: String; let title: String }
struct ChainCommand: Codable {
    let cmd: String
    let chain: String
    var shm: String?
    var channels: Int?
    var maxFrames: Int?
    var rate: Double?
    var plugins: [PluginSpec]?
}

// MARK: - PluginHost: one hosted chain (audio thread + shm + instances)

final class PluginHost: @unchecked Sendable {
    let chainID: String
    private let header: UnsafeMutablePointer<hydra_plugin_shm>
    private let mapping: UnsafeMutableRawPointer
    private let mappingBytes: Int
    private let channels: Int
    private let maxFrames: Int
    /// 1:1 with the chain (nil = a plugin that failed to load) so command indices stay valid.
    private let instances: [UnsafeMutableRawPointer?]
    private let titles: [String]
    private let active: [UnsafeMutableRawPointer]

    private let bufA: [UnsafeMutablePointer<Float>]
    private let bufB: [UnsafeMutablePointer<Float>]
    private let argA: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>
    private let argB: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>

    private var lastInput: UInt64
    private var idleSpins = 0
    private var lastCmd: UInt64 = 0
    private var running = true
    private let stopped = DispatchSemaphore(value: 0)

    init?(_ cmd: ChainCommand) {
        guard let shmName = cmd.shm, let channels = cmd.channels,
              let maxFrames = cmd.maxFrames, let rate = cmd.rate else { return nil }
        self.chainID = cmd.chain
        self.channels = channels
        self.maxFrames = maxFrames

        let fd = hydra_shm_open_rw(shmName)
        guard fd >= 0 else { return nil }
        let totalBytes = Int(hydra_plugin_shm_bytes(Int32(channels), Int32(maxFrames)))
        guard let raw = mmap(nil, totalBytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0),
              raw != MAP_FAILED else { close(fd); return nil }
        close(fd)
        let h = raw.bindMemory(to: hydra_plugin_shm.self, capacity: 1)
        guard h.pointee.magic == HYDRA_PLUGIN_SHM_MAGIC,
              h.pointee.abiVersion == HYDRA_PLUGIN_SHM_ABI,
              Int(h.pointee.channels) == channels, Int(h.pointee.maxFrames) == maxFrames else {
            munmap(raw, totalBytes); return nil
        }
        self.header = h
        self.mapping = raw
        self.mappingBytes = totalBytes

        let specs = cmd.plugins ?? []
        self.titles = specs.map { $0.title }
        var loaded: [UnsafeMutableRawPointer?] = []
        for s in specs {
            let parts = s.spec.split(separator: "#")
            if parts.count == 2, let classIndex = Int32(parts[1]) {
                loaded.append(hydra_vst_create_instance(String(parts[0]), classIndex, rate, Int32(maxFrames)))
            } else { loaded.append(nil) }
        }
        self.instances = loaded
        self.active = loaded.compactMap { $0 }
        hlog("chain \(cmd.chain.prefix(8)) loaded \(active.count)/\(specs.count) plugin(s) on shm \(shmName)")

        func make() -> [UnsafeMutablePointer<Float>] {
            (0..<channels).map { _ in
                let p = UnsafeMutablePointer<Float>.allocate(capacity: maxFrames)
                p.initialize(repeating: 0, count: maxFrames); return p
            }
        }
        bufA = make(); bufB = make()
        argA = .allocate(capacity: channels); argB = .allocate(capacity: channels)
        for ch in 0..<channels { argA[ch] = bufA[ch]; argB[ch] = bufB[ch] }
        lastInput = hydra_shm_load_u64(&h.pointee.inputSeq)
        hydra_shm_store_u32(&h.pointee.hostReady, 1)
    }

    func start() {
        let thread = Thread { [self] in runAudioLoop() }
        thread.name = "hydra.plugin-host.audio.\(chainID.prefix(8))"
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    /// Stop the chain: end the audio thread, close editors, destroy plugins, unmap.
    func stop() {
        running = false
        _ = stopped.wait(timeout: .now() + 1.0)          // let the audio loop exit
        let toDestroy = instances.compactMap { $0 }
        let destroy = { for p in toDestroy { hydra_vst_close_editor(p); hydra_vst_destroy_instance(p) } }
        if Thread.isMainThread { destroy() } else { DispatchQueue.main.sync(execute: destroy) }
        for p in bufA { p.deallocate() }
        for p in bufB { p.deallocate() }
        argA.deallocate(); argB.deallocate()
        munmap(mapping, mappingBytes)
    }

    // MARK: Realtime audio (per-chain busy-poll over its shm) — unchanged logic.

    private func configureRealTimeThread() {
        var info = thread_time_constraint_policy()
        var tb = mach_timebase_info_data_t(); mach_timebase_info(&tb)
        let msToNs: UInt32 = 1_000_000
        info.period = (3 * msToNs) * tb.denom / tb.numer
        info.computation = (1 * msToNs) * tb.denom / tb.numer
        info.constraint = UInt32(1.5 * Float(msToNs)) * tb.denom / tb.numer
        info.preemptible = 1
        let port = mach_thread_self()
        let count = mach_msg_type_number_t(MemoryLayout<thread_time_constraint_policy_data_t>.size / MemoryLayout<integer_t>.size)
        _ = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                thread_policy_set(port, thread_policy_flavor_t(THREAD_TIME_CONSTRAINT_POLICY), $0, count)
            }
        }
        mach_port_deallocate(mach_task_self_, port)
    }

    private func runAudioLoop() {
        configureRealTimeThread()
        var tb = mach_timebase_info_data_t(); mach_timebase_info(&tb)
        var lastInputTime = mach_absolute_time()
        while running {
            let seq = hydra_shm_load_u64(&header.pointee.inputSeq)
            if seq == lastInput {
                let elapsedNanos = (mach_absolute_time() - lastInputTime) * UInt64(tb.numer) / UInt64(tb.denom)
                if elapsedNanos > 50_000_000 { Thread.sleep(forTimeInterval: 0.010) }
                else if elapsedNanos > 5_000_000 { Thread.sleep(forTimeInterval: 0.001) }
                else { idleSpins += 1; if idleSpins > 1_000 { usleep(100) } }
                hydra_shm_store_u64(&header.pointee.heartbeat, header.pointee.heartbeat &+ 1)
                continue
            }
            lastInput = seq
            lastInputTime = mach_absolute_time()
            idleSpins = 0
            let frames = min(Int(header.pointee.frames), maxFrames)
            let inBuf = hydra_plugin_shm_input(header, seq)
            let outBuf = hydra_plugin_shm_output(header, seq)
            guard frames > 0 else { hydra_shm_store_u64(&header.pointee.outputSeq, seq); continue }
            if active.isEmpty {
                memcpy(outBuf, inBuf, frames * channels * MemoryLayout<Float>.size)
            } else {
                for frame in 0..<frames {
                    for ch in 0..<channels { bufA[ch][frame] = inBuf[frame * channels + ch] }
                }
                var source = argA, sink = argB
                for instance in active where hydra_vst_process(instance, source, sink, Int32(frames)) {
                    swap(&source, &sink)
                }
                for ch in 0..<channels {
                    if let data = source[ch] {
                        for frame in 0..<frames { outBuf[frame * channels + ch] = data[frame] }
                    } else {
                        for frame in 0..<frames { outBuf[frame * channels + ch] = 0 }
                    }
                }
            }
            hydra_shm_store_u64(&header.pointee.outputSeq, seq)
            hydra_shm_store_u64(&header.pointee.heartbeat, header.pointee.heartbeat &+ 1)
        }
        stopped.signal()
    }

    // MARK: Command drain (main thread) — editor/param for this chain.

    func drainCommands() {
        let write = hydra_shm_load_u64(&header.pointee.cmdWriteSeq)
        while lastCmd != write {
            lastCmd &+= 1
            let cmd = hydra_plugin_shm_cmd(header, lastCmd).pointee
            let idx = Int(cmd.instance)
            guard instances.indices.contains(idx), let inst = instances[idx] else { continue }
            switch cmd.type {
            case UInt32(HYDRA_CMD_OPEN_EDITOR):
                let title = titles.indices.contains(idx) ? titles[idx] : "Plugin \(idx + 1)"
                let ok = title.withCString { hydra_vst_open_editor(inst, $0) }
                hlog("open editor chain \(chainID.prefix(8)) idx \(idx) → \(ok)")
            case UInt32(HYDRA_CMD_CLOSE_EDITOR):
                hydra_vst_close_editor(inst)
            case UInt32(HYDRA_CMD_SET_PARAM):
                hydra_vst_set_parameter(inst, cmd.paramId, Double(cmd.value))
            default: break
            }
        }
        hydra_shm_store_u64(&header.pointee.cmdReadSeq, lastCmd)
    }
}

// MARK: - ChainManager: owns all chains; drives stdin control + the drain timer.

final class ChainManager: @unchecked Sendable {
    private var chains: [String: PluginHost] = [:]   // main-thread only

    func startControlReader() {
        Thread { [self] in
            let stdinHandle = FileHandle.standardInput
            var buffer = Data()
            while true {
                let chunk = stdinHandle.availableData
                if chunk.isEmpty { Thread.sleep(forTimeInterval: 0.05); continue }
                buffer.append(chunk)
                while let nl = buffer.firstIndex(of: 0x0A) {
                    let line = buffer.subdata(in: buffer.startIndex..<nl)
                    buffer.removeSubrange(buffer.startIndex...nl)
                    handleLine(line)
                }
            }
        }.start()
    }

    private func handleLine(_ line: Data) {
        guard !line.isEmpty else { return }
        guard let cmd = try? JSONDecoder().decode(ChainCommand.self, from: line) else {
            hlog("bad control line: \(String(data: line, encoding: .utf8) ?? "<binary>")")
            return
        }
        hlog("control: \(cmd.cmd) chain \(cmd.chain.prefix(8))")
        DispatchQueue.main.async { [self] in
            switch cmd.cmd {
            case "add":
                guard chains[cmd.chain] == nil else { return }
                guard let host = PluginHost(cmd) else { hlog("add FAILED for chain \(cmd.chain.prefix(8))"); return }
                chains[cmd.chain] = host
                host.start()
            case "remove":
                if let host = chains.removeValue(forKey: cmd.chain) {
                    DispatchQueue.global(qos: .userInitiated).async { host.stop() }
                }
            default: break
            }
        }
    }

    func startDrainTimer() {
        let timer = Timer(timeInterval: 0.03, repeats: true) { [self] _ in
            if getppid() == 1 { exit(0) }            // parent (Hydra) gone → don't orphan
            for host in chains.values { host.drainCommands() }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}

// MARK: - Startup

hlog("shared host started (pid \(getpid()), parent \(getppid()))")
let manager = ChainManager()
manager.startControlReader()
manager.startDrainTimer()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // faceless until an editor opens (the shim promotes it)

// Keep run-loop timers lively while faceless (avoid App Nap throttling editors).
let hostActivity = ProcessInfo.processInfo.beginActivity(
    options: [.userInitiated], reason: "Hosting plugin editor UI")
_ = hostActivity

app.run()
