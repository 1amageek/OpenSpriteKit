// SKShapeNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A mathematical shape that can be stroked or filled.
///
/// `SKShapeNode` allows you to create onscreen graphical elements from mathematical points, lines, and curves.
/// The advantage this has over rasterized graphics, such as those displayed by textures, is that shapes are
/// rasterized dynamically at runtime to produce crisp detail and smoother edges.
open class SKShapeNode: SKNode, @unchecked Sendable {

    // MARK: - Layer Class Override

    /// Returns CAShapeLayer as the backing layer class.
    open override class var layerClass: CALayer.Type {
        return CAShapeLayer.self
    }

    /// The backing CAShapeLayer for rendering.
    public var shapeLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }

    // MARK: - Path Property

    /// The path that defines the shape.
    private var _skPath: CGPath?
    open var path: CGPath? {
        get { return _skPath }
        set {
            _skPath = newValue
            shapeLayer.path = newValue
        }
    }

    // MARK: - Fill Properties

    /// The color used to fill the shape.
    open var fillColor: SKColor = .clear {
        didSet {
            shapeLayer.fillColor = fillColor.cgColor
        }
    }

    /// The texture used to fill the shape.
    open var fillTexture: SKTexture? {
        didSet {
            updateFillWithTexture()
        }
    }

    /// A custom shader used to determine the color of the filled portion of the shape node.
    open var fillShader: SKShader?

    // MARK: - Stroke Properties

    /// The width used to stroke the path.
    open var lineWidth: CGFloat = 1.0 {
        didSet {
            shapeLayer.lineWidth = lineWidth
        }
    }

    /// The color used to stroke the shape.
    open var strokeColor: SKColor = .white {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }

    /// The texture used to stroke the shape.
    open var strokeTexture: SKTexture? {
        didSet {
            updateStrokeWithTexture()
        }
    }

    /// A custom shader used to determine the color of the stroked portion of the shape node.
    open var strokeShader: SKShader?

    /// A glow that extends outward from the stroked line.
    open var glowWidth: CGFloat = 0.0

    /// The style used to render the endpoints of the stroked portion of the shape node.
    open var lineCap: CGLineCap = .butt {
        didSet {
            shapeLayer.lineCap = CAShapeLayerLineCap(from: lineCap)
        }
    }

    /// The junction type used when the stroked portion of the shape node is rendered.
    open var lineJoin: CGLineJoin = .miter {
        didSet {
            shapeLayer.lineJoin = CAShapeLayerLineJoin(from: lineJoin)
        }
    }

    /// The miter limit to use when the line is stroked using a miter join style.
    open var miterLimit: CGFloat = 10.0 {
        didSet {
            shapeLayer.miterLimit = miterLimit
        }
    }

    /// A Boolean value that determines whether the stroked path is smoothed when drawn.
    open var isAntialiased: Bool = true

    /// The length of the line defined by the shape node.
    ///
    /// This property calculates the total length of all line segments and curves in the path.
    open var lineLength: CGFloat {
        guard let path = path else { return 0.0 }
        return Self.calculatePathLength(path)
    }

    /// Calculates the total length of a CGPath.
    private static func calculatePathLength(_ path: CGPath) -> CGFloat {
        var totalLength: CGFloat = 0.0
        var currentPoint: CGPoint = .zero
        var subpathStart: CGPoint = .zero

        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                guard let pts = element.pointee.points else { return }
                currentPoint = pts[0]
                subpathStart = currentPoint

            case .addLineToPoint:
                guard let pts = element.pointee.points else { return }
                let endPoint = pts[0]
                let dx = endPoint.x - currentPoint.x
                let dy = endPoint.y - currentPoint.y
                totalLength += sqrt(dx * dx + dy * dy)
                currentPoint = endPoint

            case .addQuadCurveToPoint:
                guard let pts = element.pointee.points else { return }
                let controlPoint = pts[0]
                let endPoint = pts[1]
                totalLength += quadraticBezierLength(
                    start: currentPoint,
                    control: controlPoint,
                    end: endPoint
                )
                currentPoint = endPoint

            case .addCurveToPoint:
                guard let pts = element.pointee.points else { return }
                let control1 = pts[0]
                let control2 = pts[1]
                let endPoint = pts[2]
                totalLength += cubicBezierLength(
                    start: currentPoint,
                    control1: control1,
                    control2: control2,
                    end: endPoint
                )
                currentPoint = endPoint

            case .closeSubpath:
                let dx = subpathStart.x - currentPoint.x
                let dy = subpathStart.y - currentPoint.y
                totalLength += sqrt(dx * dx + dy * dy)
                currentPoint = subpathStart

            @unknown default:
                break
            }
        }

        return totalLength
    }

    /// Calculates the approximate length of a quadratic Bezier curve.
    private static func quadraticBezierLength(start: CGPoint, control: CGPoint, end: CGPoint) -> CGFloat {
        // Use adaptive subdivision for accurate length
        let segments = 20
        var length: CGFloat = 0.0
        var prevPoint = start

        for i in 1...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let invT = 1 - t

            let point = CGPoint(
                x: invT * invT * start.x + 2 * invT * t * control.x + t * t * end.x,
                y: invT * invT * start.y + 2 * invT * t * control.y + t * t * end.y
            )

            let dx = point.x - prevPoint.x
            let dy = point.y - prevPoint.y
            length += sqrt(dx * dx + dy * dy)
            prevPoint = point
        }

        return length
    }

    /// Calculates the approximate length of a cubic Bezier curve.
    private static func cubicBezierLength(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) -> CGFloat {
        // Use adaptive subdivision for accurate length
        let segments = 20
        var length: CGFloat = 0.0
        var prevPoint = start

        for i in 1...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let invT = 1 - t

            let point = CGPoint(
                x: invT * invT * invT * start.x + 3 * invT * invT * t * control1.x + 3 * invT * t * t * control2.x + t * t * t * end.x,
                y: invT * invT * invT * start.y + 3 * invT * invT * t * control1.y + 3 * invT * t * t * control2.y + t * t * t * end.y
            )

            let dx = point.x - prevPoint.x
            let dy = point.y - prevPoint.y
            length += sqrt(dx * dx + dy * dy)
            prevPoint = point
        }

        return length
    }

    // MARK: - Blending Properties

    /// The blend mode used to blend the shape into the parent's framebuffer.
    open var blendMode: SKBlendMode = .alpha

    // MARK: - Computed Properties

    /// The calculated frame of the shape node in the parent's coordinate system.
    ///
    /// The frame is calculated from the path's bounding box, accounting for position, scale, and rotation.
    open override var frame: CGRect {
        guard let path = path else {
            return CGRect(origin: position, size: .zero)
        }

        let pathBounds = path.boundingBox

        // Apply scale
        let scaledWidth = pathBounds.width * abs(xScale)
        let scaledHeight = pathBounds.height * abs(yScale)
        let scaledOriginX = pathBounds.origin.x * xScale
        let scaledOriginY = pathBounds.origin.y * yScale

        // If no rotation, simple bounding box
        if zRotation == 0 {
            return CGRect(
                x: position.x + scaledOriginX,
                y: position.y + scaledOriginY,
                width: scaledWidth,
                height: scaledHeight
            )
        }

        // With rotation, calculate the bounding box of the rotated rectangle
        let cosVal = Foundation.cos(Double(zRotation))
        let sinVal = Foundation.sin(Double(zRotation))

        // Calculate the four corners of the scaled path bounds
        let corners = [
            CGPoint(x: scaledOriginX, y: scaledOriginY),
            CGPoint(x: scaledOriginX + scaledWidth, y: scaledOriginY),
            CGPoint(x: scaledOriginX + scaledWidth, y: scaledOriginY + scaledHeight),
            CGPoint(x: scaledOriginX, y: scaledOriginY + scaledHeight)
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

    // MARK: - Shader Attribute Properties

    /// The values of each attribute associated with the node's attached shader.
    open var attributeValues: [String: SKAttributeValue] = [:]

    // MARK: - Initializers

    /// Creates a new shape node.
    public override init() {
        super.init()
        syncShapeLayerProperties()
    }

    /// Syncs all properties to the backing CAShapeLayer after initialization.
    ///
    /// This is necessary because `didSet` observers are not called during
    /// property initialization, so we must manually sync the default values.
    private func syncShapeLayerProperties() {
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = CAShapeLayerLineCap(from: lineCap)
        shapeLayer.lineJoin = CAShapeLayerLineJoin(from: lineJoin)
        shapeLayer.miterLimit = miterLimit
    }

    /// Creates a shape node from a Core Graphics path.
    ///
    /// - Parameter path: The Core Graphics path that defines the shape.
    public convenience init(path: CGPath) {
        self.init()
        self.path = path
    }

    /// Creates a shape node from a Core Graphics path, centered around its position.
    ///
    /// - Parameters:
    ///   - path: The Core Graphics path that defines the shape.
    ///   - centered: If true, the path is centered on the node's position.
    public convenience init(path: CGPath, centered: Bool) {
        self.init()
        if centered {
            // Calculate the center of the path's bounding box
            let bounds = path.boundingBox
            let centerX = bounds.midX
            let centerY = bounds.midY

            // Create a transformed path that's centered at origin
            var transform = CGAffineTransform(translationX: -centerX, y: -centerY)
            if let centeredPath = path.copy(using: &transform) {
                self.path = centeredPath
            } else {
                self.path = path
            }
        } else {
            self.path = path
        }
    }

    /// Creates a shape node with a rectangular path.
    ///
    /// - Parameter rect: The rectangle that defines the shape.
    public convenience init(rect: CGRect) {
        self.init()
        let path = CGMutablePath()
        path.addRect(rect)
        self.path = path
    }

    /// Creates a shape node with a rectangular path centered on the node's origin.
    ///
    /// - Parameter size: The size of the rectangle.
    public convenience init(rectOf size: CGSize) {
        self.init()
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        let path = CGMutablePath()
        path.addRect(rect)
        self.path = path
    }

    /// Creates a shape with a rectangular path that has rounded corners.
    ///
    /// - Parameters:
    ///   - rect: The rectangle that defines the shape.
    ///   - cornerRadius: The radius of the rounded corners.
    public convenience init(rect: CGRect, cornerRadius: CGFloat) {
        self.init()
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        self.path = path
    }

    /// Creates a shape with a rectangular path that has rounded corners centered on the node's position.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle.
    ///   - cornerRadius: The radius of the rounded corners.
    public convenience init(rectOf size: CGSize, cornerRadius: CGFloat) {
        self.init()
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        self.path = path
    }

    /// Creates a shape node with a circular path centered on the node's origin.
    ///
    /// - Parameter radius: The radius of the circle.
    public convenience init(circleOfRadius radius: CGFloat) {
        self.init()
        let rect = CGRect(
            x: -radius,
            y: -radius,
            width: radius * 2,
            height: radius * 2
        )
        let path = CGMutablePath()
        path.addEllipse(in: rect)
        self.path = path
    }

    /// Creates a shape node with an elliptical path centered on the node's origin.
    ///
    /// - Parameter size: The size of the ellipse.
    public convenience init(ellipseOf size: CGSize) {
        self.init()
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        let path = CGMutablePath()
        path.addEllipse(in: rect)
        self.path = path
    }

    /// Creates a shape node with an elliptical path that fills the specified rectangle.
    ///
    /// - Parameter rect: The rectangle to fill with an ellipse.
    public convenience init(ellipseIn rect: CGRect) {
        self.init()
        let path = CGMutablePath()
        path.addEllipse(in: rect)
        self.path = path
    }

    /// Creates a shape node from a series of points.
    ///
    /// - Parameters:
    ///   - points: A pointer to an array of points.
    ///   - count: The number of points in the array.
    public convenience init(points: UnsafeMutablePointer<CGPoint>, count: Int) {
        self.init()
        guard count > 0 else { return }
        let path = CGMutablePath()
        path.move(to: points[0])
        for i in 1..<count {
            path.addLine(to: points[i])
        }
        self.path = path
    }

    /// Creates a shape node from a series of spline points using Catmull-Rom interpolation.
    ///
    /// - Parameters:
    ///   - splinePoints: A pointer to an array of points for the spline.
    ///   - count: The number of points in the array.
    public convenience init(splinePoints: UnsafeMutablePointer<CGPoint>, count: Int) {
        self.init()
        guard count > 2 else {
            // Need at least 3 points for a spline
            if count > 0 {
                let path = CGMutablePath()
                path.move(to: splinePoints[0])
                for i in 1..<count {
                    path.addLine(to: splinePoints[i])
                }
                self.path = path
            }
            return
        }

        // Copy points to array
        var points: [CGPoint] = []
        for i in 0..<count {
            points.append(splinePoints[i])
        }

        // Generate Catmull-Rom spline path
        self.path = Self.createCatmullRomPath(points: points)
    }

    /// Creates a Catmull-Rom spline path through the given points.
    ///
    /// Catmull-Rom splines pass through all control points and provide smooth curves.
    private static func createCatmullRomPath(points: [CGPoint], alpha: CGFloat = 0.5, closed: Bool = false) -> CGPath {
        let path = CGMutablePath()

        guard points.count >= 2 else {
            if let first = points.first {
                path.move(to: first)
            }
            return path
        }

        // For a Catmull-Rom spline, we need 4 points to define each segment
        // We'll extend the endpoints by mirroring
        var extendedPoints = points

        // Add virtual points at the ends for open curves
        if !closed {
            // Mirror first point
            let first = points[0]
            let second = points[1]
            let p0 = CGPoint(
                x: 2 * first.x - second.x,
                y: 2 * first.y - second.y
            )
            extendedPoints.insert(p0, at: 0)

            // Mirror last point
            let last = points[points.count - 1]
            let secondLast = points[points.count - 2]
            let pn = CGPoint(
                x: 2 * last.x - secondLast.x,
                y: 2 * last.y - secondLast.y
            )
            extendedPoints.append(pn)
        }

        // Start the path
        path.move(to: points[0])

        // Generate curve segments
        let segments = 20  // Segments per curve for smoothness

        for i in 1..<extendedPoints.count - 2 {
            let p0 = extendedPoints[i - 1]
            let p1 = extendedPoints[i]
            let p2 = extendedPoints[i + 1]
            let p3 = extendedPoints[i + 2]

            // Generate points along this segment
            for j in 1...segments {
                let t = CGFloat(j) / CGFloat(segments)
                let point = catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t, alpha: alpha)
                path.addLine(to: point)
            }
        }

        if closed {
            path.closeSubpath()
        }

        return path
    }

    /// Calculates a point on a Catmull-Rom spline segment.
    private static func catmullRomPoint(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat, alpha: CGFloat) -> CGPoint {
        // Calculate knot intervals using centripetal parameterization
        func knotInterval(p1: CGPoint, p2: CGPoint) -> CGFloat {
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distSquared = dx * dx + dy * dy
            return pow(distSquared, alpha / 2)
        }

        let t01 = knotInterval(p1: p0, p2: p1)
        let t12 = knotInterval(p1: p1, p2: p2)
        let t23 = knotInterval(p1: p2, p2: p3)

        // Remap t to [0, 1] for this segment
        let m1x = (p1.x - p0.x) / t01 - (p2.x - p0.x) / (t01 + t12) + (p2.x - p1.x) / t12
        let m1y = (p1.y - p0.y) / t01 - (p2.y - p0.y) / (t01 + t12) + (p2.y - p1.y) / t12
        let m2x = (p2.x - p1.x) / t12 - (p3.x - p1.x) / (t12 + t23) + (p3.x - p2.x) / t23
        let m2y = (p2.y - p1.y) / t12 - (p3.y - p1.y) / (t12 + t23) + (p3.y - p2.y) / t23

        let m1 = CGPoint(x: m1x * t12, y: m1y * t12)
        let m2 = CGPoint(x: m2x * t12, y: m2y * t12)

        // Hermite basis functions
        let t2 = t * t
        let t3 = t2 * t

        let h00 = 2 * t3 - 3 * t2 + 1
        let h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 = t3 - t2

        return CGPoint(
            x: h00 * p1.x + h10 * m1.x + h01 * p2.x + h11 * m2.x,
            y: h00 * p1.y + h10 * m1.y + h01 * p2.y + h11 * m2.y
        )
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

    // MARK: - Texture Pattern Support

    /// Content layer for fill texture (WASM-compatible approach)
    private var _fillTextureLayer: CALayer?

    /// Content layer for stroke texture (WASM-compatible approach)
    private var _strokeTextureLayer: CALayer?

    /// Updates the fill color with a pattern from the fill texture.
    private func updateFillWithTexture() {
        guard let texture = fillTexture, let cgImage = texture.cgImage() else {
            // If no texture, revert to solid color and remove texture layer
            shapeLayer.fillColor = fillColor.cgColor
            removeFillTextureLayer()
            return
        }

        // Use layer-based texture tiling
        applyFillTextureViaLayer(cgImage)
    }

    /// Updates the stroke color with a pattern from the stroke texture.
    private func updateStrokeWithTexture() {
        guard let texture = strokeTexture, let cgImage = texture.cgImage() else {
            // If no texture, revert to solid color and remove texture layer
            shapeLayer.strokeColor = strokeColor.cgColor
            removeStrokeTextureLayer()
            return
        }

        // Use layer-based texture tiling
        applyStrokeTextureViaLayer(cgImage)
    }

    // MARK: - Texture Layer Methods

    /// Applies fill texture using a tiled layer (WASM-compatible).
    private func applyFillTextureViaLayer(_ image: CGImage) {
        guard let path = path else {
            removeFillTextureLayer()
            return
        }

        // Clear the fill color on the shape layer
        shapeLayer.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

        // Get the path bounds
        let pathBounds = path.boundingBox

        // Create or update the texture layer
        let textureLayer: CALayer
        if let existing = _fillTextureLayer {
            textureLayer = existing
        } else {
            textureLayer = CALayer()
            _fillTextureLayer = textureLayer
            // Insert below the shape layer's stroke
            layer.insertSublayer(textureLayer, at: 0)
        }

        // Create tiled texture image
        if let tiledImage = createTiledImage(from: image, for: pathBounds) {
            textureLayer.contents = tiledImage
            textureLayer.frame = pathBounds
        }

        // Create a mask from the path
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        maskLayer.strokeColor = nil
        maskLayer.frame = pathBounds
        // Offset the path to account for the mask's coordinate space
        let offsetPath = CGMutablePath()
        var transform = CGAffineTransform(translationX: -pathBounds.origin.x, y: -pathBounds.origin.y)
        if let transformedPath = path.copy(using: &transform) {
            offsetPath.addPath(transformedPath)
        }
        maskLayer.path = offsetPath

        textureLayer.mask = maskLayer
    }

    /// Applies stroke texture using a layer (WASM-compatible).
    private func applyStrokeTextureViaLayer(_ image: CGImage) {
        guard let path = path else {
            removeStrokeTextureLayer()
            return
        }

        // Clear the stroke color on the shape layer
        shapeLayer.strokeColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

        // Get the stroked path bounds (account for line width)
        let strokeBounds = path.boundingBox.insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2)

        // Create or update the texture layer
        let textureLayer: CALayer
        if let existing = _strokeTextureLayer {
            textureLayer = existing
        } else {
            textureLayer = CALayer()
            _strokeTextureLayer = textureLayer
            layer.addSublayer(textureLayer)
        }

        // Create tiled texture image
        if let tiledImage = createTiledImage(from: image, for: strokeBounds) {
            textureLayer.contents = tiledImage
            textureLayer.frame = strokeBounds
        }

        // Create a stroke mask from the path
        let maskLayer = CAShapeLayer()
        maskLayer.fillColor = nil
        maskLayer.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        maskLayer.lineWidth = lineWidth
        maskLayer.lineCap = CAShapeLayerLineCap(from: lineCap)
        maskLayer.lineJoin = CAShapeLayerLineJoin(from: lineJoin)
        maskLayer.frame = strokeBounds

        // Offset the path for mask coordinate space
        let offsetPath = CGMutablePath()
        var transform = CGAffineTransform(translationX: -strokeBounds.origin.x, y: -strokeBounds.origin.y)
        if let transformedPath = path.copy(using: &transform) {
            offsetPath.addPath(transformedPath)
        }
        maskLayer.path = offsetPath

        textureLayer.mask = maskLayer
    }

    /// Creates a tiled image that covers the given bounds.
    private func createTiledImage(from image: CGImage, for bounds: CGRect) -> CGImage? {
        let tileWidth = image.width
        let tileHeight = image.height
        guard tileWidth > 0 && tileHeight > 0 else { return nil }

        let boundsWidth = Int(ceil(bounds.width))
        let boundsHeight = Int(ceil(bounds.height))
        guard boundsWidth > 0 && boundsHeight > 0 else { return nil }

        // Create a bitmap context for the tiled result
        let bytesPerPixel = 4
        let bytesPerRow = boundsWidth * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * boundsHeight)

        guard let colorSpace = .deviceRGB as CGColorSpace?,
              let context = CGContext(
                  data: &pixelData,
                  width: boundsWidth,
                  height: boundsHeight,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
              ) else {
            return nil
        }

        // Tile the image across the context
        let tilesX = (boundsWidth + tileWidth - 1) / tileWidth
        let tilesY = (boundsHeight + tileHeight - 1) / tileHeight

        for ty in 0..<tilesY {
            for tx in 0..<tilesX {
                let rect = CGRect(
                    x: CGFloat(tx * tileWidth),
                    y: CGFloat(ty * tileHeight),
                    width: CGFloat(tileWidth),
                    height: CGFloat(tileHeight)
                )
                context.draw(image, in: rect)
            }
        }

        return context.makeImage()
    }

    /// Removes the fill texture layer.
    private func removeFillTextureLayer() {
        _fillTextureLayer?.removeFromSuperlayer()
        _fillTextureLayer = nil
    }

    /// Removes the stroke texture layer.
    private func removeStrokeTextureLayer() {
        _strokeTextureLayer?.removeFromSuperlayer()
        _strokeTextureLayer = nil
    }
}

// MARK: - CAShapeLayer Type Conversions

extension CAShapeLayerLineCap {
    init(from lineCap: CGLineCap) {
        switch lineCap {
        case .butt:
            self = .butt
        case .round:
            self = .round
        case .square:
            self = .square
        @unknown default:
            self = .butt
        }
    }
}

extension CAShapeLayerLineJoin {
    init(from lineJoin: CGLineJoin) {
        switch lineJoin {
        case .miter:
            self = .miter
        case .round:
            self = .round
        case .bevel:
            self = .bevel
        @unknown default:
            self = .miter
        }
    }
}
