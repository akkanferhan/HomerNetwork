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
        ),
        .library(
            name: "HomerNetworkFoundation",
            targets: ["HomerNetworkFoundation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/akkanferhan/HomerFoundation.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "HomerNetwork",
            path: "Sources/HomerNetwork"
        ),
        .target(
            name: "HomerNetworkFoundation",
            dependencies: [
                "HomerNetwork",
                .product(name: "HomerFoundation", package: "HomerFoundation")
            ],
            path: "Sources/HomerNetworkFoundation"
        )
    ],
    swiftLanguageModes: [.v6]
)
