// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CueBooth",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "CueBooth", path: "Sources/CueBooth")
    ]
)
