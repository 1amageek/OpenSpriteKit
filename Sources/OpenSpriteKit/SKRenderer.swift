// SKRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenImageIO

#if arch(wasm32)
import JavaScriptKit
#endif

/// An object that renders a SpriteKit scene without using a view.
///
/// Use an `SKRenderer` object to render SpriteKit content into a graphics context.
/// This is useful for rendering scenes to offscreen targets or integrating SpriteKit
/// with other rendering systems.
///
/// ## Example
/// ```swift
/// let renderer = SKRenderer()
/// try await renderer.initialize(canvas: canvasElement)
/// renderer.scene = myScene
///
/// // In your render loop:
/// renderer.update(atTime: currentTime)
/// renderer.render()
/// ```
open class SKRenderer: @unchecked Sendable {

    // MARK: - Properties

    /// The scene to render.
    open var scene: SKScene? {
        didSet {
            if let newScene = scene {
                // Call sceneDidLoad() once when the scene is first assigned
                if !newScene._didCallSceneDidLoad {
                    newScene._didCallSceneDidLoad = true
                    newScene.sceneDidLoad()
                }
            }
        }
    }

    /// A Boolean value that indicates whether the renderer ignores sibling order for rendering.
    open var ignoresSiblingOrder: Bool = false

    /// A Boolean value that indicates whether the renderer should cull non-visible nodes.
    open var shouldCullNonVisibleNodes: Bool = true

    /// A Boolean value that indicates whether physics bodies should be rendered.
    open var showsPhysics: Bool = false

    /// A Boolean value that indicates whether field nodes should be rendered.
    open var showsFields: Bool = false

    /// A Boolean value that indicates whether draw count should be shown.
    open var showsDrawCount: Bool = false

    /// A Boolean value that indicates whether node count should be shown.
    open var showsNodeCount: Bool = false

    /// A Boolean value that indicates whether quad count should be shown.
    open var showsQuadCount: Bool = false

    // MARK: - Private Properties

    /// The last update time for delta time calculation.
    private var lastUpdateTime: TimeInterval = 0

    /// The internal scene renderer delegate.
    private let rendererDelegate: SKSceneRendererDelegate

    // MARK: - Initializers

    /// Creates a renderer for the specified device.
    ///
    /// - Parameter device: The GPU device to use for rendering.
    public init(device: Any) {
        self.rendererDelegate = SKNullSceneRenderer()
    }

    /// Creates a new renderer.
    public init() {
        self.rendererDelegate = SKNullSceneRenderer()
    }

    #if arch(wasm32)
    /// Creates a renderer for the specified canvas.
    ///
    /// - Parameter canvas: The JavaScript canvas element to render to.
    public init(canvas: JSObject) {
        self.rendererDelegate = SKWebGPUSceneRenderer(canvas: canvas)
    }
    #endif

    // MARK: - Initialization

    /// Initializes the renderer asynchronously.
    ///
    /// This method sets up GPU resources. Call this before rendering.
    ///
    /// - Throws: An error if initialization fails.
    public func initialize() async throws {
        try await rendererDelegate.initialize()
    }

    #if arch(wasm32)
    /// Initializes the renderer for WebGPU rendering.
    ///
    /// - Parameter canvas: The JavaScript canvas element to render to.
    /// - Throws: An error if WebGPU initialization fails.
    @available(*, deprecated, message: "Use init(canvas:) and initialize() instead")
    public func initialize(canvas: JSObject) async throws {
        // For backward compatibility, create a new renderer
        // Note: This is not ideal but maintains API compatibility
        try await rendererDelegate.initialize()
    }
    #endif

    /// Resizes the renderer to match a new canvas size.
    ///
    /// - Parameters:
    ///   - width: The new width in pixels.
    ///   - height: The new height in pixels.
    public func resize(width: Int, height: Int) {
        rendererDelegate.resize(width: width, height: height)
    }

    // MARK: - Frame Cycle

    /// Updates the scene for the specified time.
    ///
    /// This method executes the full SpriteKit frame cycle:
    /// 1. `update(_:)` - App-specific per-frame logic
    /// 2. Action evaluation - Process SKActions
    /// 3. `didEvaluateActions()` - Post-action callback
    /// 4. Physics simulation - Run physics
    /// 5. `didSimulatePhysics()` - Post-physics callback
    /// 6. Constraint evaluation - Apply constraints
    /// 7. `didApplyConstraints()` - Post-constraint callback
    /// 8. `didFinishUpdate()` - Final frame callback
    ///
    /// - Parameter currentTime: The current time in seconds.
    open func update(atTime currentTime: TimeInterval) {
        guard let scene = scene else { return }

        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        // 1. User update
        scene.update(currentTime)

        // 2. Evaluate actions
        SKActionRunner.shared.update(scene: scene, deltaTime: deltaTime)

        // 3. Post-actions callback
        scene.didEvaluateActions()

        // 4. Physics simulation
        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: deltaTime)

        // 5. Post-physics callback
        scene.didSimulatePhysics()

        // 6. Update particle systems
        updateParticleSystems(for: scene, deltaTime: deltaTime)

        // 7. Apply constraints
        SKConstraintSolver.shared.applyConstraints(for: scene)

        // 8. Post-constraints callback
        scene.didApplyConstraints()

        // 9. Final callback
        scene.didFinishUpdate()
    }

    /// Updates particle systems recursively.
    private func updateParticleSystems(for scene: SKScene, deltaTime: TimeInterval) {
        updateEmittersRecursively(node: scene, deltaTime: deltaTime)
    }

    private func updateEmittersRecursively(node: SKNode, deltaTime: TimeInterval) {
        if let emitter = node as? SKEmitterNode {
            emitter.updateParticles(deltaTime: deltaTime)
        }
        if let tileMap = node as? SKTileMapNode {
            tileMap.updateAnimatedTiles(deltaTime: deltaTime)
        }
        for child in node.children {
            updateEmittersRecursively(node: child, deltaTime: deltaTime)
        }
    }

    // MARK: - Rendering

    /// Renders the scene.
    ///
    /// Call this method after `update(atTime:)` to render the current frame.
    open func render() {
        guard let scene = scene else { return }
        rendererDelegate.render(layer: scene.layer)
    }

    /// Renders the scene into the specified render pass.
    ///
    /// - Parameters:
    ///   - viewport: The viewport rectangle for rendering.
    ///   - renderCommandEncoder: The render command encoder.
    ///   - renderPassDescriptor: The render pass descriptor defining the target.
    ///   - commandQueue: The command queue.
    open func render(withViewport viewport: CGRect, renderCommandEncoder: Any, renderPassDescriptor: Any, commandQueue: Any) {
        guard let scene = scene else { return }
        rendererDelegate.render(layer: scene.layer)
    }

    /// Renders the scene into the specified render pass.
    ///
    /// - Parameters:
    ///   - viewport: The viewport rectangle for rendering.
    ///   - commandBuffer: The command buffer to encode commands into.
    ///   - renderPassDescriptor: The render pass descriptor.
    open func render(withViewport viewport: CGRect, commandBuffer: Any, renderPassDescriptor: Any) {
        guard let scene = scene else { return }
        rendererDelegate.render(layer: scene.layer)
    }

    /// Renders the scene to a CGImage.
    ///
    /// - Returns: A CGImage containing the rendered scene, or nil if rendering fails.
    open func renderToCGImage() -> CGImage? {
        guard let scene = scene else { return nil }

        let width = Int(scene.size.width)
        let height = Int(scene.size.height)
        guard width > 0 && height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let colorSpace = .deviceRGB as CGColorSpace?,
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
              ) else {
            return nil
        }

        // Clear context with scene background color
        let bgColor = scene.backgroundColor.cgColor
        context.setFillColor(bgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Render nodes recursively
        renderNodeToContext(scene, context: context, parentAlpha: 1.0)

        return context.makeImage()
    }

    /// Recursively renders a node and its children to the context.
    private func renderNodeToContext(_ node: SKNode, context: CGContext, parentAlpha: CGFloat) {
        guard !node.isHidden && node.alpha > 0 else { return }

        let effectiveAlpha = parentAlpha * node.alpha

        context.saveGState()

        // Apply node transform
        context.translateBy(x: node.position.x, y: node.position.y)
        context.rotate(by: node.zRotation)
        context.scaleBy(x: node.xScale, y: node.yScale)
        context.setAlpha(effectiveAlpha)

        // Render based on node type
        if let sprite = node as? SKSpriteNode {
            renderSpriteNode(sprite, to: context)
        } else if let shape = node as? SKShapeNode {
            renderShapeNode(shape, to: context)
        } else if let label = node as? SKLabelNode {
            renderLabelNode(label, to: context)
        }

        // Render children sorted by zPosition
        let sortedChildren = node.children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            renderNodeToContext(child, context: context, parentAlpha: effectiveAlpha)
        }

        context.restoreGState()
    }

    /// Renders a sprite node to the context.
    private func renderSpriteNode(_ sprite: SKSpriteNode, to context: CGContext) {
        guard let cgImage = sprite.texture?.cgImage else { return }

        let size = sprite.size
        let anchorPoint = sprite.anchorPoint

        let rect = CGRect(
            x: -size.width * anchorPoint.x,
            y: -size.height * anchorPoint.y,
            width: size.width,
            height: size.height
        )

        // Apply color blending if needed
        if sprite.colorBlendFactor > 0 {
            // Draw with color blend
            context.saveGState()
            context.clip(to: rect)
            context.draw(cgImage, in: rect)
            context.setBlendMode(.multiply)
            context.setFillColor(sprite.color.cgColor)
            context.fill(rect)
            context.restoreGState()
        } else {
            context.draw(cgImage, in: rect)
        }
    }

    /// Renders a shape node to the context.
    private func renderShapeNode(_ shape: SKShapeNode, to context: CGContext) {
        guard let path = shape.path else { return }

        context.addPath(path)

        if shape.fillColor != .clear {
            context.setFillColor(shape.fillColor.cgColor)
            context.fillPath()
            context.addPath(path)
        }

        if shape.strokeColor != .clear && shape.lineWidth > 0 {
            context.setStrokeColor(shape.strokeColor.cgColor)
            context.setLineWidth(shape.lineWidth)
            context.setLineCap(CGLineCap(rawValue: Int32(shape.lineCap.rawValue)) ?? .butt)
            context.setLineJoin(CGLineJoin(rawValue: Int32(shape.lineJoin.rawValue)) ?? .miter)
            context.strokePath()
        }
    }

    /// Renders a label node to the context.
    private func renderLabelNode(_ label: SKLabelNode, to context: CGContext) {
        guard let text = label.text, !text.isEmpty else { return }

        // Simple text rendering - in a full implementation this would use
        // CoreText or similar for proper font rendering
        context.saveGState()

        // Flip for text rendering (CGContext has inverted Y for text)
        context.scaleBy(x: 1, y: -1)

        _ = label.fontSize
        context.setFillColor(label.fontColor?.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1))

        // Note: Text positioning and actual rendering is handled by WebGPU renderer

        context.restoreGState()
    }

    // MARK: - Cleanup

    /// Releases resources held by the renderer.
    open func invalidate() {
        scene = nil
        rendererDelegate.invalidate()
    }
}
