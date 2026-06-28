// Hydra Audio — GPL-3.0
// Control-surface manager — wraps the multi-unit HiQnet↔HUI bridge as a headless
// daemon subsystem, in the same shape as the other managers.
//
// FULLY AUTOMATIC: enabling the bridge is the only action. The manager then
//   • publishes N virtual HUI ports (no IAC setup — Hydra creates them),
//   • listens on TCP/3804 and periodically broadcasts a HiQnet DiscoInfo invite;
//     the console dials BACK into us (HiQnet is inbound), so no IP is needed and
//     the MIDI ports never churn while we wait,
//   • exposes ALL strips (unitCount*8 — 32 for the Si Expression 3) so the whole
//     surface is live at once.
// The single irreducible step lives inside the DAW: add one HUI controller per
// published port (`portNames`); Hydra can't reach into the DAW's preferences.
//
// Route B: the bridge's I/O runs INSIDE the daemon (sources in
// `Sources/hydrad/Surface/`). `SurfaceBridge` is `@MainActor @Observable`; the
// daemon control plane is also `@MainActor`, so we own it directly and forward a
// serialisable `SurfacePayload`. A low-rate snapshot timer broadcasts only on
// change (the 2×/s heartbeat shows as `onlineToDAW`, not a counter).

import Foundation
import HydraCore
import HydraSurface   // control-surface bridge framework (HiQnet/HUI codecs + I/O)

@MainActor
final class SurfaceManager {

    /// Broadcast hook (set by DaemonContext) — called with the latest payload on
    /// every state change.
    var onChange: ((SurfacePayload) -> Void)?

    // MARK: Owned bridge + daemon-side state
    // unitCount fixed to cover the Si Expression 3 (32 faders → 4 HUI units).
    // [CALIBRAR] derive from GetVDList once the console is on the LAN.
    private let bridge = SurfaceBridge(unitCount: Hydra.surfaceDefaultUnitCount)

    private var enabled = false
    private var presetID = "protools"
    private var diagnostics = false
    private var consoleIP = ""          // auto-discovered

    // MARK: Discovery state
    private var discovering = false
    private var discovered: [SurfaceConsoleInfo] = []
    private var disco: HiQnetDiscovery?     // native HiQnet DiscoInfo broadcast (invite)

    // MARK: Snapshot timer (change-detected broadcast)
    private var timer: DispatchSourceTimer?
    private var lastPayload: SurfacePayload?
    private var tickCount = 0

    init() {
        // Route the bridge's diagnostics into the daemon log (the framework has no
        // Hydra dependency, so it logs through this hook).
        bridge.onLog = { log($0) }
    }

    // MARK: Lifecycle

    /// Begin the snapshot/broadcast + auto-connect loop. The bridge stays OFF
    /// until the user enables it (`applyConfig`).
    func start() {
        let t = DispatchSource.makeTimerSource(queue: .main)
        // 4 Hz: fast enough for a live fader/switch monitor, slow enough to stay
        // cheap. Only changed payloads go out (see `tick`).
        t.schedule(deadline: .now() + 0.25, repeating: 0.25)
        t.setEventHandler { [weak self] in MainActor.assumeIsolated { self?.tick() } }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel(); timer = nil
        disco?.stop(); disco = nil
        bridge.stop()
    }

    // MARK: Public snapshot (for pushFullState)

    func payload() -> SurfacePayload {
        SurfacePayload(
            enabled: enabled,
            onlineToDAW: bridge.isOnlineToDAW,
            consoleConnected: bridge.isConnected,
            // The console dials in, so its real IP is the bridge's peer once connected.
            consoleIP: bridge.isConnected ? bridge.consoleIP : consoleIP,
            presetID: presetID,
            unitCount: bridge.unitCount,
            portNames: bridge.portNames,
            bankOffset: bridge.bankOffset,
            diagnostics: diagnostics,
            faders: bridge.faders,
            mutes: bridge.mutes,
            solos: bridge.solos,
            selects: bridge.selects,
            channelNames: bridge.channelNames,
            lastError: bridge.lastError,
            discovering: discovering,
            discovered: discovered)
    }

    // MARK: Commands (from WSHandler)

    /// Enable/disable the bridge and pick the DAW. Everything else is automatic.
    func applyConfig(_ p: SurfaceConfigPayload) {
        presetID = p.presetID
        enabled = p.enabled
        diagnostics = p.diagnostics
        relaunch()
    }

    /// Manual hint for the console (fallback when the broadcast invite can't reach
    /// it, e.g. a direct link). With HiQnet the console dials US, so a non-empty IP
    /// just (re)fires the invite; empty = drop the current session.
    func connectConsole(ip: String) {
        consoleIP = ip.trimmingCharacters(in: .whitespaces)
        log("SurfaceManager: connectConsole manual IP hint '\(consoleIP)'")
        if enabled {
            if consoleIP.isEmpty {
                #if canImport(Network)
                bridge.disconnectConsole()
                #endif
            } else {
                discover()            // (re)broadcast the invite; the bridge is listening
            }
        }
        notify()
    }

    // MARK: Bridge (re)launch — rebuilds MIDI; console connects separately

    private func relaunch() {
        bridge.stop()
        guard enabled else { consoleIP = ""; notify(); return }
        let preset = Hydra.surfacePreset(id: presetID)
        let cfg = SurfaceBridge.Config(
            portBaseName: Hydra.surfaceHUIPortBaseName,
            heartbeat: preset?.heartbeat ?? true,
            listenMeters: true,        // VU plumbing ready (UDP 3333); layout [CALIBRAR]
            diagnostics: diagnostics)  // user-controlled; logs HiQnet frames + meter dumps
        // No IP to push: the bridge listens and the console dials in.
        bridge.start(config: cfg)
        notify()
    }

    // MARK: Change broadcast

    private func tick() {
        tickCount &+= 1
        // Auto-invite: while enabled but not yet connected, re-broadcast the HiQnet
        // DiscoInfo invite every ~3 s (12 ticks) so the console dials back. The TCP
        // listener stays up the whole time; MIDI ports are never touched.
        if tickCount % 12 == 0, enabled, !bridge.isConnected, !discovering {
            discover()
        }
        let p = payload()
        if p != lastPayload {
            lastPayload = p
            onChange?(p)
        }
    }

    /// Force an immediate broadcast (don't wait for the next tick).
    private func notify() {
        let p = payload()
        lastPayload = p
        onChange?(p)
    }

    // MARK: Console discovery (HiQnet invite broadcast)
    //
    // HiQnet is INBOUND: the console does not listen on TCP/3804 — it dials back to
    // us. So "discovery" is sending the DiscoInfo invite over UDP broadcast; the
    // bridge's TCP listener (always up while enabled) accepts the console's
    // dial-back. Confirmed against a Si Expression 3 (2026-06-27); see
    // docs/HydraSurface/PROTOCOL.md. (The old TCP /24 sweep was removed — the
    // console refuses/ignores TCP, so it never found anything.)

    func discover() {
        guard !discovering else { return }
        log("SurfaceManager: starting discovery (targetIP: \(consoleIP.isEmpty ? "none" : consoleIP))")
        discovering = true
        notify()

        // Broadcast a DiscoInfo on every local interface (incl. link-local, where a
        // directly-connected Mac+console land with no DHCP). Each invite carries
        // that interface's real IP+MAC so the console knows where to dial back; it
        // then connects to the bridge's listener. Any UDP reply also enriches the
        // discovered list for the UI.
        let d = HiQnetDiscovery()
        d.onConsole = { [weak self] host, name in
            Task { @MainActor in self?.addDiscovered(host, name: name) }
        }
        let target = consoleIP.isEmpty ? nil : consoleIP
        d.start(me: HiQnet.Address(device: 0xA2), targetIP: target)
        disco = d

        // Give the invite a window, then close the UDP socket. The bridge's TCP
        // listener keeps running, so the console can dial in at any time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            MainActor.assumeIsolated { self?.finishDiscovery() }
        }
    }

    /// End an invite pass: stop the DiscoInfo socket and broadcast the result.
    private func finishDiscovery() {
        discovering = false
        disco?.stop(); disco = nil
        notify()
    }

    /// Upsert a console seen via a DiscoInfo UDP reply (the connected console shows
    /// up directly as the bridge's peer in `payload().consoleIP`).
    private func addDiscovered(_ host: String, name: String? = nil) {
        if let i = discovered.firstIndex(where: { $0.id == host }) {
            if let name, discovered[i].name == nil { discovered[i].name = name; notify() }
            return
        }
        discovered.append(SurfaceConsoleInfo(id: host, host: host, name: name))
        discovered.sort { $0.host < $1.host }
        notify()
    }

}
