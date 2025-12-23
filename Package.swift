// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenSpriteKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "OpenSpriteKit",
            targets: ["OpenSpriteKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/OpenCoreGraphics.git", branch: "main"),
        .package(url: "https://github.com/1amageek/OpenCoreImage.git", branch: "main"),
        .package(path: "../OpenCoreAnimation"),
        .package(url: "https://github.com/1amageek/OpenImageIO.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SIMDSupport",
            dependencies: []
        ),
        .target(
            name: "OpenSpriteKit",
            dependencies: [
                "SIMDSupport",
                "OpenCoreGraphics",
                "OpenCoreImage",
                "OpenCoreAnimation",
                "OpenImageIO",
            ]
        ),
        .testTarget(
            name: "OpenSpriteKitTests",
            dependencies: ["OpenSpriteKit"]
        ),
    ]
)
