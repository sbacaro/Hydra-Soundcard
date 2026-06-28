// HiQnetDiscovery.swift — descoberta nativa HiQnet via DiscoInfo (UDP broadcast).
//
// Faz um broadcast de DiscoInfo (msg 0x0000) na porta 3804 e escuta as respostas;
// o IP do console vem do endereço de origem do datagrama (não do payload). É o
// caminho nativo da Harman — mais rápido e independente de máscara que varrer a
// sub-rede por TCP. [CALIBRAR] confirmar que uma Si real responde a esta query.

import Foundation
#if canImport(Darwin)
import Darwin
#endif
import os

private let discoveryLog = OSLog(subsystem: "audio.hydra", category: "surface-discovery")

public final class HiQnetDiscovery: @unchecked Sendable {

    /// Chamado para cada console que responde: (ip, serial?).
    public var onConsole: (@Sendable (String, String?) -> Void)?

    private var fd: Int32 = -1
    private var source: DispatchSourceRead?
    private let queue = DispatchQueue(label: "audio.hydra.surface.disco")

    public init() {}

    /// Abre o socket, manda o DiscoInfo em broadcast e escuta. `stop()` encerra.
    /// For each local IPv4 interface we send a DiscoInfo whose network block
    /// carries THAT interface's own IP + MAC, broadcast to the interface's
    /// directed broadcast (and the limited broadcast). The console reads our IP
    /// from the payload to dial back over TCP — a zeroed block is ignored, which
    /// is why a bare broadcast wasn't enough. Per-interface addressing also makes
    /// a direct link-local Ethernet link work.
    public func start(me: HiQnet.Address, targetIP: String? = nil) {
        stop()
        let s = socket(AF_INET, SOCK_DGRAM, 0)
        guard s >= 0 else { return }
        var yes: Int32 = 1
        setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &yes, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(s, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Surface.hiqnetTCPPort.bigEndian        // 3804, also for UDP disco
        addr.sin_addr.s_addr = INADDR_ANY
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(s, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0, fcntl(s, F_SETFL, fcntl(s, F_GETFL, 0) | O_NONBLOCK) != -1 else {
            close(s); return
        }
        fd = s

        let src = DispatchSource.makeReadSource(fileDescriptor: s, queue: queue)
        src.setEventHandler { [weak self] in self?.readLoop() }
        src.resume()
        source = src

        // One DiscoInfo per interface, advertising that interface's real IP+MAC.
        var sentLimited = false
        for ifc in Self.localIPv4Interfaces() {
            sendDisco(on: s, me: me, selfIP: ifc.ip, mask: ifc.mask, mac: ifc.mac, to: ifc.bcast)
            if !sentLimited {                 // also hit 255.255.255.255 once
                sendDisco(on: s, me: me, selfIP: ifc.ip, mask: ifc.mask, mac: ifc.mac, to: "255.255.255.255")
                sentLimited = true
            }
            if let targetIP, !targetIP.isEmpty {
                sendDisco(on: s, me: me, selfIP: ifc.ip, mask: ifc.mask, mac: ifc.mac, to: targetIP)
            }
        }
    }

    /// Send a single DiscoInfo (carrying `selfIP`/`mac`) to a broadcast address.
    private func sendDisco(on s: Int32, me: HiQnet.Address,
                            selfIP: (UInt8, UInt8, UInt8, UInt8),
                            mask: (UInt8, UInt8, UInt8, UInt8),
                            mac: [UInt8], to bcast: String) {
        let ipStr = "\(selfIP.0).\(selfIP.1).\(selfIP.2).\(selfIP.3)"
        let macStr = mac.map { String(format: "%02x", $0) }.joined(separator: ":")
        
        let gateway: (UInt8, UInt8, UInt8, UInt8) = (
            selfIP.0 & mask.0,
            selfIP.1 & mask.1,
            selfIP.2 & mask.2,
            (selfIP.3 & mask.3) | (1 & ~mask.3)
        )
        let gwStr = "\(gateway.0).\(gateway.1).\(gateway.2).\(gateway.3)"
        
        print("HiQnetDiscovery: sending invite from \(ipStr) (gw: \(gwStr), mask: \(mask.0).\(mask.1).\(mask.2).\(mask.3)) (\(macStr)) to \(bcast)")
        os_log("HiQnetDiscovery: sending invite from %{public}@ (gw: %{public}@, mask: %d.%d.%d.%d) (%{public}@) to %{public}@", log: discoveryLog, type: .default, ipStr, gwStr, Int(mask.0), Int(mask.1), Int(mask.2), Int(mask.3), macStr, bcast)
        
        let frame = HiQnet.discoInfo(src: me, selfIP: selfIP, mask: mask, gateway: gateway, mac: mac).encoded()
        var dst = sockaddr_in()
        dst.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        dst.sin_family = sa_family_t(AF_INET)
        dst.sin_port = Surface.hiqnetTCPPort.bigEndian
        dst.sin_addr.s_addr = inet_addr(bcast)
        
        frame.withUnsafeBytes { raw in
            let sent = withUnsafePointer(to: &dst) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(s, raw.baseAddress, raw.count, 0, $0,
                           socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            if sent < 0 {
                let errStr = String(cString: strerror(errno))
                print("HiQnetDiscovery: failed to send to \(bcast): \(errStr)")
                os_log("HiQnetDiscovery: failed to send to %{public}@ — error: %{public}@", log: discoveryLog, type: .error, bcast, errStr)
            } else {
                print("HiQnetDiscovery: sent \(sent) bytes to \(bcast)")
                os_log("HiQnetDiscovery: sent %ld bytes to %{public}@", log: discoveryLog, type: .info, sent, bcast)
            }
        }
    }

    /// Every UP, non-loopback IPv4 interface as `(directed-broadcast, ip, mask, mac)`.
    /// MAC comes from the matching AF_LINK entry (by interface name); ip octets are
    /// in normal order (e.g. 192,168,0,121). Used to fill the DiscoInfo so the
    /// console knows our address.
    private static func localIPv4Interfaces()
        -> [(bcast: String, ip: (UInt8, UInt8, UInt8, UInt8), mask: (UInt8, UInt8, UInt8, UInt8), mac: [UInt8])] {
        var macByName: [String: [UInt8]] = [:]
        var out: [(String, (UInt8, UInt8, UInt8, UInt8), (UInt8, UInt8, UInt8, UInt8), [UInt8])] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        // Pass 1: MAC per interface name (AF_LINK / sockaddr_dl).
        #if canImport(Darwin)
        var p: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = p {
            defer { p = cur.pointee.ifa_next }
            guard let a = cur.pointee.ifa_addr, a.pointee.sa_family == UInt8(AF_LINK) else { continue }
            let name = String(cString: cur.pointee.ifa_name)
            a.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { dl in
                let nlen = Int(dl.pointee.sdl_nlen)
                let alen = Int(dl.pointee.sdl_alen)
                guard alen == 6 else { return }
                var mac = [UInt8](repeating: 0, count: 6)
                withUnsafeBytes(of: &dl.pointee.sdl_data) { raw in
                    for i in 0..<6 where nlen + i < raw.count { mac[i] = raw[nlen + i] }
                }
                macByName[name] = mac
            }
        }
        #endif

        // Pass 2: IPv4 interfaces with a broadcast address.
        var q: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = q {
            defer { q = cur.pointee.ifa_next }
            let flags = Int32(cur.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0,
                  (flags & IFF_BROADCAST) == IFF_BROADCAST,
                  let addr = cur.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET),
                  let mask = cur.pointee.ifa_netmask else { continue }
            let name = String(cString: cur.pointee.ifa_name)
            let ipRaw = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            let nm = mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            let b = ipRaw | ~nm                  // network byte order
            let bcast = "\(b & 0xff).\((b >> 8) & 0xff).\((b >> 16) & 0xff).\((b >> 24) & 0xff)"
            let ip: (UInt8, UInt8, UInt8, UInt8) = (UInt8(ipRaw & 0xff), UInt8((ipRaw >> 8) & 0xff),
                                                    UInt8((ipRaw >> 16) & 0xff), UInt8((ipRaw >> 24) & 0xff))
            let maskOctets: (UInt8, UInt8, UInt8, UInt8) = (UInt8(nm & 0xff), UInt8((nm >> 8) & 0xff),
                                                            UInt8((nm >> 16) & 0xff), UInt8((nm >> 24) & 0xff))
            out.append((bcast, ip, maskOctets, macByName[name] ?? [0, 0, 0, 0, 0, 0]))
        }
        return out
    }

    private func readLoop() {
        var buf = [UInt8](repeating: 0, count: 2048)
        while true {
            var from = sockaddr_in()
            var fromLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let n = withUnsafeMutablePointer(to: &from) { fp in
                fp.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    recvfrom(fd, &buf, buf.count, 0, sa, &fromLen)
                }
            }
            if n <= 0 { break }
            let bytes = Array(buf[0..<n])
            guard let frame = HiQnet.Frame.decode(bytes), frame.message == .discoInfo else { continue }
            let a = from.sin_addr.s_addr                       // network byte order
            let ip = "\(a & 0xff).\((a >> 8) & 0xff).\((a >> 16) & 0xff).\((a >> 24) & 0xff)"
            let serial = HiQnet.parseDiscoInfo(frame)?.serial
            onConsole?(ip, (serial?.isEmpty ?? true) ? nil : serial)
        }
    }

    public func stop() {
        source?.cancel(); source = nil
        if fd >= 0 { close(fd); fd = -1 }
    }
}
