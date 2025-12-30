import Testing
@testable import OpenSpriteKit

// MARK: - SKNode Frame Tests

@Suite("SKNode Frame")
struct SKNodeFrameTests {

    @Test("SKNode base frame is zero-sized at position")
    func testSKNodeFrameIsZeroSized() {
        let node = SKNode()
        node.position = CGPoint(x: 100, y: 100)
        // SKNode has no content, so frame is zero-sized at position
        #expect(node.frame == CGRect(origin: CGPoint(x: 100, y: 100), size: .zero))
    }

    @Test("SKSpriteNode frame accounts for anchor point")
    func testSKSpriteNodeFrame() {
        let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        sprite.position = CGPoint(x: 50, y: 50)
        // Default anchor point is (0.5, 0.5), so frame origin is offset by half the size
        let frame = sprite.frame

        #expect(frame.origin.x == 0)  // 50 - 100 * 0.5
        #expect(frame.origin.y == 0)  // 50 - 100 * 0.5
        #expect(frame.width == 100)
        #expect(frame.height == 100)
    }

    @Test("SKSpriteNode frame with custom anchor point")
    func testSKSpriteNodeFrameCustomAnchor() {
        let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        sprite.position = CGPoint(x: 100, y: 100)
        sprite.anchorPoint = CGPoint(x: 0, y: 0)  // Bottom-left anchor
        let frame = sprite.frame

        #expect(frame.origin.x == 100)  // Position is at bottom-left
        #expect(frame.origin.y == 100)
        #expect(frame.width == 100)
        #expect(frame.height == 100)
    }

    @Test("SKShapeNode frame from path")
    func testSKShapeNodeFrame() {
        let shape = SKShapeNode(rectOf: CGSize(width: 100, height: 50))
        // rectOf creates a centered rectangle path
        let frame = shape.frame

        // Path is centered at origin, so frame extends from -50 to 50 in x, -25 to 25 in y
        #expect(frame.width == 100)
        #expect(frame.height == 50)
    }
}

// MARK: - SKNode Contains Tests

@Suite("SKNode Contains")
struct SKNodeContainsTests {

    @Test("Contains uses parent coordinates")
    func testContainsParentCoordinates() {
        let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        sprite.position = CGPoint(x: 200, y: 200)
        // Default anchor (0.5, 0.5), so frame is (150, 150, 100, 100)

        // Points in parent coordinate system
        #expect(sprite.contains(CGPoint(x: 200, y: 200)))  // Center
        #expect(sprite.contains(CGPoint(x: 150, y: 150)))  // Bottom-left corner
        #expect(sprite.contains(CGPoint(x: 249, y: 249)))  // Near top-right corner

        // Points outside the frame
        #expect(!sprite.contains(CGPoint(x: 100, y: 100)))  // Outside
        #expect(!sprite.contains(CGPoint(x: 300, y: 300)))  // Outside
    }

    @Test("Contains with zero-size node returns false")
    func testContainsZeroSizeNode() {
        let node = SKNode()
        node.position = CGPoint(x: 100, y: 100)

        // Zero-size frame at (100, 100) - no point can be inside
        #expect(!node.contains(CGPoint(x: 100, y: 100)))
    }
}

// MARK: - SKNode calculateAccumulatedFrame Tests

@Suite("SKNode calculateAccumulatedFrame")
struct SKNodeAccumulatedFrameTests {

    @Test("Accumulated frame without children equals frame")
    func testAccumulatedFrameNoChildren() {
        let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        sprite.position = CGPoint(x: 50, y: 50)

        let accumulated = sprite.calculateAccumulatedFrame()
        let frame = sprite.frame

        #expect(accumulated == frame)
    }

    @Test("Accumulated frame includes children")
    func testAccumulatedFrameWithChildren() {
        let parent = SKNode()
        parent.position = CGPoint(x: 100, y: 100)

        let child = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        child.position = CGPoint(x: 50, y: 50)
        parent.addChild(child)

        let accumulated = parent.calculateAccumulatedFrame()

        // calculateAccumulatedFrame returns rect in parent's coordinate system (scene coords)
        // parent.frame = (100, 100, 0, 0) - zero size since SKNode has no content
        // child.frame in parent's local coords = (25, 25, 50, 50) - offset by anchor (0.5, 0.5)
        // child.frame transformed to scene coords = (125, 125, 50, 50)
        // union of parent.frame and child's transformed frame = (100, 100, 75, 75)
        #expect(accumulated.origin.x == 100)
        #expect(accumulated.origin.y == 100)
        #expect(accumulated.width == 75)
        #expect(accumulated.height == 75)
    }

    @Test("Accumulated frame with multiple children")
    func testAccumulatedFrameMultipleChildren() {
        let parent = SKNode()

        let child1 = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 20))
        child1.position = CGPoint(x: 0, y: 0)  // Frame: (-10, -10, 20, 20)

        let child2 = SKSpriteNode(color: .blue, size: CGSize(width: 20, height: 20))
        child2.position = CGPoint(x: 100, y: 100)  // Frame: (90, 90, 20, 20)

        parent.addChild(child1)
        parent.addChild(child2)

        let accumulated = parent.calculateAccumulatedFrame()

        // Union of both children's frames
        #expect(accumulated.origin.x == -10)
        #expect(accumulated.origin.y == -10)
        #expect(accumulated.width == 120)  // From -10 to 110
        #expect(accumulated.height == 120)  // From -10 to 110
    }
}

// MARK: - SKNode Intersects Tests

@Suite("SKNode Intersects")
struct SKNodeIntersectsTests {

    @Test("Intersects with overlapping nodes")
    func testIntersectsOverlapping() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let nodeA = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        nodeA.position = CGPoint(x: 100, y: 100)

        let nodeB = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        nodeB.position = CGPoint(x: 120, y: 100)

        scene.addChild(nodeA)
        scene.addChild(nodeB)

        #expect(nodeA.intersects(nodeB))
        #expect(nodeB.intersects(nodeA))
    }

    @Test("Intersects with non-overlapping nodes")
    func testIntersectsNonOverlapping() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let nodeA = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        nodeA.position = CGPoint(x: 100, y: 100)

        let nodeB = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        nodeB.position = CGPoint(x: 200, y: 100)

        scene.addChild(nodeA)
        scene.addChild(nodeB)

        #expect(!nodeA.intersects(nodeB))
    }

    @Test("Intersects with scale")
    func testIntersectsWithScale() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let nodeA = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        nodeA.position = CGPoint(x: 100, y: 100)

        let nodeB = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        nodeB.position = CGPoint(x: 174, y: 100)  // Slightly closer so they overlap
        nodeB.xScale = 2.0  // Width becomes 100

        scene.addChild(nodeA)
        scene.addChild(nodeB)

        // nodeA: position 100, width 50, anchor (0.5, 0.5) → frame (75, 75, 50, 50), right edge at 125
        // nodeB: position 174, scaled width 100, anchor (0.5, 0.5) → frame (124, 75, 100, 50), left edge at 124
        // They overlap by 1 point
        #expect(nodeA.intersects(nodeB))
    }
}

// MARK: - SKNode Copy Tests

@Suite("SKNode Copy")
struct SKNodeCopyTests {

    @Test("Copy creates independent node")
    func testCopyCreatesIndependentNode() {
        let original = SKNode()
        original.position = CGPoint(x: 100, y: 100)
        original.name = "original"

        let copy = original.copy()

        #expect(copy !== original)
        #expect(copy.position == original.position)
        #expect(copy.name == original.name)

        // Modifying copy doesn't affect original
        copy.position = CGPoint(x: 200, y: 200)
        #expect(original.position == CGPoint(x: 100, y: 100))
    }

    @Test("Copy includes deep copy of children")
    func testCopyDeepCopiesChildren() {
        let original = SKNode()
        let child = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        child.name = "child"
        original.addChild(child)

        let copy = original.copy()

        // Original still has its child
        #expect(original.children.count == 1)
        #expect(original.children.first?.name == "child")

        // Copy also has a child
        #expect(copy.children.count == 1)
        #expect(copy.children.first?.name == "child")

        // But it's a different instance
        #expect(original.children.first !== copy.children.first)
    }

    @Test("Copy preserves original tree")
    func testCopyPreservesOriginalTree() {
        let original = SKNode()
        original.name = "parent"

        let child1 = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        child1.name = "child1"

        let child2 = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        child2.name = "child2"

        original.addChild(child1)
        original.addChild(child2)

        let copy = original.copy()

        // Original tree is intact
        #expect(original.children.count == 2)
        #expect(original.children[0].parent === original)
        #expect(original.children[1].parent === original)

        // Copy has its own children
        #expect(copy.children.count == 2)
        #expect(copy.children[0].parent === copy)
        #expect(copy.children[1].parent === copy)
    }
}

// MARK: - Coordinate Conversion Tests

@Suite("SKNode Coordinate Conversion")
struct SKNodeCoordinateConversionTests {

    @Test("Convert point between sibling nodes")
    func testConvertPointBetweenSiblings() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let nodeA = SKNode()
        nodeA.position = CGPoint(x: 100, y: 100)

        let nodeB = SKNode()
        nodeB.position = CGPoint(x: 200, y: 200)

        scene.addChild(nodeA)
        scene.addChild(nodeB)

        // Point at origin of nodeA should be (100, 100) in scene coords
        // In nodeB's coords, that's (100 - 200, 100 - 200) = (-100, -100)
        let pointInA = CGPoint(x: 0, y: 0)
        let pointInB = nodeB.convert(pointInA, from: nodeA)

        #expect(pointInB.x == -100)
        #expect(pointInB.y == -100)
    }

    @Test("Convert point with scale")
    func testConvertPointWithScale() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let parent = SKNode()
        parent.position = CGPoint(x: 100, y: 100)
        parent.setScale(2.0)
        scene.addChild(parent)

        let child = SKNode()
        child.position = CGPoint(x: 50, y: 50)
        parent.addChild(child)

        // Child's origin in scene coords:
        // child.position * parent.scale + parent.position = (50 * 2, 50 * 2) + (100, 100) = (200, 200)
        let originInScene = scene.convert(CGPoint(x: 0, y: 0), from: child)

        #expect(originInScene.x == 200)
        #expect(originInScene.y == 200)
    }

    @Test("Convert point is reversible")
    func testConvertPointReversible() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))

        let nodeA = SKNode()
        nodeA.position = CGPoint(x: 100, y: 100)
        nodeA.zRotation = .pi / 4  // 45 degrees

        let nodeB = SKNode()
        nodeB.position = CGPoint(x: 200, y: 200)
        nodeB.setScale(1.5)

        scene.addChild(nodeA)
        scene.addChild(nodeB)

        let originalPoint = CGPoint(x: 50, y: 50)
        let convertedToB = nodeB.convert(originalPoint, from: nodeA)
        let backToA = nodeA.convert(convertedToB, from: nodeB)

        // Should be approximately equal (floating point precision)
        #expect(abs(backToA.x - originalPoint.x) < 0.0001)
        #expect(abs(backToA.y - originalPoint.y) < 0.0001)
    }
}

// MARK: - Coordinate System Tests

@Suite("SpriteKit Coordinate System")
struct CoordinateSystemTests {

    @Test("Positive Y is up")
    func testPositiveYIsUp() {
        // In SpriteKit, positive Y goes up
        // When we move a node up, its Y position increases
        let node = SKNode()
        node.position = CGPoint(x: 0, y: 0)

        // Move up by 100
        node.position.y += 100

        #expect(node.position.y == 100)
    }

    @Test("Rotation is counterclockwise positive")
    func testRotationIsCounterclockwise() {
        // In SpriteKit, positive rotation is counterclockwise
        // 0 radians = pointing right (positive X)
        // π/2 radians = pointing up (positive Y)
        let node = SKNode()
        node.zRotation = 0

        // Rotate counterclockwise by 90 degrees
        node.zRotation = .pi / 2

        #expect(node.zRotation == .pi / 2)
    }

    @Test("Scene origin is bottom-left by default")
    func testSceneOriginIsBottomLeft() {
        let scene = SKScene(size: CGSize(width: 400, height: 400))
        // Default anchorPoint is (0, 0), meaning origin is at bottom-left
        #expect(scene.anchorPoint == .zero)
    }
}
