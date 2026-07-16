import SwiftUI

struct CompleteView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 12)

            // Status icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: iconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(spacing: 6) {
                Text(headline)
                    .font(.system(size: 22, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 460)
            }

            // Stats row
            HStack(spacing: 18) {
                statCard(value: state.successCount, label: state.isUninstallOnly ? "Uninstalled" : "Installed", color: .green, icon: "checkmark.circle.fill")
                if state.failureCount > 0 {
                    statCard(value: state.failureCount, label: "Failed", color: .red, icon: "xmark.circle.fill")
                }
                if state.skippedCount > 0 {
                    statCard(value: state.skippedCount, label: "Skipped", color: .orange, icon: "minus.circle.fill")
                }
            }

            if allSucceeded && !state.isUninstallOnly {
                Button("Launch Hydra") {
                    launchHydra()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }

            // Next steps
            VStack(alignment: .leading, spacing: 10) {
                Text("Next steps")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                if state.isUninstallOnly {
                    nextStep(text: "Verify that Hydra is no longer present in your Applications folder.")
                    nextStep(text: "Verify that audio loopback bridges are removed from your sound settings.")
                } else {
                    nextStep(text: "Open your DAW (Logic Pro, Ableton, Pro Tools…) or Dante Controller to check the new bridges.")
                    nextStep(text: "You can open the Hydra app from /Applications to configure active matrix routes.")
                }
                if state.failureCount > 0 {
                    nextStep(text: "Check the log file at ~/Library/Logs/Hydra Installer.log for failure details.")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var allSucceeded: Bool {
        state.failureCount == 0 && state.successCount > 0
    }

    private var someSucceeded: Bool {
        state.successCount > 0
    }

    private var headline: String {
        if state.isUninstallOnly {
            if allSucceeded { return "Uninstallation complete" }
            if someSucceeded { return "Uninstallation finished with some issues" }
            return "Uninstallation could not be completed"
        } else {
            if allSucceeded { return "Installation complete" }
            if someSucceeded { return "Installation finished with some issues" }
            return "Installation could not be completed"
        }
    }

    private var subtitle: String {
        if state.isUninstallOnly {
            if allSucceeded {
                return "All selected Hydra components were uninstalled successfully and removed from your HAL paths."
            }
            if someSucceeded {
                return "Most components were uninstalled correctly, but some failed."
            }
            return "No components were uninstalled."
        } else {
            if allSucceeded {
                return "All selected Hydra components were installed successfully and are ready for use."
            }
            if someSucceeded {
                return "Most components installed correctly, but some failed. You can run the installer again to retry."
            }
            return "No components were installed. Check permissions and try again."
        }
    }

    private var iconName: String {
        if allSucceeded { return "checkmark" }
        if someSucceeded { return "exclamationmark" }
        return "xmark"
    }

    private var iconColor: Color {
        return .white
    }

    private var iconBackground: Color {
        if allSucceeded { return .green }
        if someSucceeded { return .orange }
        return .red
    }

    private func statCard(value: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }

    private func nextStep(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func launchHydra() {
        let path = "/Applications/Hydra.app"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [path]
        try? task.run()
        NSApp.terminate(nil)
    }
}
