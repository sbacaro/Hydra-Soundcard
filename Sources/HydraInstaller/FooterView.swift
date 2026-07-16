import SwiftUI

struct FooterView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        HStack {
            // Back button
            if showBack {
                Button("Go Back") {
                    state.previousStep()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!canGoBack)
            }

            Spacer()

            // Status indicator (selection summary etc.)
            if let status = statusText {
                Text(status)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Primary action
            if state.currentStep == .selection {
                Button("Uninstall Selected") {
                    state.isUninstallOnly = true
                    state.nextStep()
                    Task {
                        await runInstallation()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!primaryEnabled)
            }

            Button(primaryButtonTitle) {
                primaryAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!primaryEnabled)
        }
    }

    // MARK: - Logic

    private var showBack: Bool {
        switch state.currentStep {
        case .welcome, .install, .complete: return false
        default: return true
        }
    }

    private var canGoBack: Bool {
        !state.isInstalling
    }

    private var primaryButtonTitle: String {
        switch state.currentStep {
        case .welcome:   return "Continue"
        case .license:   return state.licenseAccepted ? "Continue" : "Agree"
        case .selection: return "Install"
        case .install:   return state.installationFinished ? "Continue" : "Installing…"
        case .complete:  return "Close"
        }
    }

    private var primaryEnabled: Bool {
        switch state.currentStep {
        case .welcome:   return state.diskSpaceOK
        case .license:   return true
        case .selection: return !state.selectedComponentIDs.isEmpty
        case .install:   return state.installationFinished
        case .complete:  return true
        }
    }

    private var statusText: String? {
        switch state.currentStep {
        case .selection:
            let count = state.selectedComponentIDs.count
            let total = ComponentCatalog.components.count
            let mb = state.selectedSizeMB
            return "\(count) of \(total) selected · ~\(mb) MB"
        case .install:
            if state.isInstalling, let cur = state.currentlyInstalling {
                return "Installing: \(cur)"
            } else if state.installationFinished {
                return "Installation complete"
            } else {
                return "Preparing…"
            }
        default:
            return nil
        }
    }

    private func primaryAction() {
        switch state.currentStep {
        case .welcome:
            state.nextStep()
        case .license:
            if state.licenseAccepted {
                state.nextStep()
            } else {
                state.licenseAccepted = true
            }
        case .selection:
            state.isUninstallOnly = false
            state.nextStep()
            Task {
                await runInstallation()
            }
        case .install:
            if state.installationFinished {
                state.nextStep()
            }
        case .complete:
            NSApp.terminate(nil)
        }
    }

    @MainActor
    private func runInstallation() async {
        state.isInstalling = true
        state.installationFinished = false
        state.overallProgress = 0
        state.successCount = 0
        state.failureCount = 0
        state.skippedCount = 0
        state.componentStatus = [:]
        state.currentlyInstalling = nil

        for comp in state.selectedComponents {
            state.componentStatus[comp.id] = .pending
        }

        let result = await InstallerEngine.runInstallation(
            components: state.selectedComponents,
            uninstallExisting: state.shouldUninstallExisting,
            existingComponents: state.detectedExistingComponents,
            uninstallOnly: state.isUninstallOnly,
            onLog: { line in
                state.appendLog(line)
            },
            onComponentStatusChange: { id, status in
                state.componentStatus[id] = status
                state.updateOverallProgress()
            },
            onOverallProgress: { p in
                if p == 1.0 {
                    state.overallProgress = 1.0
                }
            },
            onCurrentChange: { current in
                if let id = current,
                   let comp = ComponentCatalog.components.first(where: { $0.id == id }) {
                    state.currentlyInstalling = comp.displayName
                } else {
                    state.currentlyInstalling = nil
                }
            }
        )

        state.successCount = result.succeeded.count
        state.failureCount = result.failed.count
        state.skippedCount = result.skipped.count
        state.isInstalling = false
        state.installationFinished = true
    }
}
