// Hydra Audio — GPL-3.0
// Daemon side of out-of-process VST hosting (crash isolation), SHARED-host model.
//
// `SharedPluginHost` owns ONE `hydra-plugin-host` child process that hosts EVERY
// chain, so all plugin editors live in a single process (one shared editor
// window, one Dock icon). Each chain still gets its OWN shared-memory region for
// audio (unchanged RT transport), exposed as a `ChainHandle` the engine calls.
// Chains are added/removed dynamically over the child's stdin (one JSON line per
// command). If the child dies (a plugin crashed), every chain passes audio DRY
// and the daemon relaunches the child and re-adds all chains — the daemon never
// crashes and never blocks the audio thread.

import Foundation
import Darwin
import HydraCore
import HydraPluginHostABI

// MARK: - Per-chain handle (RT audio + editor/param), backed by one shm region

final class ChainHandle: @unchecked Sendable {
    let chainID: String
    let channels: Int
    let maxFrames: Int
    let shmName: String

    private let header: UnsafeMutablePointer<hydra_plugin_shm>
    private let mapping: UnsafeMutableRawPointer
    private let mappingBytes: Int
    /// Shared with the host object: 1 = child process believed alive.
    private let aliveFlag: UnsafeMutablePointer<UInt32>

    // Audio-thread-only state (single RT caller).
    private var lastSubmittedInput: UInt64 = 0
    private var lastConsumedOutput: UInt64 = 0

    init(chainID: String, channels: Int, maxFrames: Int, shmName: String,
         header: UnsafeMutablePointer<hydra_plugin_shm>, mapping: UnsafeMutableRawPointer,
         mappingBytes: Int, aliveFlag: UnsafeMutablePointer<UInt32>) {
        self.chainID = chainID; self.channels = channels; self.maxFrames = maxFrames
        self.shmName = shmName; self.header = header; self.mapping = mapping
        self.mappingBytes = mappingBytes; self.aliveFlag = aliveFlag
    }

    /// Run `frames` of interleaved audio through the remote chain. RT-safe:
    /// memcpy + acquire/release atomics only; dry passthrough when not ready.
    func process(input: UnsafePointer<Float>, output: UnsafeMutablePointer<Float>, frames: Int) {
        let n = min(frames, maxFrames)
        let bytes = n * channels * MemoryLayout<Float>.size
        guard hydra_shm_load_u32(aliveFlag) == 1 else { memcpy(output, input, bytes); return }

        let outSeq = hydra_shm_load_u64(&header.pointee.outputSeq)
        if outSeq != 0, outSeq != lastConsumedOutput {
            memcpy(output, hydra_plugin_shm_output(header, outSeq), bytes)
            lastConsumedOutput = outSeq
        } else {
            memcpy(output, input, bytes)
        }

        let seq = lastSubmittedInput &+ 1
        memcpy(hydra_plugin_shm_input(header, seq), input, bytes)
        header.pointee.frames = Int32(n)
        hydra_shm_store_u64(&header.pointee.inputSeq, seq)
        lastSubmittedInput = seq
    }

    var isHostReady: Bool { hydra_shm_load_u32(&header.pointee.hostReady) == 1 }

    /// Per-chain heartbeat counter (read by the host watchdog).
    var heartbeat: UInt64 { hydra_shm_load_u64(&header.pointee.heartbeat) }

    // Editor / parameter commands (single producer: the main-actor control plane).
    func openEditor(index: Int)  { sendCommand(UInt32(HYDRA_CMD_OPEN_EDITOR), instance: index) }
    func closeEditor(index: Int) { sendCommand(UInt32(HYDRA_CMD_CLOSE_EDITOR), instance: index) }
    func setParameter(index: Int, paramId: UInt32, value: Float) {
        sendCommand(UInt32(HYDRA_CMD_SET_PARAM), instance: index, paramId: paramId, value: value)
    }

    private func sendCommand(_ type: UInt32, instance: Int, paramId: UInt32 = 0, value: Float = 0) {
        let seq = hydra_shm_load_u64(&header.pointee.cmdWriteSeq) &+ 1
        let slot = hydra_plugin_shm_cmd(header, seq)
        slot.pointee.type = type
        slot.pointee.instance = Int32(instance)
        slot.pointee.paramId = paramId
        slot.pointee.value = value
        hydra_shm_store_u64(&header.pointee.cmdWriteSeq, seq)
    }

    /// Re-arm the handshake so a freshly (re)launched child starts clean.
    func resetForRelaunch() { hydra_shm_store_u32(&header.pointee.hostReady, 0) }

    func unmap() { munmap(mapping, mappingBytes); shm_unlink(shmName) }
}

// MARK: - Shared host: one child process, dynamic chains over stdin

final class SharedPluginHost: @unchecked Sendable {

    private let hostURL: URL
    private let control = DispatchQueue(label: "hydra.pluginhost.shared")

    /// 1 = child believed alive (read on the audio thread via each ChainHandle).
    private let aliveFlag = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)

    private var process: Process?
    private var stdinPipe: Pipe?
    private var shuttingDown = false
    private var lastLaunch = Date.distantPast
    private var consecutiveCrashes = 0
    private let maxRelaunchAttempts = 5
    private var watchdog: DispatchSourceTimer?
    private var lastHeartbeatSum: UInt64 = 0
    private var heartbeatStallTicks = 0

    // Registry of live chains (for relaunch re-add). Keyed by chainID.
    private struct ChainSpec { let shm: String; let channels: Int; let maxFrames: Int; let rate: Double; let plugins: [(String, String)] }
    private var registry: [String: ChainSpec] = [:]
    private var handles: [String: ChainHandle] = [:]

    init(hostURL: URL) {
        self.hostURL = hostURL
        aliveFlag.initialize(to: 0)
        // Writing to the child's stdin after it has died would raise SIGPIPE and
        // kill the daemon; ignore it process-wide (we guard nil pipes too).
        signal(SIGPIPE, SIG_IGN)
        launch()
        startWatchdog()
    }

    deinit { aliveFlag.deallocate() }

    // MARK: Chain lifecycle (called from the control plane)

    /// Create a chain's shm, register it, tell the child to load it, and return a
    /// `ChainHandle` for the engine. nil if the shm couldn't be created.
    func addChain(plugins: [String], titles: [String], channels: Int, maxFrames: Int, rate: Double) -> ChainHandle? {
        let chainID = UUID().uuidString
        let shmName = "/hyd\(getpid() % 100000)-\(UInt16.random(in: 0...0xFFFF))"
        guard let (header, mapping, bytes) = Self.createShm(shmName, channels: channels, maxFrames: maxFrames) else {
            log("PluginHost: shm create failed for chain \(chainID)")
            return nil
        }
        let handle = ChainHandle(chainID: chainID, channels: channels, maxFrames: maxFrames,
                                 shmName: shmName, header: header, mapping: mapping,
                                 mappingBytes: bytes, aliveFlag: aliveFlag)
        let spec = ChainSpec(shm: shmName, channels: channels, maxFrames: maxFrames, rate: rate,
                             plugins: Array(zip(plugins, titles + Array(repeating: "", count: max(0, plugins.count - titles.count)))))
        control.sync {
            registry[chainID] = spec
            handles[chainID] = handle
            log("PluginHost: addChain \(chainID.prefix(8)) shm=\(shmName) plugins=\(plugins.count) pipe=\(stdinPipe != nil ? "ready" : "NOT-READY")")
            sendAdd(chainID: chainID, spec: spec)
        }
        return handle
    }

    func removeChain(_ handle: ChainHandle) {
        let id = handle.chainID
        control.sync {
            registry[id] = nil
            handles[id] = nil
            sendLine(["cmd": "remove", "chain": id])
        }
        handle.unmap()
    }

    /// Terminate the child (app quit). Chains' shms are unmapped by their handles.
    func shutdown() {
        control.sync {
            shuttingDown = true
            watchdog?.cancel(); watchdog = nil
            process?.terminate(); process = nil
            hydra_shm_store_u32(aliveFlag, 0)
        }
    }

    // MARK: Child process

    private func launch() {
        control.async { [self] in
            guard !shuttingDown else { return }
            let proc = Process()
            proc.executableURL = hostURL
            let pipe = Pipe()
            proc.standardInput = pipe
            var env = ProcessInfo.processInfo.environment
            env["SWIFT_BACKTRACE"] = "enable=no"
            // Xcode's Debug scheme turns on Metal API Validation (MTL_DEBUG_LAYER),
            // which the app passes to children. Some plugin GUIs (e.g. Waves, which
            // draw with Metal) trip its assertions and SIGABRT the whole host. The
            // host doesn't need Metal validation — strip it so plugin editors run.
            for key in ["MTL_DEBUG_LAYER", "MTL_SHADER_VALIDATION",
                        "METAL_DEVICE_WRAPPER_TYPE", "MTL_DEBUG_LAYER_WARNING_MODE"] {
                env.removeValue(forKey: key)
            }
            proc.environment = env
            proc.terminationHandler = { [weak self] p in self?.handleExit(status: p.terminationStatus) }
            do {
                try proc.run()
                process = proc
                stdinPipe = pipe
                lastLaunch = Date()
                hydra_shm_store_u32(aliveFlag, 1)
                log("PluginHost: shared host launched from \(hostURL.path) (\(registry.count) chain(s) to re-add)")
                // Re-add every known chain so a relaunch restores all plugins.
                for (id, spec) in registry {
                    handles[id]?.resetForRelaunch()
                    sendAdd(chainID: id, spec: spec)
                }
            } catch {
                hydra_shm_store_u32(aliveFlag, 0)
                log("PluginHost: failed to launch shared host: \(error.localizedDescription)")
                scheduleRelaunch(after: 1)
            }
        }
    }

    private func handleExit(status: Int32) {
        control.async { [self] in
            hydra_shm_store_u32(aliveFlag, 0)
            process = nil; stdinPipe = nil
            guard !shuttingDown else { return }
            let uptime = Date().timeIntervalSince(lastLaunch)
            if uptime > 30 { consecutiveCrashes = 0 } else { consecutiveCrashes += 1 }
            guard consecutiveCrashes < maxRelaunchAttempts else {
                log("PluginHost: shared host crashed \(consecutiveCrashes)× — giving up; chains stay DRY")
                EventCenter.shared.emit(.error, "A plugin kept crashing and was bypassed. The rest of Hydra is unaffected.")
                return
            }
            let delay = min(30.0, 0.5 * pow(2.0, Double(consecutiveCrashes - 1)))
            log("PluginHost: shared host exited (status \(status), uptime \(String(format: "%.1f", uptime))s) — relaunch \(consecutiveCrashes)/\(maxRelaunchAttempts) in \(String(format: "%.1f", delay))s")
            scheduleRelaunch(after: delay)
        }
    }

    private func scheduleRelaunch(after delay: TimeInterval) {
        control.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, !self.shuttingDown else { return }
            self.launch()
        }
    }

    private func startWatchdog() {
        let timer = DispatchSource.makeTimerSource(queue: control)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self, hydra_shm_load_u32(self.aliveFlag) == 1 else { return }
            // Sum heartbeats across chains; if frozen for ~3s, kill → relaunch.
            var sum: UInt64 = 0
            for h in self.handles.values { sum &+= h.heartbeat }
            if sum == self.lastHeartbeatSum, !self.handles.isEmpty {
                self.heartbeatStallTicks += 1
                if self.heartbeatStallTicks >= 3 {
                    log("PluginHost: shared host frozen — killing to relaunch")
                    self.process?.terminate()
                    self.heartbeatStallTicks = 0
                }
            } else { self.heartbeatStallTicks = 0; self.lastHeartbeatSum = sum }
        }
        timer.resume()
        watchdog = timer
    }

    // MARK: stdin control channel (control queue only)

    private func sendAdd(chainID: String, spec: ChainSpec) {
        let plugins = spec.plugins.map { ["spec": $0.0, "title": $0.1] }
        sendLine(["cmd": "add", "chain": chainID, "shm": spec.shm,
                  "channels": spec.channels, "maxFrames": spec.maxFrames,
                  "rate": spec.rate, "plugins": plugins])
    }

    private func sendLine(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return }
        guard let pipe = stdinPipe else {
            log("PluginHost: stdin NOT ready — command dropped (will re-add on launch)")
            return
        }
        var line = data
        line.append(0x0A)
        pipe.fileHandleForWriting.write(line)
    }

    // MARK: Shared memory creation (daemon side)

    private static func createShm(_ name: String, channels: Int, maxFrames: Int)
        -> (UnsafeMutablePointer<hydra_plugin_shm>, UnsafeMutableRawPointer, Int)? {
        let total = Int(hydra_plugin_shm_bytes(Int32(channels), Int32(maxFrames)))
        let fd = hydra_shm_create(name, hydra_plugin_shm_bytes(Int32(channels), Int32(maxFrames)))
        guard fd >= 0 else { return nil }
        defer { close(fd) }
        guard let raw = mmap(nil, total, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0), raw != MAP_FAILED else {
            shm_unlink(name); return nil
        }
        memset(raw, 0, total)
        let h = raw.bindMemory(to: hydra_plugin_shm.self, capacity: 1)
        h.pointee.magic = HYDRA_PLUGIN_SHM_MAGIC
        h.pointee.abiVersion = HYDRA_PLUGIN_SHM_ABI
        h.pointee.channels = Int32(channels)
        h.pointee.maxFrames = Int32(maxFrames)
        return (h, raw, total)
    }

    // MARK: Host binary location (unchanged)

    static func defaultHostURL() -> URL? {
        if let override = ProcessInfo.processInfo.environment["HYDRA_PLUGIN_HOST_PATH"] {
            return URL(fileURLWithPath: override)
        }
        let exeDir = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath().deletingLastPathComponent()
        // When running from Xcode, the FRESHLY BUILT host product sits next to
        // Hydra.app in the Build/Products dir; prefer it so a stale embedded copy
        // (Xcode often skips re-copying the helper) doesn't get launched. exeDir =
        // …/Products/<cfg>/Hydra.app/Contents/MacOS → up 3 = …/Products/<cfg>.
        let productsDir = exeDir.deletingLastPathComponent()   // Contents
            .deletingLastPathComponent()                       // Hydra.app
            .deletingLastPathComponent()                       // Products/<cfg>
        let appHelpers = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/Helpers")
        let candidates = [
            productsDir.appendingPathComponent("hydra-plugin-host.app/Contents/MacOS/hydra-plugin-host"),
            exeDir.appendingPathComponent("hydra-plugin-host"),
            appHelpers.appendingPathComponent("hydra-plugin-host.app/Contents/MacOS/hydra-plugin-host"),
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}
