// SurfaceIDs.swift — IDs de parâmetro (State Variable) da superfície + paths HiQnet.
// Apenas constantes FUNCIONAIS necessárias ao bridge. Ver docs/PROTOCOL.md.
//
// PROCEDÊNCIA (verificado direto no firmware Expression.bin, V2.2 Build1):
//   Os IDs abaixo foram lidos das tabelas de descritor do próprio console
//   (registros de 44 bytes, ID U16 no offset +0x00, name_ptr em +0x04):
//     GFAD  @ file 0xe066dc  · TLSW   @ file 0xe0d93c
//     CH_LCD@ file 0xe03054  · SLOTS  @ file 0xe0a074
//   O construtor de cada objeto instala sua tabela via fn 0x36db18, que percorre
//   os registros (stride 44) lendo o ID U16 em +0 como CHAVE do parâmetro e o
//   registra por descritor (fn 0x36daac). Ou seja: o ID do descritor É o
//   identificador de parâmetro do objeto — o mesmo valor U16 do paramID HiQnet.
//   (Confirmado byte-a-byte; cada `case` aqui bate com a tabela do firmware.)

import Foundation

public enum Surface {

    public static let numSlots = 30           // Soundcraft Si Expression 3

    // MARK: GFAD — objeto "Fader" de cada slot
    public enum GFAD: UInt16 {
        case enable           = 0x04
        case faderMode        = 0x05
        case glowFunction     = 0x07
        case glowColour       = 0x0A          // LED RGB sob o fader
        case faderUByteValue  = 0x0D          // ler posição 0..255  (surface -> DAW)
        case motorUByteValue  = 0x0E          // escrever motor 0..255 (DAW -> surface)
        case faderValue       = 0x0F          // posição cheia (signed)
        case motorValue       = 0x10          // alvo do motor (cheio)
    }

    // MARK: TLSW — TriLedSwitch = objetos OnSw / SoloSw / SelSw
    public enum TLSW: UInt16 {
        case pressedValue     = 0x05          // evento de press
        case releasedValue    = 0x06          // evento de release
        case switchMode       = 0x0E
        case switchStatus     = 0x0F          // estado on/off (LED)
        case onColour         = 0x10
        case offColour        = 0x11
        case ledOutputColour  = 0x12          // escrever p/ acender o LED
    }

    // MARK: CH_LCD — scribble strip (nome de canal)
    public enum CHLCD: UInt16 {
        case ledColourOutput  = 0x05
        case channelName      = 0x06          // -> HUI 4-char
        case mode             = 0x08
        case text             = 0x09
    }

    // MARK: SLOTS_CTL — banking / atribuição de canal por slot
    public enum SlotsCtl: UInt16 {
        case currentSlotSel     = 0x24
        case refreshCurrentSel  = 0x26
        case slotAssignments    = 0x27        // qual canal está em cada slot
    }

    // MARK: Paths HiQnet (resolver via GetVDList em runtime)
    public enum SubObject: String, CaseIterable, Sendable {
        case fader = "Fader", onSw = "OnSw", soloSw = "SoloSw", selSw = "SelSw"
        case lcd = "Lcd"                       // scribble / channel-name display (CH_LCD)
    }

    /// Path do slot. NOTA: nos consoles, switches aparecem com e sem o prefixo
    /// "CS\"; o "Fader" costuma aparecer só sem "CS\". Tentar ambas as formas.
    public static func slotPath(_ n: Int, _ sub: SubObject, withCSPrefix: Bool = true) -> String {
        let prefix = withCSPrefix ? "CS\\Coordinator" : "Coordinator"
        let slot = String(format: "Slot%02d", n)
        return "\(prefix)\\UI\\FaderBay\\\(slot)\\\(sub.rawValue)"
    }

    // MARK: Meters (sub-protocolo separado, UDP) — RE do firmware (Expression.bin)
    public static let meterUDPPort: UInt16 = 3333
    /// Tamanho FIXO do pacote de meter, lido do firmware: o getter 0x35dcac faz
    /// `movi r2,624; sth → [ctx+108]`. O buffer é memória crua do DSP
    /// (objeto do DSP + 2632) e é enviado verbatim por `sendto` na 3333.
    public static let meterPacketBytes = 624
    /// Para RECEBER meters é preciso **registrar-se**: o console só faz despatch
    /// para IPs registrados (`CRemoteMeterDespatch`). A função 0x1af6e0 registra o
    /// cliente (call 0x1b4020, log "Registering HiQnet node for meter data") quando
    /// um nó ASSINA os SVs de um grupo de meter via HiQnet. Ou seja: assinar um
    /// grupo de meter (SVSubscribe) liga o stream UDP. O layout interno dos 624
    /// bytes é definido pelo DSP (ordem de canais) → confirmar com 1 captura
    /// (mover 1 canal e ver qual byte muda no pacote de 624 B).

    // MARK: HiQnet
    public static let hiqnetTCPPort: UInt16 = 3804
}
