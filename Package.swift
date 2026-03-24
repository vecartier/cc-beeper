// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Claumagotchi",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Claumagotchi",
            path: "Sources",
            exclude: [
                "shells",
                "buttons",
                "shell.svg",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        )
    ]
)
