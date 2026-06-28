// HUI.swift — codec do protocolo Mackie HUI (lado MIDI, para o DAW).
// Reimplementação original; ver docs/PROTOCOL.md.

import Foundation

public enum HUI {

    public static let sysexHeader: [UInt8] = [0xF0, 0x00, 0x00, 0x66, 0x05, 0x00]
    public static let pingFromHost: [UInt8] = [0x90, 0x00, 0x00]  // DAW -> surface
    public static let pingReply: [UInt8]    = [0x90, 0x00, 0x7F]  // surface -> DAW

    /// Portas de switch por strip (zona = strip 0..7).
    public enum Port: Int, Sendable {
        case faderTouch = 0, select = 1, mute = 2, solo = 3
        case auto = 4, vsel = 5, insert = 6, recReady = 7
    }

    public static let faderMax = 0x3FFF

    // MARK: Surface -> DAW (gerados pelo bridge)
    public static func faderMove(strip: Int, value14: Int) -> [UInt8] {
        let v = max(0, min(faderMax, value14))
        return [0xB0, UInt8(0x00 | (strip & 0x07)), UInt8((v >> 7) & 0x7F),
                0xB0, UInt8(0x20 | (strip & 0x07)), UInt8(v & 0x7F)]
    }

    public static func faderTouch(strip: Int, touched: Bool) -> [UInt8] {
        [0xB0, 0x0F, UInt8(strip & 0x07), 0xB0, 0x2F, touched ? 0x40 : 0x00]
    }

    public static func switchEvent(zone: Int, port: Port, on: Bool) -> [UInt8] {
        [0xB0, 0x0F, UInt8(zone & 0x7F),
         0xB0, 0x2F, UInt8((on ? 0x40 : 0x00) | (port.rawValue & 0x07))]
    }

    public static func vpotDelta(vpot: Int, delta: Int) -> [UInt8] {
        let v = delta >= 0 ? 0x40 + min(delta, 0x3F) : min(-delta, 0x3F)
        return [0xB0, UInt8(0x40 | (vpot & 0x0F)), UInt8(v)]
    }

    /// VU do strip 0..7. level 0..0xC (0xC = clip). Poly Key Pressure.
    public static func vuMeter(strip: Int, level: Int, right: Bool = false) -> [UInt8] {
        let sv = ((right ? 1 : 0) << 4) | (level & 0x0F)
        return [0xA0, UInt8(strip & 0x0F), UInt8(sv)]
    }

    /// Display de 4 caracteres do strip 0..7 (SysEx). ASCII (pad/truncado em 4).
    public static func scribble4Char(strip: Int, text: String) -> [UInt8] {
        let chars = Array((text + "    ").prefix(4))
        var out = sysexHeader + [0x10, UInt8(strip & 0x0F)]
        out += chars.map { UInt8($0.asciiValue ?? 0x20) & 0x7F }
        out.append(0xF7)
        return out
    }

    // MARK: DAW -> Surface (decoder)
    public enum Event: Sendable, Equatable {
        case ping
        case fader(strip: Int, value14: Int)
        case switchState(zone: Int, port: Int, on: Bool)
        case scribble(strip: Int, text: String)     // nome do canal (4-char) vindo do DAW
    }

    /// Decoder com estado (zona corrente + MSB de fader pendente).
    /// Trata 0x0C/0x2C (host→surface, LED/estado) e 0x0F/0x2F (surface→host).
    public struct Decoder: Sendable {
        private var zone = 0
        private var faderHi: [Int: Int] = [:]
        private var buffer: [UInt8] = []
        public init() {}

        public mutating func feed(_ data: [UInt8]) -> [Event] {
            buffer.append(contentsOf: data)
            var events: [Event] = []
            var i = 0
            let n = buffer.count
            while i < n {
                let status = buffer[i]
                if status == 0x90, i + 2 < n {
                    if buffer[i+1] == 0x00 && buffer[i+2] == 0x00 { events.append(.ping) }
                    i += 3; continue
                }
                if status == 0xB0, i + 2 < n {
                    let cc = Int(buffer[i+1]); let val = Int(buffer[i+2])
                    switch cc {
                    case 0x0C, 0x0F:                       // zona-select
                        zone = val
                    case 0x2C, 0x2F:                       // porta on/off
                        events.append(.switchState(zone: zone, port: val & 0x07, on: (val & 0x40) != 0))
                    case 0x00...0x07:                      // fader MSB (zona = strip)
                        faderHi[cc] = val
                    case 0x20...0x27:                      // fader LSB
                        let strip = cc & 0x07
                        events.append(.fader(strip: strip, value14: ((faderHi[strip] ?? 0) << 7) | val))
                    default: break
                    }
                    i += 3; continue
                }
                if status == 0xF0 {                        // SysEx
                    guard let end = buffer[i...].firstIndex(of: 0xF7) else { break }
                    // Scribble de 4 caracteres: <hdr> 10 yy c0 c1 c2 c3 F7
                    // (yy = strip 0..7; yy = 8 é o display SELECT-ASSIGN, ignorado).
                    let frame = Array(buffer[i...end])
                    if frame.count >= 9, Array(frame.prefix(6)) == sysexHeader, frame[6] == 0x10 {
                        let yy = Int(frame[7])
                        if (0...7).contains(yy) {
                            let chars = frame[8 ..< min(frame.count - 1, 12)]
                            let text = String(chars.map { Character(UnicodeScalar($0 & 0x7F)) })
                            events.append(.scribble(strip: yy, text: text))
                        }
                    }
                    i = end + 1; continue
                }
                i += 1
            }
            if i > 0 { buffer.removeFirst(i) }
            return events
        }
    }

    // MARK: Escalas (GFAD UBYTE 0..255 <-> HUI 14-bit), arredondadas
    public static func ubyteToHUI(_ ub: Int) -> Int { (ub * faderMax + 127) / 255 }
    public static func huiToUbyte(_ v14: Int) -> Int { (v14 * 255 + faderMax / 2) / faderMax }
}
