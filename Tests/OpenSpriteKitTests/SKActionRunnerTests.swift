import Testing
@testable import OpenSpriteKit

// MARK: - SKActionRunner Tests
// All tests in a single serialized suite to avoid concurrent access to the shared runner

@Suite("SKActionRunner", .serialized)
struct SKActionRunnerTests {

    // Helper to reset runner state before each test
    private func resetRunner() {
        SKActionRunner.shared.reset()
    }

    // MARK: - Move Actions

    @Test("moveBy action updates position over time")
    func testMoveByAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 100, y: 100)
        let action = SKAction.moveBy(x: 100, y: 50, duration: 1.0)
        node.run(action)

        // Simulate half-way through
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)

        // Position should be approximately halfway
        #expect(abs(node.position.x - 150) < 1.0)
        #expect(abs(node.position.y - 125) < 1.0)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)

        // Position should be at target
        #expect(abs(node.position.x - 200) < 1.0)
        #expect(abs(node.position.y - 150) < 1.0)
    }

    @Test("moveTo action updates position to target")
    func testMoveToAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        let action = SKAction.move(to: CGPoint(x: 200, y: 100), duration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)

        #expect(abs(node.position.x - 200) < 1.0)
        #expect(abs(node.position.y - 100) < 1.0)
    }

    // MARK: - Scale Actions

    @Test("scaleTo action updates scale over time")
    func testScaleToAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.setScale(1.0)
        let action = SKAction.scale(to: 2.0, duration: 1.0)
        node.run(action)

        // Simulate half-way
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.xScale - 1.5) < 0.1)
        #expect(abs(node.yScale - 1.5) < 0.1)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.xScale - 2.0) < 0.1)
        #expect(abs(node.yScale - 2.0) < 0.1)
    }

    // MARK: - Rotation Actions

    @Test("rotateBy action updates rotation over time")
    func testRotateByAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.zRotation = 0
        let action = SKAction.rotate(byAngle: .pi, duration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.zRotation - .pi) < 0.01)
    }

    @Test("rotateTo action updates rotation to target")
    func testRotateToAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.zRotation = 0
        let action = SKAction.rotate(toAngle: .pi / 2, duration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.zRotation - .pi / 2) < 0.01)
    }

    // MARK: - Alpha Actions

    @Test("fadeOut action updates alpha to 0")
    func testFadeOutAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.alpha = 1.0
        let action = SKAction.fadeOut(withDuration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.alpha - 0.0) < 0.01)
    }

    @Test("fadeIn action updates alpha to 1")
    func testFadeInAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.alpha = 0.0
        let action = SKAction.fadeIn(withDuration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.alpha - 1.0) < 0.01)
    }

    @Test("fadeAlpha(to:) action updates alpha to target")
    func testFadeAlphaToAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.alpha = 1.0
        let action = SKAction.fadeAlpha(to: 0.5, duration: 1.0)
        node.run(action)

        // Simulate completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.alpha - 0.5) < 0.01)
    }

    // MARK: - Visibility Actions

    @Test("hide action sets isHidden to true")
    func testHideAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.isHidden = false
        let action = SKAction.hide()
        node.run(action)

        // Hide is instant
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.016)
        #expect(node.isHidden == true)
    }

    @Test("unhide action sets isHidden to false")
    func testUnhideAction() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.isHidden = true
        let action = SKAction.unhide()
        node.run(action)

        // Unhide is instant
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.016)
        #expect(node.isHidden == false)
    }

    // MARK: - Timing Modes

    @Test("easeIn timing starts slow and accelerates")
    func testEaseInTiming() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        action.timingMode = .easeIn
        node.run(action)

        // At 50% time, should be less than 50% progress due to easeIn
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(node.position.x < 50)
    }

    @Test("easeOut timing starts fast and decelerates")
    func testEaseOutTiming() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        action.timingMode = .easeOut
        node.run(action)

        // At 50% time, should be more than 50% progress due to easeOut
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(node.position.x > 50)
    }

    // MARK: - Completion

    @Test("completion block is called when action finishes")
    func testCompletionBlock() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        var completionCalled = false
        let action = SKAction.wait(forDuration: 0.5)
        node.run(action) {
            completionCalled = true
        }

        // Before completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.25)
        #expect(completionCalled == false)

        // After completion
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.25)
        #expect(completionCalled == true)
    }

    // MARK: - Speed

    @Test("action speed modifier affects duration")
    func testActionSpeedModifier() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        action.speed = 2.0  // 2x speed
        node.run(action)

        // At 0.5s with 2x speed, should be complete
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.position.x - 100) < 1.0)
    }

    @Test("node speed modifier affects action speed")
    func testNodeSpeedModifier() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        node.speed = 2.0  // 2x speed for node
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        node.run(action)

        // At 0.5s with 2x node speed, should be complete
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.position.x - 100) < 1.0)
    }

    // MARK: - Pause

    @Test("paused node does not execute actions")
    func testPausedNode() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        node.isPaused = true
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        node.run(action)

        // Update should not move paused node
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.position.x - 0) < 1.0)

        // Unpause and continue
        node.isPaused = false
        SKActionRunner.shared.update(scene: scene, deltaTime: 1.0)
        #expect(abs(node.position.x - 100) < 1.0)
    }

    // MARK: - Remove Actions

    @Test("removeAllActions stops all actions")
    func testRemoveAllActions() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        let action = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        node.run(action)

        // Partial progress
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        let positionAfterHalf = node.position.x

        // Remove all actions
        node.removeAllActions()

        // Further updates should not change position
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.position.x - positionAfterHalf) < 1.0)
    }

    @Test("removeAction(forKey:) stops specific action")
    func testRemoveActionForKey() {
        resetRunner()
        let node = SKNode()
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.addChild(node)

        node.position = CGPoint(x: 0, y: 0)
        node.alpha = 1.0

        let moveAction = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        let fadeAction = SKAction.fadeOut(withDuration: 1.0)

        node.run(moveAction, withKey: "move")
        node.run(fadeAction, withKey: "fade")

        // Partial progress
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)

        // Remove only move action
        node.removeAction(forKey: "move")
        let positionAfterRemove = node.position.x

        // Continue - only fade should continue
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.position.x - positionAfterRemove) < 1.0)
        #expect(abs(node.alpha - 0.0) < 0.1)
    }
}
