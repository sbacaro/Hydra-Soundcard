import Foundation
import SwiftUI
import Combine

enum InstallerStep: Int, CaseIterable {
    case welcome = 0
    case license = 1
    case selection = 2
    case install = 3
    case complete = 4

    func title(isUninstallOnly: Bool) -> String {
        switch self {
        case .welcome:   return "Introduction"
        case .license:   return "License"
        case .selection: return "Selection"
        case .install:   return isUninstallOnly ? "Uninstallation" : "Installation"
        case .complete:  return "Summary"
        }
    }

    var title: String {
        title(isUninstallOnly: false)
    }
}

enum ComponentStatus: Equatable {
    case pending
    case installing
    case installed
    case failed(reason: String)
    case skipped
}

@MainActor
final class InstallerState: ObservableObject {
    @Published var currentStep: InstallerStep = .welcome
    @Published var licenseAccepted: Bool = false

    // Component selection
    @Published var selectedComponentIDs: Set<String> = Set(ComponentCatalog.components.map { $0.id })

    // Existing installation detection
    @Published var detectedExistingComponents: [Component] = []
    @Published var shouldUninstallExisting: Bool = false
    @Published var isUninstallOnly: Bool = false

    // Disk space
    @Published var availableDiskGB: Double = 0
    @Published var requiredDiskMB: Int = Int(ComponentCatalog.components.reduce(0.0) { $0 + $1.approximateSizeMB })

    // Installation progress
    @Published var componentStatus: [String: ComponentStatus] = [:]
    @Published var currentlyInstalling: String? = nil
    @Published var installationLog: String = ""
    @Published var overallProgress: Double = 0
    @Published var isInstalling: Bool = false
    @Published var installationFinished: Bool = false

    // Completion summary
    @Published var successCount: Int = 0
    @Published var failureCount: Int = 0
    @Published var skippedCount: Int = 0

    init() {
        refreshDiskSpace()
        detectExistingComponents()
    }

    // MARK: - Disk Space

    func refreshDiskSpace() {
        let url = URL(fileURLWithPath: "/")
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
           let bytes = values.volumeAvailableCapacity {
            availableDiskGB = Double(bytes) / 1_073_741_824.0
        }
    }

    var diskSpaceOK: Bool {
        let requiredGB = Double(requiredDiskMB) / 1024.0
        return availableDiskGB >= requiredGB + 1.0 // +1GB safety margin
    }

    // MARK: - Existing components detection

    func detectExistingComponents() {
        let fm = FileManager.default
        var found: Set<String> = []
        
        if fm.fileExists(atPath: "/Applications/Hydra.app") {
            found.insert("hydra_app")
        }
        if fm.fileExists(atPath: "/Library/Audio/Plug-Ins/HAL/HydraVirtualSoundcard.driver") {
            found.insert("engine_hub")
        }
        
        // Loopback bridges
        for bridge in ComponentCatalog.components.filter({ !$0.isRequired }) {
            let filename = (bridge.pathInPayload as NSString).lastPathComponent
            if fm.fileExists(atPath: "/Library/Audio/Plug-Ins/HAL/\(filename)") {
                found.insert(bridge.id)
            }
        }

        detectedExistingComponents = ComponentCatalog.components.filter { found.contains($0.id) }
    }

    var hasExistingInstallation: Bool {
        !detectedExistingComponents.isEmpty
    }

    // MARK: - Selection helpers

    func selectAll() {
        selectedComponentIDs = Set(ComponentCatalog.components.map { $0.id })
    }

    func deselectAll() {
        // Keep required components selected
        selectedComponentIDs = Set(ComponentCatalog.components.filter { $0.isRequired }.map { $0.id })
    }

    func toggle(_ componentID: String) {
        // Cannot toggle required components
        guard let component = ComponentCatalog.components.first(where: { $0.id == componentID }),
              !component.isRequired else { return }
        
        if selectedComponentIDs.contains(componentID) {
            selectedComponentIDs.remove(componentID)
        } else {
            selectedComponentIDs.insert(componentID)
        }
    }

    var selectedComponents: [Component] {
        ComponentCatalog.components.filter { selectedComponentIDs.contains($0.id) }
    }

    var selectedSizeMB: Int {
        Int(selectedComponents.reduce(0.0) { $0 + $1.approximateSizeMB })
    }

    // MARK: - Navigation

    func nextStep() {
        if let next = InstallerStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let prev = InstallerStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    func goTo(_ step: InstallerStep) {
        currentStep = step
    }

    func appendLog(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        installationLog += "[\(timestamp)] \(message)\n"
    }

    func updateOverallProgress() {
        let components = selectedComponents
        guard !components.isEmpty else {
            overallProgress = 0
            return
        }
        
        var totalProgress: Double = 0
        for comp in components {
            let status = componentStatus[comp.id] ?? .pending
            switch status {
            case .pending:
                totalProgress += 0.0
            case .installing:
                totalProgress += 0.5
            case .installed, .failed, .skipped:
                totalProgress += 1.0
            }
        }
        
        overallProgress = totalProgress / Double(components.count)
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
