// swift-tools-version: 6.4
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
        .package(path: "../OpenFoundation")
    ],
    targets: [
        .target(
            name: "SIMDSupport",
            dependencies: [
                .product(name: "OpenFoundation", package: "OpenFoundation")
            ]
        ),
        .target(
            name: "OpenSpriteKit",
            dependencies: [
                "SIMDSupport",
                "OpenCoreGraphics",
                "OpenCoreImage",
                "OpenCoreAnimation",
                "OpenImageIO",
                .product(name: "OpenFoundation", package: "OpenFoundation"),
            ]
        ),
        .testTarget(
            name: "OpenSpriteKitTests",
            dependencies: ["OpenSpriteKit"]
        ),
    ]
)
