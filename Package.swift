// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CC-Beeper",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.12.4"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.17.0"),
    ],
    targets: [
        .executableTarget(
            name: "CC-Beeper",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "HotKey", package: "HotKey"),
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources",
            exclude: [
                "shells",
                "buttons",
                "shell.svg",
            ],
            resources: [
                .copy("cc-beeper-hook.py"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        ),
        .testTarget(
            name: "CC-BeeperTests",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
            ],
            path: "Tests/CC-BeeperTests"
        )
    ]
)
