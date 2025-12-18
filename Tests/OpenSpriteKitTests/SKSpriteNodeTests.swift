import Testing
@testable import OpenSpriteKit

// MARK: - SKSpriteNode Initialization Tests

@Suite("SKSpriteNode Initialization")
struct SKSpriteNodeInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let sprite = SKSpriteNode()

        #expect(sprite.texture == nil)
        #expect(sprite.size == .zero)
        #expect(sprite.anchorPoint == CGPoint(x: 0.5, y: 0.5))
        #expect(sprite.colorBlendFactor == 0.0)
        #expect(sprite.blendMode == .alpha)
    }

    @Test("Init with texture sets size from texture")
    func testInitWithTexture() {
        let texture = SKTexture(imageNamed: "test")
        let sprite = SKSpriteNode(texture: texture)

        #expect(sprite.texture === texture)
    }

    @Test("Init with texture and size uses provided size")
    func testInitWithTextureAndSize() {
        let texture = SKTexture(imageNamed: "test")
        let size = CGSize(width: 100, height: 50)
        let sprite = SKSpriteNode(texture: texture, size: size)

        #expect(sprite.texture === texture)
        #expect(sprite.size == size)
    }

    @Test("Init with color and size sets colorBlendFactor to 1")
    func testInitWithColorAndSize() {
        let color = SKColor.red
        let size = CGSize(width: 64, height: 64)
        let sprite = SKSpriteNode(color: color, size: size)

        #expect(sprite.texture == nil)
        #expect(sprite.size == size)
        #expect(sprite.colorBlendFactor == 1.0)
    }

    @Test("Init with imageNamed creates texture")
    func testInitWithImageNamed() {
        let sprite = SKSpriteNode(imageNamed: "test")

        #expect(sprite.texture != nil)
    }
}

// MARK: - SKSpriteNode Properties Tests

@Suite("SKSpriteNode Properties")
struct SKSpriteNodePropertiesTests {

    @Test("Anchor point can be changed")
    func testAnchorPoint() {
        let sprite = SKSpriteNode()
        sprite.anchorPoint = CGPoint(x: 0, y: 0)

        #expect(sprite.anchorPoint == CGPoint(x: 0, y: 0))
    }

    @Test("Center rect default is full texture")
    func testCenterRectDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.centerRect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test("Color blend factor can be set")
    func testColorBlendFactor() {
        let sprite = SKSpriteNode()
        sprite.colorBlendFactor = 0.5

        #expect(sprite.colorBlendFactor == 0.5)
    }

    @Test("Blend mode can be changed")
    func testBlendMode() {
        let sprite = SKSpriteNode()
        sprite.blendMode = .add

        #expect(sprite.blendMode == .add)
    }
}

// MARK: - SKSpriteNode Lighting Tests

@Suite("SKSpriteNode Lighting")
struct SKSpriteNodeLightingTests {

    @Test("Lighting bit mask default is 0")
    func testLightingBitMaskDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.lightingBitMask == 0)
    }

    @Test("Lighting bit mask can be set")
    func testLightingBitMaskSet() {
        let sprite = SKSpriteNode()
        sprite.lightingBitMask = 0b0001

        #expect(sprite.lightingBitMask == 0b0001)
    }

    @Test("Shadowed bit mask default is 0")
    func testShadowedBitMaskDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.shadowedBitMask == 0)
    }

    @Test("Shadow cast bit mask default is 0")
    func testShadowCastBitMaskDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.shadowCastBitMask == 0)
    }
}

// MARK: - SKSpriteNode Frame Tests

@Suite("SKSpriteNode Frame")
struct SKSpriteNodeFrameTests {

    @Test("Frame is calculated from size and anchor point")
    func testFrameCalculation() {
        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: 100, height: 50)
        sprite.position = CGPoint(x: 200, y: 100)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let frame = sprite.frame

        #expect(frame.origin.x == 150) // 200 - 100 * 0.5
        #expect(frame.origin.y == 75)  // 100 - 50 * 0.5
        #expect(frame.size.width == 100)
        #expect(frame.size.height == 50)
    }

    @Test("Frame with bottom-left anchor point")
    func testFrameBottomLeftAnchor() {
        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: 100, height: 50)
        sprite.position = CGPoint(x: 200, y: 100)
        sprite.anchorPoint = CGPoint(x: 0, y: 0)

        let frame = sprite.frame

        #expect(frame.origin.x == 200)
        #expect(frame.origin.y == 100)
    }

    @Test("scale(to:) changes size")
    func testScaleToSize() {
        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: 50, height: 50)

        sprite.scale(to: CGSize(width: 100, height: 200))

        #expect(sprite.size == CGSize(width: 100, height: 200))
    }
}

// MARK: - SKSpriteNode Shader Tests

@Suite("SKSpriteNode Shader")
struct SKSpriteNodeShaderTests {

    @Test("Shader is nil by default")
    func testShaderDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.shader == nil)
    }

    @Test("Shader can be assigned")
    func testShaderAssignment() {
        let sprite = SKSpriteNode()
        let shader = SKShader(source: "void main() {}")
        sprite.shader = shader

        #expect(sprite.shader === shader)
    }

    @Test("Attribute values is empty by default")
    func testAttributeValuesDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.attributeValues.isEmpty)
    }

    @Test("setValue for attribute stores value")
    func testSetAttributeValue() {
        let sprite = SKSpriteNode()
        let value = SKAttributeValue()
        sprite.setValue(value, forAttribute: "intensity")

        #expect(sprite.value(forAttributeNamed: "intensity") != nil)
    }
}

// MARK: - SKSpriteNode Warp Tests

@Suite("SKSpriteNode Warp")
struct SKSpriteNodeWarpTests {

    @Test("Warp geometry is nil by default")
    func testWarpGeometryDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.warpGeometry == nil)
    }

    @Test("Subdivision levels default is 1")
    func testSubdivisionLevelsDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.subdivisionLevels == 1)
    }
}

// MARK: - SKSpriteNode Normal Texture Tests

@Suite("SKSpriteNode Normal Texture")
struct SKSpriteNodeNormalTextureTests {

    @Test("Normal texture is nil by default")
    func testNormalTextureDefault() {
        let sprite = SKSpriteNode()

        #expect(sprite.normalTexture == nil)
    }

    @Test("Normal texture can be assigned")
    func testNormalTextureAssignment() {
        let sprite = SKSpriteNode()
        let normalTexture = SKTexture(imageNamed: "normal_map")
        sprite.normalTexture = normalTexture

        #expect(sprite.normalTexture === normalTexture)
    }

    @Test("Init with texture and normalMap sets both")
    func testInitWithNormalMap() {
        let texture = SKTexture(imageNamed: "diffuse")
        let normalMap = SKTexture(imageNamed: "normal")
        let sprite = SKSpriteNode(texture: texture, normalMap: normalMap)

        #expect(sprite.texture === texture)
        #expect(sprite.normalTexture === normalMap)
    }
}
