// SK3DNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenFoundation

// OpenSpriteKit has no SceneKit-compatible scene, camera, hit-result, or offscreen
// renderer contract. The type is unavailable until all four are implemented; callers
// must not receive empty hits or fabricated coordinates as successful results.

/// A node that renders a SceneKit scene as a 2D image.
///
/// An `SK3DNode` object lets you render a SceneKit scene as part of your SpriteKit game.
/// Use 3D nodes to add 3D content to your 2D games.
///
@available(*, unavailable, message: "SK3DNode requires a SceneKit-compatible 3D runtime and offscreen renderer")
open class SK3DNode: SKNode {

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
    open var scnScene: Any?

    /// The point of view (camera) for rendering the SceneKit scene.
    ///
    /// - Note: SceneKit is not available in WASM environments. This property
    ///   is provided for API compatibility only.
    open var pointOfView: Any?

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

    // MARK: - Copying

    /// Creates a copy of this 3D node.
    open override func copy() -> SKNode {
        let nodeCopy = SK3DNode()
        nodeCopy._copyNodeProperties(from: self)
        return nodeCopy
    }

    /// Internal helper to copy SK3DNode properties.
    internal override func _copyNodeProperties(from node: SKNode) {
        super._copyNodeProperties(from: node)
        guard let node3d = node as? SK3DNode else { return }

        self.viewportSize = node3d.viewportSize
        self.isPlaying = node3d.isPlaying
        self.loops = node3d.loops
        self.scnScene = node3d.scnScene
        self.pointOfView = node3d.pointOfView
        self.autoenablesDefaultLighting = node3d.autoenablesDefaultLighting
    }

    // MARK: - Hit Testing

    /// Searches for objects in the scene that correspond to a point in the SpriteKit scene.
    ///
    /// - Parameter point: The point in scene coordinates.
    /// - Returns: An array of hit test results.
    ///
    open func hitTest(_ point: CGPoint, options: [String: Any]? = nil) -> [Any] {
        preconditionFailure("SK3DNode is unavailable without a SceneKit-compatible runtime")
    }

    /// Projects a point from the 3D coordinate system to the 2D SpriteKit coordinate system.
    ///
    /// - Parameter point: The 3D point to project.
    /// - Returns: The projected 2D point.
    ///
    open func projectPoint(_ point: Any) -> CGPoint {
        preconditionFailure("SK3DNode is unavailable without a SceneKit-compatible runtime")
    }

    /// Unprojects a point from the 2D SpriteKit coordinate system to the 3D coordinate system.
    ///
    /// - Parameter point: The 2D point to unproject.
    /// - Returns: The unprojected 3D point.
    ///
    open func unprojectPoint(_ point: CGPoint) -> Any? {
        preconditionFailure("SK3DNode is unavailable without a SceneKit-compatible runtime")
    }
}
