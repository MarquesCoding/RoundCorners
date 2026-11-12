// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RoundCorners",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "RoundCorners", path: "Sources/RoundCorners")
    ]
)
