// swift-tools-version: 6.0
//
// OpenSpriteKit WASM smoke-test executable. Mirrors OpenCoreAnimation/SmokeTest
// so Playwright can exercise the full SKScene → SKActionRunner →
// CAWebGPURenderer pipeline in headless Chromium.
//
// Builds with:
//   swift build --product OSKSmoke --swift-sdk swift-6.3.1-RELEASE_wasm -c release
// then copy .build/wasm32-unknown-wasip1/release/OSKSmoke.wasm into
// Examples/SmokeTest/web/ where server.mjs serves it.
//
// Local-path overrides pull in sibling CoreFoundation WIP so that a fix in
// e.g. OpenCoreAnimation is picked up without publishing a branch.

import PackageDescription

let package = Package(
    name: "OSKSmoke",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../OpenCoreGraphics"),
        .package(path: "../../../OpenCoreAnimation"),
        .package(path: "../../../OpenCoreImage"),
        .package(path: "../../../OpenImageIO"),
        .package(url: "https://github.com/1amageek/swift-wasm-testing", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "OSKSmoke",
            dependencies: [
                .product(name: "OpenSpriteKit", package: "OpenSpriteKit"),
                .product(name: "WasmTesting", package: "swift-wasm-testing"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xclang-linker", "-mexec-model=reactor",
                    "-Xlinker", "--export=setup",
                ])
            ]
        ),
    ]
)
