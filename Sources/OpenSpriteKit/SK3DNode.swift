// SK3DNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

// Note: SceneKit is not available in WASM environments, so SK3DNode provides
// a stub implementation for API compatibility. In actual SpriteKit on Apple platforms,
// SK3DNode renders a SceneKit scene as a 2D image.

/// A node that renders a SceneKit scene as a 2D image.
///
/// An `SK3DNode` object lets you render a SceneKit scene as part of your SpriteKit game.
/// Use 3D nodes to add 3D content to your 2D games.
///
/// - Note: In WASM environments, SceneKit is not available. This class provides
///   API compatibility but does not render 3D content.
open class SK3DNode: SKNode, @unchecked Sendable {

    // MARK: - Properties

    /// The size of the 3D node's bounding rectangle.
    open var viewportSize: CGSize = .zero

    /// A Boolean value that indicates whether the 3D content is automatically updated.
    open var isPlaying: Bool = true

    /// A Boolean value that indicates whether the 3D content should loop.
    open var loops: Bool = true

    /// The SceneKit scene to render.
    ///
    /// - Note: SceneKit is not available in WASM environments. This property
    ///   is provided for API compatibility only.
    open var scnScene: Any? {
        didSet {
            // In a full implementation, this would set up SceneKit rendering
        }
    }

    /// The point of view (camera) for rendering the SceneKit scene.
    ///
    /// - Note: SceneKit is not available in WASM environments. This property
    ///   is provided for API compatibility only.
    open var pointOfView: Any? {
        didSet {
            // In a full implementation, this would configure the camera
        }
    }

    /// A Boolean value that indicates whether SceneKit can automatically determine a suitable point of view.
    open var autoenablesDefaultLighting: Bool = false

    // MARK: - Initializers

    /// Creates a new 3D node with the specified viewport size.
    ///
    /// - Parameter viewportSize: The size of the 3D node's bounding rectangle.
    public init(viewportSize: CGSize) {
        self.viewportSize = viewportSize
        super.init()
    }

    /// Creates a new 3D node.
    public override init() {
        super.init()
    }

    // MARK: - Hit Testing

    /// Searches for objects in the scene that correspond to a point in the SpriteKit scene.
    ///
    /// - Parameter point: The point in scene coordinates.
    /// - Returns: An array of hit test results.
    ///
    /// - Note: SceneKit is not available in WASM environments. This method
    ///   returns an empty array for API compatibility.
    open func hitTest(_ point: CGPoint, options: [String: Any]? = nil) -> [Any] {
        return []
    }

    /// Projects a point from the 3D coordinate system to the 2D SpriteKit coordinate system.
    ///
    /// - Parameter point: The 3D point to project.
    /// - Returns: The projected 2D point.
    ///
    /// - Note: SceneKit is not available in WASM environments. This method
    ///   returns zero for API compatibility.
    open func projectPoint(_ point: Any) -> CGPoint {
        return .zero
    }

    /// Unprojects a point from the 2D SpriteKit coordinate system to the 3D coordinate system.
    ///
    /// - Parameter point: The 2D point to unproject.
    /// - Returns: The unprojected 3D point.
    ///
    /// - Note: SceneKit is not available in WASM environments. This method
    ///   returns nil for API compatibility.
    open func unprojectPoint(_ point: CGPoint) -> Any? {
        return nil
    }
}
