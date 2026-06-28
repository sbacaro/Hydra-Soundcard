// HiQnetClient.swift — servidor HiQnet sobre TCP (Network.framework) + listener de meter UDP.

import Foundation

#if canImport(Network)
import Network
import os

private let serverLog = OSLog(subsystem: "audio.hydra", category: "surface-server")

/// HiQnet TCP **server**. Counter-intuitively, a Soundcraft Si/Vi console does
/// NOT listen on TCP/3804 — it *dials back* to the controller. The flow (RE'd by
/// the Mixing Station project, and confirmed against a live Si Expression 3 on
/// 2026-06-27) is:
///   1. the controller broadcasts a DiscoInfo "connect request" over UDP/3804
///      (see `HiQnetDiscovery`), advertising its own IP as the datagram source;
///   2. the **console connects to the controller** over TCP/3804.
/// So we run a listener and treat the inbound connection as the session. The
/// console's IP is the peer of that connection (reported via `onState`).
public final class HiQnetServer: @unchecked Sendable {
    private var listener: NWListener?
    private var connection: NWConnection?            // the console's inbound session
    private let queue = DispatchQueue(label: "com.hydra.surface.hiqnet")
    private var rxBuffer: [UInt8] = []

    public var onFrame: (@Sendable (HiQnet.Frame) -> Void)?
    /// `(ready, peerIP)`. `ready=true` once a console has connected (`peerIP` = its
    /// address, for display/auto-fill); `ready=false` when the session drops.
    public var onState: (@Sendable (Bool, String?) -> Void)?

    public init() {}

    /// Open the TCP listener on `port` (3804). Idempotent: a prior listener/session
    /// is torn down first.
    public func start(port: UInt16 = Surface.hiqnetTCPPort) throws {
        stop()
        os_log("HiQnetServer: starting TCP listener on port %d", log: serverLog, type: .default, port)
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        let l = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port) ?? 3804)
        listener = l
        l.newConnectionHandler = { [weak self] conn in self?.accept(conn) }
        l.start(queue: queue)
    }

    /// Accept an inbound console connection. HiQnet is one-app-at-a-time, so a new
    /// connection replaces any previous session.
    private func accept(_ conn: NWConnection) {
        os_log("HiQnetServer: accepted connection from %{public}@", log: serverLog, type: .default, String(describing: conn.endpoint))
        connection?.cancel()
        rxBuffer.removeAll(keepingCapacity: true)
        connection = conn
        conn.stateUpdateHandler = { [weak self] state in
            guard let self, conn === self.connection else { return }
            os_log("HiQnetServer: connection state changed to %{public}@", log: serverLog, type: .default, String(describing: state))
            switch state {
            case .ready:
                self.onState?(true, Self.peerIP(conn))
                self.receiveLoop(conn)
            case .failed(let error):
                os_log("HiQnetServer: connection failed with error: %{public}@", log: serverLog, type: .error, String(describing: error))
                self.onState?(false, nil)
            case .cancelled:
                self.onState?(false, nil)
            default: break
            }
        }
        conn.start(queue: queue)
    }

    /// Send a frame to the connected console (no-op if none).
    public func send(_ frame: HiQnet.Frame) {
        connection?.send(content: Data(frame.encoded()), completion: .contentProcessed { _ in })
    }

    /// Drop the active console session but keep listening for a new one.
    public func dropSession() {
        connection?.cancel(); connection = nil
    }

    /// Tear down the listener and any session.
    public func stop() {
        connection?.cancel(); connection = nil
        listener?.cancel(); listener = nil
    }

    private func receiveLoop(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self, conn === self.connection else { return }
            if let data, !data.isEmpty {
                self.rxBuffer.append(contentsOf: data)
                for frame in HiQnet.frames(from: &self.rxBuffer) { self.onFrame?(frame) }
            }
            if error == nil { self.receiveLoop(conn) } else { self.onState?(false, nil) }
        }
    }

    /// IPv4/host of the connected peer, for display and consoleIP auto-fill.
    private static func peerIP(_ conn: NWConnection) -> String? {
        let ep = conn.currentPath?.remoteEndpoint ?? conn.endpoint
        guard case let .hostPort(host, _) = ep else { return nil }
        switch host {
        case .ipv4(let a):
            var s = "\(a)"
            if let i = s.firstIndex(of: "%") { s = String(s[..<i]) }   // strip %ifc (link-local)
            return s
        case .ipv6(let a): return "\(a)"
        case .name(let n, _): return n
        @unknown default: return nil
        }
    }
}

/// Listener UDP para o despatch de meter (porta 3333). [CALIBRAR] formato do pacote.
public final class MeterListener: @unchecked Sendable {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.hydra.surface.meter")
    public var onPacket: (@Sendable ([UInt8]) -> Void)?

    public init() {}

    public func start(port: UInt16 = Surface.meterUDPPort) throws {
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        let l = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port) ?? 3333)
        listener = l
        l.newConnectionHandler = { [weak self] conn in
            conn.start(queue: self?.queue ?? .global())
            self?.receive(on: conn)
        }
        l.start(queue: queue)
    }

    private func receive(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, _ in
            if let data, !data.isEmpty { self?.onPacket?(Array(data)) }
            self?.receive(on: conn)
        }
    }

    public func stop() { listener?.cancel(); listener = nil }
}
#endif
