// SKScene.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// An object that organizes all of the active SpriteKit content.
///
/// An `SKScene` object represents a scene of content in SpriteKit. A scene is the root node
/// in a tree of SpriteKit nodes (`SKNode`). These nodes provide content that the scene animates and
/// renders for display. To display a scene, you present it from an `SKView`, `SKRenderer`, or `WKInterfaceSKScene`.
///
/// `SKScene` is a subclass of `SKEffectNode` and enables certain effects to apply to the entire scene.
/// Though applying effects to an entire scene can be an expensive operation, creativity and ingenuity
/// may help you find some interesting ways to use effects.
open class SKScene: SKEffectNode, @unchecked Sendable {

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
    open var backgroundColor: SKColor = .gray {
        didSet {
            layer.backgroundColor = backgroundColor.cgColor
        }
    }

    // MARK: - Physics

    /// The physics simulation associated with the scene.
    open private(set) var physicsWorld: SKPhysicsWorld = SKPhysicsWorld()

    // MARK: - Audio

    /// A node used to determine the position of the listener for positional audio in the scene.
    open var listener: SKNode?

    // MARK: - Internal State

    /// Tracks whether sceneDidLoad has been called.
    internal var _didCallSceneDidLoad: Bool = false

    // Note: audioEngine is not included as it requires AVFoundation which may not be available on all platforms

    // MARK: - Initializers

    /// Creates a new scene object.
    public override init() {
        super.init()
        physicsWorld.scene = self
        layer.backgroundColor = backgroundColor.cgColor
        // Scene layer should use (0, 0) anchor so it fills from top-left of viewport
        layer.anchorPoint = CGPoint(x: 0, y: 0)
    }

    /// Creates a new scene object with the specified size.
    ///
    /// - Parameter size: The size of the scene in points.
    public init(size: CGSize) {
        self._size = size
        super.init()
        physicsWorld.scene = self
        layer.backgroundColor = backgroundColor.cgColor
        layer.bounds = CGRect(origin: .zero, size: size)
        // Scene layer should use (0, 0) anchor so it fills from top-left of viewport
        // This overrides the default (0.5, 0.5) from SKNode which would center the layer at origin
        layer.anchorPoint = CGPoint(x: 0, y: 0)
    }

    /// Creates a scene from a file in the app bundle.
    ///
    /// This method loads a scene from a `.sks` file created in Xcode's SpriteKit Scene Editor.
    ///
    /// On WASM platforms, you must first register the file data with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerScene(data: sksData, forName: "GameScene")
    /// let scene = SKScene.scene(fileNamed: "GameScene")
    /// ```
    ///
    /// - Parameter filename: The name of the scene file (with or without `.sks` extension).
    /// - Returns: A new scene, or nil if the file could not be loaded.
    public class func scene(fileNamed filename: String) -> SKScene? {
        // Try to load from registered scene data first (WASM)
        if let data = SKResourceLoader.shared.sceneData(forName: filename) {
            return SKSParser.scene(from: data)
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension = filename.hasSuffix(".sks") ? String(filename.dropLast(4)) : filename

        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "sks"),
           let data = try? Data(contentsOf: url) {
            return SKSParser.scene(from: data)
        }

        return nil
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

    // MARK: - Camera Transform

    /// Calculates the transform matrix to apply for camera rendering.
    ///
    /// When a camera is set, the scene should be rendered from the camera's perspective.
    /// This method returns the inverse transform of the camera.
    ///
    /// - Returns: The affine transform to apply for camera-based rendering, or identity if no camera.
    internal func calculateCameraTransform() -> CGAffineTransform {
        guard let camera = camera else {
            return .identity
        }

        // The camera transform is the inverse of the camera's node transform
        // 1. First, translate by negative camera position (center view on camera)
        // 2. Then, rotate by negative camera rotation
        // 3. Finally, scale by inverse of camera scale (zoom)

        var transform = CGAffineTransform.identity

        // Scale by inverse (camera scale > 1 means zoom in, so content appears smaller from camera's POV)
        let scaleX = camera.xScale != 0 ? 1.0 / camera.xScale : 1.0
        let scaleY = camera.yScale != 0 ? 1.0 / camera.yScale : 1.0
        transform = transform.scaledBy(x: scaleX, y: scaleY)

        // Rotate by negative angle
        if camera.zRotation != 0 {
            transform = transform.rotated(by: -camera.zRotation)
        }

        // Translate by negative position
        transform = transform.translatedBy(x: -camera.position.x, y: -camera.position.y)

        return transform
    }

    /// Returns the visible area in scene coordinates when using the current camera.
    ///
    /// - Parameter viewSize: The size of the view.
    /// - Returns: The visible rectangle in scene coordinates.
    internal func calculateVisibleRectForCamera(viewSize: CGSize) -> CGRect {
        guard let camera = camera else {
            // No camera - visible area is based on anchor point and scene size
            return CGRect(
                x: -anchorPoint.x * size.width,
                y: -anchorPoint.y * size.height,
                width: size.width,
                height: size.height
            )
        }

        guard let view = view else {
            // Calculate visible rect without view (use provided viewSize)
            let effectiveScale = CGPoint(x: camera.xScale, y: camera.yScale)
            let scaledWidth = viewSize.width / (effectiveScale.x != 0 ? effectiveScale.x : 1)
            let scaledHeight = viewSize.height / (effectiveScale.y != 0 ? effectiveScale.y : 1)

            return CGRect(
                x: camera.position.x - scaledWidth / 2,
                y: camera.position.y - scaledHeight / 2,
                width: scaledWidth,
                height: scaledHeight
            )
        }

        return camera.calculateVisibleRect(in: view)
    }
}
