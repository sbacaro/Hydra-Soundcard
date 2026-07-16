import SwiftUI

struct InstallView: View {
    @EnvironmentObject var state: InstallerState
    @State private var showLog: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(state.installationFinished ? 
                     (state.isUninstallOnly ? "Uninstallation finished" : "Installation finished") :
                     (state.isUninstallOnly ? "Uninstalling components" : "Installing components"))
                    .font(.system(size: 22, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Overall progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(currentTitle)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("\(Int(state.overallProgress * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                ProgressView(value: state.overallProgress)
                    .progressViewStyle(.linear)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )

            // Per-component list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(state.selectedComponents) { comp in
                        ComponentInstallRow(component: comp)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Show log toggle
            HStack {
                Button(action: { showLog.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showLog ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                        Text(showLog ? "Hide installation log" : "Show installation log")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()
            }

            if showLog {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(state.installationLog.isEmpty ? "Waiting for output…" : state.installationLog)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .id("logEnd")
                    }
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .onChange(of: state.installationLog) { _ in
                        proxy.scrollTo("logEnd", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var subtitle: String {
        if state.installationFinished {
            return "Click Continue to see the summary."
        } else if state.isInstalling {
            return "Please don't quit the installer or put your Mac to sleep."
        } else {
            return state.isUninstallOnly ? "Preparing the uninstallation session…" : "Preparing the installation session…"
        }
    }

    private var currentTitle: String {
        if let cur = state.currentlyInstalling {
            return state.isUninstallOnly ? "Uninstalling \(cur)" : "Installing \(cur)"
        } else if state.installationFinished {
            return "Done"
        } else {
            return "Preparing…"
        }
    }
}

private struct ComponentInstallRow: View {
    @EnvironmentObject var state: InstallerState
    let component: Component

    private var status: ComponentStatus {
        state.componentStatus[component.id] ?? .pending
    }

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 16, height: 16)

            Text(component.displayName)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()

            Text(statusText)
                .font(.system(size: 11))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(rowBackground)
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary.opacity(0.5))
        case .installing:
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.7)
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.orange)
        }
    }

    private var statusText: String {
        switch status {
        case .pending:               return "Waiting"
        case .installing:            return state.isUninstallOnly ? "Uninstalling" : "Installing"
        case .installed:             return state.isUninstallOnly ? "Uninstalled" : "Installed"
        case .failed(let reason):    return "Failed · \(reason)"
        case .skipped:               return "Skipped"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending:     return .secondary
        case .installing:  return .accentColor
        case .installed:   return .green
        case .failed:      return .red
        case .skipped:     return .orange
        }
    }

    private var rowBackground: Color {
        switch status {
        case .installing:
            return Color.accentColor.opacity(0.08)
        default:
            return Color.clear
        }
    }
}
