import Testing
@testable import OpenSpriteKit

// MARK: - SKShapeNode Initialization Tests

@Suite("SKShapeNode Initialization")
struct SKShapeNodeInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let shape = SKShapeNode()

        #expect(shape.path == nil)
        #expect(shape.lineWidth == 1.0)
        #expect(shape.glowWidth == 0.0)
        #expect(shape.isAntialiased == true)
        #expect(shape.blendMode == .alpha)
    }

    @Test("Init with path sets path")
    func testInitWithPath() {
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: 100, height: 50))

        let shape = SKShapeNode(path: path)

        #expect(shape.path != nil)
    }

    @Test("Init with rect creates rectangular path with correct bounds")
    func testInitWithRect() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        let shape = SKShapeNode(rect: rect)

        #expect(shape.path != nil)

        // Verify the path bounds match the input rect
        let bounds = shape.path!.boundingBox
        #expect(bounds.origin.x == 10)
        #expect(bounds.origin.y == 20)
        #expect(bounds.size.width == 100)
        #expect(bounds.size.height == 50)
    }

    @Test("Init with rectOf creates centered rect with correct bounds")
    func testInitWithRectOf() {
        let size = CGSize(width: 100, height: 50)
        let shape = SKShapeNode(rectOf: size)

        #expect(shape.path != nil)

        // Centered rect should be from (-50, -25) to (50, 25)
        let bounds = shape.path!.boundingBox
        #expect(bounds.origin.x == -50)
        #expect(bounds.origin.y == -25)
        #expect(bounds.size.width == 100)
        #expect(bounds.size.height == 50)
    }

    @Test("Init with circleOfRadius creates circular path with correct diameter")
    func testInitWithCircle() {
        let radius: CGFloat = 50
        let shape = SKShapeNode(circleOfRadius: radius)

        #expect(shape.path != nil)

        // Circle of radius 50 should have bounds from (-50, -50) to (50, 50)
        let bounds = shape.path!.boundingBox
        #expect(abs(bounds.origin.x - (-radius)) < 0.01)
        #expect(abs(bounds.origin.y - (-radius)) < 0.01)
        #expect(abs(bounds.size.width - (radius * 2)) < 0.01)
        #expect(abs(bounds.size.height - (radius * 2)) < 0.01)
    }

    @Test("Init with ellipseOf creates elliptical path with correct bounds")
    func testInitWithEllipse() {
        let size = CGSize(width: 100, height: 50)
        let shape = SKShapeNode(ellipseOf: size)

        #expect(shape.path != nil)

        // Centered ellipse should be from (-50, -25) to (50, 25)
        let bounds = shape.path!.boundingBox
        #expect(abs(bounds.origin.x - (-50)) < 0.01)
        #expect(abs(bounds.origin.y - (-25)) < 0.01)
        #expect(abs(bounds.size.width - 100) < 0.01)
        #expect(abs(bounds.size.height - 50) < 0.01)
    }

    @Test("Init with ellipseIn creates elliptical path in specified rect")
    func testInitWithEllipseInRect() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        let shape = SKShapeNode(ellipseIn: rect)

        #expect(shape.path != nil)

        // Ellipse should fit within the specified rect
        let bounds = shape.path!.boundingBox
        #expect(abs(bounds.origin.x - 10) < 0.01)
        #expect(abs(bounds.origin.y - 20) < 0.01)
        #expect(abs(bounds.size.width - 100) < 0.01)
        #expect(abs(bounds.size.height - 50) < 0.01)
    }

    @Test("Init with rounded rect creates path with correct bounds")
    func testInitWithRoundedRect() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let shape = SKShapeNode(rect: rect, cornerRadius: 10)

        #expect(shape.path != nil)

        // Rounded rect should have same bounds as regular rect
        let bounds = shape.path!.boundingBox
        #expect(bounds.origin.x == 0)
        #expect(bounds.origin.y == 0)
        #expect(bounds.size.width == 100)
        #expect(bounds.size.height == 50)
    }

    @Test("Init with rectOf and cornerRadius creates centered rounded rect")
    func testInitWithRectOfCornerRadius() {
        let size = CGSize(width: 100, height: 50)
        let shape = SKShapeNode(rectOf: size, cornerRadius: 5)

        #expect(shape.path != nil)

        // Should be centered like rectOf
        let bounds = shape.path!.boundingBox
        #expect(bounds.origin.x == -50)
        #expect(bounds.origin.y == -25)
        #expect(bounds.size.width == 100)
        #expect(bounds.size.height == 50)
    }
}

// MARK: - SKShapeNode Fill Tests

@Suite("SKShapeNode Fill")
struct SKShapeNodeFillTests {

    @Test("Fill color default is clear")
    func testFillColorDefault() {
        let shape = SKShapeNode()

        #expect(shape.fillColor == .clear)
    }

    @Test("Fill color can be set")
    func testFillColorSet() {
        let shape = SKShapeNode()
        shape.fillColor = SKColor.red

        // SKColor comparison varies by platform, so just check it's not clear
        #expect(shape.fillColor != .clear)
    }

    @Test("Fill texture is nil by default")
    func testFillTextureDefault() {
        let shape = SKShapeNode()

        #expect(shape.fillTexture == nil)
    }

    @Test("Fill texture can be assigned")
    func testFillTextureSet() {
        let shape = SKShapeNode()
        let texture = SKTexture(imageNamed: "fill")
        shape.fillTexture = texture

        #expect(shape.fillTexture === texture)
    }

    @Test("Fill shader is nil by default")
    func testFillShaderDefault() {
        let shape = SKShapeNode()

        #expect(shape.fillShader == nil)
    }
}

// MARK: - SKShapeNode Stroke Tests

@Suite("SKShapeNode Stroke")
struct SKShapeNodeStrokeTests {

    @Test("Stroke color default is white")
    func testStrokeColorDefault() {
        let shape = SKShapeNode()

        #expect(shape.strokeColor == .white)
    }

    @Test("Stroke color can be set")
    func testStrokeColorSet() {
        let shape = SKShapeNode()
        shape.strokeColor = SKColor.blue

        #expect(shape.strokeColor != .white)
    }

    @Test("Line width default is 1.0")
    func testLineWidthDefault() {
        let shape = SKShapeNode()

        #expect(shape.lineWidth == 1.0)
    }

    @Test("Line width can be changed")
    func testLineWidthSet() {
        let shape = SKShapeNode()
        shape.lineWidth = 3.0

        #expect(shape.lineWidth == 3.0)
    }

    @Test("Stroke texture is nil by default")
    func testStrokeTextureDefault() {
        let shape = SKShapeNode()

        #expect(shape.strokeTexture == nil)
    }

    @Test("Stroke shader is nil by default")
    func testStrokeShaderDefault() {
        let shape = SKShapeNode()

        #expect(shape.strokeShader == nil)
    }
}

// MARK: - SKShapeNode Line Properties Tests

@Suite("SKShapeNode Line Properties")
struct SKShapeNodeLinePropertiesTests {

    @Test("Glow width default is 0.0")
    func testGlowWidthDefault() {
        let shape = SKShapeNode()

        #expect(shape.glowWidth == 0.0)
    }

    @Test("Glow width can be set")
    func testGlowWidthSet() {
        let shape = SKShapeNode()
        shape.glowWidth = 5.0

        #expect(shape.glowWidth == 5.0)
    }

    @Test("Line cap default is butt")
    func testLineCapDefault() {
        let shape = SKShapeNode()

        #expect(shape.lineCap == .butt)
    }

    @Test("Line cap can be changed")
    func testLineCapSet() {
        let shape = SKShapeNode()
        shape.lineCap = .round

        #expect(shape.lineCap == .round)
    }

    @Test("Line join default is miter")
    func testLineJoinDefault() {
        let shape = SKShapeNode()

        #expect(shape.lineJoin == .miter)
    }

    @Test("Line join can be changed")
    func testLineJoinSet() {
        let shape = SKShapeNode()
        shape.lineJoin = .bevel

        #expect(shape.lineJoin == .bevel)
    }

    @Test("Miter limit default is 10.0")
    func testMiterLimitDefault() {
        let shape = SKShapeNode()

        #expect(shape.miterLimit == 10.0)
    }

    @Test("Miter limit can be changed")
    func testMiterLimitSet() {
        let shape = SKShapeNode()
        shape.miterLimit = 5.0

        #expect(shape.miterLimit == 5.0)
    }

    @Test("isAntialiased default is true")
    func testIsAntialiasedDefault() {
        let shape = SKShapeNode()

        #expect(shape.isAntialiased == true)
    }

    @Test("isAntialiased can be changed")
    func testIsAntialiasedSet() {
        let shape = SKShapeNode()
        shape.isAntialiased = false

        #expect(shape.isAntialiased == false)
    }
}

// MARK: - SKShapeNode Points Tests

@Suite("SKShapeNode Points")
struct SKShapeNodePointsTests {

    @Test("Init with points creates path")
    func testInitWithPoints() {
        var points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 100, y: 100)
        ]

        let shape = SKShapeNode(points: &points, count: points.count)

        #expect(shape.path != nil)
    }

    @Test("Init with zero points creates empty shape")
    func testInitWithZeroPoints() {
        var points: [CGPoint] = []

        let shape = SKShapeNode(points: &points, count: 0)

        #expect(shape.path == nil)
    }
}

// MARK: - SKShapeNode Shader Attribute Tests

@Suite("SKShapeNode Shader Attributes")
struct SKShapeNodeShaderAttributeTests {

    @Test("Attribute values is empty by default")
    func testAttributeValuesDefault() {
        let shape = SKShapeNode()

        #expect(shape.attributeValues.isEmpty)
    }

    @Test("setValue stores attribute")
    func testSetValue() {
        let shape = SKShapeNode()
        let value = SKAttributeValue()
        shape.setValue(value, forAttribute: "thickness")

        #expect(shape.value(forAttributeNamed: "thickness") != nil)
    }

    @Test("value for nonexistent attribute returns nil")
    func testValueNotFound() {
        let shape = SKShapeNode()

        #expect(shape.value(forAttributeNamed: "nonexistent") == nil)
    }
}

// MARK: - SKShapeNode Blend Mode Tests

@Suite("SKShapeNode Blend Mode")
struct SKShapeNodeBlendModeTests {

    @Test("Blend mode default is alpha")
    func testBlendModeDefault() {
        let shape = SKShapeNode()

        #expect(shape.blendMode == .alpha)
    }

    @Test("Blend mode can be changed")
    func testBlendModeSet() {
        let shape = SKShapeNode()
        shape.blendMode = .add

        #expect(shape.blendMode == .add)
    }
}
