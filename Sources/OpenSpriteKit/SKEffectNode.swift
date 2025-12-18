// SKEffectNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A node that renders its children into a separate buffer, optionally applying an effect, before drawing the final result.
///
/// An `SKEffectNode` object renders its children into a buffer and optionally applies a Core Image filter
/// to this rendered output. Because effect nodes conform to `SKWarpable`, you can also use them to
/// apply distortions to nodes that don't implement the protocol, such as shape and video nodes.
/// Use effect nodes to incorporate sophisticated special effects into a scene or to cache the
/// contents of a static subtree for faster rendering performance.
open class SKEffectNode: SKNode, SKWarpable {

    // MARK: - Filter Properties

    /// The Core Image filter to apply.
    open var filter: CIFilter?

    /// A Boolean value that determines whether the effect node applies the filter to its children as they are drawn.
    open var shouldEnableEffects: Bool = false

    /// A Boolean value that determines whether the effect node automatically sets the filter's image center.
    open var shouldCenterFilter: Bool = true

    // MARK: - Shader Properties

    /// A custom shader that is called when the effect node is blended into the parent's framebuffer.
    open var shader: SKShader?

    /// The values of each attribute associated with the node's attached shader.
    open var attributeValues: [String: SKAttributeValue] = [:]

    // MARK: - Rasterization Properties

    /// A Boolean value that indicates whether the results of rendering the child nodes should be cached.
    open var shouldRasterize: Bool = false

    // MARK: - Blend Mode

    /// The blend mode used to draw the node's contents into its parent's framebuffer.
    open var blendMode: SKBlendMode = .alpha

    // MARK: - SKWarpable Conformance

    /// The warp geometry applied to this node.
    open var warpGeometry: SKWarpGeometry?

    /// The subdivisions used when rendering warped geometry.
    open var subdivisionLevels: Int = 1

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        shouldEnableEffects = coder.decodeBool(forKey: "shouldEnableEffects")
        shouldCenterFilter = coder.decodeBool(forKey: "shouldCenterFilter")
        shouldRasterize = coder.decodeBool(forKey: "shouldRasterize")
        blendMode = SKBlendMode(rawValue: coder.decodeInteger(forKey: "blendMode")) ?? .alpha
        subdivisionLevels = coder.decodeInteger(forKey: "subdivisionLevels")
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(shouldEnableEffects, forKey: "shouldEnableEffects")
        coder.encode(shouldCenterFilter, forKey: "shouldCenterFilter")
        coder.encode(shouldRasterize, forKey: "shouldRasterize")
        coder.encode(blendMode.rawValue, forKey: "blendMode")
        coder.encode(subdivisionLevels, forKey: "subdivisionLevels")
    }

    // MARK: - Attribute Management

    /// Sets an attribute value for an attached shader.
    ///
    /// - Parameters:
    ///   - value: The attribute value to set.
    ///   - key: The name of the attribute.
    open func setValue(_ value: SKAttributeValue, forAttribute key: String) {
        attributeValues[key] = value
    }

    /// Gets the value of a shader attribute.
    ///
    /// - Parameter name: The name of the attribute.
    /// - Returns: The attribute value, or nil if the attribute is not found.
    open func value(forAttributeNamed name: String) -> SKAttributeValue? {
        return attributeValues[name]
    }
}
