import Testing
@testable import OpenSpriteKit

// MARK: - SKPhysicsBody Initialization Tests

@Suite("SKPhysicsBody Initialization")
struct SKPhysicsBodyInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let body = SKPhysicsBody()

        #expect(body.affectedByGravity == true)
        #expect(body.allowsRotation == true)
        #expect(body.isDynamic == true)
        #expect(body.mass == 1.0)
        #expect(body.density == 1.0)
        #expect(body.friction == 0.2)
        #expect(body.restitution == 0.2)
        #expect(body.linearDamping == 0.1)
        #expect(body.angularDamping == 0.1)
    }

    @Test("Bit masks have correct defaults")
    func testBitMaskDefaults() {
        let body = SKPhysicsBody()

        #expect(body.categoryBitMask == 0xFFFFFFFF)
        #expect(body.collisionBitMask == 0xFFFFFFFF)
        #expect(body.contactTestBitMask == 0)
        #expect(body.fieldBitMask == 0xFFFFFFFF)
    }

    @Test("Velocity and angular velocity default to zero")
    func testVelocityDefaults() {
        let body = SKPhysicsBody()

        #expect(body.velocity == .zero)
        #expect(body.angularVelocity == 0.0)
    }
}

// MARK: - SKPhysicsBody Properties Tests

@Suite("SKPhysicsBody Properties")
struct SKPhysicsBodyPropertiesTests {

    @Test("affectedByGravity can be changed")
    func testAffectedByGravityChange() {
        let body = SKPhysicsBody()
        body.affectedByGravity = false

        #expect(body.affectedByGravity == false)
    }

    @Test("allowsRotation can be changed")
    func testAllowsRotationChange() {
        let body = SKPhysicsBody()
        body.allowsRotation = false

        #expect(body.allowsRotation == false)
    }

    @Test("isDynamic can be changed")
    func testIsDynamicChange() {
        let body = SKPhysicsBody()
        body.isDynamic = false

        #expect(body.isDynamic == false)
    }

    @Test("Mass can be changed")
    func testMassChange() {
        let body = SKPhysicsBody()
        body.mass = 5.0

        #expect(body.mass == 5.0)
    }

    @Test("Friction can be changed")
    func testFrictionChange() {
        let body = SKPhysicsBody()
        body.friction = 0.5

        #expect(body.friction == 0.5)
    }

    @Test("Restitution can be changed")
    func testRestitutionChange() {
        let body = SKPhysicsBody()
        body.restitution = 0.8

        #expect(body.restitution == 0.8)
    }

    @Test("Pinned can be set")
    func testPinnedSet() {
        let body = SKPhysicsBody()
        body.pinned = true

        #expect(body.pinned == true)
    }

    @Test("Charge can be set")
    func testChargeSet() {
        let body = SKPhysicsBody()
        body.charge = 1.5

        #expect(body.charge == 1.5)
    }
}

// MARK: - SKPhysicsBody Collision Tests

@Suite("SKPhysicsBody Collision")
struct SKPhysicsBodyCollisionTests {

    @Test("Category bit mask can be set")
    func testCategoryBitMaskSet() {
        let body = SKPhysicsBody()
        body.categoryBitMask = 0b0001

        #expect(body.categoryBitMask == 0b0001)
    }

    @Test("Collision bit mask can be set")
    func testCollisionBitMaskSet() {
        let body = SKPhysicsBody()
        body.collisionBitMask = 0b0011

        #expect(body.collisionBitMask == 0b0011)
    }

    @Test("Contact test bit mask can be set")
    func testContactTestBitMaskSet() {
        let body = SKPhysicsBody()
        body.contactTestBitMask = 0b0010

        #expect(body.contactTestBitMask == 0b0010)
    }

    @Test("usesPreciseCollisionDetection can be enabled")
    func testPreciseCollisionDetection() {
        let body = SKPhysicsBody()
        body.usesPreciseCollisionDetection = true

        #expect(body.usesPreciseCollisionDetection == true)
    }
}

// MARK: - SKPhysicsBody Factory Methods Tests

@Suite("SKPhysicsBody Factory Methods")
struct SKPhysicsBodyFactoryMethodsTests {

    @Test("circleOfRadius calculates area as π*r²")
    func testCircleOfRadiusArea() {
        let radius: CGFloat = 50
        let body = SKPhysicsBody.circleOfRadius(radius)

        // Area = π * r² = π * 50² = π * 2500 ≈ 7853.98
        let expectedArea = CGFloat.pi * radius * radius
        #expect(abs(body.area - expectedArea) < 0.01)
    }

    @Test("circleOfRadius with different radii")
    func testCircleOfRadiusVariousRadii() {
        let body1 = SKPhysicsBody.circleOfRadius(10)
        let body2 = SKPhysicsBody.circleOfRadius(20)

        // Area of circle with r=20 should be 4x area of circle with r=10
        let ratio = body2.area / body1.area
        #expect(abs(ratio - 4.0) < 0.01)
    }

    @Test("rectangleOf calculates area as width * height")
    func testRectangleOfArea() {
        let size = CGSize(width: 100, height: 50)
        let body = SKPhysicsBody.rectangleOf(size: size)

        // Area = width * height = 100 * 50 = 5000
        let expectedArea = size.width * size.height
        #expect(body.area == expectedArea)
    }

    @Test("rectangleOf with different sizes")
    func testRectangleOfVariousSizes() {
        let body1 = SKPhysicsBody.rectangleOf(size: CGSize(width: 10, height: 10))
        let body2 = SKPhysicsBody.rectangleOf(size: CGSize(width: 20, height: 20))

        // Area of 20x20 should be 4x area of 10x10
        #expect(body1.area == 100)
        #expect(body2.area == 400)
    }

    @Test("edgeLoopFrom rect creates static non-dynamic body")
    func testEdgeLoopFromRect() {
        let body = SKPhysicsBody.edgeLoopFrom(rect: CGRect(x: 0, y: 0, width: 100, height: 100))

        // Edge bodies are static (not dynamic)
        #expect(body.isDynamic == false)
        // Edge bodies have no area (they're just edges)
        #expect(body.area == 0)
    }

    @Test("edgeFrom point to point creates static body")
    func testEdgeFromPoints() {
        let body = SKPhysicsBody.edgeFrom(CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 0))

        #expect(body.isDynamic == false)
    }

    @Test("circleOfRadius with center creates body with correct area")
    func testCircleOfRadiusWithCenter() {
        let radius: CGFloat = 30
        let center = CGPoint(x: 100, y: 100)
        let body = SKPhysicsBody.circleOfRadius(radius, center: center)

        // Area should still be π * r²
        let expectedArea = CGFloat.pi * radius * radius
        #expect(abs(body.area - expectedArea) < 0.01)
    }

    @Test("rectangleOf with center creates body with correct area")
    func testRectangleOfWithCenter() {
        let size = CGSize(width: 80, height: 40)
        let center = CGPoint(x: 50, y: 50)
        let body = SKPhysicsBody.rectangleOf(size: size, center: center)

        // Area = width * height regardless of center
        #expect(body.area == 3200)
    }
}

// MARK: - SKPhysicsBody Velocity Tests

@Suite("SKPhysicsBody Velocity")
struct SKPhysicsBodyVelocityTests {

    @Test("Velocity can be set")
    func testVelocitySet() {
        let body = SKPhysicsBody()
        body.velocity = CGVector(dx: 100, dy: 50)

        #expect(body.velocity.dx == 100)
        #expect(body.velocity.dy == 50)
    }

    @Test("Angular velocity can be set")
    func testAngularVelocitySet() {
        let body = SKPhysicsBody()
        body.angularVelocity = 1.5

        #expect(body.angularVelocity == 1.5)
    }

    @Test("isResting is false by default")
    func testIsRestingDefault() {
        let body = SKPhysicsBody()

        #expect(body.isResting == false)
    }
}

// MARK: - SKPhysicsWorld Tests

@Suite("SKPhysicsWorld")
struct SKPhysicsWorldTests {

    @Test("Default gravity is Earth-like")
    func testDefaultGravity() {
        let world = SKPhysicsWorld()

        #expect(world.gravity.dx == 0.0)
        #expect(world.gravity.dy == -9.8)
    }

    @Test("Gravity can be changed")
    func testGravityChange() {
        let world = SKPhysicsWorld()
        world.gravity = CGVector(dx: 0, dy: -4.9)

        #expect(world.gravity.dy == -4.9)
    }

    @Test("Speed default is 1.0")
    func testSpeedDefault() {
        let world = SKPhysicsWorld()

        #expect(world.speed == 1.0)
    }

    @Test("Speed can be changed")
    func testSpeedChange() {
        let world = SKPhysicsWorld()
        world.speed = 2.0

        #expect(world.speed == 2.0)
    }

    @Test("Contact delegate is nil by default")
    func testContactDelegateDefault() {
        let world = SKPhysicsWorld()

        #expect(world.contactDelegate == nil)
    }
}

// MARK: - SKPhysicsJoint Tests

@Suite("SKPhysicsJoint")
struct SKPhysicsJointTests {

    @Test("Pin joint can be created")
    func testPinJointCreation() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let joint = SKPhysicsJointPin.joint(withBodyA: bodyA, bodyB: bodyB, anchor: CGPoint(x: 50, y: 50))

        #expect(joint.bodyA === bodyA)
        #expect(joint.bodyB === bodyB)
    }

    @Test("Spring joint can be created")
    func testSpringJointCreation() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let joint = SKPhysicsJointSpring.joint(
            withBodyA: bodyA,
            bodyB: bodyB,
            anchorA: CGPoint(x: 0, y: 0),
            anchorB: CGPoint(x: 100, y: 0)
        )

        #expect(joint.bodyA === bodyA)
        #expect(joint.bodyB === bodyB)
    }

    @Test("Fixed joint can be created")
    func testFixedJointCreation() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let joint = SKPhysicsJointFixed.joint(withBodyA: bodyA, bodyB: bodyB, anchor: CGPoint(x: 50, y: 50))

        #expect(joint.bodyA === bodyA)
        #expect(joint.bodyB === bodyB)
    }

    @Test("Sliding joint can be created")
    func testSlidingJointCreation() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let joint = SKPhysicsJointSliding.joint(
            withBodyA: bodyA,
            bodyB: bodyB,
            anchor: CGPoint(x: 50, y: 50),
            axis: CGVector(dx: 1, dy: 0)
        )

        #expect(joint.bodyA === bodyA)
        #expect(joint.bodyB === bodyB)
    }

    @Test("Limit joint can be created")
    func testLimitJointCreation() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let joint = SKPhysicsJointLimit.joint(
            withBodyA: bodyA,
            bodyB: bodyB,
            anchorA: CGPoint(x: 0, y: 0),
            anchorB: CGPoint(x: 100, y: 0)
        )

        #expect(joint.bodyA === bodyA)
        #expect(joint.bodyB === bodyB)
    }
}

// MARK: - SKPhysicsContact Tests

@Suite("SKPhysicsContact")
struct SKPhysicsContactTests {

    @Test("Contact has bodies")
    func testContactBodies() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let contact = SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: CGPoint(x: 50, y: 50),
            contactNormal: CGVector(dx: 0, dy: 1),
            collisionImpulse: 10.0
        )

        #expect(contact.bodyA === bodyA)
        #expect(contact.bodyB === bodyB)
    }

    @Test("Contact has collision impulse")
    func testContactImpulse() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let contact = SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: .zero,
            contactNormal: .zero,
            collisionImpulse: 15.0
        )

        #expect(contact.collisionImpulse == 15.0)
    }

    @Test("Contact has contact point")
    func testContactPoint() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let contact = SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: CGPoint(x: 100, y: 200),
            contactNormal: .zero,
            collisionImpulse: 0
        )

        #expect(contact.contactPoint == CGPoint(x: 100, y: 200))
    }

    @Test("Contact has contact normal")
    func testContactNormal() {
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        let contact = SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: .zero,
            contactNormal: CGVector(dx: 1, dy: 0),
            collisionImpulse: 0
        )

        #expect(contact.contactNormal.dx == 1)
        #expect(contact.contactNormal.dy == 0)
    }
}
