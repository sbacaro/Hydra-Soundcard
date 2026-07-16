import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App identity
            VStack(alignment: .leading, spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .padding(.bottom, 4)

                Text("Hydra")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Audio Soundcard")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 24)

            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Steps
            VStack(alignment: .leading, spacing: 4) {
                ForEach(InstallerStep.allCases, id: \.self) { step in
                    StepRow(step: step)
                }
            }
            .padding(.horizontal, 14)

            Spacer()

            // Version footer
            VStack(alignment: .leading, spacing: 2) {
                Text("Version \(installerVersion)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("Hydra Installer")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
        .frame(maxHeight: .infinity)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        )
    }

    private var installerVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1.11"
    }
}

private struct StepRow: View {
    @EnvironmentObject var state: InstallerState
    let step: InstallerStep

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(circleColor)
                .frame(width: 8, height: 8)

            Text(step.title(isUninstallOnly: state.isUninstallOnly))
                .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(textColor)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
        )
    }

    private var isCurrent: Bool {
        state.currentStep == step
    }

    private var isPast: Bool {
        state.currentStep.rawValue > step.rawValue
    }

    private var circleColor: Color {
        if isCurrent { return .accentColor }
        if isPast { return .green }
        return Color.secondary.opacity(0.4)
    }

    private var textColor: Color {
        if isCurrent { return .primary }
        if isPast { return .secondary }
        return .secondary.opacity(0.75)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
