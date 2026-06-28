# HydraSurface

Núcleo Swift 6 de uma ponte de **control surface** entre consoles **Soundcraft Si**
(via HiQnet, na rede) e DAWs que falam **Mackie HUI** (Pro Tools, etc.), via MIDI.
Sem UI — pensado para ser consumido por um app SwiftUI (ex.: **Hydra**) ou standalone.

HiQnet é **inbound**: o bridge convida por broadcast UDP e o console disca de volta.

```
[HydraSurface] ──DiscoInfo (broadcast UDP/3804, convite)──►  Console Si
Console Si     ──conecta de volta (TCP/3804)────────────►  [HydraSurface] ──HUI/MIDI (IAC)──► DAW
               ◄──── MultiParamSet ──                     ── faders/mutes/… ────►
```

## Escopo e aviso

Este pacote é uma **reimplementação original e independente**, escrita para fins de
**interoperabilidade** (fazer o console funcionar como superfície de controle de um DAW).

- **Não** contém, **não** distribui e **não** depende de firmware, binários, disassembly
  ou SDK de terceiros. Só código original e fatos de protocolo (formatos, IDs, portas).
- **Não é afiliado** à Harman, Soundcraft, Avid/Pro Tools ou Mackie, nem endossado por
  eles. "Soundcraft", "Si Expression", "HiQnet", "HUI", "Pro Tools" e "Mackie" são marcas
  de seus respectivos donos, usadas aqui apenas de forma **nominativa/descritiva** para
  indicar compatibilidade.

## Conteúdo

| Arquivo | Papel |
|---------|-------|
| `HiQnet.swift` | codec do protocolo HiQnet (header, MultiParamSet/Subscribe, tipos) |
| `HUI.swift` | codec Mackie HUI (faders, switches, ping, VU, scribble) + decoder |
| `SurfaceIDs.swift` | IDs de parâmetro da superfície (GFAD/TLSW/CH_LCD/SLOTS) e paths |
| `MIDIBackend.swift` | abstração de MIDI + implementação CoreMIDI (virtual ou IAC) |
| `HiQnetClient.swift` | **servidor** HiQnet/TCP (a mesa conecta de volta) + listener UDP de meter |
| `SurfaceBridge.swift` | engine + **API observável** pronta para SwiftUI |
| `docs/PROTOCOL.md` | spec funcional (só fatos necessários ao código) |

Os codecs (`HiQnet`, `HUI`, `Surface*`) são **puros e independentes de plataforma** —
testáveis em qualquer lugar. A I/O (`CoreMIDIBackend`, `HiQnetServer`) é macOS/Apple.

## API para a UI

`SurfaceBridge` é `@MainActor @Observable` — a UI só observa as propriedades:

```swift
import HydraSurface

@State private var bridge = SurfaceBridge()

// Iniciar (modo DAW-only por IAC, sem console ainda):
bridge.start(config: .init(midiOutName: "Bus 1", midiInName: "Bus 2"))

// Observável em SwiftUI:
//   bridge.isOnlineToDAW, bridge.heartbeatCount
//   bridge.faders[0..7], bridge.mutes/solos/selects
//   bridge.isConnected (HiQnet), bridge.lastError
```

Para o console: **não há IP a configurar**. `start(config:)` já abre o listener
TCP/3804 (`startListening()`); o app só precisa mandar o convite DiscoInfo em
broadcast UDP (o daemon faz isso) e a mesa **disca de volta**. `bridge.consoleIP`
é preenchido com o IP da mesa quando ela conecta. Os endereços dos slots se resolvem
em runtime (GetVDList) ou manualmente via `setSlotAddress(slot:sub:address:)`.

## Build / uso

Standalone:
```bash
swift build
swift test          # roda os testes dos codecs (Swift Testing)
```

Dentro do Hydra (recomendado): adicionar como **package local** e listar `HydraSurface`
como dependência do target do app. O módulo é só plano de controle (MIDI + rede) — não
toca no engine de áudio em tempo real.

## Pendências de calibração (precisam de console real na LAN) — marcadas `[CALIBRAR]`

1. Confirmar **SV-ID == paramID** (mexer 1 controle, ver o paramID que volta).
2. **GetVDList**: parsear a resposta → preencher os endereços dos slots.
3. **Device address** do bridge (Hello vs RequestAddress).
4. **Meters**: decifrar o pacote UDP 3333 (o listener já recebe; falta o layout).

O lado **HUI/DAW** já é testável sem console (handshake por heartbeat, faders, switches).

## Licença

Pretendido como **GPL-3.0** (para alinhar ao Hydra). Adicione o arquivo `LICENSE`
correspondente ao integrar. O copyright do código deste pacote é do autor.
