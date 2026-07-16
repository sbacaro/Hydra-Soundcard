import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to the Hydra Soundcard Installer")
                    .font(.system(size: 22, weight: .semibold))
                Text("This installer will copy the Hydra application and install the selected virtual loopback cables.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Info box
            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    icon: "info.circle.fill",
                    iconColor: .blue,
                    title: "What this installer does",
                    detail: "Places the main Hydra app inside /Applications, configures the communications engine hub, and installs chosen virtual audio device drivers inside /Library/Audio/Plug-Ins/HAL."
                )

                Divider()

                infoRow(
                    icon: "internaldrive",
                    iconColor: state.diskSpaceOK ? .green : .red,
                    title: "Disk space",
                    detail: diskSpaceDetail
                )

                Divider()

                if state.hasExistingInstallation {
                    infoRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "Existing Hydra components detected",
                        detail: existingDetail
                    )

                    Toggle(isOn: $state.shouldUninstallExisting) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clean install (uninstall existing version before copying)")
                                .font(.system(size: 13, weight: .medium))
                            Text("Recommended when updating. Cleans up old HAL drivers to prevent audio conflicts.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .padding(.top, 4)
                } else {
                    infoRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "No existing Hydra components detected",
                        detail: "Your system is ready for a clean installation."
                    )
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
            )

            Spacer()

            Text("Click Continue to review the terms and choose which virtual loopback devices to create.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private var diskSpaceDetail: String {
        let availableStr = String(format: "%.1f GB", state.availableDiskGB)
        let requiredStr = String(format: "%.1f GB", Double(state.requiredDiskMB) / 1024.0)
        if state.diskSpaceOK {
            return "\(availableStr) available · approximately \(requiredStr) required."
        } else {
            return "Only \(availableStr) available, but \(requiredStr) needed. Free up disk space before continuing."
        }
    }

    private var existingDetail: String {
        let names = state.detectedExistingComponents.map { $0.displayName }
        if names.count <= 3 {
            return "Found: " + names.joined(separator: ", ") + "."
        } else {
            return "Found \(names.count) components including " + names.prefix(3).joined(separator: ", ") + "…"
        }
    }

    private func infoRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}
