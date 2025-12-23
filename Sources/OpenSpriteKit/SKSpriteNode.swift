// SKSpriteNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// An image or solid color.
///
/// `SKSpriteNode` is an onscreen graphical element that can be initialized from an image or a solid color.
/// SpriteKit adds functionality to its ability to display images using the functions discussed below.
open class SKSpriteNode: SKNode, SKWarpable, @unchecked Sendable {

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
    open var color: SKColor = .white {
        didSet {
            updateLayerBackgroundColor()
        }
    }

    /// A floating-point value that describes how the color is blended with the sprite's texture.
    ///
    /// A value of 0.0 means the texture is used without any color blending.
    /// A value of 1.0 means the color is used entirely.
    open var colorBlendFactor: CGFloat = 0.0 {
        didSet {
            updateLayerBackgroundColor()
        }
    }

    /// Updates the layer's background color based on color and colorBlendFactor.
    private func updateLayerBackgroundColor() {
        // Only set backgroundColor when using solid color (no texture and full blend)
        if texture == nil && colorBlendFactor > 0 {
            layer.backgroundColor = color.cgColor
        } else {
            layer.backgroundColor = nil
        }
    }

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

    // MARK: - Internal Lighting State (for WASM rendering)

    /// The computed lighting color from all affecting light nodes.
    /// This is set by SKViewRenderer during the lighting pass.
    /// Components are (red, green, blue, alpha) in range [0, 1].
    internal var _computedLightingColor: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) = (1.0, 1.0, 1.0, 1.0)

    /// Whether lighting has been computed for this frame.
    internal var _hasComputedLighting: Bool = false

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
            let normalMap = Self.generateNormalMap(from: texture)
            self.init(texture: texture, normalMap: normalMap)
        } else {
            self.init(texture: texture)
        }
    }

    /// Generates a normal map from a texture using Sobel edge detection.
    ///
    /// This method analyzes the grayscale values of the source texture to compute
    /// surface normals, creating a normal map that can be used for lighting effects.
    ///
    /// - Parameter texture: The source texture to generate a normal map from.
    /// - Returns: A new texture containing the generated normal map, or nil if generation failed.
    private static func generateNormalMap(from texture: SKTexture) -> SKTexture? {
        guard let cgImage = texture.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        guard width > 2, height > 2 else { return nil }

        // Create a grayscale representation for height values
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: .deviceRGB,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Convert to grayscale height values
        var heightMap = [[Float]](repeating: [Float](repeating: 0, count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = Float(pixelData[offset]) / 255.0
                let g = Float(pixelData[offset + 1]) / 255.0
                let b = Float(pixelData[offset + 2]) / 255.0
                // Convert to grayscale using luminance formula
                heightMap[y][x] = 0.299 * r + 0.587 * g + 0.114 * b
            }
        }

        // Create normal map using Sobel operator
        var normalData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        // Sobel kernels for X and Y gradients
        let strength: Float = 2.0  // Normal map strength

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                // Sobel X kernel
                let dx = (heightMap[y - 1][x + 1] - heightMap[y - 1][x - 1]) +
                         2.0 * (heightMap[y][x + 1] - heightMap[y][x - 1]) +
                         (heightMap[y + 1][x + 1] - heightMap[y + 1][x - 1])

                // Sobel Y kernel
                let dy = (heightMap[y + 1][x - 1] - heightMap[y - 1][x - 1]) +
                         2.0 * (heightMap[y + 1][x] - heightMap[y - 1][x]) +
                         (heightMap[y + 1][x + 1] - heightMap[y - 1][x + 1])

                // Create normal vector
                var nx = -dx * strength
                var ny = -dy * strength
                var nz: Float = 1.0

                // Normalize the vector
                let length = sqrt(nx * nx + ny * ny + nz * nz)
                if length > 0 {
                    nx /= length
                    ny /= length
                    nz /= length
                }

                // Convert from [-1, 1] to [0, 255]
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                normalData[offset] = UInt8((nx * 0.5 + 0.5) * 255.0)     // R = X
                normalData[offset + 1] = UInt8((ny * 0.5 + 0.5) * 255.0) // G = Y
                normalData[offset + 2] = UInt8((nz * 0.5 + 0.5) * 255.0) // B = Z
                normalData[offset + 3] = 255                              // A = 1
            }
        }

        // Handle edges (copy nearest computed values)
        for x in 0..<width {
            // Top and bottom edges
            let topOffset = x * bytesPerPixel
            let secondRowOffset = bytesPerRow + x * bytesPerPixel
            for i in 0..<4 { normalData[topOffset + i] = normalData[secondRowOffset + i] }

            let bottomOffset = (height - 1) * bytesPerRow + x * bytesPerPixel
            let secondLastRowOffset = (height - 2) * bytesPerRow + x * bytesPerPixel
            for i in 0..<4 { normalData[bottomOffset + i] = normalData[secondLastRowOffset + i] }
        }
        for y in 0..<height {
            // Left and right edges
            let leftOffset = y * bytesPerRow
            let secondColOffset = y * bytesPerRow + bytesPerPixel
            for i in 0..<4 { normalData[leftOffset + i] = normalData[secondColOffset + i] }

            let rightOffset = y * bytesPerRow + (width - 1) * bytesPerPixel
            let secondLastColOffset = y * bytesPerRow + (width - 2) * bytesPerPixel
            for i in 0..<4 { normalData[rightOffset + i] = normalData[secondLastColOffset + i] }
        }

        // Create CGImage from normal data
        guard let normalContext = CGContext(
            data: &normalData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: .deviceRGB,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        ) else { return nil }

        guard let normalCGImage = normalContext.makeImage() else { return nil }

        return SKTexture(cgImage: normalCGImage)
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
        // Manually update layer since didSet isn't called during init
        updateLayerBounds()
        updateLayerContents()
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
        layer.backgroundColor = color.cgColor
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
