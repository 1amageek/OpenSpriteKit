// SKSceneRendererDelegate.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License


/// Protocol for rendering backends that execute scene rendering operations.
///
/// This protocol enables pluggable rendering backends (such as WebGPU for WASM)
/// to receive rendering commands from SKRenderer/SKViewRenderer.
///
/// The delegate is:
/// - **Internal** (not exposed to users)
/// - **Non-optional** (not `weak` or `Optional`)
/// - **Switched at initialization time** based on architecture
///
/// This follows the same pattern as `CGContextRendererDelegate` in OpenCoreGraphics.
///
/// ## Implementation Notes
///
/// - On WASM: `SKWebGPUSceneRenderer` provides the WebGPU implementation
/// - For testing: `SKNullSceneRenderer` provides a no-op implementation
///
internal protocol SKSceneRendererDelegate: AnyObject, Sendable {

    // MARK: - Initialization

    /// Initializes the renderer asynchronously.
    ///
    /// This method sets up GPU resources, creates pipelines, and prepares
    /// the rendering context. It must be called before any rendering operations.
    ///
    /// - Throws: An error if initialization fails (e.g., WebGPU not available).
    func initialize() async throws

    // MARK: - Rendering

    /// Renders a layer tree to the output target.
    ///
    /// This method traverses the layer hierarchy and renders all visible layers
    /// to the GPU texture or canvas.
    ///
    /// - Parameter layer: The root layer to render.
    func render(layer: CALayer)

    // MARK: - Resize

    /// Updates the renderer size when the output target is resized.
    ///
    /// This method should recreate any size-dependent GPU resources such as
    /// depth buffers, render textures, etc.
    ///
    /// - Parameters:
    ///   - width: The new width in pixels.
    ///   - height: The new height in pixels.
    func resize(width: Int, height: Int)

    // MARK: - Cleanup

    /// Releases all resources held by the renderer.
    ///
    /// After calling this method, the renderer should not be used for
    /// any further rendering operations.
    func invalidate()
}

// MARK: - Default Implementations

extension SKSceneRendererDelegate {

    /// Default implementation does nothing.
    func initialize() async throws {}

    /// Default implementation does nothing.
    func render(layer: CALayer) {}

    /// Default implementation does nothing.
    func resize(width: Int, height: Int) {}

    /// Default implementation does nothing.
    func invalidate() {}
}
