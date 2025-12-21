// SKWebGPUSceneRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if arch(wasm32)

import OpenCoreAnimation
import JavaScriptKit

/// WebGPU-based scene renderer for WASM environments.
///
/// This class implements `SKSceneRendererDelegate` using `CAWebGPURenderer` from
/// OpenCoreAnimation to render SpriteKit scene layer trees to a WebGPU canvas.
///
/// ## Usage
///
/// ```swift
/// let canvas = document.getElementById("gameCanvas")
/// let renderer = SKWebGPUSceneRenderer(canvas: canvas)
/// try await renderer.initialize()
///
/// // In render loop:
/// renderer.render(layer: scene.layer)
/// ```
///
internal final class SKWebGPUSceneRenderer: SKSceneRendererDelegate, @unchecked Sendable {

    // MARK: - Properties

    /// The underlying WebGPU renderer from OpenCoreAnimation.
    private var webGPURenderer: CAWebGPURenderer?

    /// The JavaScript canvas element to render to.
    private let canvas: JSObject

    // MARK: - Initialization

    /// Creates a new WebGPU scene renderer.
    ///
    /// - Parameter canvas: The JavaScript canvas element to render to.
    init(canvas: JSObject) {
        self.canvas = canvas
    }

    // MARK: - SKSceneRendererDelegate

    func initialize() async throws {
        let renderer = CAWebGPURenderer(canvas: canvas)
        try await renderer.initialize()
        self.webGPURenderer = renderer
    }

    func render(layer: CALayer) {
        webGPURenderer?.render(layer: layer)
    }

    func resize(width: Int, height: Int) {
        webGPURenderer?.resize(width: width, height: height)
    }

    func invalidate() {
        webGPURenderer?.invalidate()
        webGPURenderer = nil
    }
}

#endif
