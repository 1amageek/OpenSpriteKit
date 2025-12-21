// SKLabelNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenCoreAnimation

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
    open var text: String? {
        didSet {
            textLayer.string = text
        }
    }

    /// The attributed string displayed by the label.
    open var attributedText: NSAttributedString? {
        didSet {
            textLayer.string = attributedText
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

    // MARK: - Initializers

    /// Creates a new label node.
    public override init() {
        super.init()
    }

    /// Initializes a new label object with a specified font.
    ///
    /// - Parameter fontName: The name of the font to use for the label.
    public init(fontNamed fontName: String?) {
        self.fontName = fontName
        super.init()
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
