// SKView.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics
import OpenCoreImage

#if arch(wasm32)
import JavaScriptKit
#endif

/// Base class for SKView
open class SKViewBase {
    public init() {
    }
}

/// A view that displays SpriteKit content.
///
/// An `SKView` object renders a SpriteKit scene. You add the view to a window and then
/// tell it which scene to present.
@MainActor
open class SKView: SKViewBase {

    // MARK: - Properties

    /// The scene currently presented in this view.
    open private(set) var scene: SKScene?

    /// The internal renderer that manages the render loop.
    private var viewRenderer: SKViewRenderer?

    /// A Boolean value that indicates whether the view pauses the scene when the app becomes inactive.
    open var pauseWhenInactive: Bool = true

    /// A Boolean value that indicates whether the view should pause the scene.
    open var isPaused: Bool = false

    /// A Boolean value that indicates whether the view should show diagnostic information.
    open var showsFPS: Bool = false

    /// A Boolean value that indicates whether the view should show the node count.
    open var showsNodeCount: Bool = false

    /// A Boolean value that indicates whether the view should show draw count.
    open var showsDrawCount: Bool = false

    /// A Boolean value that indicates whether the view should show quad count.
    open var showsQuadCount: Bool = false

    /// A Boolean value that indicates whether the view should show physics bodies.
    open var showsPhysics: Bool = false

    /// A Boolean value that indicates whether the view should show fields.
    open var showsFields: Bool = false

    /// A Boolean value that determines whether content is rendered asynchronously.
    open var allowsTransparency: Bool = false

    /// A Boolean value that indicates whether the view renders its content asynchronously.
    open var isAsynchronous: Bool = true

    /// A Boolean value that determines whether the view ignores sibling order for rendering.
    open var ignoresSiblingOrder: Bool = false

    /// A Boolean value that determines whether Core Animation features can be used.
    open var shouldCullNonVisibleNodes: Bool = true

    /// The preferred frame rate of the view.
    open var preferredFramesPerSecond: Int = 60

    /// The delegate for this view.
    open weak var delegate: SKViewDelegate?

    /// The size of the view for scene calculations.
    open nonisolated(unsafe) var viewSize: CGSize = .zero

    /// Sets the view size.
    open func setViewSize(_ size: CGSize) {
        viewSize = size
    }

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - Scene Presentation

    /// Presents a scene in the view.
    ///
    /// - Parameter scene: The scene to present.
    open func presentScene(_ scene: SKScene?) {
        if let oldScene = self.scene {
            oldScene.willMove(from: self)
            // Reset physics state for the old scene
            SKPhysicsEngine.shared.reset(for: oldScene)
        }

        self.scene = scene
        scene?._view = self

        // Reset physics state for the new scene
        if let newScene = scene {
            SKPhysicsEngine.shared.reset(for: newScene)

            // Call sceneDidLoad() once when the scene is first presented
            if !newScene._didCallSceneDidLoad {
                newScene._didCallSceneDidLoad = true
                newScene.sceneDidLoad()
            }
        }

        scene?.didMove(to: self)
    }

    /// Sets the scene internally (for transitions).
    internal func _setScene(_ scene: SKScene?) {
        self.scene = scene
    }

    /// Presents a scene in the view with a transition animation.
    ///
    /// - Parameters:
    ///   - scene: The scene to present.
    ///   - transition: The transition to use when presenting the scene.
    open func presentScene(_ scene: SKScene, transition: SKTransition) {
        guard let oldScene = self.scene else {
            // No existing scene, just present the new one
            presentScene(scene)
            return
        }

        // Start the transition
        SKTransitionManager.shared.performTransition(
            transition,
            from: oldScene,
            to: scene,
            in: self
        )
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// View coordinates have origin at top-left, Y increasing downward.
    /// Scene coordinates have origin at bottom-left, Y increasing upward.
    ///
    /// - Parameters:
    ///   - point: A point in view coordinates.
    ///   - scene: The scene to convert to.
    /// - Returns: The point converted to scene coordinates.
    open func convert(_ point: CGPoint, to scene: SKScene) -> CGPoint {
        let viewSize = self.viewSize
        let sceneSize = scene.size

        // Handle scale mode
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0

        switch scene.scaleMode {
        case .fill:
            scaleX = sceneSize.width / viewSize.width
            scaleY = sceneSize.height / viewSize.height

        case .aspectFill:
            let scale = max(sceneSize.width / viewSize.width, sceneSize.height / viewSize.height)
            scaleX = scale
            scaleY = scale
            offsetX = (viewSize.width * scale - sceneSize.width) / 2
            offsetY = (viewSize.height * scale - sceneSize.height) / 2

        case .aspectFit:
            let scale = min(sceneSize.width / viewSize.width, sceneSize.height / viewSize.height)
            scaleX = scale
            scaleY = scale
            offsetX = (viewSize.width * scale - sceneSize.width) / 2
            offsetY = (viewSize.height * scale - sceneSize.height) / 2

        case .resizeFill:
            scaleX = 1.0
            scaleY = 1.0
        }

        // Convert from view coordinates (origin top-left, Y down) to scene coordinates (origin bottom-left, Y up)
        var scenePoint = CGPoint(
            x: point.x * scaleX - offsetX,
            y: (viewSize.height - point.y) * scaleY - offsetY
        )

        // Apply anchor point offset
        scenePoint.x += sceneSize.width * scene.anchorPoint.x
        scenePoint.y += sceneSize.height * scene.anchorPoint.y

        // Apply camera transform if present
        if let camera = scene.camera {
            // Camera position offsets the view
            scenePoint.x += camera.position.x - sceneSize.width / 2
            scenePoint.y += camera.position.y - sceneSize.height / 2

            // Camera scale
            let cameraScale = CGPoint(x: camera.xScale, y: camera.yScale)
            if cameraScale.x != 0 && cameraScale.y != 0 {
                scenePoint.x = (scenePoint.x - camera.position.x) / cameraScale.x + camera.position.x
                scenePoint.y = (scenePoint.y - camera.position.y) / cameraScale.y + camera.position.y
            }

            // Camera rotation
            if camera.zRotation != 0 {
                let cos = Foundation.cos(Double(-camera.zRotation))
                let sin = Foundation.sin(Double(-camera.zRotation))
                let dx = scenePoint.x - camera.position.x
                let dy = scenePoint.y - camera.position.y
                scenePoint.x = CGFloat(Double(dx) * cos - Double(dy) * sin) + camera.position.x
                scenePoint.y = CGFloat(Double(dx) * sin + Double(dy) * cos) + camera.position.y
            }
        }

        return scenePoint
    }

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// Scene coordinates have origin at bottom-left, Y increasing upward.
    /// View coordinates have origin at top-left, Y increasing downward.
    ///
    /// - Parameters:
    ///   - point: A point in scene coordinates.
    ///   - scene: The scene to convert from.
    /// - Returns: The point converted to view coordinates.
    open func convert(_ point: CGPoint, from scene: SKScene) -> CGPoint {
        let viewSize = self.viewSize
        let sceneSize = scene.size

        var scenePoint = point

        // Apply camera transform if present (inverse of convert to scene)
        if let camera = scene.camera {
            // Camera rotation (inverse)
            if camera.zRotation != 0 {
                let cos = Foundation.cos(Double(camera.zRotation))
                let sin = Foundation.sin(Double(camera.zRotation))
                let dx = scenePoint.x - camera.position.x
                let dy = scenePoint.y - camera.position.y
                scenePoint.x = CGFloat(Double(dx) * cos - Double(dy) * sin) + camera.position.x
                scenePoint.y = CGFloat(Double(dx) * sin + Double(dy) * cos) + camera.position.y
            }

            // Camera scale (inverse)
            let cameraScale = CGPoint(x: camera.xScale, y: camera.yScale)
            scenePoint.x = (scenePoint.x - camera.position.x) * cameraScale.x + camera.position.x
            scenePoint.y = (scenePoint.y - camera.position.y) * cameraScale.y + camera.position.y

            // Camera position offset (inverse)
            scenePoint.x -= camera.position.x - sceneSize.width / 2
            scenePoint.y -= camera.position.y - sceneSize.height / 2
        }

        // Remove anchor point offset
        scenePoint.x -= sceneSize.width * scene.anchorPoint.x
        scenePoint.y -= sceneSize.height * scene.anchorPoint.y

        // Handle scale mode
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0

        switch scene.scaleMode {
        case .fill:
            scaleX = sceneSize.width / viewSize.width
            scaleY = sceneSize.height / viewSize.height

        case .aspectFill:
            let scale = max(sceneSize.width / viewSize.width, sceneSize.height / viewSize.height)
            scaleX = scale
            scaleY = scale
            offsetX = (viewSize.width * scale - sceneSize.width) / 2
            offsetY = (viewSize.height * scale - sceneSize.height) / 2

        case .aspectFit:
            let scale = min(sceneSize.width / viewSize.width, sceneSize.height / viewSize.height)
            scaleX = scale
            scaleY = scale
            offsetX = (viewSize.width * scale - sceneSize.width) / 2
            offsetY = (viewSize.height * scale - sceneSize.height) / 2

        case .resizeFill:
            scaleX = 1.0
            scaleY = 1.0
        }

        // Convert from scene coordinates to view coordinates
        let viewPoint = CGPoint(
            x: (scenePoint.x + offsetX) / scaleX,
            y: viewSize.height - (scenePoint.y + offsetY) / scaleY
        )

        return viewPoint
    }

    // MARK: - Texture Generation

    /// Renders a portion of a node's contents to a texture.
    ///
    /// - Parameters:
    ///   - node: The node whose content is rendered.
    ///   - crop: The rectangle in the node's coordinate space to render.
    /// - Returns: A texture containing the rendered content.
    open func texture(from node: SKNode, crop: CGRect) -> SKTexture? {
        let width = Int(crop.width)
        let height = Int(crop.height)

        guard width > 0 && height > 0 else { return nil }

        // Create a bitmap context for rendering
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = Data(count: bytesPerRow * height)

        guard let colorSpace = .deviceRGB as CGColorSpace?,
              let context = pixelData.withUnsafeMutableBytes({ buffer -> CGContext? in
                  CGContext(
                      data: buffer.baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
                  )
              }) else {
            return nil
        }

        // Set up the context
        context.translateBy(x: -crop.origin.x, y: -crop.origin.y)

        // Render the node hierarchy to the context
        renderNode(node, to: context)

        // Create CGImage from the rendered data
        guard let cgImage = context.makeImage() else {
            return nil
        }

        return SKTexture(cgImage: cgImage)
    }

    /// Renders a node's contents to a texture.
    ///
    /// - Parameter node: The node whose content is rendered.
    /// - Returns: A texture containing the rendered content.
    open func texture(from node: SKNode) -> SKTexture? {
        // Calculate the node's accumulated frame
        let frame = node.calculateAccumulatedFrame()
        guard !frame.isEmpty else { return nil }
        return texture(from: node, crop: frame)
    }

    /// Renders a node and its children to a Core Graphics context.
    private func renderNode(_ node: SKNode, to context: CGContext) {
        guard !node.isHidden && node.alpha > 0 else { return }

        context.saveGState()

        // Apply node's transform
        context.translateBy(x: node.position.x, y: node.position.y)
        context.rotate(by: node.zRotation)
        context.scaleBy(x: node.xScale, y: node.yScale)
        context.setAlpha(node.alpha)

        // Render based on node type
        if let sprite = node as? SKSpriteNode {
            renderSpriteNode(sprite, to: context)
        } else if let shape = node as? SKShapeNode {
            renderShapeNode(shape, to: context)
        } else if let label = node as? SKLabelNode {
            renderLabelNode(label, to: context)
        }

        // Render children (sorted by zPosition)
        let sortedChildren = node.children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            renderNode(child, to: context)
        }

        context.restoreGState()
    }

    /// Renders a sprite node to a Core Graphics context.
    private func renderSpriteNode(_ sprite: SKSpriteNode, to context: CGContext) {
        guard let cgImage = sprite.texture?.cgImage else { return }

        let size = sprite.size
        let anchorPoint = sprite.anchorPoint

        // Calculate the drawing rect based on anchor point
        let rect = CGRect(
            x: -size.width * anchorPoint.x,
            y: -size.height * anchorPoint.y,
            width: size.width,
            height: size.height
        )

        // Draw the image
        context.draw(cgImage, in: rect)
    }

    /// Renders a shape node to a Core Graphics context.
    private func renderShapeNode(_ shape: SKShapeNode, to context: CGContext) {
        guard let path = shape.path else { return }

        context.addPath(path)

        // Fill
        if shape.fillColor != .clear {
            context.setFillColor(shape.fillColor.cgColor)
            context.fillPath()
            context.addPath(path)  // Re-add path for stroke
        }

        // Stroke
        if shape.strokeColor != .clear && shape.lineWidth > 0 {
            context.setStrokeColor(shape.strokeColor.cgColor)
            context.setLineWidth(shape.lineWidth)
            context.strokePath()
        }
    }

    /// Renders a label node to a Core Graphics context.
    private func renderLabelNode(_ label: SKLabelNode, to context: CGContext) {
        // For WASM, text rendering is done via the WebGPU renderer
        // This is a simple placeholder for software rendering
        guard let text = label.text, !text.isEmpty else { return }

        // Set text color
        context.setFillColor(label.fontColor?.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1))

        // Note: Text positioning and actual rendering is handled by WebGPU renderer
    }

    // MARK: - Render Loop Control

    /// Starts the render loop for the current scene.
    ///
    /// This method is called automatically when a scene is presented.
    /// On WASM, use `attachToCanvas(_:)` instead.
    internal func startRenderLoop() {
        guard viewRenderer == nil else { return }
        let renderer = SKViewRenderer()
        renderer.start(view: self)
        viewRenderer = renderer
    }

    /// Stops the render loop.
    internal func stopRenderLoop() {
        viewRenderer?.stop()
        viewRenderer = nil
    }
}

// MARK: - Canvas Integration

#if arch(wasm32)
extension SKView {
    /// Attaches the view to a canvas element and starts rendering.
    ///
    /// This method initializes the WebGPU renderer and begins the animation loop.
    /// Call this method after presenting a scene.
    ///
    /// - Parameter canvas: The JavaScript canvas element to render to.
    /// - Throws: An error if WebGPU initialization fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let view = SKView()
    /// let scene = SKScene(size: CGSize(width: 800, height: 600))
    /// view.presentScene(scene)
    ///
    /// let canvas = JSObject.global.document.getElementById("game-canvas")
    /// try await view.attachToCanvas(canvas.object!)
    /// ```
    public func attachToCanvas(_ canvas: JSObject) async throws {
        // Stop any existing render loop
        stopRenderLoop()

        // Create new renderer with canvas
        let renderer = SKViewRenderer()
        try await renderer.start(canvas: canvas, view: self)
        viewRenderer = renderer
    }

    /// Detaches the view from the canvas and stops rendering.
    public func detachFromCanvas() {
        stopRenderLoop()
    }

    /// Updates the renderer when the canvas is resized.
    ///
    /// - Parameters:
    ///   - width: The new width in pixels.
    ///   - height: The new height in pixels.
    public func canvasDidResize(width: Int, height: Int) {
        viewRenderer?.resize(width: width, height: height)
        setViewSize(CGSize(width: CGFloat(width), height: CGFloat(height)))
    }
}
#endif

// MARK: - SKViewDelegate

/// Methods that allow you to participate in the scene rendering process.
public protocol SKViewDelegate: AnyObject {

    /// Asks the delegate whether the scene should render.
    ///
    /// - Parameters:
    ///   - view: The view asking the question.
    ///   - time: The current time.
    /// - Returns: `true` if the scene should render; otherwise, `false`.
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool
}

// MARK: - Default Implementations

public extension SKViewDelegate {
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool {
        return true
    }
}


