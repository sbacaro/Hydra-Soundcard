// Hydra Audio — GPL-3.0
// Control-surface configuration sheet (Network ▸ Control Surface ▸ Configure…).
//
// Fully automatic: the only choices are the DAW and the on/off switch. Hydra
// publishes the virtual HUI ports itself, auto-discovers the console and connects
// on its own. The sheet is otherwise status — which HUI ports to add in the DAW
// (the single in-DAW step), console search state, and a restrained live monitor.
//
// HIG: native `Form { Section }` (.grouped), `LabeledContent` rows, SF Symbols
// rendered hierarchically, semantic colors, and a calm monitor where the channel
// NUMBER encodes mute/solo and the bar encodes level/select — no widget clutter.

import SwiftUI
import HydraCore

struct SurfaceConfigSheet: View {
    @Environment(DaemonClient.self) private var client
    @Environment(\.dismiss) private var dismiss
    @State private var manualIP = ""

    private var s: SurfacePayload { client.surface }
    private var dawName: String { Hydra.surfacePreset(id: s.presetID)?.name ?? "your DAW" }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Form {
                dawSection
                portsSection
                consoleSection
                monitorSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 640)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "slider.vertical.3")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Control Surface")
                .font(.headline)
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: DAW + on/off (the only choices)

    private var dawSection: some View {
        Section {
            Picker("DAW", selection: Binding(
                get: { s.presetID },
                set: { client.setSurfaceConfig(enabled: s.enabled, presetID: $0, diagnostics: s.diagnostics) })) {
                ForEach(Hydra.surfacePresets) { Text($0.name).tag($0.id) }
            }
            Toggle("Control surface", isOn: Binding(
                get: { s.enabled },
                set: { client.setSurfaceConfig(enabled: $0, presetID: s.presetID, diagnostics: s.diagnostics) }))
        } header: {
            Text("DAW")
        } footer: {
            Text("Hydra creates the MIDI ports and finds the console automatically — you only pick the DAW and turn it on.")
        }
    }

    // MARK: The one in-DAW step — add a HUI controller per published port

    private var portsSection: some View {
        Section {
            if s.portNames.isEmpty {
                LabeledContent("Ports") {
                    Text(s.enabled ? "Publishing…" : "Off")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(s.portNames, id: \.self) { name in
                    LabeledContent {
                        Image(systemName: s.onlineToDAW ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(s.onlineToDAW ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                            .help(s.onlineToDAW ? "Online" : "Waiting for the DAW")
                    } label: {
                        Label(name, systemImage: "pianokeys")
                    }
                }
            }
        } header: {
            Text("Add in \(dawName) · \(s.stripCount) channels")
        } footer: {
            Text("Add one Mackie HUI controller per port above in \(dawName). Together the units cover all \(s.stripCount) faders at once. This is the only step that lives inside the DAW.")
        }
    }

    // MARK: Console (automatic discovery + connection)

    private var consoleSection: some View {
        Section {
            LabeledContent("Soundcraft console") {
                consoleStatus
            }
            HStack(spacing: 8) {
                Button("Rescan Network") { client.discoverSurfaces() }
                    .disabled(s.discovering || !s.enabled)
                Spacer()
            }
            // Manual connect — fallback when discovery can't reach the console
            // (e.g. a direct link-local Ethernet link).
            HStack(spacing: 8) {
                TextField("Console IP", text: $manualIP, prompt: Text("192.168.1.50"))
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()
                Button("Connect") { client.connectSurfaceConsole(ip: manualIP) }
                    .disabled(!s.enabled || manualIP.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Toggle("Diagnostic logging", isOn: Binding(
                get: { s.diagnostics },
                set: { client.setSurfaceConfig(enabled: s.enabled, presetID: s.presetID, diagnostics: $0) }))
                .help("Logs every HiQnet frame and meter packet to the system log (Console.app, subsystem audio.hydra). For the first hardware session; leave off otherwise.")
        } header: {
            Text("Console")
        } footer: {
            Text("Hydra finds the console over HiQnet on its own. For a direct Ethernet link (or if discovery can't reach it), enter the console's IP and Connect.")
        }
    }

    @ViewBuilder private var consoleStatus: some View {
        if s.consoleConnected {
            Label(s.consoleIP, systemImage: "checkmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.tint)
        } else if s.discovering {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Searching…").foregroundStyle(.secondary)
            }
        } else {
            Text(s.enabled ? "Not found" : "Off")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Live monitor — every strip across all units (calm)

    private var monitorSection: some View {
        Section {
            ForEach(Array(0..<max(s.unitCount, 1)), id: \.self) { unit in
                VStack(alignment: .leading, spacing: 7) {
                    Text("HUI \(unit + 1)  ·  ch \(unit * 8 + 1)–\(unit * 8 + 8)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    HStack(spacing: 10) {
                        ForEach(Array(0..<8), id: \.self) { z in
                            strip(unit * 8 + z)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(.vertical, 3)
            }
            if let err = s.lastError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Theme.warning)
                    .lineLimit(2)
            }
        } header: {
            Text("Monitor")
        } footer: {
            Text("Live state of every strip. Each shows the DAW track name once it arrives (else the channel number); the bar is the fader (highlighted when selected), green when soloed, orange when muted.")
        }
    }

    private func strip(_ g: Int) -> some View {
        let level = g < s.faders.count ? Double(s.faders[g]) / 255 : 0
        let mute  = g < s.mutes.count  && s.mutes[g]
        let solo  = g < s.solos.count  && s.solos[g]
        let sel   = g < s.selects.count && s.selects[g]
        let name  = g < s.channelNames.count ? s.channelNames[g] : ""
        let stateColor: Color = solo ? Theme.live : (mute ? Theme.warning : .secondary)
        return VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                Capsule().fill(.quaternary)
                    .frame(width: 6, height: 48)
                Capsule().fill(sel ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                    .frame(width: 6, height: max(3, CGFloat(level) * 48))
            }
            // Track name from the DAW when present (HUI scribble), else the number.
            Text(name.isEmpty ? "\(g + 1)" : name)
                .font(.system(size: 9, weight: (mute || solo) ? .semibold : .regular))
                .foregroundStyle(name.isEmpty ? stateColor : (mute || solo ? stateColor : .primary))
                .monospacedDigit()
                .lineLimit(1)
                .frame(width: 26)
        }
    }
}
