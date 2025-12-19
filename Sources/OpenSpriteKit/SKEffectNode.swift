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

    // MARK: - Internal Rendering State

    /// Cached filtered image when shouldRasterize is true.
    internal var _cachedFilteredImage: CGImage?

    /// Flag indicating the cache needs to be invalidated.
    internal var _needsFilterUpdate: Bool = true

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

    // MARK: - Filter Application

    /// Invalidates the cached filter result.
    ///
    /// Call this when the node tree changes and needs to be re-rendered.
    internal func invalidateFilterCache() {
        _cachedFilteredImage = nil
        _needsFilterUpdate = true
    }

    /// Applies the filter to the input image.
    ///
    /// - Parameter inputImage: The image to filter.
    /// - Returns: The filtered image, or the input image if no filter is applied.
    internal func applyFilter(to inputImage: CGImage) -> CGImage? {
        guard shouldEnableEffects, let ciFilter = filter else {
            return inputImage
        }

        // Create CIImage from CGImage
        let ciInput = CIImage(cgImage: inputImage)

        // Set the input image on the filter
        ciFilter.setValue(ciInput, forKey: kCIInputImageKey)

        // Set center if required
        if shouldCenterFilter {
            let center = CIVector(
                x: ciInput.extent.midX,
                y: ciInput.extent.midY
            )
            if ciFilter.inputKeys.contains(kCIInputCenterKey) {
                ciFilter.setValue(center, forKey: kCIInputCenterKey)
            }
        }

        // Get output image
        guard let outputCIImage = ciFilter.outputImage else {
            return inputImage
        }

        // Create a CIContext to render the filtered image
        let context = CIContext(options: nil)

        // Render to CGImage
        guard let outputCGImage = context.createCGImage(
            outputCIImage,
            from: outputCIImage.extent
        ) else {
            return inputImage
        }

        // Cache if rasterization is enabled
        if shouldRasterize {
            _cachedFilteredImage = outputCGImage
            _needsFilterUpdate = false
        }

        return outputCGImage
    }

    /// Renders children to an offscreen buffer and returns the resulting image.
    ///
    /// - Parameter size: The size of the output image.
    /// - Returns: A CGImage containing the rendered children.
    internal func renderChildrenToImage(size: CGSize) -> CGImage? {
        guard !children.isEmpty else { return nil }

        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0 && height > 0 else { return nil }

        #if canImport(UIKit) || canImport(AppKit)
        // Native platforms: Use CGContext with hardware acceleration
        return renderChildrenToImageNative(width: width, height: height)
        #else
        // WASM: Use software compositing
        return renderChildrenToImageWASM(width: width, height: height)
        #endif
    }

    #if canImport(UIKit) || canImport(AppKit)
    /// Native platform implementation using CGContext.
    private func renderChildrenToImageNative(width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let colorSpace = CGColorSpaceCreateDeviceRGB() as CGColorSpace?,
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        // Clear context
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        // Render each child
        for child in children {
            renderNodeToContext(child, context: context)
        }

        return context.makeImage()
    }

    /// Recursively renders a node to the given context.
    private func renderNodeToContext(_ node: SKNode, context: CGContext) {
        guard !node.isHidden && node.alpha > 0 else { return }

        context.saveGState()

        // Apply node transform
        context.translateBy(x: node.position.x, y: node.position.y)
        context.rotate(by: node.zRotation)
        context.scaleBy(x: node.xScale, y: node.yScale)
        context.setAlpha(node.alpha)

        // Render based on node type
        if let sprite = node as? SKSpriteNode {
            renderSpriteNode(sprite, to: context)
        } else if let shape = node as? SKShapeNode {
            renderShapeNode(shape, to: context)
        }

        // Render children
        let sortedChildren = node.children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            renderNodeToContext(child, context: context)
        }

        context.restoreGState()
    }

    /// Renders a sprite node to the context.
    private func renderSpriteNode(_ sprite: SKSpriteNode, to context: CGContext) {
        guard let cgImage = sprite.texture?.cgImage else { return }

        let size = sprite.size
        let anchorPoint = sprite.anchorPoint

        let rect = CGRect(
            x: -size.width * anchorPoint.x,
            y: -size.height * anchorPoint.y,
            width: size.width,
            height: size.height
        )

        context.draw(cgImage, in: rect)
    }

    /// Renders a shape node to the context.
    private func renderShapeNode(_ shape: SKShapeNode, to context: CGContext) {
        guard let path = shape.path else { return }

        context.addPath(path)

        if shape.fillColor != .clear {
            context.setFillColor(shape.fillColor.cgColor)
            context.fillPath()
            context.addPath(path)
        }

        if shape.strokeColor != .clear && shape.lineWidth > 0 {
            context.setStrokeColor(shape.strokeColor.cgColor)
            context.setLineWidth(shape.lineWidth)
            context.strokePath()
        }
    }
    #endif

    // MARK: - WASM Software Compositing

    #if !canImport(UIKit) && !canImport(AppKit)
    /// WASM implementation using software compositing.
    ///
    /// This method directly composites child node images without relying on
    /// CGContext.draw() which requires a renderer delegate in OpenCoreGraphics.
    private func renderChildrenToImageWASM(width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

        // Collect and composite all child nodes
        let sortedChildren = children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            compositeNodeWASM(child, into: &pixelData, width: width, height: height, bytesPerRow: bytesPerRow)
        }

        // Create CGImage from pixel data
        guard let colorSpace = CGColorSpaceCreateDeviceRGB() as CGColorSpace? else {
            return nil
        }

        let dataProvider = CGDataProvider(data: Data(pixelData) as CFData)
        guard let provider = dataProvider else { return nil }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Composites a node and its children into the pixel buffer.
    private func compositeNodeWASM(_ node: SKNode, into pixelData: inout [UInt8],
                                    width: Int, height: Int, bytesPerRow: Int,
                                    parentTransform: CGAffineTransform = .identity,
                                    parentAlpha: CGFloat = 1.0) {
        guard !node.isHidden && node.alpha > 0 else { return }

        // Calculate accumulated transform
        var transform = parentTransform
        transform = transform.translatedBy(x: node.position.x, y: node.position.y)
        transform = transform.rotated(by: node.zRotation)
        transform = transform.scaledBy(x: node.xScale, y: node.yScale)

        let alpha = parentAlpha * node.alpha

        // Composite based on node type
        if let sprite = node as? SKSpriteNode {
            compositeSpriteWASM(sprite, into: &pixelData, width: width, height: height,
                               bytesPerRow: bytesPerRow, transform: transform, alpha: alpha)
        }
        // Shape nodes would require path rasterization - skip for now

        // Composite children
        let sortedChildren = node.children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            compositeNodeWASM(child, into: &pixelData, width: width, height: height,
                             bytesPerRow: bytesPerRow, parentTransform: transform, parentAlpha: alpha)
        }
    }

    /// Composites a sprite node into the pixel buffer using software rendering.
    private func compositeSpriteWASM(_ sprite: SKSpriteNode, into pixelData: inout [UInt8],
                                      width: Int, height: Int, bytesPerRow: Int,
                                      transform: CGAffineTransform, alpha: CGFloat) {
        guard let cgImage = sprite.texture?.cgImage else { return }

        // Get source image data
        let srcWidth = cgImage.width
        let srcHeight = cgImage.height
        guard srcWidth > 0 && srcHeight > 0 else { return }

        guard let srcData = cgImage.dataProvider?.data,
              let srcBytes = CFDataGetBytePtr(srcData) else { return }

        let srcBytesPerRow = cgImage.bytesPerRow
        let srcBytesPerPixel = cgImage.bitsPerPixel / 8

        // Calculate destination rect (accounting for anchor point)
        let dstWidth = sprite.size.width
        let dstHeight = sprite.size.height
        let anchorX = sprite.anchorPoint.x
        let anchorY = sprite.anchorPoint.y

        // Sample the source image and composite into destination
        for dy in 0..<height {
            for dx in 0..<width {
                // Transform destination point back to sprite local coordinates
                let dstPoint = CGPoint(x: CGFloat(dx), y: CGFloat(dy))
                let localPoint = dstPoint.applying(transform.inverted())

                // Check if point is within sprite bounds (accounting for anchor)
                let spriteMinX = -dstWidth * anchorX
                let spriteMaxX = dstWidth * (1 - anchorX)
                let spriteMinY = -dstHeight * anchorY
                let spriteMaxY = dstHeight * (1 - anchorY)

                guard localPoint.x >= spriteMinX && localPoint.x < spriteMaxX &&
                      localPoint.y >= spriteMinY && localPoint.y < spriteMaxY else {
                    continue
                }

                // Map to source texture coordinates
                let u = (localPoint.x - spriteMinX) / dstWidth
                let v = (localPoint.y - spriteMinY) / dstHeight

                let srcX = Int(u * CGFloat(srcWidth))
                let srcY = Int((1 - v) * CGFloat(srcHeight))  // Flip Y for image coordinates

                guard srcX >= 0 && srcX < srcWidth && srcY >= 0 && srcY < srcHeight else {
                    continue
                }

                // Read source pixel
                let srcOffset = srcY * srcBytesPerRow + srcX * srcBytesPerPixel
                guard srcOffset + 3 < CFDataGetLength(srcData) else { continue }

                let srcR = CGFloat(srcBytes[srcOffset]) / 255.0
                let srcG = CGFloat(srcBytes[srcOffset + 1]) / 255.0
                let srcB = CGFloat(srcBytes[srcOffset + 2]) / 255.0
                let srcA = srcBytesPerPixel > 3 ? CGFloat(srcBytes[srcOffset + 3]) / 255.0 : 1.0

                // Apply alpha
                let finalAlpha = srcA * alpha

                // Read destination pixel
                let dstOffset = dy * bytesPerRow + dx * 4
                let dstR = CGFloat(pixelData[dstOffset]) / 255.0
                let dstG = CGFloat(pixelData[dstOffset + 1]) / 255.0
                let dstB = CGFloat(pixelData[dstOffset + 2]) / 255.0
                let dstA = CGFloat(pixelData[dstOffset + 3]) / 255.0

                // Alpha compositing (Porter-Duff over)
                let outA = finalAlpha + dstA * (1 - finalAlpha)
                if outA > 0 {
                    let outR = (srcR * finalAlpha + dstR * dstA * (1 - finalAlpha)) / outA
                    let outG = (srcG * finalAlpha + dstG * dstA * (1 - finalAlpha)) / outA
                    let outB = (srcB * finalAlpha + dstB * dstA * (1 - finalAlpha)) / outA

                    pixelData[dstOffset] = UInt8(min(255, max(0, outR * 255)))
                    pixelData[dstOffset + 1] = UInt8(min(255, max(0, outG * 255)))
                    pixelData[dstOffset + 2] = UInt8(min(255, max(0, outB * 255)))
                    pixelData[dstOffset + 3] = UInt8(min(255, max(0, outA * 255)))
                }
            }
        }
    }
    #endif
}
