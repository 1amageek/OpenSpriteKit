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
        .package(path: "../OpenCoreGraphics"),
        .package(path: "../OpenCoreImage"),
        .package(path: "../OpenCoreAnimation"),
        .package(path: "../OpenImageIO"),
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
