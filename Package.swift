// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HomerNetwork",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "HomerNetwork",
            targets: ["HomerNetwork"]
        )
    ],
    targets: [
        .target(
            name: "HomerNetwork",
            path: "Sources/HomerNetwork"
        )
    ],
    swiftLanguageModes: [.v6]
)
