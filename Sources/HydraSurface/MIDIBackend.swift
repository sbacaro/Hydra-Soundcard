// MIDIBackend.swift — abstração de I/O MIDI + implementação CoreMIDI.
// O engine depende do protocolo; isso mantém a lógica testável com um mock.

import Foundation

public protocol MIDIBackend: AnyObject {
    /// Envia bytes MIDI crus para o DAW.
    func send(_ bytes: [UInt8])
    /// Handler chamado a cada mensagem MIDI recebida do DAW.
    func setReceiveHandler(_ handler: @escaping @Sendable ([UInt8]) -> Void)
    func close()
}

#if canImport(CoreMIDI)
import CoreMIDI

/// Implementação CoreMIDI. Por padrão cria portas virtuais; opcionalmente conecta
/// a portas existentes por nome (ex.: "IAC Driver Bus 1/2"), que o Pro Tools enxerga.
public final class CoreMIDIBackend: MIDIBackend, @unchecked Sendable {
    private var client = MIDIClientRef()
    private var outPort = MIDIPortRef()
    private var inPort = MIDIPortRef()
    private var virtualSource = MIDIEndpointRef()
    private var destination = MIDIEndpointRef()      // p/ onde enviamos (named/IAC)
    private var handler: (@Sendable ([UInt8]) -> Void)?
    private let name: String

    /// - outName/inName: substring de portas existentes (modo IAC). Se nil, cria virtuais.
    public init(name: String = "Hydra Surface", outName: String? = nil, inName: String? = nil) throws {
        self.name = name
        try check(MIDIClientCreateWithBlock(name as CFString, &client, nil))

        if let outName {
            destination = try Self.findDestination(matching: outName)
            try check(MIDIOutputPortCreate(client, "\(name) Out" as CFString, &outPort))
        } else {
            try check(MIDISourceCreate(client, name as CFString, &virtualSource))
        }

        let readBlock: MIDIReadBlock = { [weak self] pktList, _ in
            self?.dispatch(pktList)
        }
        if let inName {
            let src = try Self.findSource(matching: inName)
            try check(MIDIInputPortCreateWithBlock(client, "\(name) In" as CFString, &inPort, readBlock))
            try check(MIDIPortConnectSource(inPort, src, nil))
        } else {
            try check(MIDIDestinationCreateWithBlock(client, "\(name) IN" as CFString, &inPort, readBlock))
        }
    }

    public func setReceiveHandler(_ handler: @escaping @Sendable ([UInt8]) -> Void) {
        self.handler = handler
    }

    public func send(_ bytes: [UInt8]) {
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        _ = MIDIPacketListAdd(&packetList, 1024, packet, 0, bytes.count, bytes)
        if destination != 0 {
            MIDISend(outPort, destination, &packetList)
        } else if virtualSource != 0 {
            MIDIReceived(virtualSource, &packetList)
        }
    }

    public func close() {
        if inPort != 0 { MIDIPortDispose(inPort) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if virtualSource != 0 { MIDIEndpointDispose(virtualSource) }
        if client != 0 { MIDIClientDispose(client) }
    }

    private func dispatch(_ pktList: UnsafePointer<MIDIPacketList>) {
        var packet = pktList.pointee.packet
        for _ in 0..<pktList.pointee.numPackets {
            let bytes = withUnsafeBytes(of: packet.data) { raw in
                Array(raw.prefix(Int(packet.length)))
            }
            handler?(bytes)
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    // MARK: lookup de portas por nome
    private static func endpointName(_ ep: MIDIEndpointRef) -> String {
        var cf: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &cf) == noErr,
              let s = cf?.takeRetainedValue() else { return "" }
        return s as String
    }
    private static func findDestination(matching sub: String) throws -> MIDIEndpointRef {
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            if endpointName(ep).localizedCaseInsensitiveContains(sub) { return ep }
        }
        throw MIDIError.portNotFound(sub)
    }
    private static func findSource(matching sub: String) throws -> MIDIEndpointRef {
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            if endpointName(ep).localizedCaseInsensitiveContains(sub) { return ep }
        }
        throw MIDIError.portNotFound(sub)
    }

    public static func listPorts() -> (outputs: [String], inputs: [String]) {
        let outs = (0..<MIDIGetNumberOfDestinations()).map { endpointName(MIDIGetDestination($0)) }
        let ins = (0..<MIDIGetNumberOfSources()).map { endpointName(MIDIGetSource($0)) }
        return (outs, ins)
    }
}

public enum MIDIError: Error, CustomStringConvertible {
    case osStatus(Int32)
    case portNotFound(String)
    public var description: String {
        switch self {
        case .osStatus(let s): "CoreMIDI OSStatus \(s)"
        case .portNotFound(let n): "porta MIDI não encontrada: \(n)"
        }
    }
}
private func check(_ status: OSStatus) throws {
    if status != noErr { throw MIDIError.osStatus(status) }
}
#endif
