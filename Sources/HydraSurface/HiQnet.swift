// HiQnet.swift — codec do protocolo HiQnet (Harman), camada de controle de rede.
// Tudo BIG-ENDIAN (network order). Reimplementação original; ver docs/PROTOCOL.md.

import Foundation

public enum HiQnet {

    // MARK: Message IDs
    public enum Message: UInt16, Sendable {
        case discoInfo          = 0x0000
        case getNetworkInfo     = 0x0002
        case requestAddress     = 0x0004
        case setAddress         = 0x0006
        case goodbye            = 0x0007
        case hello              = 0x0008
        case multiParamSet      = 0x0100   // console -> nós: valores atuais (notificação)
        case multiObjectParamSet = 0x0101
        case paramSetPercent    = 0x0102
        case multiParamGet      = 0x0103
        case getAttributes      = 0x010D
        case multiParamSubscribe = 0x010F  // nós -> console: assinar params específicos
        case paramSubscribePercent = 0x0111
        case multiParamUnsubscribe = 0x0112
        case parameterSubscribeAll = 0x0113 // nós -> console: assinar todos de um VD/object
        case parameterUnsubscribeAll = 0x0114
        case getVDList          = 0x011A
    }

    // MARK: Flags
    public struct Flags: OptionSet, Sendable {
        public let rawValue: UInt16
        public init(rawValue: UInt16) { self.rawValue = rawValue }
        public static let requestAck = Flags(rawValue: 0x0001)
        public static let ack        = Flags(rawValue: 0x0002)
        public static let info       = Flags(rawValue: 0x0004) // set = traz dado (resposta)
        public static let error      = Flags(rawValue: 0x0008)
        public static let guaranteed = Flags(rawValue: 0x0020)
        public static let multipart  = Flags(rawValue: 0x0040)
        public static let session    = Flags(rawValue: 0x0100)
    }

    // MARK: Data types
    public enum DataType: UInt8, Sendable {
        case byte = 0, ubyte, word, uword, long, ulong
        case float32, float64, block, string, long64, ulong64
    }

    /// Valor tipado HiQnet (1 byte de tipo + payload).
    public enum Value: Sendable, Equatable {
        case byte(Int8), ubyte(UInt8), word(Int16), uword(UInt16)
        case long(Int32), ulong(UInt32)
        case float32(Float), float64(Double)
        case block([UInt8]), string(String)
        case long64(Int64), ulong64(UInt64)

        public var dataType: DataType {
            switch self {
            case .byte: .byte;      case .ubyte: .ubyte
            case .word: .word;      case .uword: .uword
            case .long: .long;      case .ulong: .ulong
            case .float32: .float32; case .float64: .float64
            case .block: .block;    case .string: .string
            case .long64: .long64;  case .ulong64: .ulong64
            }
        }

        /// Inteiro de conveniência (para os usos típicos da surface).
        public var intValue: Int {
            switch self {
            case .byte(let v): Int(v);   case .ubyte(let v): Int(v)
            case .word(let v): Int(v);   case .uword(let v): Int(v)
            case .long(let v): Int(v);   case .ulong(let v): Int(v)
            case .float32(let v): Int(v); case .float64(let v): Int(v)
            case .long64(let v): Int(v); case .ulong64(let v): Int(v)
            case .block, .string: 0
            }
        }

        public func encoded() -> [UInt8] {
            var out: [UInt8] = [dataType.rawValue]
            switch self {
            case .byte(let v):   out.append(UInt8(bitPattern: v))
            case .ubyte(let v):  out.append(v)
            case .word(let v):   out.appendBE(UInt16(bitPattern: v))
            case .uword(let v):  out.appendBE(v)
            case .long(let v):   out.appendBE(UInt32(bitPattern: v))
            case .ulong(let v):  out.appendBE(v)
            case .float32(let v): out.appendBE(v.bitPattern)
            case .float64(let v): out.appendBE(v.bitPattern)
            case .long64(let v):  out.appendBE(UInt64(bitPattern: v))
            case .ulong64(let v): out.appendBE(v)
            case .block(let b):  out.appendBE(UInt16(b.count)); out.append(contentsOf: b)
            case .string(let s):
                let u = Array(s.utf16).flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] }
                out.appendBE(UInt16(u.count)); out.append(contentsOf: u)
            }
            return out
        }

        /// Lê um valor tipado. Retorna (valor, novoOffset) ou nil se inválido.
        public static func read(_ b: [UInt8], at off: Int) -> (Value, Int)? {
            guard off < b.count, let t = DataType(rawValue: b[off]) else { return nil }
            var p = off + 1
            func need(_ n: Int) -> Bool { p + n <= b.count }
            switch t {
            case .byte:    guard need(1) else { return nil }; return (.byte(Int8(bitPattern: b[p])), p + 1)
            case .ubyte:   guard need(1) else { return nil }; return (.ubyte(b[p]), p + 1)
            case .word:    guard need(2) else { return nil }; return (.word(Int16(bitPattern: b.beU16(p))), p + 2)
            case .uword:   guard need(2) else { return nil }; return (.uword(b.beU16(p)), p + 2)
            case .long:    guard need(4) else { return nil }; return (.long(Int32(bitPattern: b.beU32(p))), p + 4)
            case .ulong:   guard need(4) else { return nil }; return (.ulong(b.beU32(p)), p + 4)
            case .float32: guard need(4) else { return nil }; return (.float32(Float(bitPattern: b.beU32(p))), p + 4)
            case .float64: guard need(8) else { return nil }; return (.float64(Double(bitPattern: b.beU64(p))), p + 8)
            case .long64:  guard need(8) else { return nil }; return (.long64(Int64(bitPattern: b.beU64(p))), p + 8)
            case .ulong64: guard need(8) else { return nil }; return (.ulong64(b.beU64(p)), p + 8)
            case .block:
                guard need(2) else { return nil }; let n = Int(b.beU16(p)); p += 2
                guard p + n <= b.count else { return nil }
                return (.block(Array(b[p..<p+n])), p + n)
            case .string:
                guard need(2) else { return nil }; let n = Int(b.beU16(p)); p += 2
                guard p + n <= b.count else { return nil }
                let units = stride(from: p, to: p + n - 1, by: 2).map { UInt16(b[$0]) << 8 | UInt16(b[$0 + 1]) }
                return (.string(String(utf16CodeUnits: units, count: units.count)), p + n)
            }
        }
    }

    // MARK: Endereço — device(2) + VD(1) + object(3)
    public struct Address: Sendable, Equatable, Hashable {
        public var device: UInt16
        public var vd: UInt8
        public var object: UInt32   // 24 bits
        public init(device: UInt16 = 0, vd: UInt8 = 0, object: UInt32 = 0) {
            self.device = device; self.vd = vd; self.object = object & 0xFF_FFFF
        }
        public func packed() -> [UInt8] {
            var out: [UInt8] = []
            out.appendBE(device)
            out.append(vd)
            out.append(UInt8((object >> 16) & 0xFF))
            out.append(UInt8((object >> 8) & 0xFF))
            out.append(UInt8(object & 0xFF))
            return out
        }
        public static func unpack(_ b: [UInt8], at off: Int) -> Address? {
            guard off + 6 <= b.count else { return nil }
            return Address(device: b.beU16(off), vd: b[off + 2],
                           object: UInt32(b[off+3]) << 16 | UInt32(b[off+4]) << 8 | UInt32(b[off+5]))
        }
        public var description: String { "\(device).\(vd).\(object >> 16).\((object >> 8) & 0xFF).\(object & 0xFF)" }
    }

    // MARK: Frame (header 25 bytes + payload)
    public struct Frame: Sendable {
        public var message: Message
        public var src: Address
        public var dst: Address
        public var payload: [UInt8]
        public var flags: Flags
        public var hop: UInt8
        public var seq: UInt16
        public var version: UInt8

        public init(_ message: Message, src: Address, dst: Address, payload: [UInt8] = [],
                    flags: Flags = [], hop: UInt8 = 5, seq: UInt16 = 0, version: UInt8 = 2) {
            self.message = message; self.src = src; self.dst = dst; self.payload = payload
            self.flags = flags; self.hop = hop; self.seq = seq; self.version = version
        }

        public func encoded() -> [UInt8] {
            let headerLen: UInt8 = 25
            var out: [UInt8] = []
            out.append(version)
            out.append(headerLen)
            out.appendBE(UInt32(Int(headerLen) + payload.count))   // messageLen
            out.append(contentsOf: src.packed())
            out.append(contentsOf: dst.packed())
            out.appendBE(message.rawValue)
            out.appendBE(flags.rawValue)
            out.append(hop)
            out.appendBE(seq)
            out.append(contentsOf: payload)
            return out
        }

        public static func decode(_ b: [UInt8]) -> Frame? {
            guard b.count >= 25, let mid = Message(rawValue: b.beU16(18)),
                  let s = Address.unpack(b, at: 6), let d = Address.unpack(b, at: 12) else { return nil }
            let headerLen = Int(b[1])
            let msgLen = Int(b.beU32(2))
            let payload = (headerLen < msgLen && msgLen <= b.count) ? Array(b[headerLen..<msgLen]) : []
            return Frame(mid, src: s, dst: d, payload: payload,
                         flags: Flags(rawValue: b.beU16(20)), hop: b[22], seq: b.beU16(23), version: b[0])
        }
    }

    /// Extrai frames completos de um buffer de stream TCP (consome o buffer).
    public static func frames(from buffer: inout [UInt8]) -> [Frame] {
        var out: [Frame] = []
        while buffer.count >= 6 {
            let msgLen = Int(buffer.beU32(2))
            if msgLen < 25 || msgLen > (1 << 20) { buffer.removeFirst(); continue }
            if buffer.count < msgLen { break }
            if let f = Frame.decode(Array(buffer[0..<msgLen])) { out.append(f) }
            buffer.removeFirst(msgLen)
        }
        return out
    }

    // MARK: Builders
    public static func hello(src: Address, dst: Address, session: UInt16 = 1, flagMask: UInt16 = 0x01FF, flags: Flags = [.session]) -> Frame {
        var p: [UInt8] = []; p.appendBE(session); p.appendBE(flagMask)
        return Frame(.hello, src: src, dst: dst, payload: p, flags: flags)
    }

    /// DiscoInfo discovery query (msg 0x0000), broadcast. Payload per the HiQnet
    /// Third Party Programmers Guide v2 (Wireshark `packet-hiqnet.c`):
    ///   devAddr:U16 · cost:U8 · serialLen:U16+serial · maxMsgSize:U32 ·
    ///   keepAlive:U16 · netID:U8(=1 TCP/IP) · MAC:6 · dhcp:U8 · IP:4 · mask:4 · gw:4
    /// MAC/serial are best-effort (zeros/empty) — the console replies to our UDP
    /// source IP regardless. [CALIBRAR] confirm a real Si answers this query.
    public static func discoInfo(src: Address,
                                 selfIP: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0),
                                 mask: (UInt8, UInt8, UInt8, UInt8) = (255, 255, 255, 0),
                                 gateway: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0),
                                 mac: [UInt8] = [0, 0, 0, 0, 0, 0],
                                 keepAlive: UInt16 = 10_000) -> Frame {
        // CRITICAL: the IP/MAC below are how the console learns where to dial back
        // (HiQnet is inbound). A zeroed block = the invite is silently ignored, so
        // these MUST be the real address of the sending interface.
        let macBytes = (mac.count == 6) ? mac : [0, 0, 0, 0, 0, 0]
        var p: [UInt8] = []
        p.appendBE(src.device)                 // devAddr
        p.append(0)                            // cost
        let serialBytes = Array("Hydra".utf8)
        p.appendBE(UInt16(serialBytes.count))  // serial length
        p += serialBytes                       // serial
        p.appendBE(UInt32(1048576))            // maxMessageSize (changed from 1500 to 1MB)
        p.appendBE(keepAlive)                  // keepAlivePeriod (ms)
        p.append(1)                            // netID = TCP/IP
        p += macBytes                          // our MAC (6)
        p.append(1)                            // dhcp (1 = automatic/DHCP address)
        p += [selfIP.0, selfIP.1, selfIP.2, selfIP.3]  // our IP
        p += [mask.0, mask.1, mask.2, mask.3]          // subnet mask
        p += [gateway.0, gateway.1, gateway.2, gateway.3] // gateway
        // Broadcast device address 0xFFFF; INFO flag not set (this is a query).
        return Frame(.discoInfo, src: src, dst: Address(device: 0xFFFF), payload: p)
    }

    /// Parse a DiscoInfo reply → (device address, serial string). The console's
    /// IP comes from the UDP source address, not the payload.
    public static func parseDiscoInfo(_ frame: Frame) -> (device: UInt16, serial: String)? {
        guard frame.message == .discoInfo else { return nil }
        let p = frame.payload
        guard p.count >= 3 else { return nil }
        let device = p.beU16(0)
        guard p.count >= 5 else { return (device, "") }
        let serialLen = Int(p.beU16(3))
        var serial = ""
        if 5 + serialLen <= p.count {
            let bytes = p[5 ..< 5 + serialLen].filter { $0 >= 0x20 && $0 < 0x7f }
            serial = String(bytes: bytes, encoding: .ascii) ?? ""
        }
        return (device, serial)
    }

    public static func getVDList(src: Address, dst: Address, path: String) -> Frame {
        let u = Array(path.utf16).flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] }
        var p: [UInt8] = []; p.appendBE(UInt16(u.count)); p.append(contentsOf: u)
        return Frame(.getVDList, src: src, dst: dst, payload: p)
    }

    public static func subscribeAll(src: Address, dst: Address, target: Address,
                                    subType: DataType = .ubyte, sensorRate: UInt16 = 0,
                                    subFlags: UInt16 = 0) -> Frame {
        var p: [UInt8] = []
        p.appendBE(target.device); p.append(target.vd)
        p.append(UInt8((target.object >> 16) & 0xFF)); p.append(UInt8((target.object >> 8) & 0xFF)); p.append(UInt8(target.object & 0xFF))
        p.append(subType.rawValue); p.appendBE(sensorRate); p.appendBE(subFlags)
        return Frame(.parameterSubscribeAll, src: src, dst: dst, payload: p)
    }

    public struct Subscription: Sendable {
        public var publisherParamID: UInt16
        public var subType: DataType
        public var subscriberAddr: Address
        public var subscriberParamID: UInt16
        public var sensorRate: UInt16
        public init(publisherParamID: UInt16, subscriberAddr: Address, subType: DataType = .ubyte,
                    subscriberParamID: UInt16 = 0, sensorRate: UInt16 = 0) {
            self.publisherParamID = publisherParamID; self.subType = subType
            self.subscriberAddr = subscriberAddr; self.subscriberParamID = subscriberParamID
            self.sensorRate = sensorRate
        }
    }

    public static func multiParamSubscribe(src: Address, dst: Address, subs: [Subscription]) -> Frame {
        var p: [UInt8] = []; p.appendBE(UInt16(subs.count))
        for s in subs {
            p.appendBE(s.publisherParamID); p.append(s.subType.rawValue)
            p.append(contentsOf: s.subscriberAddr.packed())
            p.appendBE(s.subscriberParamID); p.append(0); p.appendBE(UInt16(0)); p.appendBE(s.sensorRate)
        }
        return Frame(.multiParamSubscribe, src: src, dst: dst, payload: p)
    }

    /// Escreve parâmetros no console (ex.: mover motor, setar estado).
    public static func multiParamSet(src: Address, dst: Address, params: [(UInt16, Value)]) -> Frame {
        var p: [UInt8] = []; p.appendBE(UInt16(params.count))
        for (pid, v) in params { p.appendBE(pid); p.append(contentsOf: v.encoded()) }
        return Frame(.multiParamSet, src: src, dst: dst, payload: p, flags: .info)
    }

    // MARK: Parser
    /// (param_id, valor) de um MultiParamSet recebido.
    public static func parseMultiParamSet(_ frame: Frame) -> [(UInt16, Value)] {
        let b = frame.payload
        guard b.count >= 2 else { return [] }
        let count = Int(b.beU16(0))
        var off = 2
        var out: [(UInt16, Value)] = []
        for _ in 0..<count {
            guard off + 2 <= b.count else { break }
            let pid = b.beU16(off); off += 2
            guard let (v, next) = Value.read(b, at: off) else { break }
            out.append((pid, v)); off = next
        }
        return out
    }
}

// MARK: - Helpers big-endian
extension Array where Element == UInt8 {
    mutating func appendBE<T: FixedWidthInteger>(_ v: T) {
        var be = v.bigEndian
        // Qualify with `Swift.` — inside an Array extension the unqualified name
        // resolves to Array's instance `withUnsafeBytes`, not the global one.
        Swift.withUnsafeBytes(of: &be) { append(contentsOf: $0) }
    }
    func beU16(_ o: Int) -> UInt16 { UInt16(self[o]) << 8 | UInt16(self[o + 1]) }
    func beU32(_ o: Int) -> UInt32 { UInt32(self[o]) << 24 | UInt32(self[o+1]) << 16 | UInt32(self[o+2]) << 8 | UInt32(self[o+3]) }
    func beU64(_ o: Int) -> UInt64 {
        var r: UInt64 = 0; for i in 0..<8 { r = (r << 8) | UInt64(self[o + i]) }; return r
    }
}
