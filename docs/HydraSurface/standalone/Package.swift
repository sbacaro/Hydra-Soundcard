// swift-tools-version: 6.0
// HydraSurface — ponte de control surface (HiQnet ↔ HUI) para consoles Soundcraft Si.
//
// Reimplementação ORIGINAL e limpa, voltada a interoperabilidade. Não contém,
// não distribui e não depende de firmware, binários ou SDK de terceiros.
// Ver README.md (escopo/aviso de não-afiliação) e docs/PROTOCOL.md (spec funcional).
import PackageDescription

let package = Package(
    name: "HydraSurface",
    platforms: [
        // Alinhado ao Hydra (macOS 26 Tahoe — APIs de Liquid Glass na camada de UI).
        .macOS("26.0")
    ],
    products: [
        .library(name: "HydraSurface", targets: ["HydraSurface"])
    ],
    targets: [
        .target(
            name: "HydraSurface",
            path: "Sources/HydraSurface",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "HydraSurfaceTests",
            dependencies: ["HydraSurface"],
            path: "Tests/HydraSurfaceTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
