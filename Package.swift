// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Claumagotchi",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Claumagotchi",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        )
    ]
)
