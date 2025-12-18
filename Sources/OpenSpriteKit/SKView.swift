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
        }

        self.scene = scene
        scene?._view = self
        scene?.didMove(to: self)
    }

    /// Presents a scene in the view with a transition animation.
    ///
    /// - Parameters:
    ///   - scene: The scene to present.
    ///   - transition: The transition to use when presenting the scene.
    open func presentScene(_ scene: SKScene, transition: SKTransition) {
        // TODO: Implement transition animation
        presentScene(scene)
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// - Parameter point: A point in view coordinates.
    /// - Returns: The point converted to scene coordinates.
    open func convert(_ point: CGPoint, to scene: SKScene) -> CGPoint {
        // TODO: Implement proper coordinate conversion
        return point
    }

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// - Parameter point: A point in scene coordinates.
    /// - Returns: The point converted to view coordinates.
    open func convert(_ point: CGPoint, from scene: SKScene) -> CGPoint {
        // TODO: Implement proper coordinate conversion
        return point
    }

    // MARK: - Texture Generation

    /// Renders a portion of a node's contents to a texture.
    ///
    /// - Parameters:
    ///   - node: The node whose content is rendered.
    ///   - crop: The rectangle in the node's coordinate space to render.
    /// - Returns: A texture containing the rendered content.
    open func texture(from node: SKNode, crop: CGRect) -> SKTexture? {
        // TODO: Implement texture rendering
        return nil
    }

    /// Renders a node's contents to a texture.
    ///
    /// - Parameter node: The node whose content is rendered.
    /// - Returns: A texture containing the rendered content.
    open func texture(from node: SKNode) -> SKTexture? {
        // TODO: Implement texture rendering
        return nil
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

    // MARK: - Properties

    /// A Boolean value that indicates whether the transition should pause the incoming scene.
    open var pausesIncomingScene: Bool = true

    /// A Boolean value that indicates whether the transition should pause the outgoing scene.
    open var pausesOutgoingScene: Bool = true

    // MARK: - Factory Methods

    /// Creates a cross-fade transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A cross-fade transition.
    public class func crossFade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a fade transition.
    ///
    /// - Parameters:
    ///   - color: The color to fade through.
    ///   - duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(with color: SKColor, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a transition that first fades to black and then fades to the new scene.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a fade-in transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-in transition.
    public class func fadeIn(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a fade-out transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-out transition.
    public class func fadeOut(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a flip transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the flip.
    ///   - duration: The duration of the transition.
    /// - Returns: A flip transition.
    public class func flip(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a transition where the two scenes are flipped across a horizontal line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A horizontal flip transition.
    public class func flipHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a transition where the two scenes are flipped across a vertical line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A vertical flip transition.
    public class func flipVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a reveal transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the reveal.
    ///   - duration: The duration of the transition.
    /// - Returns: A reveal transition.
    public class func reveal(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a move-in transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the move.
    ///   - duration: The duration of the transition.
    /// - Returns: A move-in transition.
    public class func moveIn(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a push transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the push.
    ///   - duration: The duration of the transition.
    /// - Returns: A push transition.
    public class func push(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a doorway transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doorway transition.
    public class func doorway(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    /// Creates a CIFilter-based transition.
    ///
    /// - Parameters:
    ///   - filter: The filter to use.
    ///   - duration: The duration of the transition.
    /// - Returns: A filter-based transition.
    public class func transition(with filter: CIFilter, duration: TimeInterval) -> SKTransition {
        return SKTransition()
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTransition()
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
