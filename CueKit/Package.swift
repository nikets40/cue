// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CueKit",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "CueKit", targets: ["CueKit"])
    ],
    targets: [
        .target(name: "CueKit")
    ]
)
