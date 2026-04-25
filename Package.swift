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
    dependencies: [
        .package(url: "https://github.com/akkanferhan/HomerFoundation.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "HomerNetwork",
            dependencies: [
                .product(name: "HomerFoundation", package: "HomerFoundation")
            ],
            path: "Sources/HomerNetwork"
        ),
        .testTarget(
            name: "HomerNetworkTests",
            dependencies: ["HomerNetwork"],
            path: "Tests/HomerNetworkTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
