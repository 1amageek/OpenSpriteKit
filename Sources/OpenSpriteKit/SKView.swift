// SKView.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(UIKit)
import UIKit
public typealias SKViewBase = UIView
#elseif canImport(AppKit)
import AppKit
public typealias SKViewBase = NSView
#else
// For WASM or other platforms without UIKit/AppKit
open class SKViewBase: NSObject {}
#endif

/// A view that displays SpriteKit content.
///
/// An `SKView` object renders a SpriteKit scene. You add the view to a window and then
/// tell it which scene to present.
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
    /// This is a cross-platform property that returns the view's size.
    open nonisolated var viewSize: CGSize {
        #if canImport(UIKit) || canImport(AppKit)
        return MainActor.assumeIsolated { bounds.size }
        #else
        return _viewSize
        #endif
    }

    #if !canImport(UIKit) && !canImport(AppKit)
    private var _viewSize: CGSize = .zero

    /// Sets the view size on platforms without UIKit/AppKit.
    open func setViewSize(_ size: CGSize) {
        _viewSize = size
    }
    #endif

    #if canImport(UIKit) || canImport(AppKit)
    // MARK: - Initializers

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // Setup rendering
    }
    #else
    public override init() {
        super.init()
    }
    #endif

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

        guard let colorSpace = CGColorSpaceCreateDeviceRGB() as CGColorSpace?,
              let context = pixelData.withUnsafeMutableBytes({ buffer -> CGContext? in
                  CGContext(
                      data: buffer.baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
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
        // For WASM, text rendering would need a different approach
        // This is a placeholder that works on native platforms
        #if canImport(CoreText)
        guard let text = label.text, !text.isEmpty else { return }

        let font = CTFontCreateWithName(
            (label.fontName ?? "Helvetica") as CFString,
            label.fontSize,
            nil
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: label.fontColor?.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        // Position based on alignment
        var xOffset: CGFloat = 0
        switch label.horizontalAlignmentMode {
        case .center:
            xOffset = -bounds.width / 2
        case .left:
            xOffset = 0
        case .right:
            xOffset = -bounds.width
        }

        var yOffset: CGFloat = 0
        switch label.verticalAlignmentMode {
        case .center:
            yOffset = -bounds.height / 2
        case .top:
            yOffset = -bounds.height
        case .bottom:
            yOffset = 0
        case .baseline:
            yOffset = 0
        }

        context.textPosition = CGPoint(x: xOffset, y: yOffset)
        CTLineDraw(line, context)
        #endif
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

// MARK: - WASM Canvas Integration

#if arch(wasm32)
import JavaScriptKit

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
public protocol SKViewDelegate: NSObjectProtocol {

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

// MARK: - SKTransition

/// An object used to perform an animated transition to a new scene.
///
/// An `SKTransition` object is used to animate a change from one scene to another.
open class SKTransition: NSObject, NSCopying {

    // MARK: - Internal Types

    /// The type of transition to perform.
    internal enum TransitionType {
        case crossFade
        case fade(color: SKColor)
        case fadeIn
        case fadeOut
        case flip(direction: SKTransitionDirection)
        case reveal(direction: SKTransitionDirection)
        case moveIn(direction: SKTransitionDirection)
        case push(direction: SKTransitionDirection)
        case doorsOpen(horizontal: Bool)
        case doorsClose(horizontal: Bool)
        case doorway
        case ciFilter(filter: CIFilter)
        case none
    }

    // MARK: - Properties

    /// A Boolean value that indicates whether the transition should pause the incoming scene.
    open var pausesIncomingScene: Bool = true

    /// A Boolean value that indicates whether the transition should pause the outgoing scene.
    open var pausesOutgoingScene: Bool = true

    /// The duration of the transition in seconds.
    internal private(set) var duration: TimeInterval = 0

    /// The type of transition.
    internal private(set) var transitionType: TransitionType = .none

    // MARK: - Initializers

    /// Creates an empty transition.
    public override init() {
        super.init()
    }

    /// Creates a transition with the specified type and duration.
    private init(type: TransitionType, duration: TimeInterval) {
        self.transitionType = type
        self.duration = duration
        super.init()
    }

    // MARK: - Factory Methods

    /// Creates a cross-fade transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A cross-fade transition.
    public class func crossFade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .crossFade, duration: duration)
    }

    /// Creates a fade transition.
    ///
    /// - Parameters:
    ///   - color: The color to fade through.
    ///   - duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(with color: SKColor, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fade(color: color), duration: duration)
    }

    /// Creates a transition that first fades to black and then fades to the new scene.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fade(color: .black), duration: duration)
    }

    /// Creates a fade-in transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-in transition.
    public class func fadeIn(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fadeIn, duration: duration)
    }

    /// Creates a fade-out transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-out transition.
    public class func fadeOut(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fadeOut, duration: duration)
    }

    /// Creates a flip transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the flip.
    ///   - duration: The duration of the transition.
    /// - Returns: A flip transition.
    public class func flip(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: direction), duration: duration)
    }

    /// Creates a transition where the two scenes are flipped across a horizontal line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A horizontal flip transition.
    public class func flipHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: .up), duration: duration)
    }

    /// Creates a transition where the two scenes are flipped across a vertical line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A vertical flip transition.
    public class func flipVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: .right), duration: duration)
    }

    /// Creates a reveal transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the reveal.
    ///   - duration: The duration of the transition.
    /// - Returns: A reveal transition.
    public class func reveal(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .reveal(direction: direction), duration: duration)
    }

    /// Creates a move-in transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the move.
    ///   - duration: The duration of the transition.
    /// - Returns: A move-in transition.
    public class func moveIn(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .moveIn(direction: direction), duration: duration)
    }

    /// Creates a push transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the push.
    ///   - duration: The duration of the transition.
    /// - Returns: A push transition.
    public class func push(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .push(direction: direction), duration: duration)
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsOpen(horizontal: true), duration: duration)
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsOpen(horizontal: false), duration: duration)
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsClose(horizontal: true), duration: duration)
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsClose(horizontal: false), duration: duration)
    }

    /// Creates a doorway transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doorway transition.
    public class func doorway(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorway, duration: duration)
    }

    /// Creates a CIFilter-based transition.
    ///
    /// - Parameters:
    ///   - filter: The filter to use.
    ///   - duration: The duration of the transition.
    /// - Returns: A filter-based transition.
    public class func transition(with filter: CIFilter, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .ciFilter(filter: filter), duration: duration)
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTransition(type: transitionType, duration: duration)
        copy.pausesIncomingScene = pausesIncomingScene
        copy.pausesOutgoingScene = pausesOutgoingScene
        return copy
    }
}

// MARK: - SKTransitionDirection

/// For some transitions, the direction in which the transition is performed.
public enum SKTransitionDirection: Int, Sendable, Hashable {
    case up = 0
    case down = 1
    case right = 2
    case left = 3
}

// MARK: - SKColor Typealias

#if canImport(UIKit)
public typealias SKColor = UIColor
#elseif canImport(AppKit)
public typealias SKColor = NSColor
#else
/// A color type for use when neither UIKit nor AppKit is available.
public struct SKColor: Sendable, Hashable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let white = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = SKColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = SKColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let red = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = SKColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let gray = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
}
#endif
