import Foundation

struct Component: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let category: String
    let approximateSizeMB: Double
    let isRequired: Bool
    let pathInPayload: String
    let destinationPath: String
    let bundleIdentifier: String
}

enum ComponentCatalog {
    static let components: [Component] = [
        Component(
            id: "hydra_app",
            displayName: "Hydra App & Audio Engine",
            description: "The main user interface and the core in-process audio routing backplane.",
            category: "Core Application",
            approximateSizeMB: 85.0,
            isRequired: true,
            pathInPayload: "Applications/Hydra.app",
            destinationPath: "/Applications/Hydra.app",
            bundleIdentifier: "audio.hydra.app"
        ),
        Component(
            id: "engine_hub",
            displayName: "Hydra Engine Hub Driver",
            description: "CoreAudio driver acting as the communications backplane.",
            category: "Core Drivers",
            approximateSizeMB: 1.0,
            isRequired: true,
            pathInPayload: "HAL/HydraVirtualSoundcard.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraVirtualSoundcard.driver",
            bundleIdentifier: "audio.hydra.virtualsoundcard"
        ),
        Component(
            id: "bridge_2a",
            displayName: "2 Channels Loopback Cable",
            description: "Recommended. Low latency 2-channel loopback audio bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge2A.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge2A.driver",
            bundleIdentifier: "audio.hydra.bridge.2a"
        ),
        Component(
            id: "bridge_2b",
            displayName: "2 Channels Loopback Cable (B)",
            description: "Secondary low latency 2-channel loopback audio bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge2B.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge2B.driver",
            bundleIdentifier: "audio.hydra.bridge.2b"
        ),
        Component(
            id: "bridge_4",
            displayName: "4 Channels Loopback Cable",
            description: "4-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge4.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge4.driver",
            bundleIdentifier: "audio.hydra.bridge.4"
        ),
        Component(
            id: "bridge_8",
            displayName: "8 Channels Loopback Cable",
            description: "8-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge8.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge8.driver",
            bundleIdentifier: "audio.hydra.bridge.8"
        ),
        Component(
            id: "bridge_16",
            displayName: "16 Channels Loopback Cable",
            description: "16-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge16.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge16.driver",
            bundleIdentifier: "audio.hydra.bridge.16"
        ),
        Component(
            id: "bridge_32",
            displayName: "32 Channels Loopback Cable",
            description: "32-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge32.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge32.driver",
            bundleIdentifier: "audio.hydra.bridge.32"
        ),
        Component(
            id: "bridge_64",
            displayName: "64 Channels Loopback Cable",
            description: "64-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge64.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge64.driver",
            bundleIdentifier: "audio.hydra.bridge.64"
        ),
        Component(
            id: "bridge_128",
            displayName: "128 Channels Loopback Cable",
            description: "128-channel virtual audio loopback bridge.",
            category: "Audio Bridges",
            approximateSizeMB: 0.5,
            isRequired: false,
            pathInPayload: "HAL/HydraAudioBridge128.driver",
            destinationPath: "/Library/Audio/Plug-Ins/HAL/HydraAudioBridge128.driver",
            bundleIdentifier: "audio.hydra.bridge.128"
        )
    ]
}
