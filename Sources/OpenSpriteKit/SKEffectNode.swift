// SKEffectNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenFoundation
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
    open var filter: CIFilter? {
        didSet { invalidateFilterCache() }
    }

    /// A Boolean value that determines whether the effect node applies the filter to its children as they are drawn.
    open var shouldEnableEffects: Bool = false {
        didSet { invalidateFilterCache() }
    }

    /// A Boolean value that determines whether the effect node automatically sets the filter's image center.
    open var shouldCenterFilter: Bool = true {
        didSet { invalidateFilterCache() }
    }

    // MARK: - Shader Properties

    /// A custom shader that is called when the effect node is blended into the parent's framebuffer.
    open var shader: SKShader? {
        didSet { invalidateFilterCache() }
    }

    /// The values of each attribute associated with the node's attached shader.
    open var attributeValues: [String: SKAttributeValue] = [:] {
        didSet { invalidateFilterCache() }
    }

    // MARK: - Rasterization Properties

    /// A Boolean value that indicates whether the results of rendering the child nodes should be cached.
    open var shouldRasterize: Bool = false {
        didSet { invalidateFilterCache() }
    }

    // MARK: - Internal Rendering State

    /// Cached filtered image when shouldRasterize is true.
    internal var _cachedFilteredImage: CGImage?

    /// Flag indicating the cache needs to be invalidated.
    internal var _needsFilterUpdate: Bool = true

    /// Generation used to discard an asynchronous result when configuration
    /// changes while WebGPU work is suspended.
    internal private(set) var _filterRevision: UInt64 = 0

    /// The mutable filter revision captured by the cached framebuffer.
    internal private(set) var _renderedFilterConfigurationRevision: UInt64?

    // MARK: - Blend Mode

    /// The blend mode used to draw the node's contents into its parent's framebuffer.
    open var blendMode: SKBlendMode = .alpha {
        didSet { invalidateFilterCache() }
    }

    // MARK: - SKWarpable Conformance

    /// The warp geometry applied to this node.
    open var warpGeometry: SKWarpGeometry? {
        didSet { invalidateFilterCache() }
    }

    /// The subdivisions used when rendering warped geometry.
    open var subdivisionLevels: Int = 1 {
        didSet { invalidateFilterCache() }
    }

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - Copying

    /// Creates a copy of this effect node.
    open override func copy() -> SKNode {
        let effectCopy = SKEffectNode()
        effectCopy._copyNodeProperties(from: self)
        return effectCopy
    }

    /// Internal helper to copy SKEffectNode properties.
    internal override func _copyNodeProperties(from node: SKNode) {
        super._copyNodeProperties(from: node)
        guard let effectNode = node as? SKEffectNode else { return }

        self.filter = effectNode.filter
        self.shouldEnableEffects = effectNode.shouldEnableEffects
        self.shouldCenterFilter = effectNode.shouldCenterFilter
        self.shader = effectNode.shader
        self.attributeValues = effectNode.attributeValues
        self.shouldRasterize = effectNode.shouldRasterize
        self.blendMode = effectNode.blendMode
        self.warpGeometry = effectNode.warpGeometry
        self.subdivisionLevels = effectNode.subdivisionLevels
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
        _filterRevision &+= 1
        _cachedFilteredImage = nil
        _renderedFilterConfigurationRevision = nil
        _needsFilterUpdate = true
        layer.contents = nil
        for child in children {
            child.layer.isHidden = child.isHidden
        }
    }

    /// Builds the immutable Core Image recipe for the configured filter.
    ///
    /// - Parameter inputImage: The image to filter.
    /// - Returns: The filter output recipe. Evaluation belongs to the renderer.
    /// - Throws: A typed renderer error when an enabled filter cannot produce output.
    internal func filteredImageRecipe(for inputImage: CGImage) throws -> CIImage {
        guard shouldEnableEffects else {
            throw SKRendererError.imageProcessingFailed("SKEffectNode filter evaluation was requested while effects were disabled")
        }
        guard let ciFilter = filter else {
            throw SKRendererError.imageProcessingFailed("SKEffectNode has effects enabled but no filter")
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

        guard let outputCIImage = ciFilter.outputImage else {
            throw SKRendererError.imageProcessingFailed("Core Image filter \(ciFilter.name) produced no output image")
        }
        return outputCIImage
    }

    /// Commits a successfully rendered filter result.
    internal func storeFilteredImage(_ image: CGImage, filterRevision: UInt64) {
        _cachedFilteredImage = image
        _renderedFilterConfigurationRevision = filterRevision
        _needsFilterUpdate = false
    }

    /// The child-tree bounds in this effect node's local coordinate system.
    internal var filterContentFrame: CGRect {
        children.reduce(CGRect.null) { accumulated, child in
            accumulated.union(child.calculateAccumulatedFrame())
        }
    }

    /// Renders children to an offscreen buffer and returns the resulting image.
    ///
    /// - Parameter frame: The child bounds in this effect node's local space.
    /// - Returns: A CGImage containing the rendered children.
    internal func renderChildrenToImage(in frame: CGRect) -> CGImage? {
        guard !children.isEmpty, !frame.isNull, !frame.isEmpty else { return nil }

        let width = Int(ceil(frame.width))
        let height = Int(ceil(frame.height))
        guard width > 0 && height > 0 else { return nil }

        let bytesPerRow = width * 4
        var pixelData = Data(count: bytesPerRow * height)
        return pixelData.withUnsafeMutableBytes { buffer -> CGImage? in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: .deviceRGB,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            ) else {
                return nil
            }

            context.clear(CGRect(x: 0, y: 0, width: width, height: height))
            context.translateBy(x: -frame.minX, y: -frame.minY)

            var renderItems: [EffectNodeRenderItem] = []
            for child in children {
                collectNodesForEffectRendering(
                    node: child,
                    accumulatedZ: 0,
                    accumulatedAlpha: 1,
                    accumulatedTransform: .identity,
                    items: &renderItems
                )
            }
            renderItems.sort { lhs, rhs in
                if lhs.accumulatedZ != rhs.accumulatedZ {
                    return lhs.accumulatedZ < rhs.accumulatedZ
                }
                return lhs.treeOrder < rhs.treeOrder
            }

            for item in renderItems {
                render(item, to: context)
            }
            return context.makeImage()
        }
    }

    /// Information needed to render a node with proper z-ordering.
    private struct EffectNodeRenderItem {
        let node: SKNode
        let accumulatedZ: CGFloat
        let accumulatedAlpha: CGFloat
        let accumulatedTransform: CGAffineTransform
        let treeOrder: Int
    }

    /// Collects all visible nodes with their accumulated properties for sorted rendering.
    private func collectNodesForEffectRendering(
        node: SKNode,
        accumulatedZ: CGFloat,
        accumulatedAlpha: CGFloat,
        accumulatedTransform: CGAffineTransform,
        items: inout [EffectNodeRenderItem]
    ) {
        guard !node.isHidden && node.alpha > 0 else { return }

        let nodeZ = accumulatedZ + node.zPosition
        let nodeAlpha = accumulatedAlpha * node.alpha

        // Build the transform for this node
        var nodeTransform = accumulatedTransform
        nodeTransform = nodeTransform.translatedBy(x: node.position.x, y: node.position.y)
        nodeTransform = nodeTransform.rotated(by: node.zRotation)
        nodeTransform = nodeTransform.scaledBy(x: node.xScale, y: node.yScale)

        // Add this node to the list
        let treeOrder = items.count
        items.append(EffectNodeRenderItem(
            node: node,
            accumulatedZ: nodeZ,
            accumulatedAlpha: nodeAlpha,
            accumulatedTransform: nodeTransform,
            treeOrder: treeOrder
        ))

        // A prepared nested effect is already a flattened framebuffer. Its
        // descendants must not also be drawn into the parent effect.
        if let effectNode = node as? SKEffectNode,
           effectNode.shouldEnableEffects,
           effectNode._cachedFilteredImage != nil {
            return
        }

        // Collect children sorted by local zPosition (for deterministic sibling order)
        let sortedChildren = node.children.sorted { $0.zPosition < $1.zPosition }
        for child in sortedChildren {
            collectNodesForEffectRendering(
                node: child,
                accumulatedZ: nodeZ,
                accumulatedAlpha: nodeAlpha,
                accumulatedTransform: nodeTransform,
                items: &items
            )
        }
    }

    /// Renders one flattened item into the effect's private framebuffer.
    private func render(_ item: EffectNodeRenderItem, to context: CGContext) {
        let node = item.node
        context.saveGState()
        context.concatenate(item.accumulatedTransform)
        context.setAlpha(item.accumulatedAlpha)

        if let sprite = node as? SKSpriteNode {
            render(sprite, to: context)
        } else if let shape = node as? SKShapeNode {
            render(shape, to: context)
        } else if let label = node as? SKLabelNode {
            SKSoftwareLabelRenderer.render(label, to: context)
        } else if let effect = node as? SKEffectNode,
                  let image = effect._cachedFilteredImage {
            context.draw(image, in: effect.layer.bounds)
        }
        context.restoreGState()
    }

    private func render(_ sprite: SKSpriteNode, to context: CGContext) {
        guard let image = sprite.texture?.cgImage() else { return }
        let rect = CGRect(
            x: -sprite.size.width * sprite.anchorPoint.x,
            y: -sprite.size.height * sprite.anchorPoint.y,
            width: sprite.size.width,
            height: sprite.size.height
        )
        context.draw(image, in: rect)
    }

    private func render(_ shape: SKShapeNode, to context: CGContext) {
        guard let path = shape.path else { return }
        context.addPath(path)
        if shape.fillColor != .clear {
            context.setFillColor(shape.fillColor.cgColor)
            context.fillPath()
            context.addPath(path)
        }
        if shape.strokeColor != .clear, shape.lineWidth > 0 {
            context.setStrokeColor(shape.strokeColor.cgColor)
            context.setLineWidth(shape.lineWidth)
            context.setLineCap(shape.lineCap)
            context.setLineJoin(shape.lineJoin)
            context.strokePath()
        }
    }

    // MARK: - Convenience Filter Methods

    /// Applies a Gaussian blur effect to the node's children.
    ///
    /// - Parameter radius: The blur radius in points. Higher values produce more blur.
    ///
    /// ## Example
    /// ```swift
    /// let effectNode = SKEffectNode()
    /// effectNode.applyGaussianBlur(radius: 10)
    /// effectNode.addChild(spriteNode)
    /// scene.addChild(effectNode)
    /// ```
    open func applyGaussianBlur(radius: CGFloat) {
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        self.filter = blurFilter
        self.shouldEnableEffects = true
    }

    /// Applies a color adjustment effect to the node's children.
    ///
    /// - Parameters:
    ///   - saturation: The saturation adjustment (1.0 = original, 0.0 = grayscale, > 1.0 = oversaturated).
    ///   - brightness: The brightness adjustment (-1.0 to 1.0, 0.0 = original).
    ///   - contrast: The contrast adjustment (1.0 = original, < 1.0 = less contrast, > 1.0 = more contrast).
    open func applyColorControls(saturation: CGFloat = 1.0, brightness: CGFloat = 0.0, contrast: CGFloat = 1.0) {
        guard let colorFilter = CIFilter(name: "CIColorControls") else { return }
        colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        colorFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
        self.filter = colorFilter
        self.shouldEnableEffects = true
    }

    /// Applies a sepia tone effect to the node's children.
    ///
    /// - Parameter intensity: The intensity of the sepia effect (0.0 to 1.0).
    open func applySepiaTone(intensity: CGFloat = 1.0) {
        guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return }
        sepiaFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        self.filter = sepiaFilter
        self.shouldEnableEffects = true
    }

    /// Applies a vignette effect to the node's children.
    ///
    /// - Parameters:
    ///   - radius: The radius of the vignette (larger = smaller dark area).
    ///   - intensity: The intensity of the darkening effect.
    open func applyVignette(radius: CGFloat = 1.0, intensity: CGFloat = 0.5) {
        guard let vignetteFilter = CIFilter(name: "CIVignette") else { return }
        vignetteFilter.setValue(radius, forKey: kCIInputRadiusKey)
        vignetteFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        self.filter = vignetteFilter
        self.shouldEnableEffects = true
    }

    /// Applies a pixellate effect to the node's children.
    ///
    /// - Parameter scale: The size of the pixels in the output image.
    open func applyPixellate(scale: CGFloat = 8.0) {
        guard let pixelFilter = CIFilter(name: "CIPixellate") else { return }
        pixelFilter.setValue(scale, forKey: kCIInputScaleKey)
        self.filter = pixelFilter
        self.shouldEnableEffects = true
    }

    /// Applies an exposure adjustment to the node's children.
    ///
    /// - Parameter ev: The exposure value adjustment in EV units.
    open func applyExposureAdjust(ev: CGFloat = 0.5) {
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return }
        exposureFilter.setValue(ev, forKey: kCIInputEVKey)
        self.filter = exposureFilter
        self.shouldEnableEffects = true
    }

    /// Applies a hue adjustment to the node's children.
    ///
    /// - Parameter angle: The hue rotation angle in radians.
    open func applyHueAdjust(angle: CGFloat) {
        guard let hueFilter = CIFilter(name: "CIHueAdjust") else { return }
        hueFilter.setValue(angle, forKey: kCIInputAngleKey)
        self.filter = hueFilter
        self.shouldEnableEffects = true
    }

    /// Applies a color inversion effect to the node's children.
    open func applyColorInvert() {
        guard let invertFilter = CIFilter(name: "CIColorInvert") else { return }
        self.filter = invertFilter
        self.shouldEnableEffects = true
    }

    /// Applies a bloom (glow) effect to the node's children.
    ///
    /// - Parameters:
    ///   - radius: The radius of the bloom effect.
    ///   - intensity: The intensity of the bloom.
    open func applyBloom(radius: CGFloat = 10.0, intensity: CGFloat = 0.5) {
        guard let bloomFilter = CIFilter(name: "CIBloom") else { return }
        bloomFilter.setValue(radius, forKey: kCIInputRadiusKey)
        bloomFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        self.filter = bloomFilter
        self.shouldEnableEffects = true
    }

    /// Applies a crystallize effect to the node's children.
    ///
    /// - Parameter radius: The size of the crystals.
    open func applyCrystallize(radius: CGFloat = 20.0) {
        guard let crystalFilter = CIFilter(name: "CICrystallize") else { return }
        crystalFilter.setValue(radius, forKey: kCIInputRadiusKey)
        self.filter = crystalFilter
        self.shouldEnableEffects = true
    }

    /// Applies a comic effect to the node's children.
    open func applyComicEffect() {
        guard let comicFilter = CIFilter(name: "CIComicEffect") else { return }
        self.filter = comicFilter
        self.shouldEnableEffects = true
    }

    /// Applies an edge detection effect to the node's children.
    ///
    /// - Parameter intensity: The intensity of the edge detection.
    open func applyEdges(intensity: CGFloat = 1.0) {
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return }
        edgeFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        self.filter = edgeFilter
        self.shouldEnableEffects = true
    }

    /// Applies a sharpen effect to the node's children.
    ///
    /// - Parameter sharpness: The amount of sharpening.
    open func applySharpenLuminance(sharpness: CGFloat = 0.4) {
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return }
        sharpenFilter.setValue(sharpness, forKey: kCIInputSharpnessKey)
        self.filter = sharpenFilter
        self.shouldEnableEffects = true
    }

    /// Removes any applied filter effect.
    open func removeFilter() {
        self.filter = nil
        self.shouldEnableEffects = false
        invalidateFilterCache()
    }
}
