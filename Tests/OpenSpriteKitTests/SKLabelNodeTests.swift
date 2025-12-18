import Testing
@testable import OpenSpriteKit

// MARK: - SKLabelNode Initialization Tests

@Suite("SKLabelNode Initialization")
struct SKLabelNodeInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let label = SKLabelNode()

        #expect(label.text == nil)
        #expect(label.fontName == "Helvetica")
        #expect(label.fontSize == 32.0)
        #expect(label.verticalAlignmentMode == .baseline)
        #expect(label.horizontalAlignmentMode == .center)
        #expect(label.blendMode == .alpha)
    }

    @Test("Init with fontNamed sets font")
    func testInitWithFontNamed() {
        let label = SKLabelNode(fontNamed: "Arial")

        #expect(label.fontName == "Arial")
    }

    @Test("Init with text sets text")
    func testInitWithText() {
        let label = SKLabelNode(text: "Hello World")

        #expect(label.text == "Hello World")
    }

    @Test("Init with attributedText sets attributedText")
    func testInitWithAttributedText() {
        let attributed = NSAttributedString(string: "Attributed")
        let label = SKLabelNode(attributedText: attributed)

        #expect(label.attributedText != nil)
        #expect(label.attributedText?.string == "Attributed")
    }
}

// MARK: - SKLabelNode Text Properties Tests

@Suite("SKLabelNode Text Properties")
struct SKLabelNodeTextPropertiesTests {

    @Test("Text can be changed")
    func testTextChange() {
        let label = SKLabelNode()
        label.text = "New Text"

        #expect(label.text == "New Text")
    }

    @Test("Font name can be changed")
    func testFontNameChange() {
        let label = SKLabelNode()
        label.fontName = "Courier"

        #expect(label.fontName == "Courier")
    }

    @Test("Font size can be changed")
    func testFontSizeChange() {
        let label = SKLabelNode()
        label.fontSize = 24.0

        #expect(label.fontSize == 24.0)
    }

    @Test("Font color default is white")
    func testFontColorDefault() {
        let label = SKLabelNode()

        #expect(label.fontColor == .white)
    }

    @Test("Font color can be changed")
    func testFontColorChange() {
        let label = SKLabelNode()
        label.fontColor = .red

        #expect(label.fontColor != .white)
    }
}

// MARK: - SKLabelNode Alignment Tests

@Suite("SKLabelNode Alignment")
struct SKLabelNodeAlignmentTests {

    @Test("Vertical alignment mode can be changed")
    func testVerticalAlignmentChange() {
        let label = SKLabelNode()

        label.verticalAlignmentMode = .center
        #expect(label.verticalAlignmentMode == .center)

        label.verticalAlignmentMode = .top
        #expect(label.verticalAlignmentMode == .top)

        label.verticalAlignmentMode = .bottom
        #expect(label.verticalAlignmentMode == .bottom)
    }

    @Test("Horizontal alignment mode can be changed")
    func testHorizontalAlignmentChange() {
        let label = SKLabelNode()

        label.horizontalAlignmentMode = .left
        #expect(label.horizontalAlignmentMode == .left)

        label.horizontalAlignmentMode = .right
        #expect(label.horizontalAlignmentMode == .right)
    }
}

// MARK: - SKLabelVerticalAlignmentMode Tests

@Suite("SKLabelVerticalAlignmentMode")
struct SKLabelVerticalAlignmentModeTests {

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(SKLabelVerticalAlignmentMode.baseline.rawValue == 0)
        #expect(SKLabelVerticalAlignmentMode.center.rawValue == 1)
        #expect(SKLabelVerticalAlignmentMode.top.rawValue == 2)
        #expect(SKLabelVerticalAlignmentMode.bottom.rawValue == 3)
    }
}

// MARK: - SKLabelHorizontalAlignmentMode Tests

@Suite("SKLabelHorizontalAlignmentMode")
struct SKLabelHorizontalAlignmentModeTests {

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(SKLabelHorizontalAlignmentMode.center.rawValue == 0)
        #expect(SKLabelHorizontalAlignmentMode.left.rawValue == 1)
        #expect(SKLabelHorizontalAlignmentMode.right.rawValue == 2)
    }
}

// MARK: - SKLabelNode Line Breaking Tests

@Suite("SKLabelNode Line Breaking")
struct SKLabelNodeLineBreakingTests {

    @Test("preferredMaxLayoutWidth default is 0")
    func testPreferredMaxLayoutWidthDefault() {
        let label = SKLabelNode()

        #expect(label.preferredMaxLayoutWidth == 0.0)
    }

    @Test("preferredMaxLayoutWidth can be set")
    func testPreferredMaxLayoutWidthSet() {
        let label = SKLabelNode()
        label.preferredMaxLayoutWidth = 200.0

        #expect(label.preferredMaxLayoutWidth == 200.0)
    }

    @Test("Number of lines default is 1")
    func testNumberOfLinesDefault() {
        let label = SKLabelNode()

        #expect(label.numberOfLines == 1)
    }

    @Test("Number of lines can be changed")
    func testNumberOfLinesChange() {
        let label = SKLabelNode()
        label.numberOfLines = 0 // Unlimited

        #expect(label.numberOfLines == 0)
    }

    @Test("Line break mode default is truncating tail")
    func testLineBreakModeDefault() {
        let label = SKLabelNode()

        #expect(label.lineBreakMode == .byTruncatingTail)
    }

    @Test("Line break mode can be changed")
    func testLineBreakModeChange() {
        let label = SKLabelNode()
        label.lineBreakMode = .byWordWrapping

        #expect(label.lineBreakMode == .byWordWrapping)
    }
}

// MARK: - SKLabelNode Color Blend Tests

@Suite("SKLabelNode Color Blend")
struct SKLabelNodeColorBlendTests {

    @Test("Color blend factor default is 0")
    func testColorBlendFactorDefault() {
        let label = SKLabelNode()

        #expect(label.colorBlendFactor == 0.0)
    }

    @Test("Color blend factor can be set")
    func testColorBlendFactorSet() {
        let label = SKLabelNode()
        label.colorBlendFactor = 0.5

        #expect(label.colorBlendFactor == 0.5)
    }

    @Test("Color is nil by default")
    func testColorDefault() {
        let label = SKLabelNode()

        #expect(label.color == nil)
    }

    @Test("Color can be set")
    func testColorSet() {
        let label = SKLabelNode()
        label.color = .blue

        #expect(label.color != nil)
    }
}

// MARK: - SKLabelNode Blend Mode Tests

@Suite("SKLabelNode Blend Mode")
struct SKLabelNodeBlendModeTests {

    @Test("Blend mode default is alpha")
    func testBlendModeDefault() {
        let label = SKLabelNode()

        #expect(label.blendMode == .alpha)
    }

    @Test("Blend mode can be changed")
    func testBlendModeChange() {
        let label = SKLabelNode()
        label.blendMode = .add

        #expect(label.blendMode == .add)
    }
}
