# Spec funcional — HiQnet + HUI

Apenas os fatos de protocolo necessários para o código (formatos, IDs, portas). Tudo
**big-endian** salvo indicação. Esta é informação de interface/interoperabilidade.

## Transporte

- **HiQnet:** TCP, porta **3804**. **A direção é INVERSA:** o **bridge é o servidor**
  (escuta na 3804) e **o console é quem conecta**. Sequência:
  1. o bridge manda um **DiscoInfo em broadcast UDP/3804** (convite); o IP de origem
     do datagrama é o endereço do bridge;
  2. ao receber o convite, **o console disca de volta por TCP/3804** para esse IP.

  Confirmado contra uma **Si Expression 3** (2026-06-27): a mesa responde a `ping`,
  mas **dropa silenciosamente** qualquer `connect()` TCP em 3804 — ela não é
  servidor. Também documentado pelo projeto Mixing Station
  (<https://dev-core.org/ms-docs/mixers/soundcraft/hiqnet/>).

  **Requisitos:** Mac e mesa no **mesmo /24**, **broadcast liberado**, e no menu
  `HIQNET` da mesa o device do app com acesso **ALL** (sem access-control bloqueando).
  A mesa fala com **um app por vez** — feche o ViSi Remote antes.
- **Meter:** UDP, porta **3333** (despatch para IPs registrados; sub-protocolo à parte).
- **HUI:** MIDI serial 31250 (lado do DAW), aqui sobre porta MIDI virtual/IAC.

## HiQnet — header (25 bytes)

| off | tam | campo |
|----:|----:|-------|
| 0 | 1 | version (tip. `0x02`) |
| 1 | 1 | headerLen (≥25) |
| 2 | 4 | messageLen (total) — usar p/ enquadrar no stream |
| 6 | 2 | source device |
| 8 | 4 | source VD(1)+object(3) |
| 12 | 2 | dest device |
| 14 | 4 | dest VD(1)+object(3) |
| 18 | 2 | messageID |
| 20 | 2 | flags |
| 22 | 1 | hopCount (iniciar `0x05`) |
| 23 | 2 | sequenceNumber |

Endereço = `device(2).vd(1).object(3)` (6 bytes).

### Message IDs (subconjunto usado)
`0x0008` Hello · `0x0100` MultiParamSet (console→nós: notificação) ·
`0x0103` MultiParamGet · `0x010F` MultiParamSubscribe · `0x0113` ParameterSubscribeAll ·
`0x0114` ParameterUnsubscribeAll · `0x011A` GetVDList.

### Flags
`0x0004` INFO (set = traz dado) · `0x0008` ERROR · `0x0040` MULTIPART · `0x0100` SESSION.

### Tipos de dado (1 byte de tipo + valor)
`0` BYTE · `1` UBYTE · `2` WORD · `3` UWORD · `4` LONG · `5` ULONG · `6` FLOAT32 ·
`7` FLOAT64 · `8` BLOCK(`len:U16`+bytes) · `9` STRING(`len:U16`+UTF-16BE) · `10/11` (U)LONG64.

### Corpos
- **MultiParamSet `0x0100`:** `paramCount:U16` então N× `paramID:U16` + valor tipado.
- **ParameterSubscribeAll `0x0113`:** `devAddr:U16` + `vdObject:4` + `subType:U8` +
  `sensorRate:U16` + `subFlags:U16`.
- **MultiParamSubscribe `0x010F`:** `subCount:U16` então N× registro de 16 bytes:
  `pubParamID:U16` + `subType:U8` + `subAddr:6` + `subParamID:U16` + `rsv0:U8` + `rsv1:U16`
  + `sensorRate:U16`.
- **GetVDList `0x011A`:** `strLen:U16` + path UTF-16BE.

## Superfície — paths e IDs de parâmetro

Cada channel strip é um "slot", endereçável por path HiQnet:
```
CS\Coordinator\UI\FaderBay\Slot{NN}\{Fader|OnSw|SoloSw|SelSw}
```
(`NN` = 01..30 na Si Expression 3. Nota: o `Fader` pode aparecer sem o prefixo `CS\`.)
O canal de cada slot vem de `SLOTS_CTL.SLOT_ASSIGNMENTS` (banking/layers).

### Parâmetros (paramID = SV ID local do objeto)

**Fader (GFAD):**
`FADER_UBYTE_VALUE 0x0D` (ler 0..255) · `MOTOR_UBYTE_VALUE 0x0E` (escrever 0..255) ·
`FADER_VALUE 0x0F` · `MOTOR_VALUE 0x10` · `GLOW_COLOUR 0x0A` (LED RGB) · `FADER_MODE 0x05`.

**Switch (TLSW — OnSw/SoloSw/SelSw):**
`PRESSED 0x05` · `RELEASED 0x06` · `SWITCH_STATUS 0x0F` (estado/LED) ·
`LED_OUTPUT_COLOUR 0x12`.

**Scribble (CH_LCD):** `CHANNEL_NAME 0x06` · `TEXT 0x09` · `LED_COLOUR_OUTPUT 0x05`.

**Banking (SLOTS_CTL):** `CURRENT_SLOT_SEL 0x24` · `SLOT_ASSIGNMENTS 0x27`.

## HUI (lado do DAW)

- **Ping/keep-alive:** host→surface `90 00 00`, surface→host `90 00 7F`. O critério de
  "online" do Pro Tools é **continuar recebendo HUI da surface**; portanto a surface deve
  **emitir `90 00 7F` continuamente (~2×/s)** como heartbeat, mesmo sem receber ping.
- **Fader (14-bit):** `B0 0z hi` + `B0 2z lo`, `z` = strip 0..7, valor `(hi<<7)|lo`, 0..0x3FFF.
- **Switch/LED:** par zona-select + porta. **Host→surface (LED):** CC `0x0C`/`0x2C`.
  **Surface→host (press):** CC `0x0F`/`0x2F`. Porta nos 3 bits baixos, `0x40` = on.
  Zonas 0..7 = os 8 strips; portas: 1=select, 2=mute, 3=solo.
- **VU:** `A0 0y sv` (Poly Key Pressure), `y`=strip, `sv` nibble baixo = nível 0..0xC.
- **Scribble 4-char:** `F0 00 00 66 05 00 10 yy c0 c1 c2 c3 F7`, `yy`=strip (0..7).

### Escala fader
`FADER_UBYTE`/`MOTOR_UBYTE` (0..255) ↔ HUI 14-bit:
`hui = round(ub*0x3FFF/255)`, `ub = round(v14*255/0x3FFF)` (round-trip exato nos 256 valores).
