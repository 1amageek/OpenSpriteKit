import Testing
import simd
@testable import OpenSpriteKit

// MARK: - SKFieldNode Initialization Tests

@Suite("SKFieldNode Initialization")
struct SKFieldNodeInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let field = SKFieldNode()

        #expect(field.isEnabled == true)
        #expect(field.isExclusive == false)
        #expect(field.minimumRadius == 0.01)
        #expect(field.categoryBitMask == 0xFFFFFFFF)
        #expect(field.strength == 1.0)
        #expect(field.falloff == 0.0)
    }

    @Test("Region defaults to infinite")
    func testRegionDefault() {
        let field = SKFieldNode()

        #expect(field.region != nil)
    }
}

// MARK: - SKFieldNode Factory Methods Tests

@Suite("SKFieldNode Factory Methods")
struct SKFieldNodeFactoryMethodsTests {

    @Test("dragField creates drag field")
    func testDragField() {
        let field = SKFieldNode.dragField()

        #expect(field.isEnabled == true)
    }

    @Test("electricField creates electric field")
    func testElectricField() {
        let field = SKFieldNode.electricField()

        #expect(field.isEnabled == true)
    }

    @Test("linearGravityField creates field with direction")
    func testLinearGravityField() {
        let direction = simd_float3(0, -1, 0)
        let field = SKFieldNode.linearGravityField(withVector: direction)

        #expect(field.isEnabled == true)
        #expect(field.direction.y == -1)
    }

    @Test("magneticField creates magnetic field")
    func testMagneticField() {
        let field = SKFieldNode.magneticField()

        #expect(field.isEnabled == true)
    }

    @Test("noiseField creates noise field")
    func testNoiseField() {
        let field = SKFieldNode.noiseField(withSmoothness: 0.5, animationSpeed: 1.0)

        #expect(field.isEnabled == true)
        #expect(field.smoothness == 0.5)
        #expect(field.animationSpeed == 1.0)
    }

    @Test("radialGravityField creates radial gravity field")
    func testRadialGravityField() {
        let field = SKFieldNode.radialGravityField()

        #expect(field.isEnabled == true)
    }

    @Test("springField creates spring field")
    func testSpringField() {
        let field = SKFieldNode.springField()

        #expect(field.isEnabled == true)
    }

    @Test("turbulenceField creates turbulence field")
    func testTurbulenceField() {
        let field = SKFieldNode.turbulenceField(withSmoothness: 0.3, animationSpeed: 2.0)

        #expect(field.isEnabled == true)
        #expect(field.smoothness == 0.3)
        #expect(field.animationSpeed == 2.0)
    }

    @Test("velocityField with vector creates field")
    func testVelocityFieldWithVector() {
        let direction = simd_float3(1, 0, 0)
        let field = SKFieldNode.velocityField(withVector: direction)

        #expect(field.isEnabled == true)
        #expect(field.direction.x == 1)
    }

    @Test("velocityField with texture creates field")
    func testVelocityFieldWithTexture() {
        let texture = SKTexture(imageNamed: "velocity_map")
        let field = SKFieldNode.velocityField(with: texture)

        #expect(field.isEnabled == true)
        #expect(field.texture === texture)
    }

    @Test("vortexField creates vortex field")
    func testVortexField() {
        let field = SKFieldNode.vortexField()

        #expect(field.isEnabled == true)
    }

    @Test("customField creates custom field with evaluator")
    func testCustomField() {
        let field = SKFieldNode.customField { position, velocity, mass, charge, deltaTime in
            return simd_float3(0, 0, 0)
        }

        #expect(field.isEnabled == true)
    }
}

// MARK: - SKFieldNode Properties Tests

@Suite("SKFieldNode Properties")
struct SKFieldNodePropertiesTests {

    @Test("isEnabled can be changed")
    func testIsEnabledChange() {
        let field = SKFieldNode()
        field.isEnabled = false

        #expect(field.isEnabled == false)
    }

    @Test("isExclusive can be changed")
    func testIsExclusiveChange() {
        let field = SKFieldNode()
        field.isExclusive = true

        #expect(field.isExclusive == true)
    }

    @Test("strength can be changed")
    func testStrengthChange() {
        let field = SKFieldNode()
        field.strength = 2.0

        #expect(field.strength == 2.0)
    }

    @Test("falloff can be changed")
    func testFalloffChange() {
        let field = SKFieldNode()
        field.falloff = 1.0

        #expect(field.falloff == 1.0)
    }

    @Test("minimumRadius can be changed")
    func testMinimumRadiusChange() {
        let field = SKFieldNode()
        field.minimumRadius = 1.0

        #expect(field.minimumRadius == 1.0)
    }

    @Test("categoryBitMask can be changed")
    func testCategoryBitMaskChange() {
        let field = SKFieldNode()
        field.categoryBitMask = 0b0001

        #expect(field.categoryBitMask == 0b0001)
    }

    @Test("region can be changed")
    func testRegionChange() {
        let field = SKFieldNode()
        let customRegion = SKRegion(radius: 100)
        field.region = customRegion

        #expect(field.region === customRegion)
    }

    @Test("animationSpeed can be changed")
    func testAnimationSpeedChange() {
        let field = SKFieldNode.noiseField(withSmoothness: 0.5, animationSpeed: 1.0)
        field.animationSpeed = 3.0

        #expect(field.animationSpeed == 3.0)
    }

    @Test("smoothness can be changed")
    func testSmoothnessChange() {
        let field = SKFieldNode.noiseField(withSmoothness: 0.5, animationSpeed: 1.0)
        field.smoothness = 0.8

        #expect(field.smoothness == 0.8)
    }
}

// MARK: - SKFieldNode in Scene Tests

@Suite("SKFieldNode in Scene")
struct SKFieldNodeInSceneTests {

    @Test("Field can be added to scene")
    func testFieldAddedToScene() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        let field = SKFieldNode.radialGravityField()
        field.position = CGPoint(x: 400, y: 300)

        scene.addChild(field)

        #expect(field.parent === scene)
        #expect(field.scene === scene)
    }

    @Test("Multiple fields can be in scene")
    func testMultipleFields() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        let field1 = SKFieldNode.radialGravityField()
        let field2 = SKFieldNode.dragField()
        let field3 = SKFieldNode.vortexField()

        scene.addChild(field1)
        scene.addChild(field2)
        scene.addChild(field3)

        #expect(scene.children.count == 3)
    }
}
