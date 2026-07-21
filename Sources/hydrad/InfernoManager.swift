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
    public private(set) var activeIP: String = "127.0.0.1"

    /// Resolve interface name to IPv4 address (e.g. "en1" -> "192.168.1.10").
    /// Only considers wired connections (excludes Wi-Fi). Returns nil if not found or interface is invalid.
    private func resolveIP(for interfaceName: String) -> String? {
        guard !interfaceName.isEmpty else { return nil }
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(first) }
        
        let wifiIfaces = NetworkUtils.wifiInterfaces

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            let sa = ifa.pointee.ifa_addr
            let flags = ifa.pointee.ifa_flags
            let isUpAndRunning = (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_RUNNING)) != 0
            if sa?.pointee.sa_family == UInt8(AF_INET) && isUpAndRunning {
                let name = String(cString: ifa.pointee.ifa_name)
                if name == interfaceName {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(sa, socklen_t(MemoryLayout<sockaddr_in>.size),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let ipStr = String(cString: hostname)
                        let isTunnel = name.hasPrefix("utun") || name.hasPrefix("tun") || name.hasPrefix("tap") || name.hasPrefix("gif") || name.hasPrefix("stf") || name.hasPrefix("ppp") || name.hasPrefix("ipsec")
                        if !ipStr.hasPrefix("127.") && !isTunnel && !wifiIfaces.contains(name) {
                            return ipStr
                        }
                    }
                }
            }
            cursor = ifa.pointee.ifa_next
        }
        return nil
    }

    private func start(config: ConfigPayload) {
        guard !isRunning else { return }

        guard !config.infernoInterface.isEmpty else {
            log("InfernoManager: Refusing to start Dante — no network interface selected.")
            return
        }

        guard let resolvedIP = resolveIP(for: config.infernoInterface) else {
            log("InfernoManager: Refusing to start Dante — selected interface '\(config.infernoInterface)' has no valid IPv4 address or is down.")
            return
        }

        // Auto-enable the selected Hydra bridge so the CoreAudio device is present.
        if let bm = bridgeManager {
            bm.setEnabled(id: config.infernoBridgeID, enabled: true)
            log("InfernoManager: Auto-enabled bridge \(config.infernoBridgeID)")
        }

        // 1. Look for pre-compiled binary in the App Bundle Resources (production)
        var binaryPath = Bundle.main.url(forResource: "hydra-inferno-bridge", withExtension: nil)

        // 2. If not found in Bundle (dev/Xcode run), fallback to the workspace build product.
        //    If the binary doesn't exist yet, kick off a background `cargo build` so the UI
        //    never freezes — the start() call returns immediately and retries are not needed
        //    because InfernoManager.applyConfig() is edge-triggered on infernoEnabled.
        if binaryPath == nil || !FileManager.default.fileExists(atPath: binaryPath!.path) {
            let infernoDir = findInfernoDir()
            let devBinary = infernoDir
                .appendingPathComponent("target")
                .appendingPathComponent("release")
                .appendingPathComponent("hydra-inferno-bridge")

            if !FileManager.default.fileExists(atPath: devBinary.path) {
                log("InfernoManager: hydra-inferno-bridge not built yet — starting background cargo build...")
                // Dispatch cargo build to a background thread so we never block @MainActor.
                Task.detached(priority: .utility) {
                    let buildProc = Process()
                    buildProc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                    buildProc.arguments = ["cargo", "build", "--release", "-p", "hydra-inferno-bridge"]
                    buildProc.currentDirectoryURL = infernoDir
                    do {
                        try buildProc.run()
                        buildProc.waitUntilExit()
                        if buildProc.terminationStatus == 0 {
                            log("InfernoManager: cargo build succeeded — re-enable Dante to start.")
                        } else {
                            log("InfernoManager: cargo build failed with status \(buildProc.terminationStatus)")
                        }
                    } catch {
                        log("InfernoManager: Failed to run cargo build: \(error)")
                    }
                }
                log("InfernoManager: Binary not ready yet. Re-enable Dante once the build finishes.")
                return
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

        proc.arguments = [
            "--bridge-name", bridgeName,
            // BIND_IP in inferno accepts either an IPv4 address or an interface name.
            // We resolve to an IP here so the correct address is always used even
            // when the user selects "en0" (which may have multiple addresses).
            "--bind-ip", resolvedIP,
            "--latency-ms", "\(config.infernoLatencyMs)",
            "--channels", "\(channels)"
        ]

        var env = ProcessInfo.processInfo.environment
        env["INFERNO_NAME"] = "Hydra Soundcard"
        env["INFERNO_MANUFACTURER"] = "Hydra Audio"
        env["INFERNO_MODEL_NAME"] = "Hydra Soundcard"
        env["INFERNO_BOARD_NAME"] = "Hydra Soundcard"
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
            self.activeIP = resolvedIP
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
        activeIP = "127.0.0.1"
        log("InfernoManager: Stopped")
        onChange?(false)
    }

    private func handleExit(status: Int32) {
        process = nil
        isRunning = false
        activeIP = "127.0.0.1"
        log("InfernoManager: Process exited with status \(status)")
        onChange?(false)
    }

    /// Returns the channel count for the given bridge ID by looking it up in the
    /// catalog. Falls back to 2 only if the ID is somehow not in the catalog
    /// (which should never happen in production — catalog and config share IDs).
    private func inferChannelCount(from bridgeID: String) -> Int {
        Hydra.bridgeCatalog.first { $0.id == bridgeID }?.channels ?? 2
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
