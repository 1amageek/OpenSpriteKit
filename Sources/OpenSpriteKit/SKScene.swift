// SKScene.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// An object that organizes all of the active SpriteKit content.
///
/// An `SKScene` object represents a scene of content in SpriteKit. A scene is the root node
/// in a tree of SpriteKit nodes (`SKNode`). These nodes provide content that the scene animates and
/// renders for display. To display a scene, you present it from an `SKView`, `SKRenderer`, or `WKInterfaceSKScene`.
///
/// `SKScene` is a subclass of `SKEffectNode` and enables certain effects to apply to the entire scene.
/// Though applying effects to an entire scene can be an expensive operation, creativity and ingenuity
/// may help you find some interesting ways to use effects.
open class SKScene: SKEffectNode {

    // MARK: - Size and Scale Properties

    /// The dimensions of the scene in points.
    open var size: CGSize {
        get { _size }
        set {
            let oldSize = _size
            _size = newValue
            if oldSize != newValue {
                didChangeSize(oldSize)
            }
        }
    }
    private var _size: CGSize = .zero

    /// A setting that defines how the scene is mapped to the view that presents it.
    open var scaleMode: SKSceneScaleMode = .fill

    // MARK: - Viewport Properties

    /// The camera node in the scene that determines what part of the scene's coordinate space is visible in the view.
    open var camera: SKCameraNode?

    /// The point in the view's frame that corresponds to the scene's origin.
    open var anchorPoint: CGPoint = .zero

    // MARK: - Delegate

    /// A delegate to be called during the animation loop.
    open weak var delegate: SKSceneDelegate?

    // MARK: - View Reference

    /// The view that is currently presenting the scene.
    open private(set) weak var view: SKView?

    /// Internal setter for view, used by SKView when presenting.
    internal var _view: SKView? {
        get { view }
        set { view = newValue }
    }

    // MARK: - Background

    /// The background color of the scene.
    open var backgroundColor: SKColor = .gray

    // MARK: - Physics

    /// The physics simulation associated with the scene.
    open private(set) var physicsWorld: SKPhysicsWorld = SKPhysicsWorld()

    // MARK: - Audio

    /// A node used to determine the position of the listener for positional audio in the scene.
    open var listener: SKNode?

    // Note: audioEngine is not included as it requires AVFoundation which may not be available on all platforms

    // MARK: - Initializers

    /// Creates a new scene object.
    public override init() {
        super.init()
        physicsWorld.scene = self
    }

    /// Creates a new scene object with the specified size.
    ///
    /// - Parameter size: The size of the scene in points.
    public init(size: CGSize) {
        self._size = size
        super.init()
        physicsWorld.scene = self
    }

    /// Creates a scene from a file in the app bundle.
    ///
    /// - Parameter filename: The name of the scene file.
    /// - Returns: A new scene, or nil if the file could not be loaded.
    public class func scene(fileNamed filename: String) -> SKScene? {
        // TODO: Implement scene loading from file
        return nil
    }

    public required init?(coder: NSCoder) {
        let width = CGFloat(coder.decodeDouble(forKey: "size.width"))
        let height = CGFloat(coder.decodeDouble(forKey: "size.height"))
        _size = CGSize(width: width, height: height)
        scaleMode = SKSceneScaleMode(rawValue: coder.decodeInteger(forKey: "scaleMode")) ?? .fill
        let anchorX = CGFloat(coder.decodeDouble(forKey: "anchorPoint.x"))
        let anchorY = CGFloat(coder.decodeDouble(forKey: "anchorPoint.y"))
        anchorPoint = CGPoint(x: anchorX, y: anchorY)
        super.init(coder: coder)
        physicsWorld.scene = self
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(_size.width), forKey: "size.width")
        coder.encode(Double(_size.height), forKey: "size.height")
        coder.encode(scaleMode.rawValue, forKey: "scaleMode")
        coder.encode(Double(anchorPoint.x), forKey: "anchorPoint.x")
        coder.encode(Double(anchorPoint.y), forKey: "anchorPoint.y")
    }

    // MARK: - Scene Reference

    /// Updates scene reference for SKScene (always returns self).
    internal func updateSceneReference() {
        // For SKScene, scene reference is always self, handled internally
    }

    // MARK: - Lifecycle Methods

    /// Tells you when the scene is presented.
    ///
    /// This method is called once after the scene is presented. Override this method to perform
    /// any one-time setup for your scene.
    open func sceneDidLoad() {
        // Subclasses can override
    }

    /// Tells you when the scene's size has changed.
    ///
    /// - Parameter oldSize: The previous size of the scene.
    open func didChangeSize(_ oldSize: CGSize) {
        // Subclasses can override
    }

    /// Tells you when the scene is about to be removed from a view.
    ///
    /// - Parameter view: The view that the scene is being removed from.
    open func willMove(from view: SKView) {
        // Subclasses can override
    }

    /// Tells you when the scene is presented by a view.
    ///
    /// - Parameter view: The view that is presenting the scene.
    open func didMove(to view: SKView) {
        // Subclasses can override
    }

    // MARK: - Frame Cycle Methods

    /// Tells your app to perform any app-specific logic to update your scene.
    ///
    /// This method is called exactly once per frame, before any actions are evaluated or any physics simulations
    /// are performed. Override this method to implement per-frame game logic.
    ///
    /// - Parameter currentTime: The current system time.
    open func update(_ currentTime: TimeInterval) {
        delegate?.update(currentTime, for: self)
    }

    /// Tells your app to perform any necessary logic after scene actions are evaluated.
    ///
    /// This method is called exactly once per frame, after any actions have been evaluated.
    open func didEvaluateActions() {
        delegate?.didEvaluateActions(for: self)
    }

    /// Tells your app to perform any necessary logic after physics simulations are performed.
    ///
    /// This method is called exactly once per frame, after physics simulations have been processed.
    open func didSimulatePhysics() {
        delegate?.didSimulatePhysics(for: self)
    }

    /// Tells your app to perform any necessary logic after constraints are applied.
    ///
    /// This method is called exactly once per frame, after all constraints have been applied.
    open func didApplyConstraints() {
        delegate?.didApplyConstraints(for: self)
    }

    /// Tells your app to perform any necessary logic after the scene has finished all of the steps required to process animations.
    ///
    /// This method is called exactly once per frame, after all other frame processing is complete.
    open func didFinishUpdate() {
        delegate?.didFinishUpdate(for: self)
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// - Parameter point: A point in view coordinates.
    /// - Returns: The point converted to scene coordinates.
    open func convertPoint(fromView point: CGPoint) -> CGPoint {
        guard let view = view else { return point }

        // Apply anchor point offset
        let anchorOffset = CGPoint(
            x: anchorPoint.x * size.width,
            y: anchorPoint.y * size.height
        )

        // Convert based on scale mode
        let viewSize = view.viewSize
        var scenePoint = point

        switch scaleMode {
        case .fill:
            let scaleX = size.width / viewSize.width
            let scaleY = size.height / viewSize.height
            scenePoint.x = point.x * scaleX
            scenePoint.y = (viewSize.height - point.y) * scaleY

        case .aspectFill:
            let scale = max(size.width / viewSize.width, size.height / viewSize.height)
            let offsetX = (viewSize.width * scale - size.width) / 2
            let offsetY = (viewSize.height * scale - size.height) / 2
            scenePoint.x = point.x * scale - offsetX
            scenePoint.y = (viewSize.height - point.y) * scale - offsetY

        case .aspectFit:
            let scale = min(size.width / viewSize.width, size.height / viewSize.height)
            let offsetX = (viewSize.width * scale - size.width) / 2
            let offsetY = (viewSize.height * scale - size.height) / 2
            scenePoint.x = point.x * scale - offsetX
            scenePoint.y = (viewSize.height - point.y) * scale - offsetY

        case .resizeFill:
            scenePoint.x = point.x
            scenePoint.y = viewSize.height - point.y
        }

        // Apply anchor point
        scenePoint.x -= anchorOffset.x
        scenePoint.y -= anchorOffset.y

        return scenePoint
    }

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// - Parameter point: A point in scene coordinates.
    /// - Returns: The point converted to view coordinates.
    open func convertPoint(toView point: CGPoint) -> CGPoint {
        guard let view = view else { return point }

        // Apply anchor point offset
        let anchorOffset = CGPoint(
            x: anchorPoint.x * size.width,
            y: anchorPoint.y * size.height
        )

        let adjustedPoint = CGPoint(
            x: point.x + anchorOffset.x,
            y: point.y + anchorOffset.y
        )

        // Convert based on scale mode
        let viewSize = view.viewSize
        var viewPoint = adjustedPoint

        switch scaleMode {
        case .fill:
            let scaleX = viewSize.width / size.width
            let scaleY = viewSize.height / size.height
            viewPoint.x = adjustedPoint.x * scaleX
            viewPoint.y = viewSize.height - adjustedPoint.y * scaleY

        case .aspectFill:
            let scale = max(viewSize.width / size.width, viewSize.height / size.height)
            let offsetX = (size.width * scale - viewSize.width) / 2
            let offsetY = (size.height * scale - viewSize.height) / 2
            viewPoint.x = adjustedPoint.x * scale - offsetX
            viewPoint.y = viewSize.height - (adjustedPoint.y * scale - offsetY)

        case .aspectFit:
            let scale = min(viewSize.width / size.width, viewSize.height / size.height)
            let offsetX = (viewSize.width - size.width * scale) / 2
            let offsetY = (viewSize.height - size.height * scale) / 2
            viewPoint.x = adjustedPoint.x * scale + offsetX
            viewPoint.y = viewSize.height - (adjustedPoint.y * scale + offsetY)

        case .resizeFill:
            viewPoint.x = adjustedPoint.x
            viewPoint.y = viewSize.height - adjustedPoint.y
        }

        return viewPoint
    }
}
