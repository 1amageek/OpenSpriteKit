// SKViewRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

// We always need OpenCoreAnimation for CADisplayLinkDelegate and rendering
import OpenCoreAnimation

#if canImport(QuartzCore)
import QuartzCore
#endif

#if arch(wasm32)
import JavaScriptKit
#endif

// Type alias to disambiguate from QuartzCore.CADisplayLink
internal typealias OCADisplayLink = OpenCoreAnimation.CADisplayLink

/// Manages the render loop and frame cycle for SKView.
///
/// This class integrates with OpenCoreAnimation's rendering infrastructure to:
/// - Run the SpriteKit frame cycle (update, actions, physics, etc.)
/// - Coordinate with CADisplayLink for frame timing
/// - Render the scene's layer tree via CAWebGPURenderer (on WASM)
internal final class SKViewRenderer: OpenCoreAnimation.CADisplayLinkDelegate {

    // MARK: - Properties

    private var displayLink: OCADisplayLink?
    private weak var view: SKView?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning: Bool = false

    #if arch(wasm32)
    private var renderer: CAWebGPURenderer?
    #endif

    // MARK: - Initialization

    init() {}

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    #if arch(wasm32)
    /// Initializes the renderer and starts the render loop (WASM version).
    ///
    /// - Parameters:
    ///   - canvas: The JavaScript canvas element to render to.
    ///   - view: The SKView to render.
    func start(canvas: JSObject, view: SKView) async throws {
        self.view = view

        // Initialize WebGPU renderer
        let webGPURenderer = CAWebGPURenderer(canvas: canvas)
        try await webGPURenderer.initialize()
        self.renderer = webGPURenderer

        // Create and start display link
        startDisplayLink()
    }
    #endif

    /// Starts the render loop (native/test version).
    ///
    /// - Parameter view: The SKView to render.
    func start(view: SKView) {
        self.view = view
        startDisplayLink()
    }

    /// Stops the render loop and releases resources.
    func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil

        #if arch(wasm32)
        renderer?.invalidate()
        renderer = nil
        #endif
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        guard !isRunning else { return }
        isRunning = true
        lastUpdateTime = 0

        // Create display link with self as delegate
        // OpenCoreAnimation.CADisplayLink uses CADisplayLinkDelegate protocol;
        // the selector parameter is stored but not used (ignored on both platforms)
        displayLink = OCADisplayLink(target: self, selector: Selector(("displayLinkDidFire:")))
        displayLink?.preferredFramesPerSecond = view?.preferredFramesPerSecond ?? 60
        // The runloop and mode parameters are ignored on both native (Timer-based) and WASM platforms
        displayLink?.add(to: self as AnyObject, forMode: self as AnyObject)
    }

    // MARK: - CADisplayLinkDelegate

    /// Called by CADisplayLink on each frame.
    public func displayLinkDidFire(_ displayLink: OCADisplayLink) {
        guard isRunning else { return }
        guard let view = view else { return }

        // Check pause state
        if view.isPaused { return }

        guard let scene = view.scene else { return }

        let currentTime = displayLink.timestamp
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        // Execute the frame cycle
        executeFrameCycle(scene: scene, currentTime: currentTime, deltaTime: deltaTime)

        // Render the scene
        renderScene(scene)
    }

    // MARK: - Frame Cycle

    /// Executes the SpriteKit frame cycle in the correct order.
    ///
    /// The order is:
    /// 1. `update(_:)` - App-specific per-frame logic
    /// 2. Action evaluation - Process SKActions
    /// 3. `didEvaluateActions()` - Post-action callback
    /// 4. Physics simulation - Run physics
    /// 5. `didSimulatePhysics()` - Post-physics callback
    /// 6. Constraint evaluation - Apply constraints
    /// 7. `didApplyConstraints()` - Post-constraint callback
    /// 8. `didFinishUpdate()` - Final frame callback
    private func executeFrameCycle(scene: SKScene, currentTime: TimeInterval, deltaTime: TimeInterval) {
        // 1. User update
        scene.update(currentTime)

        // 2. Evaluate actions (Phase 2で実装)
        evaluateActions(for: scene, deltaTime: deltaTime)

        // 3. Post-actions callback
        scene.didEvaluateActions()

        // 4. Physics simulation (Phase 4で実装)
        simulatePhysics(for: scene, deltaTime: deltaTime)

        // 5. Post-physics callback
        scene.didSimulatePhysics()

        // 6. Apply constraints (後で実装)
        applyConstraints(for: scene)

        // 7. Post-constraints callback
        scene.didApplyConstraints()

        // 8. Final callback
        scene.didFinishUpdate()
    }

    // MARK: - Action Evaluation

    private func evaluateActions(for scene: SKScene, deltaTime: TimeInterval) {
        SKActionRunner.shared.update(scene: scene, deltaTime: deltaTime)
    }

    // MARK: - Physics Simulation

    private func simulatePhysics(for scene: SKScene, deltaTime: TimeInterval) {
        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: deltaTime)
    }

    // MARK: - Constraint Application

    private func applyConstraints(for scene: SKScene) {
        // TODO: 制約適用の実装
        // applyConstraintsRecursively(node: scene)
    }

    // MARK: - Rendering

    private func renderScene(_ scene: SKScene) {
        #if arch(wasm32)
        // Render the scene's layer tree via WebGPU
        renderer?.render(layer: scene.layer)
        #else
        // On native platforms, CALayer handles rendering automatically
        // through the view system, so we just need to mark for redisplay if needed
        scene.layer.setNeedsDisplay()
        #endif
    }

    // MARK: - Resize

    /// Updates the renderer size when the view is resized.
    ///
    /// - Parameters:
    ///   - width: The new width in pixels.
    ///   - height: The new height in pixels.
    func resize(width: Int, height: Int) {
        #if arch(wasm32)
        renderer?.resize(width: width, height: height)
        #endif
    }
}
