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
        let body = SKPhysicsBody(circleOfRadius:radius)

        // Area = π * r² = π * 50² = π * 2500 ≈ 7853.98
        let expectedArea = CGFloat.pi * radius * radius
        #expect(abs(body.area - expectedArea) < 0.01)
    }

    @Test("circleOfRadius with different radii")
    func testCircleOfRadiusVariousRadii() {
        let body1 = SKPhysicsBody(circleOfRadius:10)
        let body2 = SKPhysicsBody(circleOfRadius:20)

        // Area of circle with r=20 should be 4x area of circle with r=10
        let ratio = body2.area / body1.area
        #expect(abs(ratio - 4.0) < 0.01)
    }

    @Test("rectangleOf calculates area as width * height")
    func testRectangleOfArea() {
        let size = CGSize(width: 100, height: 50)
        let body = SKPhysicsBody(rectangleOf:size)

        // Area = width * height = 100 * 50 = 5000
        let expectedArea = size.width * size.height
        #expect(body.area == expectedArea)
    }

    @Test("rectangleOf with different sizes")
    func testRectangleOfVariousSizes() {
        let body1 = SKPhysicsBody(rectangleOf:CGSize(width: 10, height: 10))
        let body2 = SKPhysicsBody(rectangleOf:CGSize(width: 20, height: 20))

        // Area of 20x20 should be 4x area of 10x10
        #expect(body1.area == 100)
        #expect(body2.area == 400)
    }

    @Test("edgeLoopFrom rect creates static non-dynamic body")
    func testEdgeLoopFromRect() {
        let body = SKPhysicsBody(edgeLoopFrom:CGRect(x: 0, y: 0, width: 100, height: 100))

        // Edge bodies are static (not dynamic)
        #expect(body.isDynamic == false)
        // Edge bodies have no area (they're just edges)
        #expect(body.area == 0)
    }

    @Test("edgeFrom point to point creates static body")
    func testEdgeFromPoints() {
        let body = SKPhysicsBody(edgeFrom:CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 0))

        #expect(body.isDynamic == false)
    }

    @Test("circleOfRadius with center creates body with correct area")
    func testCircleOfRadiusWithCenter() {
        let radius: CGFloat = 30
        let center = CGPoint(x: 100, y: 100)
        let body = SKPhysicsBody(circleOfRadius:radius, center: center)

        // Area should still be π * r²
        let expectedArea = CGFloat.pi * radius * radius
        #expect(abs(body.area - expectedArea) < 0.01)
    }

    @Test("rectangleOf with center creates body with correct area")
    func testRectangleOfWithCenter() {
        let size = CGSize(width: 80, height: 40)
        let center = CGPoint(x: 50, y: 50)
        let body = SKPhysicsBody(rectangleOf:size, center: center)

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

// MARK: - SKPhysicsBody Mass/Density Linkage Tests

@Suite("SKPhysicsBody Mass Density Linkage")
struct SKPhysicsBodyMassDensityLinkageTests {

    @Test("Setting density recalculates mass")
    func testDensitySetRecalculatesMass() {
        let body = SKPhysicsBody(circleOfRadius:10)
        let area = body.area
        body.density = 2.0

        #expect(body.density == 2.0)
        #expect(abs(body.mass - 2.0 * area) < 0.001)
    }

    @Test("Setting mass recalculates density")
    func testMassSetRecalculatesDensity() {
        let body = SKPhysicsBody(rectangleOf:CGSize(width: 10, height: 10))
        let area = body.area // 100
        body.mass = 200.0

        #expect(body.mass == 200.0)
        #expect(abs(body.density - 200.0 / area) < 0.001)
    }

    @Test("Factory body mass equals density times area")
    func testFactoryBodyMassEqualsDensityTimesArea() {
        let body = SKPhysicsBody(circleOfRadius:5)

        #expect(abs(body.mass - body.density * body.area) < 0.001)
    }

    @Test("Zero area body allows mass set without crash")
    func testZeroAreaMassSet() {
        let body = SKPhysicsBody()
        // area is 0, should not crash or produce NaN
        body.mass = 5.0
        body.density = 3.0

        #expect(body.mass == 5.0)
        #expect(body.density == 3.0)
    }

    @Test("Copy preserves mass and density independently")
    func testCopyPreservesMassDensity() {
        let body = SKPhysicsBody(rectangleOf:CGSize(width: 20, height: 20))
        body.mass = 10.0

        let copy = body.copy()

        #expect(copy.mass == body.mass)
        #expect(copy.density == body.density)
        #expect(copy.area == body.area)

        // Modifying copy should not affect original
        copy.mass = 99.0
        #expect(body.mass == 10.0)
    }
}

// MARK: - SKPhysicsBody Edge Body Tests

@Suite("SKPhysicsBody Edge Body")
struct SKPhysicsBodyEdgeBodyTests {

    @Test("Edge body isDynamic stays false when set to true")
    func testEdgeBodyCannotBeDynamic() {
        let body = SKPhysicsBody(edgeLoopFrom:CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(body.isDynamic == false)

        body.isDynamic = true
        #expect(body.isDynamic == false)
    }

    @Test("Edge from points cannot be made dynamic")
    func testEdgeFromPointsCannotBeDynamic() {
        let body = SKPhysicsBody(edgeFrom:CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 0))
        body.isDynamic = true

        #expect(body.isDynamic == false)
    }

    @Test("Edge chain cannot be made dynamic")
    func testEdgeChainCannotBeDynamic() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 100))
        let body = SKPhysicsBody(edgeChainFrom:path)
        #expect(body.isDynamic == false)

        body.isDynamic = true
        #expect(body.isDynamic == false)
    }

    @Test("Edge loop from path cannot be made dynamic")
    func testEdgeLoopFromPathCannotBeDynamic() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 100))
        path.closeSubpath()
        let body = SKPhysicsBody(edgeLoopFrom:path)
        #expect(body.isDynamic == false)

        body.isDynamic = true
        #expect(body.isDynamic == false)
    }

    @Test("Volume body can be made non-dynamic and back")
    func testVolumeBodyCanToggleDynamic() {
        let body = SKPhysicsBody(circleOfRadius:10)
        #expect(body.isDynamic == true)

        body.isDynamic = false
        #expect(body.isDynamic == false)

        body.isDynamic = true
        #expect(body.isDynamic == true)
    }
}

// MARK: - SKPhysicsEngine Zero Mass Safety Tests

@Suite("SKPhysicsEngine Zero Mass Safety")
struct SKPhysicsEngineZeroMassSafetyTests {

    @Test("Force on zero-mass body produces finite velocity")
    @MainActor func testForceOnZeroMassBody() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        let node = SKNode()
        let body = SKPhysicsBody(circleOfRadius:10)
        body.mass = 0
        body.affectedByGravity = false
        node.physicsBody = body
        node.position = CGPoint(x: 200, y: 200)
        scene.addChild(node)

        body.applyForce(CGVector(dx: 100, dy: 100))

        // Simulate one step
        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(body.velocity.dx.isFinite)
        #expect(body.velocity.dy.isFinite)
    }

    @Test("Area change recalculates mass from density")
    func testAreaChangeRecalculatesMass() {
        let body = SKPhysicsBody()
        body.density = 2.0

        // Simulate a factory method setting area
        body.area = 100.0

        let expectedMass: CGFloat = 2.0 * 100.0
        #expect(body.mass == expectedMass)
        #expect(body.density == 2.0)
    }

    @Test("Collision between two zero-mass bodies produces no NaN")
    @MainActor func testZeroMassCollision() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        scene.physicsWorld.gravity = .zero

        let nodeA = SKNode()
        let bodyA = SKPhysicsBody(circleOfRadius:20)
        bodyA.mass = 0
        bodyA.affectedByGravity = false
        bodyA.velocity = CGVector(dx: 100, dy: 0)
        nodeA.physicsBody = bodyA
        nodeA.position = CGPoint(x: 100, y: 200)
        scene.addChild(nodeA)

        let nodeB = SKNode()
        let bodyB = SKPhysicsBody(circleOfRadius:20)
        bodyB.mass = 0
        bodyB.affectedByGravity = false
        bodyB.velocity = CGVector(dx: -100, dy: 0)
        nodeB.physicsBody = bodyB
        nodeB.position = CGPoint(x: 120, y: 200)
        scene.addChild(nodeB)

        // Simulate — should not crash or produce NaN
        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(bodyB.velocity.dx.isFinite)
        #expect(bodyB.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }
}

// MARK: - SKPhysicsJoint Zero Mass Safety Tests

@Suite("SKPhysicsJoint Zero Mass Safety")
struct SKPhysicsJointZeroMassSafetyTests {

    /// Helper to create a scene with two connected nodes for joint testing.
    @MainActor private func makeJointTestScene(
        massA: CGFloat = 0,
        massB: CGFloat = 0
    ) -> (scene: SKScene, nodeA: SKNode, nodeB: SKNode, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody) {
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        scene.physicsWorld.gravity = .zero

        let nodeA = SKNode()
        let bodyA = SKPhysicsBody(circleOfRadius:10)
        bodyA.mass = massA
        bodyA.affectedByGravity = false
        nodeA.physicsBody = bodyA
        nodeA.position = CGPoint(x: 100, y: 200)
        scene.addChild(nodeA)

        let nodeB = SKNode()
        let bodyB = SKPhysicsBody(circleOfRadius:10)
        bodyB.mass = massB
        bodyB.affectedByGravity = false
        nodeB.physicsBody = bodyB
        nodeB.position = CGPoint(x: 200, y: 200)
        scene.addChild(nodeB)

        return (scene, nodeA, nodeB, bodyA, bodyB)
    }

    @Test("Spring joint with zero-mass bodies produces no NaN")
    @MainActor func testSpringJointZeroMass() {
        let (scene, nodeA, nodeB, bodyA, bodyB) = makeJointTestScene()
        bodyA.velocity = CGVector(dx: 50, dy: 0)

        let joint = SKPhysicsJointSpring.joint(
            withBodyA: bodyA, bodyB: bodyB,
            anchorA: nodeA.position, anchorB: nodeB.position
        )
        scene.physicsWorld.add(joint)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(bodyB.velocity.dx.isFinite)
        #expect(bodyB.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }

    @Test("Fixed joint with zero-mass bodies produces no NaN")
    @MainActor func testFixedJointZeroMass() {
        let (scene, nodeA, nodeB, bodyA, bodyB) = makeJointTestScene()
        bodyA.velocity = CGVector(dx: 30, dy: 0)
        bodyB.velocity = CGVector(dx: -30, dy: 0)

        let anchor = CGPoint(x: 150, y: 200)
        let joint = SKPhysicsJointFixed.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchor)
        scene.physicsWorld.add(joint)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(bodyB.velocity.dx.isFinite)
        #expect(bodyB.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }

    @Test("Limit joint with zero-mass bodies produces no NaN")
    @MainActor func testLimitJointZeroMass() {
        let (scene, nodeA, nodeB, bodyA, bodyB) = makeJointTestScene()
        bodyA.velocity = CGVector(dx: 100, dy: 0)

        let joint = SKPhysicsJointLimit.joint(
            withBodyA: bodyA, bodyB: bodyB,
            anchorA: nodeA.position, anchorB: nodeB.position
        )
        scene.physicsWorld.add(joint)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(bodyB.velocity.dx.isFinite)
        #expect(bodyB.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }

    @Test("Pin joint with zero-mass bodies produces no NaN")
    @MainActor func testPinJointZeroMass() {
        let (scene, nodeA, nodeB, bodyA, bodyB) = makeJointTestScene()

        let anchor = CGPoint(x: 150, y: 200)
        let joint = SKPhysicsJointPin.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchor)
        scene.physicsWorld.add(joint)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }

    @Test("Sliding joint with zero-mass bodies produces no NaN")
    @MainActor func testSlidingJointZeroMass() {
        let (scene, nodeA, nodeB, bodyA, bodyB) = makeJointTestScene()
        bodyA.velocity = CGVector(dx: 50, dy: 50)

        let joint = SKPhysicsJointSliding.joint(
            withBodyA: bodyA, bodyB: bodyB,
            anchor: CGPoint(x: 150, y: 200),
            axis: CGVector(dx: 1, dy: 0)
        )
        scene.physicsWorld.add(joint)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 1.0 / 60.0)

        #expect(bodyA.velocity.dx.isFinite)
        #expect(bodyA.velocity.dy.isFinite)
        #expect(bodyB.velocity.dx.isFinite)
        #expect(bodyB.velocity.dy.isFinite)
        #expect(nodeA.position.x.isFinite)
        #expect(nodeB.position.x.isFinite)
    }
}
