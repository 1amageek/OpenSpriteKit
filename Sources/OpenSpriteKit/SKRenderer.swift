// SKRenderer.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// An object that renders a SpriteKit scene without using a view.
///
/// Use an `SKRenderer` object to render SpriteKit content into a graphics context.
/// This is useful for rendering scenes to offscreen targets or integrating SpriteKit
/// with other rendering systems.
open class SKRenderer: NSObject {

    // MARK: - Properties

    /// The scene to render.
    open var scene: SKScene?

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

    // MARK: - Initializers

    /// Creates a renderer for the specified device.
    ///
    /// - Parameter device: The GPU device to use for rendering. In WASM environments,
    ///   this is typically a WebGPU device.
    ///
    /// - Note: In WASM environments, you would pass a WebGPU device.
    public init(device: Any) {
        super.init()
    }

    /// Creates a new renderer.
    public override init() {
        super.init()
    }

    // MARK: - Rendering

    /// Renders the scene into the specified render pass.
    ///
    /// - Parameters:
    ///   - renderPassDescriptor: The render pass descriptor defining the target.
    ///   - commandBuffer: The command buffer to encode rendering commands into.
    ///   - viewport: The viewport rectangle for rendering.
    open func render(withViewport viewport: CGRect, renderCommandEncoder: Any, renderPassDescriptor: Any, commandQueue: Any) {
        // TODO: Implement rendering using WebGPU
    }

    /// Renders the scene into the specified render pass.
    ///
    /// - Parameters:
    ///   - viewport: The viewport rectangle for rendering.
    ///   - commandBuffer: The command buffer to encode commands into.
    ///   - renderPassDescriptor: The render pass descriptor.
    open func render(withViewport viewport: CGRect, commandBuffer: Any, renderPassDescriptor: Any) {
        // TODO: Implement rendering using WebGPU
    }

    /// Updates the scene for the specified time.
    ///
    /// - Parameter currentTime: The current time.
    open func update(atTime currentTime: TimeInterval) {
        scene?.update(currentTime)
    }
}
