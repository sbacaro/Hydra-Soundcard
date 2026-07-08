// Hydra Audio — GPL-3.0
// Left sidebar — macOS 26 Liquid Glass native sidebar.
//
// Apple HIG changes vs previous version:
//   • Section tabs (Devices / Apps / Network) live INSIDE the sidebar via
//     .safeAreaInset(edge: .top), not in the main window toolbar. Navigation
//     is the sidebar's responsibility — the toolbar never duplicates it.
//   • txBadge custom capsule pills → .bordered .controlSize(.mini) buttons
//     with .tint() for the active state. Native hit targets, system styling.
//   • Row text uses semantic colors (.primary, .secondary, .tertiary) so the
//     sidebar adapts correctly to both Light and Dark Mode.
//   • List separators and backgrounds follow the .sidebar listStyle defaults.
//   • InfoButton popover unchanged — it's already HIG-correct.

import SwiftUI
import HydraCore
import SystemConfiguration

enum SidebarTab: String, CaseIterable {
    case devices = "Devices"
    case apps    = "Apps"
    case network = "Network"
}

struct SidebarView: View {
    @Environment(DaemonClient.self) private var client
    @Binding var tab: SidebarTab
    /// Selected bridge → its config shows in the inspector (master/detail).
    @Binding var selectedBridge: String?
    @State private var showManageBridges = false
    @State private var showSurfaceConfig = false
    @AppStorage("experimentalModules") private var experimentalModules = false
    @AppStorage("expControlSurface") private var expControlSurface = true
    @AppStorage("expModules") private var expModules = true

    var body: some View {
        List {
            switch tab {

                // MARK: Devices
                case .devices:
                    Section {
                        let active = client.bridges.filter(\.enabled)
                        if active.isEmpty {
                            emptyHint("No bridges on yet. Tap Manage to turn one on.")
                        } else {
                            ForEach(active) { bridge in
                                bridgeRow(bridge)
                            }
                        }
                        Button {
                            showManageBridges = true
                        } label: {
                            Label("Manage Bridges…", systemImage: "slider.horizontal.3")
                        }
                        .tint(.accentColor)
                        .sheet(isPresented: $showManageBridges) {
                            ManageBridgesSheet().environment(client)
                        }
                    } header: {
                        sectionHeader("Bridges",
                                      info: "Fixed virtual soundcards selectable by any app. Select one to configure it in the inspector; use Manage to turn bridges on or off.")
                    }

                    Section {
                        if client.devices.isEmpty {
                            emptyHint("No audio interfaces detected.")
                        } else {
                            ForEach(client.devices) { device in
                                deviceRow(device)
                            }
                        }
                    } header: {
                        sectionHeader("Audio Interfaces",
                                      info: "Devices added to the grid get their own audio path with drift correction (ASRC).")
                    }

                // MARK: Apps
                case .apps:
                    Section {
                        if client.apps.isEmpty {
                            emptyHint("Apps appear here once they use audio.")
                        } else {
                            ForEach(client.apps) { app in
                                appRow(app)
                            }
                        }
                    } header: {
                        sectionHeader("App Capture",
                                      info: "Captured apps appear as two mono lanes (L/R) while still playing normally.")
                    }

                // MARK: Network
                case .network:
                    Section {
                        if client.aes67.streams.isEmpty {
                            networkPlaceholder("dot.radiowaves.left.and.right",
                                               "No AES67 streams announced yet.")
                        } else {
                            ForEach(client.aes67.streams) { stream in
                                streamRow(stream)
                            }
                        }
                    } header: {
                        sectionHeader("AES67",
                                      info: "Standards-based audio-over-IP. Hydra slaves to PTP and subscribes to SAP-announced multicast streams.")
                    } footer: {
                        ptpStatusFooter
                    }

                    Section {
                        if !client.ndi.runtimeAvailable {
                            ndiRuntimeNotice
                        } else if client.ndi.sources.isEmpty {
                            networkPlaceholder("antenna.radiowaves.left.and.right",
                                               "No NDI sources on the network yet.")
                        } else {
                            ForEach(client.ndi.sources) { source in
                                ndiRow(source)
                            }
                        }
                    } header: {
                        sectionHeader("NDI Sources",
                                      info: "NDI audio sources on the network. Mark a bridge as NDI TX to broadcast it.")
                    }

                    // MARK: Dante Virtual Soundcard (Inferno)
                    Section {
                        infernoSection
                    } header: {
                        sectionHeader("Dante Virtual Soundcard",
                                      info: "Dante audio-over-IP using the Inferno engine. Select a Hydra Bridge, network interface, and latency, then turn it on. The device will appear as \"Hydra Soundcard\" in Dante Controller. Settings are locked while running.")
                    }

                    if experimentalModules && expControlSurface {
                        Section {
                            surfaceStatusRow
                            Button {
                                showSurfaceConfig = true
                            } label: {
                                Label("Configure…", systemImage: "slider.horizontal.3")
                            }
                            .tint(.accentColor)
                        } header: {
                            sectionHeader("Control Surface · HiQnet",
                                          info: "Uses the HiQnet protocol (exclusive to Soundcraft / Harman consoles such as the Si series). Hydra bridges the console over HiQnet to a HUI DAW (Pro Tools, Logic…) via virtual MIDI. Interoperability-only, personal use.")
                        }
                    }

                    if experimentalModules && expModules {
                        Section {
                            if client.modules.modules.isEmpty {
                                emptyHint("No modules loaded. Drop a .dylib into ~/Library/Application Support/Hydra/modules/ and restart the daemon.")
                            } else {
                                ForEach(client.modules.modules) { module in
                                    Label("\(module.name) \(module.version)",
                                          systemImage: "puzzlepiece.extension")
                                        .font(.callout.weight(.semibold))
                                }
                                ForEach(client.modules.sources) { source in
                                    moduleSourceRow(source)
                                }
                                if client.modules.sources.isEmpty {
                                    emptyHint("Loaded, but no sources discovered yet.")
                                }
                            }
                        } header: {
                            sectionHeader("Modules",
                                          info: "External plugin host. Modules are separate .dylibs, never shipped with Hydra.")
                        }
                    }
                }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showSurfaceConfig) {
            SurfaceConfigSheet().environment(client)
        }
        // The bottom status bar (Daemon · Backplane · Engine · CPU) is applied as
        // a safeAreaInset on the NavigationSplitView, but that inset doesn't reach
        // the sidebar column's scrolling list — so its last rows slide under the
        // bar. Reserve matching clearance here so the list ends ABOVE the bar.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 30)
        }
        // Section picker anchored to the top of the sidebar. An opaque .bar
        // background (matching the bottom status bar) occludes the scrolling list
        // so its text never bleeds through behind the picker; a bottom Divider
        // gives the strip a crisp edge.
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("Section", selection: $tab) {
                ForEach(SidebarTab.allCases, id: \.self) { t in
                    Text(LocalizedStringKey(t.rawValue)).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(.bar)
            .overlay(alignment: .bottom) { Divider() }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: LocalizedStringKey, info: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Text(title)
            InfoButton(text: info)
        }
        .padding(.leading, 16)
    }

    // MARK: - Empty hint

    private func emptyHint(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            // macOS `.sidebar` list rows truncate to one line by default; allow as
            // many lines as needed so the whole hint shows. The tooltip is a belt-
            // and-suspenders fallback (Apple shows the full text on hover).
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowSeparator(.hidden)
            .help(text)
    }

    // MARK: - Inferno Dante Virtual Soundcard

    /// Names of network interfaces that are Wi-Fi (IEEE80211).
    private var wifiInterfaces: Set<String> {
        var names = Set<String>()
        if let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
            for interface in interfaces {
                if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
                   let type = SCNetworkInterfaceGetInterfaceType(interface) as String?,
                   type == kSCNetworkInterfaceTypeIEEE80211 as String {
                    names.insert(bsdName)
                }
            }
        }
        return names
    }

    /// Network interfaces available on the machine (IPv4 only, excluding Wi-Fi).
    private var networkInterfaces: [(name: String, ip: String)] {
        var results: [(String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return results }
        defer { freeifaddrs(first) }
        let wifiIfaces = wifiInterfaces
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            let sa = ifa.pointee.ifa_addr
            if sa?.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: ifa.pointee.ifa_name)
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(sa, socklen_t(MemoryLayout<sockaddr_in>.size),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: hostname)
                    if !ip.hasPrefix("127.") && !wifiIfaces.contains(name) {
                        results.append((name, ip))
                    }
                }
            }
            cursor = ifa.pointee.ifa_next
        }
        return results
    }

    /// Whether the Inferno bridge is currently running.
    private var infernoIsRunning: Bool {
        client.status?.infernoRunning ?? false
    }

    /// Whether the given bridge ID is locked by Dante (cannot be disabled).
    private func isBridgeLockedByDante(_ bridgeID: String) -> Bool {
        client.config.infernoEnabled && client.config.infernoBridgeID == bridgeID
    }

    /// Resolves the link speed of a given network interface on macOS by running `ifconfig`.
    private func getLinkSpeed(for interfaceName: String) -> String {
        guard !interfaceName.isEmpty else { return "—" }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        process.arguments = [interfaceName]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("status: inactive") {
                    return "Inactive"
                }
                for line in output.components(separatedBy: .newlines) {
                    if line.contains("media:") {
                        if line.contains("1000base") || line.contains("1000Base") {
                            return "1 Gbps"
                        } else if line.contains("10Gbase") || line.contains("10gbase") || line.contains("10G-") {
                            return "10 Gbps"
                        } else if line.contains("2500base") || line.contains("2.5G") {
                            return "2.5 Gbps"
                        } else if line.contains("5000base") || line.contains("5G") {
                            return "5 Gbps"
                        } else if line.contains("100base") || line.contains("100Base") {
                            return "100 Mbps"
                        } else if line.contains("10base") || line.contains("10Base") {
                            return "10 Mbps"
                        }
                        if let start = line.range(of: "(")?.upperBound,
                           let end = line.range(of: " <")?.lowerBound {
                            return String(line[start..<end])
                        }
                        if line.contains("autoselect") {
                            return "1 Gbps"
                        }
                    }
                }
            }
        } catch {
            // ignore
        }
        return "1 Gbps"
    }

    /// The Dante Virtual Soundcard control panel (Inferno).
    @ViewBuilder
    private var infernoSection: some View {
        let locked = infernoIsRunning
        let ifaces = networkInterfaces

        // Source bridge
        VStack(alignment: .leading, spacing: 4) {
            Text("Source Bridge")
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: { client.config.infernoBridgeID },
                set: { value in client.updateConfig { $0.infernoBridgeID = value } }
            )) {
                ForEach(Hydra.bridgeCatalog, id: \.id) { spec in
                    Text(spec.name).tag(spec.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(locked)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)

        // Network interface
        VStack(alignment: .leading, spacing: 4) {
            Text("Network Interface")
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: { client.config.infernoInterface },
                set: { value in client.updateConfig { $0.infernoInterface = value } }
            )) {
                if ifaces.isEmpty {
                    Text("No interfaces").tag("")
                } else {
                    ForEach(ifaces, id: \.name) { iface in
                        Text("\(iface.name) (\(iface.ip))").tag(iface.name)
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(locked)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)

        // Latency
        VStack(alignment: .leading, spacing: 4) {
            Text("Latency")
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: { client.config.infernoLatencyMs },
                set: { value in client.updateConfig { $0.infernoLatencyMs = value } }
            )) {
                Text("4 ms").tag(4)
                Text("10 ms").tag(10)
                Text("20 ms").tag(20)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(locked)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)

        // Link Speed (read-only)
        HStack {
            Text("Link Speed")
                .foregroundStyle(.secondary)
            Spacer()
            let selectedInterfaceName = client.config.infernoInterface.isEmpty
                ? (ifaces.first?.name ?? "")
                : client.config.infernoInterface
            Text(getLinkSpeed(for: selectedInterfaceName))
                .foregroundStyle(.primary)
        }
        .font(.callout)

        // Start / Stop button
        Button {
            client.updateConfig { $0.infernoEnabled = !locked }
        } label: {
            Label(locked ? "Stop Dante" : "Start Dante",
                  systemImage: locked ? "stop.fill" : "play.fill")
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(locked ? .red : .accentColor)
        .padding(.top, 4)

        // Status line
        HStack(spacing: 6) {
            Circle()
                .fill(locked ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 7, height: 7)
            Text(locked ? "\"Hydra Soundcard\" on Dante network" : "Stopped")
                .font(.caption)
                .foregroundStyle(locked ? .primary : .secondary)
        }
        .listRowSeparator(.hidden)
        .padding(.top, 2)
    }

    // MARK: - Network empty placeholder (calm, centered — Apple's empty-state)

    /// A quiet, centered placeholder for an empty network section: a muted SF
    /// Symbol over one secondary line. Replaces the bare left-flush gray sentence
    /// so an idle Network tab reads as "nothing here yet", not as an error.
    private func networkPlaceholder(_ icon: String, _ text: LocalizedStringKey) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .help(text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // MARK: - Clock sync status (calm — a normal free-run is NOT a warning)

    /// PTP/clock state shown as a quiet section footer (a small dot + caption),
    /// not a yellow warning row. "No grandmaster" is the normal idle state — TX
    /// just free-runs — so it gets a neutral dot, never an alert triangle.
    private var ptpStatusFooter: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(client.aes67.ptpLocked ? Theme.live : Color.secondary)
                .frame(width: 6, height: 6)
            Text(client.aes67.ptpLocked
                 ? "PTP locked · \(client.aes67.ptpGrandmaster)"
                 : "PTP: no grandmaster")
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .help(client.aes67.ptpLocked
              ? "Following clock — grandmaster \(client.aes67.ptpGrandmaster), domain \(client.aes67.ptpDomain)."
              : "No PTP grandmaster — TX free-runs.")
    }

    // MARK: - NDI runtime call-to-action (calm, with the download action)

    private var ndiRuntimeNotice: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 22, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
            Text("NDI runtime not installed — Hydra loads it dynamically (GPL constraint).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Link("Download NDI Runtime…", destination: URL(string: Hydra.ndiRedistURL)!)
                .font(.callout.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // MARK: - Bridge row (lean, selectable → config in the inspector)

    private func bridgeRow(_ bridge: BridgeInfo) -> some View {
        Button { selectedBridge = bridge.id } label: {
            HStack(spacing: 9) {
                Image(systemName: "cable.connector")
                    .foregroundStyle(bridge.present ? .secondary : .tertiary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(bridge.name)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .help(bridge.name)
                    Text(bridgeSubtitle(bridge))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 6)
                if !bridge.present {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .help("Activating…")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedBridge == bridge.id ? Color.accentColor.opacity(0.12) : Color.clear)
    }

    private func bridgeSubtitle(_ bridge: BridgeInfo) -> String {
        if bridge.enabled && !bridge.present { return "\(bridge.channels) ch · activating…" }
        var parts = ["\(bridge.channels) ch"]
        switch bridge.role {
        case .input:  parts.append("in")
        case .output: parts.append("out")
        case .both:   parts.append("in · out")
        }
        if bridge.ndiTX { parts.append("NDI") }
        if bridge.aes67TX { parts.append("AES67") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Interface row (legacy, unused — kept until fully removed)

    private func interfaceRow(_ iface: VirtualInterfaceInfo) -> some View {
        let recording = client.recording(for: iface.id) != nil
        // Source-list row: icon + name + directional I/O badges. The most common
        // actions (record / TX / delete) are reachable from BOTH a visible ⋯ menu
        // (discoverable) and the right-click context menu (power users).
        return HStack(spacing: 8) {
            Image(systemName: "rectangle.3.group")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(iface.name)
                    .lineLimit(1)
                ioBadges(inputs: iface.inChannels, outputs: iface.outChannels, stereo: iface.stereo)
            }
            Spacer(minLength: 6)
            if recording {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(Theme.clip)
                    .help("Recording to disk")
            }
            if iface.aes67TX { statusTag("AES") }
            if iface.ndiTX   { statusTag("NDI") }
            interfaceMenu(iface, recording: recording)
        }
        .contentShape(Rectangle())
        .help("Pool: TX \(iface.inBase + 1)–\(iface.inBase + max(iface.inChannels, 1)) · RX \(iface.outBase + 1)–\(iface.outBase + max(iface.outChannels, 1))")
        .contextMenu { interfaceMenuItems(iface, recording: recording) }
    }

    /// Actions shared by the visible ⋯ menu and the right-click context menu.
    @ViewBuilder
    private func interfaceMenuItems(_ iface: VirtualInterfaceInfo, recording: Bool) -> some View {
        Button(recording ? "Stop Recording" : "Record Output…") {
            if recording { client.stopRecording(iface.id) }
            else         { client.startRecording(iface.id) }
        }
        Toggle("Announce on the network (AES67 TX)", isOn: Binding(
            get: { iface.aes67TX },
            set: { client.setInterfaceAES67(iface.id, enabled: $0) }))
        Toggle("Broadcast as NDI source (TX)", isOn: Binding(
            get: { iface.ndiTX },
            set: { client.setInterfaceNDI(iface.id, enabled: $0) }))
            .disabled(!client.ndi.runtimeAvailable)
        Divider()
        Button("Delete Interface", role: .destructive) {
            client.deleteInterface(iface.id)
        }
    }

    /// Always-visible ⋯ button so the row's actions aren't hidden behind a
    /// right-click (the System Settings / Music pattern for list rows).
    private func interfaceMenu(_ iface: VirtualInterfaceInfo, recording: Bool) -> some View {
        Menu {
            interfaceMenuItems(iface, recording: recording)
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.medium)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)        // .borderless dims the label further → near-black in Dark Mode
        .fixedSize()
        .help("Interface actions")
    }

    private func statusTag(_ text: String) -> some View {
        Badge(text, small: true)
            .help("\(text) TX on")
    }

    // MARK: - Directional I/O badges
    //
    // The person's request: read input vs output at a glance. Each badge pairs a
    // directional arrow with a written "in"/"out" label and the channel count —
    // meaning is carried by icon + text, never color alone (HIG: Accessibility).

    @ViewBuilder
    private func ioBadges(inputs inCh: Int, outputs outCh: Int, stereo: Bool = false) -> some View {
        HStack(spacing: 9) {
            if inCh > 0 {
                ioBadge(arrow: "arrow.down", count: inCh, label: "in")
                    .help("\(inCh) input channel\(inCh == 1 ? "" : "s") — what plays INTO this")
            }
            if outCh > 0 {
                ioBadge(arrow: "arrow.up", count: outCh, label: "out")
                    .help("\(outCh) output channel\(outCh == 1 ? "" : "s") — what is recorded/sent FROM this")
            }
            if inCh == 0 && outCh == 0 {
                Text("no channels")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if stereo {
                Text("stereo")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func ioBadge(arrow: String, count: Int, label: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: arrow)
                .font(.system(size: 9, weight: .bold))
            Text("\(count) \(label)")
                .font(.caption)
                .monospacedDigit()
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Device row

    private func deviceRow(_ device: PhysicalDeviceInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: deviceIcon(device))
                .foregroundStyle(device.present ? .secondary : .tertiary)
                .frame(width: 20)
                .help(device.present ? "Connected"
                                     : "Offline — patches kept, re-binds on return")
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .foregroundStyle(device.present ? .primary : .secondary)
                    .lineLimit(1)
                    .help(device.name)
                HStack(spacing: 8) {
                    Text(deviceKind(device))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    ioBadges(inputs: device.inputChannels, outputs: device.outputChannels)
                }
            }
            Spacer(minLength: 6)
            InfoPopoverButton { DeviceDetailView(device: device).environment(client) }
            Toggle("", isOn: Binding(
                get: { device.used },
                set: { client.setDeviceUse(uid: device.uid, used: $0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
                .help("Add this device's channels to the patch grid")
        }
    }

    private func deviceIcon(_ device: PhysicalDeviceInfo) -> String {
        if device.inputChannels > 0 && device.outputChannels == 0 { return "mic" }
        if device.outputChannels > 0 && device.inputChannels == 0 { return "hifispeaker" }
        return "pianokeys"
    }

    /// A plain-language direction label, complementing the icon and I/O badges.
    private func deviceKind(_ device: PhysicalDeviceInfo) -> String {
        if device.inputChannels > 0 && device.outputChannels == 0 { return "Input" }
        if device.outputChannels > 0 && device.inputChannels == 0 { return "Output" }
        return "In/Out"
    }

    // MARK: - App row

    private func appRow(_ app: AppInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "macwindow")
                .foregroundStyle(app.isPlaying ? .secondary : .tertiary)
                .frame(width: 18)
                .help(app.isPlaying ? "Playing audio" : "Silent")
            Text(app.name)
                .foregroundStyle(app.isPlaying ? .primary : .secondary)
                .lineLimit(1)
                .help(app.name)
            Spacer(minLength: 6)
            InfoPopoverButton { AppCaptureDetailView(app: app).environment(client) }
            Toggle("", isOn: Binding(
                get: { app.captured },
                set: { client.setAppCapture(pid: app.pid, captured: $0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
                .help("Capture — the app keeps playing normally, Hydra gets a tap copy")
        }
    }

    // MARK: - AES67 stream row

    private func streamRow(_ stream: Aes67Stream) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .foregroundStyle(stream.subscribed ? .secondary : .tertiary)
                .frame(width: 18)
                .help(stream.subscribed ? "Subscribed" : "Available")
            Text(stream.name)
                .foregroundStyle(stream.subscribed ? .primary : .secondary)
                .lineLimit(1)
                .help(stream.name)
            Spacer(minLength: 6)
            InfoPopoverButton { StreamDetailView(stream: stream).environment(client) }
            Toggle("", isOn: Binding(
                get: { stream.subscribed },
                set: { client.subscribeStream(id: stream.id, subscribed: $0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
                .help("Subscribe — joins the multicast group, adds channels to the grid")
        }
    }

    // MARK: - NDI source row

    private func ndiRow(_ source: NdiSourceInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(source.subscribed ? .secondary : .tertiary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(source.name)
                    .foregroundStyle(source.subscribed ? .primary : .secondary)
                    .lineLimit(1)
                    .help(source.name)
                if source.channels > 0 {
                    Text("\(source.channels) ch @ \(Int(source.sampleRate)) Hz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 6)
            Toggle("", isOn: Binding(
                get: { source.subscribed },
                set: { client.subscribeNdi(id: source.id, subscribed: $0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
        }
    }

    // MARK: - Module source row

    private func moduleSourceRow(_ source: ModuleSourceInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension")
                .foregroundStyle(source.subscribed ? .secondary : .tertiary)
                .frame(width: 18)
            Text(source.channels > 0 ? "\(source.name) · \(source.channels)ch" : source.name)
                .foregroundStyle(source.subscribed ? .primary : .secondary)
                .lineLimit(1)
            Spacer(minLength: 6)
            Toggle("", isOn: Binding(
                get: { source.subscribed },
                set: { client.subscribeModuleSource(id: source.id, subscribed: $0) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
        }
    }

    // MARK: - Control surface status row

    private var surfaceStatusRow: some View {
        let s = client.surface
        return HStack(spacing: 8) {
            Image(systemName: "pianokeys")
                .foregroundStyle(s.enabled ? .secondary : .tertiary)
                .frame(width: 18)
                .help(s.enabled ? "Bridge running" : "Bridge off")
            VStack(alignment: .leading, spacing: 1) {
                Text("Soundcraft Si · HiQnet")
                    .foregroundStyle(s.enabled ? .primary : .secondary)
                    .lineLimit(1)
                    .help("HiQnet control-surface bridge (Soundcraft/Harman) → HUI DAW")
                Text(surfaceSubtitle(s))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            // Quick on/off — keeps the current DAW; everything else is automatic.
            Toggle("", isOn: Binding(
                get: { s.enabled },
                set: { client.setSurfaceConfig(enabled: $0, presetID: s.presetID, diagnostics: s.diagnostics) }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(.accentColor)
                .help("Start or stop the control-surface bridge")
        }
    }

    private func surfaceSubtitle(_ s: SurfacePayload) -> String {
        let preset = Hydra.surfacePreset(id: s.presetID)?.name ?? "DAW"
        guard s.enabled else { return "Off · \(preset)" }
        // Keep to three short segments so the sidebar row never truncates.
        let state: String
        if s.consoleConnected      { state = "console connected" }
        else if s.discovering      { state = "searching…" }
        else if s.onlineToDAW      { state = "DAW online" }
        else                       { state = "starting…" }
        return "\(preset) · \(s.stripCount) ch · \(state)"
    }

}

// MARK: - Detail scaffolding
//
// Shown in a popover from each row's ⓘ button (macOS System Settings pattern),
// so details never push into the sidebar or cover the grid. A ScrollView + VStack
// (not a grouped Form, which lays out empty in this context) with SEMANTIC colors
// (.primary/.secondary) so nothing turns invisible in either appearance.

private struct DetailHeader: View {
    let icon: String
    let title: String
    let online: Bool
    let onlineLabel: String
    let offlineLabel: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                HStack(spacing: 5) {
                    Circle().fill(online ? Theme.live : Theme.warning).frame(width: 7, height: 7)
                    Text(online ? onlineLabel : offlineLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private func detailRow(_ label: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
        Text(label).foregroundStyle(.secondary)
        Spacer(minLength: 12)
        Text(value).foregroundStyle(.primary).monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
    .font(.callout)
}

private func detailMono(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label).font(.callout).foregroundStyle(.secondary)
        Text(value)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .lineLimit(2).truncationMode(.middle)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: - Device detail

private struct DeviceDetailView: View {
    @Environment(DaemonClient.self) private var client
    let device: PhysicalDeviceInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DetailHeader(icon: "hifispeaker.fill", title: device.name,
                             online: device.present,
                             onlineLabel: "Connected", offlineLabel: "Waiting to reconnect")
                Divider()
                detailRow("Inputs",  "\(device.inputChannels) ch")
                detailRow("Outputs", "\(device.outputChannels) ch")
                detailRow("Sample rate", device.present ? "\(Int(device.sampleRate)) Hz" : "—")
                detailRow("Format", "32-bit float")
                detailRow("Clock", "ASRC to engine")
                detailRow("In grid", device.used ? "Yes" : "No")
                detailMono("UID", device.uid)
                Divider()
                Toggle("Use in grid", isOn: Binding(
                    get: { device.used },
                    set: { client.setDeviceUse(uid: device.uid, used: $0) }))
                    .tint(.accentColor)
                    .help("Adds this device's channels to the patch grid")
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - App capture detail

private struct AppCaptureDetailView: View {
    @Environment(DaemonClient.self) private var client
    let app: AppInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DetailHeader(icon: "macwindow", title: app.name,
                             online: app.isPlaying,
                             onlineLabel: "Playing audio", offlineLabel: "Silent")
                Divider()
                detailRow("Format", "2 mono lanes (L/R)")
                detailRow("Captured", app.captured ? "Yes" : "No")
                detailRow("PID", "\(app.pid)")
                if let bid = app.bundleID { detailMono("Bundle ID", bid) }
                Divider()
                Toggle("Capture", isOn: Binding(
                    get: { app.captured },
                    set: { client.setAppCapture(pid: app.pid, captured: $0) }))
                    .tint(.accentColor)
                    .help("The app keeps playing to its normal output; Hydra gets a tap copy")
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - AES67 stream detail

private struct StreamDetailView: View {
    @Environment(DaemonClient.self) private var client
    let stream: Aes67Stream

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DetailHeader(icon: "network", title: stream.name,
                             online: stream.subscribed,
                             onlineLabel: "Subscribed", offlineLabel: "Available")
                Divider()
                detailRow("Channels", "\(stream.channels)")
                detailRow("Encoding", stream.encoding)
                detailRow("Sample rate", "\(Int(stream.sampleRate)) Hz")
                detailMono("Multicast", "\(stream.address):\(stream.port)")
                detailMono("Origin", stream.origin)
                Divider()
                Toggle("Subscribe", isOn: Binding(
                    get: { stream.subscribed },
                    set: { client.subscribeStream(id: stream.id, subscribed: $0) }))
                    .tint(.accentColor)
                    .help("Joins the multicast group and adds channels to the grid")
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Info balloon

struct InfoButton: View {
    let text: LocalizedStringKey
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            Image(systemName: "info.circle")
                .font(.callout)
                .imageScale(.small)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .bottom) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                // Wrap and grow to fit the whole sentence — a popover is the place
                // to SHOW the text, so it must never truncate. fixedSize forces the
                // full multi-line height instead of collapsing to one clipped line.
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 280, alignment: .leading)
                .padding(14)
        }
    }
}

// MARK: - Row detail popover

/// A trailing ⓘ that reveals an item's details in a popover — the macOS System
/// Settings pattern (Wi-Fi / network rows). Details never push into the sidebar
/// or cover the grid.
struct InfoPopoverButton<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .imageScale(.medium)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Details")
        .popover(isPresented: $open, arrowEdge: .trailing) {
            content().frame(width: 300, height: 340)
        }
    }
}

// MARK: - Manage Bridges sheet

/// Turn the 8 fixed bridges on/off. Enabled ones appear in the sidebar list.
/// Bridges in use by Dante are locked and cannot be disabled.
struct ManageBridgesSheet: View {
    @Environment(DaemonClient.self) private var client
    @Environment(\.dismiss) private var dismiss

    /// Whether the given bridge is locked by Dante (in use as the DVS source).
    private func lockedByDante(_ bridge: BridgeInfo) -> Bool {
        client.config.infernoEnabled && client.config.infernoBridgeID == bridge.id
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bridges")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)

            Divider()

            List {
                ForEach(client.bridges) { bridge in
                    let isDanteLocked = lockedByDante(bridge)
                    HStack(spacing: 11) {
                        Image(systemName: "cable.connector")
                            .foregroundStyle(bridge.enabled ? Color.accentColor : .secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 5) {
                                Text(bridge.name)
                                if isDanteLocked {
                                    Text("Dante")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.accentColor, in: Capsule())
                                }
                            }
                            Text(isDanteLocked
                                 ? "\(bridge.channels) ch · in use by Dante — stop DVS to release"
                                 : "\(bridge.channels) in · \(bridge.channels) out")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(isDanteLocked ? .orange : .secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { bridge.enabled },
                            set: { client.setBridgeEnabled(bridge.id, enabled: $0) }))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(isDanteLocked)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset)
        }
        .frame(width: 380, height: 460)
    }
}
