// SKNullSceneRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License


/// An explicit unsupported renderer for native test builds.
///
/// Native builds use `renderToCGImage()` for software rendering. This delegate
/// rejects GPU initialization and render attempts instead of treating an absent
/// output target as success.
///
internal final class SKNullSceneRenderer: SKSceneRendererDelegate {

    // MARK: - Initialization

    /// Creates a new null scene renderer.
    init() {}

    // MARK: - SKSceneRendererDelegate

    func initialize() async throws {
        throw SKRendererError.unsupportedPlatform
    }

    func render(layer: CALayer) -> SKRendererError? {
        .unsupportedPlatform
    }

    func resize(width: Int, height: Int) {
        // No-op
    }

    func invalidate() {
        // No-op
    }
}
