// SKSpriteNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(QuartzCore)
import QuartzCore
#else
import OpenCoreAnimation
#endif

/// An image or solid color.
///
/// `SKSpriteNode` is an onscreen graphical element that can be initialized from an image or a solid color.
/// SpriteKit adds functionality to its ability to display images using the functions discussed below.
open class SKSpriteNode: SKNode, SKWarpable {

    // MARK: - Texture Properties

    /// The texture used to draw the sprite.
    open var texture: SKTexture? {
        didSet {
            if let texture = texture, size == .zero {
                size = texture.size
            }
            updateLayerContents()
        }
    }

    /// A texture that specifies the normal map for the sprite.
    open var normalTexture: SKTexture?

    // MARK: - Size and Position Properties

    /// The dimensions of the sprite, in points.
    open var size: CGSize = .zero {
        didSet {
            updateLayerBounds()
        }
    }

    /// Defines the point in the sprite that corresponds to the node's position.
    ///
    /// The default value is (0.5, 0.5), which indicates that the sprite is centered on its position.
    /// A value of (0, 0) indicates that the sprite's bottom-left corner is on its position.
    open var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            layer.anchorPoint = anchorPoint
        }
    }

    /// Enable nine-part stretching of the sprite's texture.
    ///
    /// The default value is a rectangle that covers the entire texture (0, 0, 1, 1).
    /// This property is specified in unit coordinates.
    open var centerRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet {
            layer.contentsCenter = centerRect
        }
    }

    // MARK: - Layer Synchronization

    /// Updates the layer's bounds based on the sprite size.
    private func updateLayerBounds() {
        layer.bounds = CGRect(origin: .zero, size: size)
    }

    /// Updates the layer's contents based on the texture.
    private func updateLayerContents() {
        layer.contents = texture?.cgImage
    }

    // MARK: - Color Properties

    /// The sprite's color.
    open var color: SKColor = .white

    /// A floating-point value that describes how the color is blended with the sprite's texture.
    ///
    /// A value of 0.0 means the texture is used without any color blending.
    /// A value of 1.0 means the color is used entirely.
    open var colorBlendFactor: CGFloat = 0.0

    // MARK: - Blending Properties

    /// The blend mode used to draw the sprite into the parent's framebuffer.
    open var blendMode: SKBlendMode = .alpha

    // MARK: - Lighting Properties

    /// A mask that defines how this sprite is lit by light nodes in the scene.
    open var lightingBitMask: UInt32 = 0

    /// A mask that defines which lights add shadows to the sprite.
    open var shadowedBitMask: UInt32 = 0

    /// A mask that defines which lights are occluded by this sprite.
    open var shadowCastBitMask: UInt32 = 0

    // MARK: - Shader Properties

    /// A text file that defines code that does custom per-pixel drawing or colorization.
    open var shader: SKShader?

    /// The values of each attribute associated with the node's attached shader.
    open var attributeValues: [String: SKAttributeValue] = [:]

    // MARK: - SKWarpable Conformance

    /// The warp geometry applied to this node.
    open var warpGeometry: SKWarpGeometry?

    /// The subdivisions used when rendering warped geometry.
    open var subdivisionLevels: Int = 1

    // MARK: - Computed Properties

    /// The calculated frame of the sprite in the parent's coordinate system.
    ///
    /// The frame accounts for the sprite's size, anchor point, position, scale, and rotation.
    open override var frame: CGRect {
        // Apply scale to size
        let scaledWidth = size.width * abs(xScale)
        let scaledHeight = size.height * abs(yScale)

        // If no rotation, simple bounding box
        if zRotation == 0 {
            let origin = CGPoint(
                x: position.x - scaledWidth * anchorPoint.x,
                y: position.y - scaledHeight * anchorPoint.y
            )
            return CGRect(origin: origin, size: CGSize(width: scaledWidth, height: scaledHeight))
        }

        // With rotation, calculate the bounding box of the rotated rectangle
        let cosVal = Foundation.cos(Double(zRotation))
        let sinVal = Foundation.sin(Double(zRotation))

        // Calculate the four corners relative to anchor point, then rotate
        let corners = [
            CGPoint(x: -scaledWidth * anchorPoint.x, y: -scaledHeight * anchorPoint.y),
            CGPoint(x: scaledWidth * (1 - anchorPoint.x), y: -scaledHeight * anchorPoint.y),
            CGPoint(x: scaledWidth * (1 - anchorPoint.x), y: scaledHeight * (1 - anchorPoint.y)),
            CGPoint(x: -scaledWidth * anchorPoint.x, y: scaledHeight * (1 - anchorPoint.y))
        ]

        // Rotate corners and find bounding box
        var minX = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var minY = CGFloat.infinity
        var maxY = -CGFloat.infinity

        for corner in corners {
            let rotatedX = CGFloat(Double(corner.x) * cosVal - Double(corner.y) * sinVal)
            let rotatedY = CGFloat(Double(corner.x) * sinVal + Double(corner.y) * cosVal)
            minX = min(minX, rotatedX)
            maxX = max(maxX, rotatedX)
            minY = min(minY, rotatedY)
            maxY = max(maxY, rotatedY)
        }

        return CGRect(
            x: position.x + minX,
            y: position.y + minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    // MARK: - Initializers

    /// Creates a new sprite node.
    public override init() {
        super.init()
    }

    /// Initializes a textured sprite using an image file.
    ///
    /// - Parameter name: The name of an image file in the app bundle.
    public convenience init(imageNamed name: String) {
        self.init(texture: SKTexture(imageNamed: name))
    }

    /// Initializes a textured sprite using an image file, optionally adding a normal map.
    ///
    /// - Parameters:
    ///   - name: The name of an image file in the app bundle.
    ///   - generateNormalMap: A Boolean value indicating whether to generate a normal map.
    public convenience init(imageNamed name: String, normalMapped generateNormalMap: Bool) {
        let texture = SKTexture(imageNamed: name)
        if generateNormalMap {
            // TODO: Generate normal map from texture
            self.init(texture: texture, normalMap: nil)
        } else {
            self.init(texture: texture)
        }
    }

    /// Initializes a textured sprite using an existing texture object.
    ///
    /// - Parameter texture: The texture to use for the sprite.
    public convenience init(texture: SKTexture?) {
        self.init(texture: texture, color: .white, size: texture?.size ?? .zero)
    }

    /// Initializes a textured sprite using an existing texture object but with a specified size.
    ///
    /// - Parameters:
    ///   - texture: The texture to use for the sprite.
    ///   - size: The size of the sprite.
    public convenience init(texture: SKTexture?, size: CGSize) {
        self.init(texture: texture, color: .white, size: size)
    }

    /// Initializes a textured sprite in color using an existing texture object.
    ///
    /// - Parameters:
    ///   - texture: The texture to use for the sprite.
    ///   - color: The color to blend with the texture.
    ///   - size: The size of the sprite.
    public init(texture: SKTexture?, color: SKColor, size: CGSize) {
        self.texture = texture
        self.color = color
        self.size = size
        super.init()
    }

    /// Initializes a textured sprite with a normal map to simulate 3D lighting.
    ///
    /// - Parameters:
    ///   - texture: The texture to use for the sprite.
    ///   - normalMap: The normal map texture for lighting.
    public convenience init(texture: SKTexture?, normalMap: SKTexture?) {
        self.init(texture: texture)
        self.normalTexture = normalMap
    }

    /// Initializes a single-color sprite node.
    ///
    /// - Parameters:
    ///   - color: The color of the sprite.
    ///   - size: The size of the sprite.
    public convenience init(color: SKColor, size: CGSize) {
        self.init(texture: nil, color: color, size: size)
        self.colorBlendFactor = 1.0
    }

    public required init?(coder: NSCoder) {
        size = CGSize(
            width: CGFloat(coder.decodeDouble(forKey: "size.width")),
            height: CGFloat(coder.decodeDouble(forKey: "size.height"))
        )
        anchorPoint = CGPoint(
            x: CGFloat(coder.decodeDouble(forKey: "anchorPoint.x")),
            y: CGFloat(coder.decodeDouble(forKey: "anchorPoint.y"))
        )
        centerRect = CGRect(
            x: CGFloat(coder.decodeDouble(forKey: "centerRect.x")),
            y: CGFloat(coder.decodeDouble(forKey: "centerRect.y")),
            width: CGFloat(coder.decodeDouble(forKey: "centerRect.width")),
            height: CGFloat(coder.decodeDouble(forKey: "centerRect.height"))
        )
        colorBlendFactor = CGFloat(coder.decodeDouble(forKey: "colorBlendFactor"))
        blendMode = SKBlendMode(rawValue: coder.decodeInteger(forKey: "blendMode")) ?? .alpha
        lightingBitMask = UInt32(coder.decodeInt32(forKey: "lightingBitMask"))
        shadowedBitMask = UInt32(coder.decodeInt32(forKey: "shadowedBitMask"))
        shadowCastBitMask = UInt32(coder.decodeInt32(forKey: "shadowCastBitMask"))
        subdivisionLevels = coder.decodeInteger(forKey: "subdivisionLevels")
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(size.width), forKey: "size.width")
        coder.encode(Double(size.height), forKey: "size.height")
        coder.encode(Double(anchorPoint.x), forKey: "anchorPoint.x")
        coder.encode(Double(anchorPoint.y), forKey: "anchorPoint.y")
        coder.encode(Double(centerRect.origin.x), forKey: "centerRect.x")
        coder.encode(Double(centerRect.origin.y), forKey: "centerRect.y")
        coder.encode(Double(centerRect.size.width), forKey: "centerRect.width")
        coder.encode(Double(centerRect.size.height), forKey: "centerRect.height")
        coder.encode(Double(colorBlendFactor), forKey: "colorBlendFactor")
        coder.encode(blendMode.rawValue, forKey: "blendMode")
        coder.encode(Int32(lightingBitMask), forKey: "lightingBitMask")
        coder.encode(Int32(shadowedBitMask), forKey: "shadowedBitMask")
        coder.encode(Int32(shadowCastBitMask), forKey: "shadowCastBitMask")
        coder.encode(subdivisionLevels, forKey: "subdivisionLevels")
    }

    // MARK: - Size Methods

    /// Scales the sprite node to a specified size.
    ///
    /// - Parameter size: The target size for the sprite.
    open func scale(to size: CGSize) {
        self.size = size
    }

    // MARK: - Shader Attribute Methods

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
    /// - Returns: The attribute value, or nil if not found.
    open func value(forAttributeNamed name: String) -> SKAttributeValue? {
        return attributeValues[name]
    }
}
