// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CueBooth",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../CueKit")
    ],
    targets: [
        .executableTarget(
            name: "CueBooth",
            dependencies: ["CueKit"],
            path: "Sources/CueBooth"
        )
    ]
)
