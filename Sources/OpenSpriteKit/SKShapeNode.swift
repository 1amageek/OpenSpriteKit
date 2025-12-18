// SKShapeNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(QuartzCore)
import QuartzCore
#else
import OpenCoreAnimation
#endif

/// A mathematical shape that can be stroked or filled.
///
/// `SKShapeNode` allows you to create onscreen graphical elements from mathematical points, lines, and curves.
/// The advantage this has over rasterized graphics, such as those displayed by textures, is that shapes are
/// rasterized dynamically at runtime to produce crisp detail and smoother edges.
open class SKShapeNode: SKNode {

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
    open var path: CGPath? {
        didSet {
            shapeLayer.path = path
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
    open var fillTexture: SKTexture?

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
    open var strokeTexture: SKTexture?

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
    open var lineLength: CGFloat {
        // TODO: Calculate actual line length from path
        return 0.0
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
            // TODO: Center the path
            self.path = path
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

    /// Creates a shape node from a series of spline points.
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
        // TODO: Implement spline interpolation
        let path = CGMutablePath()
        path.move(to: splinePoints[0])
        for i in 1..<count {
            path.addLine(to: splinePoints[i])
        }
        self.path = path
    }

    public required init?(coder: NSCoder) {
        lineWidth = CGFloat(coder.decodeDouble(forKey: "lineWidth"))
        glowWidth = CGFloat(coder.decodeDouble(forKey: "glowWidth"))
        lineCap = CGLineCap(rawValue: Int32(coder.decodeInteger(forKey: "lineCap"))) ?? .butt
        lineJoin = CGLineJoin(rawValue: Int32(coder.decodeInteger(forKey: "lineJoin"))) ?? .miter
        miterLimit = CGFloat(coder.decodeDouble(forKey: "miterLimit"))
        isAntialiased = coder.decodeBool(forKey: "isAntialiased")
        blendMode = SKBlendMode(rawValue: coder.decodeInteger(forKey: "blendMode")) ?? .alpha
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(lineWidth), forKey: "lineWidth")
        coder.encode(Double(glowWidth), forKey: "glowWidth")
        coder.encode(Int(lineCap.rawValue), forKey: "lineCap")
        coder.encode(Int(lineJoin.rawValue), forKey: "lineJoin")
        coder.encode(Double(miterLimit), forKey: "miterLimit")
        coder.encode(isAntialiased, forKey: "isAntialiased")
        coder.encode(blendMode.rawValue, forKey: "blendMode")
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

// MARK: - SKColor CGColor Extension (for WASM)

#if !canImport(UIKit) && !canImport(AppKit)
extension SKColor {
    /// Returns a CGColor representation of this color.
    public var cgColor: CGColor {
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
