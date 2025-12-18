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
@MainActor
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
        // Directly clean up resources without calling MainActor-isolated methods
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
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
    nonisolated public func displayLinkDidFire(_ displayLink: OCADisplayLink) {
        MainActor.assumeIsolated {
            guard isRunning else { return }
            guard let view = view else { return }

            // Check pause state
            if view.isPaused { return }

            let currentTime = displayLink.timestamp
            let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
            lastUpdateTime = currentTime

            // Update transition if one is in progress
            let isTransitioning = SKTransitionManager.shared.update(currentTime: currentTime)

            guard let scene = view.scene else { return }

            // Execute the frame cycle (scene may be different during transition)
            executeFrameCycle(scene: scene, currentTime: currentTime, deltaTime: deltaTime)

            // Render the scene (and transition if in progress)
            if isTransitioning {
                // During transition, render both scenes
                renderTransition(currentTime: currentTime)
            } else {
                renderScene(scene)
            }
        }
    }

    /// Renders both scenes during a transition.
    private func renderTransition(currentTime: TimeInterval) {
        #if arch(wasm32)
        // For WASM, the transition rendering needs to composite both scenes
        // This is handled by the SKTransitionManager modifying scene alpha/position
        // The actual rendering is done through the layer system
        if let transitionFromScene = SKTransitionManager.shared.fromScene {
            renderer?.render(layer: transitionFromScene.layer)
        }
        if let transitionToScene = SKTransitionManager.shared.toScene {
            renderer?.render(layer: transitionToScene.layer)
        }
        #else
        // On native platforms, CALayer handles compositing automatically
        if let transitionFromScene = SKTransitionManager.shared.fromScene {
            transitionFromScene.layer.setNeedsDisplay()
        }
        if let transitionToScene = SKTransitionManager.shared.toScene {
            transitionToScene.layer.setNeedsDisplay()
        }
        #endif
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
    /// 6. Particle system update - Update emitter particles
    /// 7. Constraint evaluation - Apply constraints
    /// 8. `didApplyConstraints()` - Post-constraint callback
    /// 9. `didFinishUpdate()` - Final frame callback
    private func executeFrameCycle(scene: SKScene, currentTime: TimeInterval, deltaTime: TimeInterval) {
        // 1. User update
        scene.update(currentTime)

        // 2. Evaluate actions
        evaluateActions(for: scene, deltaTime: deltaTime)

        // 3. Post-actions callback
        scene.didEvaluateActions()

        // 4. Physics simulation
        simulatePhysics(for: scene, deltaTime: deltaTime)

        // 5. Post-physics callback
        scene.didSimulatePhysics()

        // 6. Update particle systems
        updateParticleSystems(for: scene, deltaTime: deltaTime)

        // 7. Apply constraints
        applyConstraints(for: scene)

        // 8. Post-constraints callback
        scene.didApplyConstraints()

        // 9. Final callback
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

    // MARK: - Particle System Update

    private func updateParticleSystems(for scene: SKScene, deltaTime: TimeInterval) {
        updateEmittersRecursively(node: scene, deltaTime: deltaTime)
    }

    private func updateEmittersRecursively(node: SKNode, deltaTime: TimeInterval) {
        if let emitter = node as? SKEmitterNode {
            emitter.updateParticles(deltaTime: deltaTime)
        }
        for child in node.children {
            updateEmittersRecursively(node: child, deltaTime: deltaTime)
        }
    }

    // MARK: - Constraint Application

    private func applyConstraints(for scene: SKScene) {
        SKConstraintSolver.shared.applyConstraints(for: scene)
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
