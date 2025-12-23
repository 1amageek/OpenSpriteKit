// SKNullSceneRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License


/// A no-op scene renderer for testing and non-WASM builds.
///
/// This class provides an empty implementation of `SKSceneRendererDelegate`
/// that performs no actual rendering. It is used:
///
/// - During unit tests to avoid GPU dependencies
/// - On non-WASM platforms where no rendering is needed
/// - As a fallback when no canvas is provided
///
/// ## Usage
///
/// ```swift
/// let renderer = SKNullSceneRenderer()
/// // All methods are no-ops
/// renderer.render(layer: scene.layer)
/// ```
///
internal final class SKNullSceneRenderer: SKSceneRendererDelegate, @unchecked Sendable {

    // MARK: - Initialization

    /// Creates a new null scene renderer.
    init() {}

    // MARK: - SKSceneRendererDelegate

    func initialize() async throws {
        // No-op
    }

    func render(layer: CALayer) {
        // No-op
    }

    func resize(width: Int, height: Int) {
        // No-op
    }

    func invalidate() {
        // No-op
    }
}
