import SwiftUI
import AppKit

// MARK: - App Entry Point

@main
struct HydraInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var state = InstallerState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(width: 820, height: 560)
                .background(WindowAccessor { window in
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.styleMask.insert(.fullSizeContentView)
                    window.isMovableByWindowBackground = true
                    window.standardWindowButton(.zoomButton)?.isEnabled = false
                    window.standardWindowButton(.miniaturizeButton)?.isEnabled = true
                    window.center()

                    let delegate = InstallerWindowDelegate(state: state)
                    appDelegate.windowDelegate = delegate
                    window.delegate = delegate
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .windowList) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var windowDelegate: InstallerWindowDelegate?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let state = windowDelegate?.state, state.isInstalling {
            let response = InstallerWindowDelegate.askToAbort(reason: .quit)
            switch response {
            case .terminateNow:
                InstallerEngine.requestCancellation()
                return .terminateNow
            case .terminateCancel:
                return .terminateCancel
            default:
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Window close confirmation

final class InstallerWindowDelegate: NSObject, NSWindowDelegate {
    let state: InstallerState

    init(state: InstallerState) {
        self.state = state
    }

    enum Reason { case close, quit }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard state.isInstalling else { return true }

        let resp = Self.askToAbort(reason: .close)
        if resp == .terminateNow {
            InstallerEngine.requestCancellation()
            return true
        }
        return false
    }

    static func askToAbort(reason: Reason) -> NSApplication.TerminateReply {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Installation in progress"
        alert.informativeText = """
            Hydra audio drivers are currently being copied and configured. \
            Closing now will abort the installation process and could leave the \
            audio system in an incomplete state.

            Are you sure you want to stop?
            """
        alert.addButton(withTitle: "Continue Installing")
        alert.addButton(withTitle: "Stop and Close")
        alert.buttons.last?.hasDestructiveAction = true

        let result = alert.runModal()
        return result == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
    }
}

// MARK: - Window accessor

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
