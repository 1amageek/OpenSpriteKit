// SKViewRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenCoreAnimation

#if arch(wasm32)
import JavaScriptKit
#endif

/// Manages the render loop and frame cycle for SKView.
///
/// This class integrates with OpenCoreAnimation's rendering infrastructure to:
/// - Run the SpriteKit frame cycle (update, actions, physics, etc.)
/// - Coordinate with CADisplayLink for frame timing
/// - Render the scene's layer tree via the scene renderer delegate
@MainActor
internal final class SKViewRenderer: CADisplayLinkDelegate {

    // MARK: - Properties

    private var displayLink: CADisplayLink?
    private weak var view: SKView?
    private var lastUpdateTime: TimeInterval = 0
    private var isRunning: Bool = false

    /// The internal scene renderer delegate.
    /// Starts with null renderer and is replaced with the appropriate implementation in start().
    private var rendererDelegate: SKSceneRendererDelegate

    // MARK: - Initialization

    init() {
        self.rendererDelegate = SKNullSceneRenderer()
    }

    deinit {
        // Directly clean up resources without calling MainActor-isolated methods
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Lifecycle

    #if arch(wasm32)
    /// Initializes the renderer and starts the render loop.
    ///
    /// - Parameters:
    ///   - canvas: The JavaScript canvas element to render to.
    ///   - view: The SKView to render.
    func start(canvas: JSObject, view: SKView) async throws {
        self.view = view

        // Initialize WebGPU scene renderer delegate
        let webGPURenderer = SKWebGPUSceneRenderer(canvas: canvas)
        try await webGPURenderer.initialize()
        self.rendererDelegate = webGPURenderer

        // Create and start display link
        startDisplayLink()
    }
    #endif

    /// Starts the render loop (for testing/native builds).
    func start(view: SKView) {
        self.view = view
        // Keep the null renderer for non-WASM builds
        startDisplayLink()
    }

    /// Stops the render loop and releases resources.
    func stop() {
        isRunning = false
        displayLink?.invalidate()
        displayLink = nil
        rendererDelegate.invalidate()
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        guard !isRunning else { return }
        isRunning = true
        lastUpdateTime = 0

        // Create display link with self as delegate
        displayLink = CADisplayLink(target: self, selector: Selector(("displayLinkDidFire:")))
        displayLink?.preferredFramesPerSecond = view?.preferredFramesPerSecond ?? 60
        displayLink?.add(to: .main, forMode: .default)
    }

    // MARK: - CADisplayLinkDelegate

    /// Called by CADisplayLink on each frame.
    nonisolated public func displayLinkDidFire(_ displayLink: CADisplayLink) {
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
        // Render both scenes during transition via the delegate
        if let transitionFromScene = SKTransitionManager.shared.fromScene {
            rendererDelegate.render(layer: transitionFromScene.layer)
        }
        if let transitionToScene = SKTransitionManager.shared.toScene {
            rendererDelegate.render(layer: transitionToScene.layer)
        }
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

        // 9. Process effect nodes (apply CIFilters)
        processEffectNodes(for: scene)

        // 10. Apply lighting
        applyLighting(for: scene)

        // 11. Final callback
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
        // Update tile map animations
        if let tileMap = node as? SKTileMapNode {
            tileMap.updateAnimatedTiles(deltaTime: deltaTime)
        }
        for child in node.children {
            updateEmittersRecursively(node: child, deltaTime: deltaTime)
        }
    }

    // MARK: - Constraint Application

    private func applyConstraints(for scene: SKScene) {
        SKConstraintSolver.shared.applyConstraints(for: scene)
    }

    // MARK: - Lighting

    private func applyLighting(for scene: SKScene) {
        // Collect all light nodes in the scene
        var lights: [SKLightNode] = []
        collectLightNodes(from: scene, into: &lights)

        // If no lights, reset any lighting adjustments
        guard !lights.isEmpty else {
            resetLighting(for: scene)
            return
        }

        // Apply lighting to lit nodes
        applyLightingRecursively(node: scene, lights: lights)
    }

    private func collectLightNodes(from node: SKNode, into lights: inout [SKLightNode]) {
        if let light = node as? SKLightNode, light.isEnabled {
            lights.append(light)
        }
        for child in node.children {
            collectLightNodes(from: child, into: &lights)
        }
    }

    private func resetLighting(for scene: SKScene) {
        resetLightingRecursively(node: scene)
    }

    private func resetLightingRecursively(node: SKNode) {
        if let sprite = node as? SKSpriteNode, sprite.lightingBitMask != 0 {
            // Reset to default lighting (full brightness, no tint)
            sprite._computedLightingColor = (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            sprite._hasComputedLighting = false
            sprite.layer.opacity = Float(sprite.alpha)
        }
        for child in node.children {
            resetLightingRecursively(node: child)
        }
    }

    private func applyLightingRecursively(node: SKNode, lights: [SKLightNode]) {
        if let sprite = node as? SKSpriteNode, sprite.lightingBitMask != 0 {
            applyLightingToSprite(sprite, lights: lights)
        }
        for child in node.children {
            applyLightingRecursively(node: child, lights: lights)
        }
    }

    private func applyLightingToSprite(_ sprite: SKSpriteNode, lights: [SKLightNode]) {
        // Calculate total light contribution
        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0

        // Get sprite world position
        let spriteWorldPos = sprite.scene?.convert(sprite.position, from: sprite.parent ?? sprite.scene!) ?? sprite.position

        for light in lights {
            // Check if this light affects this sprite
            guard (light.categoryBitMask & sprite.lightingBitMask) != 0 else {
                continue
            }

            // Get light world position
            let lightWorldPos = light.scene?.convert(light.position, from: light.parent ?? light.scene!) ?? light.position

            // Calculate distance
            let dx = spriteWorldPos.x - lightWorldPos.x
            let dy = spriteWorldPos.y - lightWorldPos.y
            let distance = sqrt(dx * dx + dy * dy)

            // Calculate attenuation based on falloff
            let attenuation: CGFloat
            if light.falloff <= 0 {
                attenuation = 1.0  // No falloff
            } else {
                // Inverse distance falloff
                attenuation = 1.0 / pow(max(1.0, distance / 100.0), light.falloff)
            }

            // Add ambient light contribution
            let ambient = light.ambientColor
            totalRed += extractRed(from: ambient)
            totalGreen += extractGreen(from: ambient)
            totalBlue += extractBlue(from: ambient)

            // Add diffuse light contribution with attenuation
            let diffuse = light.lightColor
            totalRed += extractRed(from: diffuse) * attenuation
            totalGreen += extractGreen(from: diffuse) * attenuation
            totalBlue += extractBlue(from: diffuse) * attenuation
        }

        // Clamp values to [0, 1]
        totalRed = min(1.0, max(0.0, totalRed))
        totalGreen = min(1.0, max(0.0, totalGreen))
        totalBlue = min(1.0, max(0.0, totalBlue))

        // Store the computed lighting color for WASM/WebGPU rendering
        sprite._computedLightingColor = (red: totalRed, green: totalGreen, blue: totalBlue, alpha: 1.0)
        sprite._hasComputedLighting = true

        // Apply lighting via layer for both native and WASM platforms
        // Use a combination of opacity for brightness and filters for color
        applyLightingColorToLayer(sprite, red: totalRed, green: totalGreen, blue: totalBlue)
    }

    /// Applies the computed lighting color to the sprite's layer.
    private func applyLightingColorToLayer(_ sprite: SKSpriteNode, red: CGFloat, green: CGFloat, blue: CGFloat) {
        // Calculate overall brightness
        let brightness = (red + green + blue) / 3.0

        // Apply brightness via opacity
        sprite.layer.opacity = Float(sprite.alpha * max(0.1, brightness))

        // Apply color tint via layer filters or compositing
        // The WebGPU renderer will read _computedLightingColor and apply it in the shader
        if red != 1.0 || green != 1.0 || blue != 1.0 {
            applyColorMultiplyFilter(to: sprite.layer, red: red, green: green, blue: blue)
        } else {
            removeColorMultiplyFilter(from: sprite.layer)
        }
    }

    /// Applies a color multiply filter to the layer for rendering.
    private func applyColorMultiplyFilter(to layer: CALayer, red: CGFloat, green: CGFloat, blue: CGFloat) {
        let existingOverlay = layer.sublayers?.first { $0.name == "_lightingOverlay" }

        if let overlay = existingOverlay {
            overlay.backgroundColor = CGColor(red: red, green: green, blue: blue, alpha: 1.0)
        } else {
            let overlay = CALayer()
            overlay.name = "_lightingOverlay"
            overlay.frame = layer.bounds
            overlay.backgroundColor = CGColor(red: red, green: green, blue: blue, alpha: 1.0)
            layer.insertSublayer(overlay, at: 0)
        }
    }

    /// Removes the color multiply filter from the layer.
    private func removeColorMultiplyFilter(from layer: CALayer) {
        if let overlay = layer.sublayers?.first(where: { $0.name == "_lightingOverlay" }) {
            overlay.removeFromSuperlayer()
        }
    }

    // Helper functions to extract color components
    private func extractRed(from color: SKColor) -> CGFloat {
        return color.red
    }

    private func extractGreen(from color: SKColor) -> CGFloat {
        return color.green
    }

    private func extractBlue(from color: SKColor) -> CGFloat {
        return color.blue
    }

    // MARK: - Effect Node Processing

    private func processEffectNodes(for scene: SKScene) {
        processEffectNodesRecursively(node: scene)
    }

    private func processEffectNodesRecursively(node: SKNode) {
        // Process effect nodes
        if let effectNode = node as? SKEffectNode {
            processEffectNode(effectNode)
        }

        // Recurse to children
        for child in node.children {
            processEffectNodesRecursively(node: child)
        }
    }

    private func processEffectNode(_ effectNode: SKEffectNode) {
        guard effectNode.shouldEnableEffects, effectNode.filter != nil else {
            // No filter to apply, clear any cached image
            effectNode._cachedFilteredImage = nil
            return
        }

        // If rasterized and cache is valid, skip processing
        if effectNode.shouldRasterize && !effectNode._needsFilterUpdate {
            if effectNode._cachedFilteredImage != nil {
                return
            }
        }

        // Calculate the size for rendering
        let frame = effectNode.calculateAccumulatedFrame()
        guard !frame.isEmpty else { return }

        // Render children to an offscreen image
        guard let childImage = effectNode.renderChildrenToImage(size: frame.size) else {
            return
        }

        // Apply the filter
        if let filteredImage = effectNode.applyFilter(to: childImage) {
            // Update the effect node's layer contents with the filtered image
            effectNode.layer.contents = filteredImage
            effectNode.layer.bounds = CGRect(origin: .zero, size: frame.size)
        }
    }

    // MARK: - Rendering

    private func renderScene(_ scene: SKScene) {
        // Apply camera transform if a camera is set
        applyCameraTransform(to: scene)

        // Render the scene's layer tree via the delegate
        rendererDelegate.render(layer: scene.layer)
    }

    /// Applies the camera transform to the scene's layer for rendering.
    ///
    /// When a camera is set, the scene content should be transformed to show
    /// the view from the camera's perspective. Camera children (HUD elements)
    /// are not affected by this transform.
    private func applyCameraTransform(to scene: SKScene) {
        guard let camera = scene.camera else {
            // No camera - reset any previous transform
            scene.layer.transform = CATransform3DIdentity
            return
        }

        guard let view = view else { return }

        // Calculate the center of the view (where the camera should be positioned)
        let viewSize = view.viewSize
        let viewCenterX = viewSize.width / 2
        let viewCenterY = viewSize.height / 2

        // Build the 3D transform for the layer
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, viewCenterX, viewCenterY, 0)
        let scaleX = camera.xScale != 0 ? 1.0 / camera.xScale : 1.0
        let scaleY = camera.yScale != 0 ? 1.0 / camera.yScale : 1.0
        transform = CATransform3DScale(transform, scaleX, scaleY, 1.0)
        if camera.zRotation != 0 {
            transform = CATransform3DRotate(transform, Double(-camera.zRotation), 0, 0, 1)
        }
        transform = CATransform3DTranslate(transform, -camera.position.x, -camera.position.y, 0)
        let anchorOffsetX = scene.anchorPoint.x * scene.size.width
        let anchorOffsetY = scene.anchorPoint.y * scene.size.height
        transform = CATransform3DTranslate(transform, anchorOffsetX, anchorOffsetY, 0)
        transform = CATransform3DTranslate(transform, -viewCenterX, -viewCenterY, 0)

        scene.layer.transform = transform

        // Reset transform for camera's children (HUD elements stay fixed)
        updateCameraChildrenTransform(camera: camera, sceneTransform: transform)
    }

    /// Updates transforms for camera children so they appear fixed on screen (HUD elements).
    private func updateCameraChildrenTransform(camera: SKCameraNode, sceneTransform: CATransform3D) {
        let inverseTransform = CATransform3DInvert(sceneTransform)

        for child in camera.children {
            child.layer.transform = inverseTransform
        }
    }

    // MARK: - Resize

    /// Updates the renderer size when the view is resized.
    ///
    /// - Parameters:
    ///   - width: The new width in pixels.
    ///   - height: The new height in pixels.
    func resize(width: Int, height: Int) {
        rendererDelegate.resize(width: width, height: height)
    }
}
