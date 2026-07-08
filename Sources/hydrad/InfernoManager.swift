// Hydra Audio — GPL-3.0
// Manages the Inferno Dante Virtual Soundcard subprocess.
// Spawns/stops `hydra-inferno-bridge` based on config.infernoEnabled.

import Foundation
import HydraCore
import SystemConfiguration

@MainActor
final class InfernoManager {
    private var process: Process?
    private var isRunning = false
    /// Reference to the bridge manager so we can auto-enable the selected bridge.
    weak var bridgeManager: BridgeManager?

    /// Called whenever the running state changes.
    var onChange: ((Bool) -> Void)?

    /// Apply the current config. If infernoEnabled changed, start or stop the bridge.
    func applyConfig(_ config: ConfigPayload) {
        if config.infernoEnabled && !isRunning {
            start(config: config)
        } else if !config.infernoEnabled && isRunning {
            stop()
        }
    }

    var running: Bool { isRunning }

    /// Resolve interface name to IPv4 address (e.g. "en1" -> "192.168.1.10").
    /// Only considers wired connections (excludes Wi-Fi) for both matching and fallback.
    private func resolveIP(for interfaceName: String) -> String {
        var addr: String?
        var fallbackAddr: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return "127.0.0.1" }
        defer { freeifaddrs(first) }
        
        var wifiIfaces = Set<String>()
        if let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
            for interface in interfaces {
                if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
                   let type = SCNetworkInterfaceGetInterfaceType(interface) as String?,
                   type == kSCNetworkInterfaceTypeIEEE80211 as String {
                    wifiIfaces.insert(bsdName)
                }
            }
        }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            let sa = ifa.pointee.ifa_addr
            if sa?.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: ifa.pointee.ifa_name)
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(sa, socklen_t(MemoryLayout<sockaddr_in>.size),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    let ipStr = String(cString: hostname)
                    if !ipStr.hasPrefix("127.") && !wifiIfaces.contains(name) {
                        if name == interfaceName {
                            addr = ipStr
                            break
                        }
                        if fallbackAddr == nil {
                            fallbackAddr = ipStr
                        }
                    }
                }
            }
            cursor = ifa.pointee.ifa_next
        }
        return addr ?? fallbackAddr ?? "127.0.0.1"
    }

    private func start(config: ConfigPayload) {
        guard !isRunning else { return }

        // Auto-enable the selected Hydra bridge so the CoreAudio device is present.
        if let bm = bridgeManager {
            bm.setEnabled(id: config.infernoBridgeID, enabled: true)
            log("InfernoManager: Auto-enabled bridge \(config.infernoBridgeID)")
        }

        // 1. Look for pre-compiled binary in the App Bundle Resources (production)
        var binaryPath = Bundle.main.url(forResource: "hydra-inferno-bridge", withExtension: nil)

        // 2. If not found in Bundle (dev/Xcode run), compile/fallback to workspace build
        if binaryPath == nil || !FileManager.default.fileExists(atPath: binaryPath!.path) {
            let infernoDir = findInfernoDir()
            let devBinary = infernoDir
                .appendingPathComponent("target")
                .appendingPathComponent("release")
                .appendingPathComponent("hydra-inferno-bridge")

            // Build first if dev binary doesn't exist
            if !FileManager.default.fileExists(atPath: devBinary.path) {
                log("InfernoManager: Building hydra-inferno-bridge in dev workspace...")
                let buildProc = Process()
                buildProc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                buildProc.arguments = ["cargo", "build", "--release", "-p", "hydra-inferno-bridge"]
                buildProc.currentDirectoryURL = infernoDir
                do {
                    try buildProc.run()
                    buildProc.waitUntilExit()
                    guard buildProc.terminationStatus == 0 else {
                        log("InfernoManager: cargo build failed with status \(buildProc.terminationStatus)")
                        return
                    }
                } catch {
                    log("InfernoManager: Failed to run cargo build: \(error)")
                    return
                }
            }
            binaryPath = devBinary
        }

        guard let executablePath = binaryPath else {
            log("InfernoManager: Could not resolve hydra-inferno-bridge binary path.")
            return
        }

        let proc = Process()
        proc.executableURL = executablePath

        let bridgeSpec = Hydra.bridgeCatalog.first { $0.id == config.infernoBridgeID }
        let bridgeName = bridgeSpec?.name ?? "Hydra Audio Bridge \(config.infernoBridgeID)"
        let channels = inferChannelCount(from: config.infernoBridgeID)
        let resolvedIP = resolveIP(for: config.infernoInterface.isEmpty ? "en0" : config.infernoInterface)

        proc.arguments = [
            "--bridge-name", bridgeName,
            "--interface-name", resolvedIP,
            "--latency-ms", "\(config.infernoLatencyMs)",
            "--channels", "\(channels)"
        ]

        var env = ProcessInfo.processInfo.environment
        env["INFERNO_NAME"] = "Hydra Soundcard"
        env["RUST_LOG"] = "info"
        proc.environment = env

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                log("InfernoManager: \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        proc.terminationHandler = { [weak self] p in
            Task { @MainActor in
                self?.handleExit(status: p.terminationStatus)
            }
        }

        do {
            try proc.run()
            process = proc
            isRunning = true
            log("InfernoManager: Started hydra-inferno-bridge (PID \(proc.processIdentifier)) — bridge=\(bridgeName), ip=\(resolvedIP), latency=\(config.infernoLatencyMs)ms")
            onChange?(true)
        } catch {
            log("InfernoManager: Failed to start: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard let proc = process, isRunning else { return }
        proc.terminate()
        process = nil
        isRunning = false
        log("InfernoManager: Stopped")
        onChange?(false)
    }

    private func handleExit(status: Int32) {
        process = nil
        isRunning = false
        log("InfernoManager: Process exited with status \(status)")
        onChange?(false)
    }

    private func inferChannelCount(from bridgeID: String) -> Int {
        if let n = Int(bridgeID) { return n }
        if bridgeID.hasPrefix("2") { return 2 }
        return 2
    }

    private func findInfernoDir() -> URL {
        let bundle = Bundle.main.bundleURL
        var candidate = bundle
        for _ in 0..<6 {
            candidate = candidate.deletingLastPathComponent()
            let inferno = candidate.appendingPathComponent("Sources").appendingPathComponent("Inferno")
            if FileManager.default.fileExists(atPath: inferno.appendingPathComponent("Cargo.toml").path) {
                return inferno
            }
        }
        return URL(fileURLWithPath: "/Users/samuelbacaro/GitHub/Hydra-Soundcard/Sources/Inferno")
    }
}
