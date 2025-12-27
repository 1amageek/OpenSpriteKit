// SKLabelNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// Line break modes for text rendering.
public enum NSLineBreakMode: Int, Sendable, Hashable {
    case byWordWrapping = 0
    case byCharWrapping = 1
    case byClipping = 2
    case byTruncatingHead = 3
    case byTruncatingTail = 4
    case byTruncatingMiddle = 5
}

/// A graphical element that draws text.
///
/// `SKLabelNode` allows you to render text in your scene. You can define a custom style using properties
/// such as `fontName` and `fontColor`, or configure the look of your text with an `NSAttributedString`.
open class SKLabelNode: SKNode, @unchecked Sendable {

    // MARK: - Layer Class Override

    /// Returns CATextLayer as the backing layer class.
    open override class var layerClass: CALayer.Type {
        return CATextLayer.self
    }

    /// The backing CATextLayer for rendering.
    public var textLayer: CATextLayer {
        return layer as! CATextLayer
    }

    // MARK: - Text Properties

    /// The string that the label node displays.
    private var _skText: String?
    open var text: String? {
        get { return _skText }
        set {
            _skText = newValue
            textLayer.string = newValue
            updateLayerBounds()
        }
    }

    /// The attributed string displayed by the label.
    open var attributedText: NSAttributedString? {
        didSet {
            textLayer.string = attributedText
            updateLayerBounds()
        }
    }

    // MARK: - Font Properties

    /// The color of the label.
    open var fontColor: SKColor? = .white {
        didSet {
            textLayer.foregroundColor = fontColor?.cgColor
        }
    }

    /// The font used for the text in the label.
    open var fontName: String? = "Helvetica" {
        didSet {
            #if canImport(QuartzCore)
            textLayer.font = fontName as CFTypeRef?
            #else
            textLayer.font = fontName
            #endif
        }
    }

    /// The size of the font used in the label.
    open var fontSize: CGFloat = 32.0 {
        didSet {
            textLayer.fontSize = fontSize
            updateLayerBounds()
        }
    }

    // MARK: - Layer Bounds

    /// Updates layer bounds based on preferredMaxLayoutWidth.
    ///
    /// Text size measurement is handled by the renderer (CAWebGPURenderer).
    /// If bounds is empty, the renderer will auto-measure text using Canvas2D.
    /// This method only sets bounds width when preferredMaxLayoutWidth is specified
    /// (for multi-line text wrapping).
    private func updateLayerBounds() {
        if preferredMaxLayoutWidth > 0 {
            // Set width for text wrapping - height will be calculated by renderer
            layer.bounds = CGRect(x: 0, y: 0, width: preferredMaxLayoutWidth, height: 0)
        } else {
            // Let renderer auto-measure the text size
            layer.bounds = .zero
        }
    }

    // MARK: - Alignment Properties

    /// The vertical position of the text within the node.
    open var verticalAlignmentMode: SKLabelVerticalAlignmentMode = .baseline

    /// The horizontal position of the text within the node.
    open var horizontalAlignmentMode: SKLabelHorizontalAlignmentMode = .center {
        didSet {
            updateTextLayerAlignment()
        }
    }

    /// Updates the text layer alignment based on horizontal alignment mode.
    private func updateTextLayerAlignment() {
        switch horizontalAlignmentMode {
        case .left:
            textLayer.alignmentMode = .left
        case .center:
            textLayer.alignmentMode = .center
        case .right:
            textLayer.alignmentMode = .right
        }
    }

    // MARK: - Line Breaking Properties

    /// The width, in screen points, after which line-break mode should be applied.
    open var preferredMaxLayoutWidth: CGFloat = 0.0

    /// Determines the line-break mode for multiple lines.
    open var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            updateTextLayerTruncation()
        }
    }

    /// Updates the text layer truncation mode.
    private func updateTextLayerTruncation() {
        switch lineBreakMode {
        case .byWordWrapping, .byCharWrapping, .byClipping:
            textLayer.truncationMode = .none
            textLayer.isWrapped = lineBreakMode == .byWordWrapping || lineBreakMode == .byCharWrapping
        case .byTruncatingHead:
            textLayer.truncationMode = .start
        case .byTruncatingTail:
            textLayer.truncationMode = .end
        case .byTruncatingMiddle:
            textLayer.truncationMode = .middle
        @unknown default:
            textLayer.truncationMode = .none
        }
    }

    /// Determines the number of lines to draw.
    open var numberOfLines: Int = 1

    // MARK: - Color Blend Properties

    /// An alternative to the font color that can be used for animations.
    open var color: SKColor?

    /// A floating-point value that describes how the color is blended with the font color.
    open var colorBlendFactor: CGFloat = 0.0

    // MARK: - Blending Properties

    /// The blend mode used to draw the label into the parent's framebuffer.
    open var blendMode: SKBlendMode = .alpha

    // MARK: - Computed Properties

    /// Estimates the text size based on the current text and font settings.
    ///
    /// This is an approximation since actual text measurement requires platform-specific APIs.
    /// The renderer may calculate the actual size for rendering purposes.
    private func estimatedTextSize() -> CGSize {
        guard let text = text, !text.isEmpty else {
            return .zero
        }

        // Approximate character width as 0.6 * fontSize for typical fonts
        let characterWidthFactor: CGFloat = 0.6
        let lineHeight = fontSize * 1.2

        if preferredMaxLayoutWidth > 0 && (lineBreakMode == .byWordWrapping || lineBreakMode == .byCharWrapping) {
            // Multi-line text: estimate based on wrapping
            let charWidth = fontSize * characterWidthFactor
            let charsPerLine = max(1, Int(preferredMaxLayoutWidth / charWidth))
            let lines = max(1, (text.count + charsPerLine - 1) / charsPerLine)
            let effectiveLines = numberOfLines > 0 ? min(lines, numberOfLines) : lines
            return CGSize(width: preferredMaxLayoutWidth, height: lineHeight * CGFloat(effectiveLines))
        } else {
            // Single line text
            let width = CGFloat(text.count) * fontSize * characterWidthFactor
            return CGSize(width: width, height: lineHeight)
        }
    }

    /// A rectangle in the label's local coordinate system that defines its content area.
    ///
    /// The bounds are calculated from the estimated text size and alignment modes.
    internal override var _contentBounds: CGRect {
        let textSize = estimatedTextSize()
        guard textSize.width > 0 && textSize.height > 0 else {
            return .zero
        }

        var originX: CGFloat = 0
        var originY: CGFloat = 0

        // Adjust for horizontal alignment
        switch horizontalAlignmentMode {
        case .center:
            originX = -textSize.width / 2
        case .left:
            originX = 0
        case .right:
            originX = -textSize.width
        }

        // Adjust for vertical alignment
        switch verticalAlignmentMode {
        case .center:
            originY = -textSize.height / 2
        case .top:
            originY = -textSize.height
        case .bottom:
            originY = 0
        case .baseline:
            // Baseline is typically about 0.2 * fontSize from the bottom
            originY = -textSize.height + fontSize * 0.2
        }

        return CGRect(origin: CGPoint(x: originX, y: originY), size: textSize)
    }

    /// The calculated frame of the label in the parent's coordinate system.
    ///
    /// The frame accounts for the label's size, alignment, position, scale, and rotation.
    open override var frame: CGRect {
        let localBounds = _contentBounds
        guard localBounds.width > 0 && localBounds.height > 0 else {
            return CGRect(origin: position, size: .zero)
        }

        // Apply scale
        let scaledWidth = localBounds.width * abs(xScale)
        let scaledHeight = localBounds.height * abs(yScale)
        let scaledOriginX = localBounds.origin.x * xScale
        let scaledOriginY = localBounds.origin.y * yScale

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
        let cosVal = cos(Double(zRotation))
        let sinVal = sin(Double(zRotation))

        let corners = [
            CGPoint(x: scaledOriginX, y: scaledOriginY),
            CGPoint(x: scaledOriginX + scaledWidth, y: scaledOriginY),
            CGPoint(x: scaledOriginX + scaledWidth, y: scaledOriginY + scaledHeight),
            CGPoint(x: scaledOriginX, y: scaledOriginY + scaledHeight)
        ]

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

    /// Creates a new label node.
    public override init() {
        super.init()
        syncLayerProperties()
    }

    /// Initializes a new label object with a specified font.
    ///
    /// - Parameter fontName: The name of the font to use for the label.
    public init(fontNamed fontName: String?) {
        super.init()
        self.fontName = fontName
        syncLayerProperties()
    }

    /// Initializes a new label object with a text string.
    ///
    /// - Parameter text: The text to display in the label.
    public convenience init(text: String?) {
        self.init()
        self.text = text
    }

    /// Initializes a new label object with an attributed text string.
    ///
    /// - Parameter attributedText: The attributed string to display in the label.
    public convenience init(attributedText: NSAttributedString?) {
        self.init()
        self.attributedText = attributedText
    }

    /// Syncs all properties to the layer after initialization.
    private func syncLayerProperties() {
        textLayer.foregroundColor = fontColor?.cgColor
        textLayer.fontSize = fontSize
        #if canImport(QuartzCore)
        textLayer.font = fontName as CFTypeRef?
        #else
        textLayer.font = fontName
        #endif
        updateTextLayerAlignment()
        updateTextLayerTruncation()
    }

    // MARK: - Copying

    /// Creates a copy of this label node.
    open override func copy() -> SKNode {
        let labelCopy = SKLabelNode()
        labelCopy._copyNodeProperties(from: self)
        return labelCopy
    }

    /// Internal helper to copy SKLabelNode properties.
    internal override func _copyNodeProperties(from node: SKNode) {
        super._copyNodeProperties(from: node)
        guard let label = node as? SKLabelNode else { return }

        self.text = label.text
        self.attributedText = label.attributedText
        self.fontColor = label.fontColor
        self.fontName = label.fontName
        self.fontSize = label.fontSize
        self.verticalAlignmentMode = label.verticalAlignmentMode
        self.horizontalAlignmentMode = label.horizontalAlignmentMode
        self.preferredMaxLayoutWidth = label.preferredMaxLayoutWidth
        self.lineBreakMode = label.lineBreakMode
        self.numberOfLines = label.numberOfLines
        self.color = label.color
        self.colorBlendFactor = label.colorBlendFactor
        self.blendMode = label.blendMode
    }

}

// MARK: - SKLabelVerticalAlignmentMode

/// Options for aligning text vertically.
public enum SKLabelVerticalAlignmentMode: Int, Sendable, Hashable {
    /// The baseline of the text is at the node's origin.
    case baseline = 0

    /// The center of the text is at the node's origin.
    case center = 1

    /// The top of the text is at the node's origin.
    case top = 2

    /// The bottom of the text is at the node's origin.
    case bottom = 3
}

// MARK: - SKLabelHorizontalAlignmentMode

/// Options for aligning text horizontally.
public enum SKLabelHorizontalAlignmentMode: Int, Sendable, Hashable {
    /// The center of the text is at the node's origin.
    case center = 0

    /// The left side of the text is at the node's origin.
    case left = 1

    /// The right side of the text is at the node's origin.
    case right = 2
}
