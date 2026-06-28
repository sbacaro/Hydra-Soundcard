// SurfaceBridge.swift — engine + API observável (pronta para SwiftUI).
//
// Liga o console (HiQnet/rede) ao DAW (HUI/MIDI), nos dois sentidos:
//   surface -> DAW : MultiParamSet do console  -> traduz -> HUI MIDI
//   DAW -> surface : HUI MIDI do DAW            -> traduz -> MultiParamSet
//
// MULTI-UNIDADE: o HUI expõe 8 strips por dispositivo. Para cobrir os ~32 faders
// da Si Expression 3 SIMULTANEAMENTE, a ponte publica N unidades HUI (N portas
// MIDI VIRTUAIS, criadas pela própria Hydra — sem IAC manual). A unidade `u`
// cobre os strips globais [u*8 .. u*8+7]; o slot do console é
// `globalStrip + 1 + bankOffset` (o offset segue o banco/layer da mesa).
//
// A UI observa as propriedades @Observable. I/O em background marshalado p/ MainActor.

import Foundation
import Observation

@MainActor
@Observable
public final class SurfaceBridge {

    // MARK: Estado observável (para a UI)
    public private(set) var isConnected = false        // sessão HiQnet com o console
    public private(set) var isOnlineToDAW = false      // heartbeat HUI ativo
    public private(set) var heartbeatCount = 0
    public private(set) var faders: [Int]              // 0..255 por strip (len = stripCount)
    public private(set) var mutes: [Bool]
    public private(set) var solos: [Bool]
    public private(set) var selects: [Bool]
    /// Track names from the DAW (HUI scribble), per strip — for the console LCD
    /// and the UI monitor. Length = stripCount.
    public private(set) var channelNames: [String]
    public private(set) var lastError: String?
    public private(set) var meterPacketCount = 0
    /// Nomes das portas MIDI virtuais publicadas (uma por unidade HUI) — o que o
    /// usuário adiciona como controladores HUI na DAW.
    public private(set) var portNames: [String] = []

    /// IP of the console currently dialed in (HiQnet is inbound — the console
    /// connects to us). Set from the listener's peer; empty when not connected.
    public private(set) var consoleIP: String = ""
    /// Offset (em strips) do banco/layer ativo da mesa. slot = strip+1+bankOffset.
    /// Segue automaticamente as trocas de layer do console (quando calibrado).
    public var bankOffset = 0
    /// Diagnostic sink. The host (daemon) wires this to its logger; nil = silent.
    /// Keeps this package free of any Hydra/daemon dependency.
    public var onLog: ((String) -> Void)?

    /// Número de unidades HUI (cada uma = 8 strips).
    public let unitCount: Int
    public var stripCount: Int { unitCount * 8 }

    // MARK: Config
    public struct Config: Sendable {
        /// Prefixo das portas virtuais: vira "Hydra HUI 1" … "Hydra HUI N".
        public var portBaseName: String
        public var heartbeat: Bool
        public var listenMeters: Bool
        /// Loga cada frame HiQnet recebido + dump (throttled) do pacote de meter.
        /// Só produz saída com um console real conectado — ideal p/ a 1ª sessão de
        /// calibração. Ver via Console.app ou `log show --predicate
        /// 'subsystem == "audio.hydra"' --info`.
        public var diagnostics: Bool
        /// Modo IAC opcional (avançado): nomes de portas existentes por unidade.
        /// nil = cria portas VIRTUAIS (modo automático, recomendado).
        public var unitInNames: [String]?
        public var unitOutNames: [String]?
        public init(portBaseName: String = "Hydra HUI", heartbeat: Bool = true,
                    listenMeters: Bool = false, diagnostics: Bool = false,
                    unitInNames: [String]? = nil, unitOutNames: [String]? = nil) {
            self.portBaseName = portBaseName
            self.heartbeat = heartbeat
            self.listenMeters = listenMeters
            self.diagnostics = diagnostics
            self.unitInNames = unitInNames
            self.unitOutNames = unitOutNames
        }
    }

    // MARK: Interno
    private var midis: [MIDIBackend] = []
    private var decoders: [HUI.Decoder] = []
    private var heartbeatTask: Task<Void, Never>?
    private struct SlotKey: Hashable { let slot: Int; let sub: Surface.SubObject }
    private var slotAddresses: [SlotKey: HiQnet.Address] = [:]
    private var addrToSlot: [HiQnet.Address: SlotKey] = [:]
    private let me = HiQnet.Address(device: 0xA2)      // device addr do bridge [CALIBRAR]
    private var console = HiQnet.Address(device: 0)
    private var diagnostics = false
    private var requestedMap = false               // surface map requested this session

    #if canImport(Network)
    private var server: HiQnetServer?
    private var meterListener: MeterListener?
    #endif

    public init(unitCount: Int = 4) {
        self.unitCount = max(1, min(unitCount, 8))      // Pro Tools/Logic: até 4 (32 ch); teto 8
        let n = self.unitCount * 8
        faders = Array(repeating: 0, count: n)
        mutes = Array(repeating: false, count: n)
        solos = Array(repeating: false, count: n)
        selects = Array(repeating: false, count: n)
        channelNames = Array(repeating: "", count: n)
    }

    // MARK: Ciclo de vida
    /// Inicia o bridge: publica N unidades HUI (portas virtuais) e abre o listener
    /// HiQnet (a mesa conecta de volta — HiQnet é de entrada). Sem IP a configurar.
    public func start(config: Config = Config()) {
        do {
            midis = try buildBackends(config)
        } catch {
            lastError = "MIDI: \(error)"
            return
        }
        decoders = (0..<unitCount).map { _ in HUI.Decoder() }
        portNames = (0..<unitCount).map { "\(config.portBaseName) \($0 + 1)" }
        diagnostics = config.diagnostics

        for u in 0..<midis.count {
            midis[u].setReceiveHandler { [weak self] bytes in
                Task { @MainActor in self?.handleMIDI(unit: u, bytes) }
            }
        }
        if config.heartbeat { startHeartbeat() }

        #if canImport(Network)
        // Always listen: the console dials us. No outbound connect, no IP needed.
        startListening()
        if config.listenMeters {
            let m = MeterListener()
            m.onPacket = { [weak self] bytes in Task { @MainActor in self?.onMeterPacket(bytes) } }
            try? m.start()
            meterListener = m
        }
        #endif
    }

    private func onMeterPacket(_ bytes: [UInt8]) {
        meterPacketCount += 1
        guard diagnostics else { return }
        // Throttle: first packet, then ~1/s (assume ~25/s), plus any odd size.
        let sizeMatch = bytes.count == Surface.meterPacketBytes
        if meterPacketCount == 1 || meterPacketCount % 25 == 0 || !sizeMatch {
            onLog?("Surface METER #\(meterPacketCount) \(bytes.count)B"
                + (sizeMatch ? "" : " (expected \(Surface.meterPacketBytes)!)")
                + " [\(Self.hexDump(bytes, max: 64))]")
        }
    }

    /// Compact hex dump (first `max` bytes) for diagnostics.
    private static func hexDump(_ b: [UInt8], max: Int) -> String {
        b.prefix(max).map { String(format: "%02x", $0) }.joined(separator: " ")
            + (b.count > max ? " …" : "")
    }

    public func stop() {
        heartbeatTask?.cancel(); heartbeatTask = nil
        isOnlineToDAW = false
        for m in midis { m.close() }
        midis = []
        decoders = []
        portNames = []
        #if canImport(Network)
        server?.stop(); server = nil
        meterListener?.stop(); meterListener = nil
        #endif
        isConnected = false
        requestedMap = false
    }

    private func buildBackends(_ config: Config) throws -> [MIDIBackend] {
        #if canImport(CoreMIDI)
        var result: [MIDIBackend] = []
        result.reserveCapacity(unitCount)
        for u in 0..<unitCount {
            let name = "\(config.portBaseName) \(u + 1)"
            let out = (config.unitOutNames?.indices.contains(u) ?? false) ? config.unitOutNames?[u] : nil
            let inn = (config.unitInNames?.indices.contains(u) ?? false) ? config.unitInNames?[u] : nil
            result.append(try CoreMIDIBackend(name: name, outName: out, inName: inn))
        }
        return result
        #else
        throw NSError(domain: "HydraSurface", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "CoreMIDI indisponível nesta plataforma"])
        #endif
    }

    // MARK: Sessão HiQnet (independente do MIDI — não derruba as portas HUI)
    #if canImport(Network)
    /// Start (or restart) the HiQnet TCP listener so the console can dial in.
    /// HiQnet is inbound: we never connect out — we listen on 3804 and the console
    /// connects to us after receiving the DiscoInfo broadcast invite (sent by the
    /// daemon's SurfaceManager). Safe to call repeatedly; MIDI is untouched.
    public func startListening() {
        server?.stop()
        let s = HiQnetServer()
        s.onState = { [weak self] ready, peer in
            Task { @MainActor in self?.onHiQnetState(ready, peer: peer) }
        }
        s.onFrame = { [weak self] frame in Task { @MainActor in self?.handleFrame(frame) } }
        server = s
        do { try s.start() } catch {
            lastError = "HiQnet listen: \(error)"
            server = nil
        }
    }

    /// Drop the current console session. The listener keeps running, so the same
    /// console (after a reboot) or another one can reconnect.
    public func disconnectConsole() {
        server?.dropSession()
        isConnected = false
        consoleIP = ""
        requestedMap = false
    }
    #endif

    /// Registra o endereço de um objeto de slot e **assina** (feedback de fader/LED).
    /// Usado pelo `learnVD` (após GetVDList) e como fallback manual.
    public func setSlotAddress(slot: Int, sub: Surface.SubObject, address: HiQnet.Address) {
        let k = SlotKey(slot: slot, sub: sub)
        slotAddresses[k] = address
        addrToSlot[address] = k
        #if canImport(Network)
        server?.send(HiQnet.subscribeAll(src: me, dst: console, target: address))
        #endif
    }

    // MARK: Heartbeat (keep-alive HUI — uma resposta por unidade, ver PROTOCOL §ping)
    private func startHeartbeat() {
        isOnlineToDAW = true
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                for m in self.midis { m.send(HUI.pingReply) }
                self.heartbeatCount &+= 1
            }
        }
    }

    // MARK: DAW -> surface (HUI recebido numa unidade `unit`)
    private func handleMIDI(unit: Int, _ bytes: [UInt8]) {
        guard decoders.indices.contains(unit) else { return }
        for ev in decoders[unit].feed(bytes) {
            switch ev {
            case .ping:
                midis[unit].send(HUI.pingReply)
            case .fader(let strip, let value14):
                guard (0..<8).contains(strip) else { break }
                let g = unit * 8 + strip
                let ub = HUI.huiToUbyte(value14)
                faders[g] = ub
                writeToConsole(slot: g + 1 + bankOffset, sub: .fader,
                               param: Surface.GFAD.motorUByteValue.rawValue, value: .ubyte(UInt8(ub)))
            case .switchState(let zone, let port, let on):
                guard zone < 8 else { break }              // zonas 0..7 = strips da unidade
                applySwitch(unit: unit, strip: zone, port: port, on: on)
            case .scribble(let strip, let text):
                guard (0..<8).contains(strip) else { break }
                let g = unit * 8 + strip
                channelNames[g] = text.trimmingCharacters(in: .whitespaces)
                // Espelha o nome no display do canal do console (CH_LCD TEXT).
                writeToConsole(slot: g + 1 + bankOffset, sub: .lcd,
                               param: Surface.CHLCD.text.rawValue, value: .string(text))
            }
        }
    }

    private func applySwitch(unit: Int, strip: Int, port: Int, on: Bool) {
        let g = unit * 8 + strip
        let sub: Surface.SubObject
        switch port {
        case HUI.Port.mute.rawValue:   mutes[g] = on;   sub = .onSw
        case HUI.Port.solo.rawValue:   solos[g] = on;   sub = .soloSw
        case HUI.Port.select.rawValue: selects[g] = on; sub = .selSw
        default: return
        }
        writeToConsole(slot: g + 1 + bankOffset, sub: sub,
                       param: Surface.TLSW.switchStatus.rawValue, value: .ubyte(on ? 1 : 0))
    }

    // MARK: surface -> DAW (MultiParamSet recebido) → roteia p/ a unidade certa
    private func handleFrame(_ frame: HiQnet.Frame) {
        if console.device == 0, frame.src.device != 0 {
            console.device = frame.src.device
            maybeRequestMap()                  // we now know the console; map its surface
        }
        if diagnostics {
            onLog?("Surface RX msg=0x\(String(frame.message.rawValue, radix: 16)) "
                + "src=\(frame.src.description) flags=0x\(String(frame.flags.rawValue, radix: 16)) "
                + "len=\(frame.payload.count) [\(Self.hexDump(frame.payload, max: 48))]")
        }
        if frame.message == .getVDList { learnVD(frame); return }
        guard frame.message == .multiParamSet, let key = addrToSlot[frame.src] else { return }
        let g = key.slot - 1 - bankOffset
        guard (0..<stripCount).contains(g) else { return }
        for (pid, value) in HiQnet.parseMultiParamSet(frame) {
            route(global: g, sub: key.sub, pid: pid, value: value)
        }
    }

    private func route(global g: Int, sub: Surface.SubObject, pid: UInt16, value: HiQnet.Value) {
        let unit = g / 8, z = g % 8
        guard midis.indices.contains(unit) else { return }
        switch (sub, pid) {
        case (.fader, Surface.GFAD.faderUByteValue.rawValue):
            let ub = value.intValue
            faders[g] = ub
            midis[unit].send(HUI.faderMove(strip: z, value14: HUI.ubyteToHUI(ub)))
        case (.onSw, Surface.TLSW.switchStatus.rawValue):
            mutes[g] = value.intValue != 0
            midis[unit].send(HUI.switchEvent(zone: z, port: .mute, on: mutes[g]))
        case (.soloSw, Surface.TLSW.switchStatus.rawValue):
            solos[g] = value.intValue != 0
            midis[unit].send(HUI.switchEvent(zone: z, port: .solo, on: solos[g]))
        case (.selSw, Surface.TLSW.switchStatus.rawValue):
            selects[g] = value.intValue != 0
            midis[unit].send(HUI.switchEvent(zone: z, port: .select, on: selects[g]))
        default: break
        }
    }

    private func writeToConsole(slot: Int, sub: Surface.SubObject, param: UInt16, value: HiQnet.Value) {
        #if canImport(Network)
        guard let addr = slotAddresses[SlotKey(slot: slot, sub: sub)], let server else { return }
        server.send(HiQnet.multiParamSet(src: me, dst: addr, params: [(param, value)]))
        #endif
    }

    /// Listener state changed. `ready=true` = a console dialed in (`peer` = its IP).
    private func onHiQnetState(_ ready: Bool, peer: String?) {
        isConnected = ready
        guard ready else { requestedMap = false; return }
        if let peer, !peer.isEmpty { consoleIP = peer }
        // Fresh session: forget any stale device/slot map, then kick the console.
        // The full surface map is requested once we learn its device (handleFrame).
        console = HiQnet.Address(device: 0)
        slotAddresses.removeAll(); addrToSlot.removeAll()
        requestedMap = false
        #if canImport(Network)
        server?.send(HiQnet.hello(src: me, dst: console))
        #endif
    }

    /// Once the console's device address is known, request its surface map exactly
    /// once per session (Hello + GetVDList for every fader-bay slot).
    private func maybeRequestMap() {
        guard isConnected, !requestedMap, console.device != 0 else { return }
        requestedMap = true
        requestSurfaceMap()
    }

    /// On connect: open the session (Hello) and ask the console for the address of
    /// every fader-bay slot object, so we can subscribe to them. Porting the
    /// Python RE bridge's handshake. The slot addresses arrive as GetVDList
    /// responses → `learnVD`.
    private func requestSurfaceMap() {
        #if canImport(Network)
        guard let server else { return }
        server.send(HiQnet.hello(src: me, dst: console))
        for n in 1...Surface.numSlots {
            // RE: the Fader object appears WITHOUT the "CS\" prefix; switches/LCD WITH it.
            server.send(HiQnet.getVDList(src: me, dst: console,
                                         path: Surface.slotPath(n, .fader, withCSPrefix: false)))
            for sub in [Surface.SubObject.onSw, .soloSw, .selSw, .lcd] {
                server.send(HiQnet.getVDList(src: me, dst: console,
                                             path: Surface.slotPath(n, sub, withCSPrefix: true)))
            }
        }
        #endif
    }

    /// Parse a GetVDList response → resolve a slot's VD address and subscribe.
    /// Layout (HiQnet Third Party Programmers Guide v2, per the Wireshark
    /// `packet-hiqnet.c` dissector): `strLen:U16` + path(UTF-16BE) + `numVDs:U16`
    /// + numVDs×{ `vdAddr:U8`, `vdClassID:U16` }. The path echoes the request, so
    /// we map it back to (slot, sub). The object index defaults to 0 (the VD
    /// itself); [CALIBRAR] only if a real Si needs a non-zero object.
    private func learnVD(_ frame: HiQnet.Frame) {
        guard frame.flags.contains(.info) else { return }     // response, not a request
        let p = frame.payload
        guard p.count >= 2 else { return }
        let strLen = Int(p.beU16(0))
        var off = 2
        guard strLen >= 0, off + strLen + 2 <= p.count else { return }
        var units: [UInt16] = []
        var k = off
        while k + 1 < off + strLen { units.append(UInt16(p[k]) << 8 | UInt16(p[k + 1])); k += 2 }
        let path = String(utf16CodeUnits: units, count: units.count)
            .replacingOccurrences(of: "\u{0}", with: "")
        off += strLen
        guard off + 2 <= p.count else { return }
        let numVDs = Int(p.beU16(off)); off += 2
        guard numVDs > 0, off + 3 <= p.count else { return }
        let vdAddr = p[off]                                    // first VD entry
        let vdClass = p.beU16(off + 1)
        guard let (slot, sub) = Self.parseSlotPath(path) else {
            if diagnostics { onLog?("Surface GetVDList: unparsed path '\(path)' numVDs=\(numVDs) vd=\(vdAddr)") }
            return
        }
        let addr = HiQnet.Address(device: frame.src.device, vd: vdAddr, object: 0)
        if diagnostics {
            onLog?("Surface learnVD: Slot\(slot)/\(sub.rawValue) → \(addr.description) "
                + "(class 0x\(String(vdClass, radix: 16)), numVDs=\(numVDs))")
        }
        setSlotAddress(slot: slot, sub: sub, address: addr)
    }

    /// Extract (slot number, sub-object) from a `…\SlotNN\Sub` HiQnet path.
    private static func parseSlotPath(_ path: String) -> (Int, Surface.SubObject)? {
        let parts = path.split(separator: "\\")
        guard let last = parts.last, let sub = Surface.SubObject(rawValue: String(last)),
              let slotPart = parts.first(where: { $0.hasPrefix("Slot") }),
              let n = Int(slotPart.dropFirst(4)) else { return nil }
        return (n, sub)
    }
}
