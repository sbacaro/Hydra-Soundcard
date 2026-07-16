import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: InstallerState

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 230)

            Divider()

            VStack(spacing: 0) {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 36)
                    .padding(.top, 32)
                    .padding(.bottom, 20)

                Divider()

                FooterView()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 820, minHeight: 560)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case .welcome:   WelcomeView()
        case .license:   LicenseView()
        case .selection: SelectionView()
        case .install:   InstallView()
        case .complete:  CompleteView()
        }
    }
}
