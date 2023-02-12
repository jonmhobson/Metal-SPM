// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MetalSPM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MetalSPM", targets: ["MetalSPM"]),
    ],
    targets: [
        .executableTarget(
            name: "MetalSPM",
            dependencies: [])
    ]
)
