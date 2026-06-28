// CodecTests.swift — testes dos codecs puros (espelham bridge_selftest.py).
import Testing
@testable import HydraSurface

@Suite("HiQnet")
struct HiQnetTests {

    @Test func headerRoundTrip() {
        let src = HiQnet.Address(device: 0xA1)
        let dst = HiQnet.Address(device: 0x01, vd: 2, object: 0x000101)
        let f = HiQnet.multiParamSet(src: src, dst: dst,
                                     params: [(Surface.GFAD.motorUByteValue.rawValue, .ubyte(200))])
        let raw = f.encoded()
        let d = HiQnet.Frame.decode(raw)
        #expect(d != nil)
        #expect(d?.message == .multiParamSet)
        #expect(d?.src.device == 0xA1)
        #expect(d?.dst.object == 0x000101)
        #expect(d?.flags.contains(.info) == true)
        let parsed = HiQnet.parseMultiParamSet(d!)
        #expect(parsed.count == 1)
        #expect(parsed.first?.0 == Surface.GFAD.motorUByteValue.rawValue)
        #expect(parsed.first?.1 == .ubyte(200))
    }

    @Test func addressRoundTrip() {
        let a = HiQnet.Address(device: 0x0102, vd: 3, object: 0xAABBCC)
        let b = HiQnet.Address.unpack(a.packed(), at: 0)
        #expect(a == b)
    }

    @Test func streamFraming() {
        let raw = HiQnet.multiParamSet(src: .init(device: 1), dst: .init(device: 2), params: []).encoded()
        var buf = raw + raw + Array(raw.prefix(5))   // 2 inteiras + lixo parcial
        let frames = HiQnet.frames(from: &buf)
        #expect(frames.count == 2)
        #expect(buf.count == 5)
    }

    @Test func subscribeRecordSize() {
        let s = HiQnet.Address(device: 0xA1)
        let d = HiQnet.Address(device: 1, vd: 2, object: 3)
        // SubscribeAll: header 25 + (devaddr2 + vdobj4 + subtype1 + rate2 + flags2 = 11)
        #expect(HiQnet.subscribeAll(src: s, dst: d, target: d).encoded().count == 25 + 11)
        // MultiParamSubscribe: 25 + count2 + record16
        let sub = HiQnet.Subscription(publisherParamID: 0x0D, subscriberAddr: s)
        #expect(HiQnet.multiParamSubscribe(src: s, dst: d, subs: [sub]).encoded().count == 25 + 2 + 16)
    }

    @Test func dataTypeRoundTrips() {
        for v: HiQnet.Value in [.ubyte(200), .word(-1234), .ulong(0xDEADBEEF),
                                .float32(0.5), .string("KICK")] {
            let enc = v.encoded()
            let (decoded, off) = HiQnet.Value.read(enc, at: 0)!
            #expect(decoded == v)
            #expect(off == enc.count)
        }
    }
}

@Suite("HUI")
struct HUITests {

    @Test func faderScaleIsLossless() {
        for ub in 0...255 {
            #expect(HUI.huiToUbyte(HUI.ubyteToHUI(ub)) == ub)
        }
    }

    @Test func faderBytes() {
        let fb = HUI.faderMove(strip: 3, value14: HUI.ubyteToHUI(200))
        #expect(fb[0] == 0xB0 && fb[1] == 0x03 && fb[4] == 0x23)
    }

    @Test func decoderHandlesPingFaderSwitch() {
        var d = HUI.Decoder()
        var ev: [HUI.Event] = []
        ev += d.feed(HUI.pingFromHost)
        ev += d.feed([0xB0, 0x0F, 0x04, 0xB0, 0x2F, 0x43])   // surface->host: zona4 porta3 ON
        ev += d.feed([0xB0, 0x02, 0x40, 0xB0, 0x22, 0x10])   // fader strip2
        #expect(ev.contains(.ping))
        #expect(ev.contains(.switchState(zone: 4, port: 3, on: true)))
        #expect(ev.contains { if case .fader(2, _) = $0 { true } else { false } })
    }

    @Test func decoderHandlesHostToSurfaceLED() {
        var d = HUI.Decoder()
        // host->surface (LED): CC 0x0C/0x2C
        let ev = d.feed([0xB0, 0x0C, 0x04, 0xB0, 0x2C, 0x42])  // zona4 porta2 (mute) ON
        #expect(ev.contains(.switchState(zone: 4, port: 2, on: true)))
    }

    @Test func scribbleEncodesSysex() {
        let s = HUI.scribble4Char(strip: 0, text: "KICK")
        #expect(s == [0xF0,0x00,0x00,0x66,0x05,0x00,0x10,0x00,0x4B,0x49,0x43,0x4B,0xF7])
    }

    @Test func vuMeter() {
        #expect(HUI.vuMeter(strip: 2, level: 0x0A) == [0xA0, 0x02, 0x0A])
        #expect(HUI.vuMeter(strip: 2, level: 0x0C, right: true) == [0xA0, 0x02, 0x1C])
    }
}
