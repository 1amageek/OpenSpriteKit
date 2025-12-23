import Testing
@testable import OpenSpriteKit

// MARK: - SKAction Basic Tests

@Suite("SKAction Basic")
struct SKActionBasicTests {

    @Test("Action initialization has correct defaults")
    func testActionDefaults() {
        let action = SKAction()

        #expect(action.duration == 0.0)
        #expect(action.timingMode == .linear)
        #expect(action.speed == 1.0)
    }

    @Test("Action copy creates independent instance with same values")
    func testActionCopy() {
        let original = SKAction.wait(forDuration: 2.0)
        original.speed = 2.0
        original.timingMode = .easeIn

        let copy = original.copy() as! SKAction

        // Verify copy has same values
        #expect(copy.duration == original.duration)
        #expect(copy.speed == original.speed)
        #expect(copy.timingMode == original.timingMode)

        // Verify independence - modifying copy doesn't affect original
        copy.speed = 3.0
        copy.timingMode = .easeOut
        #expect(original.speed == 2.0)
        #expect(original.timingMode == .easeIn)
    }
}

// MARK: - SKAction Move Tests

@Suite("SKAction Move")
struct SKActionMoveTests {

    @Test("moveBy stores correct delta values")
    func testMoveByValues() {
        let action = SKAction.moveBy(x: 100, y: -50, duration: 1.5)

        #expect(action.duration == 1.5)

        // Verify action type stores correct values
        if case .moveBy(let dx, let dy) = action.actionType {
            #expect(dx == 100)
            #expect(dy == -50)
        } else {
            Issue.record("Expected moveBy action type")
        }
    }

    @Test("move(by:) with CGVector stores correct values")
    func testMoveByVector() {
        let vector = CGVector(dx: 200, dy: 150)
        let action = SKAction.move(by: vector, duration: 2.0)

        #expect(action.duration == 2.0)

        if case .moveBy(let dx, let dy) = action.actionType {
            #expect(dx == 200)
            #expect(dy == 150)
        } else {
            Issue.record("Expected moveBy action type")
        }
    }

    @Test("move(to:) stores target position")
    func testMoveTo() {
        let target = CGPoint(x: 300, y: 400)
        let action = SKAction.move(to: target, duration: 1.0)

        #expect(action.duration == 1.0)

        if case .moveTo(let x, let y) = action.actionType {
            #expect(x == 300)
            #expect(y == 400)
        } else {
            Issue.record("Expected moveTo action type")
        }
    }

    @Test("moveTo(x:) stores only x value")
    func testMoveToX() {
        let action = SKAction.moveTo(x: 150, duration: 0.5)

        if case .moveTo(let x, let y) = action.actionType {
            #expect(x == 150)
            #expect(y == nil)
        } else {
            Issue.record("Expected moveTo action type")
        }
    }

    @Test("moveTo(y:) stores only y value")
    func testMoveToY() {
        let action = SKAction.moveTo(y: 250, duration: 0.75)

        if case .moveTo(let x, let y) = action.actionType {
            #expect(x == nil)
            #expect(y == 250)
        } else {
            Issue.record("Expected moveTo action type")
        }
    }
}

// MARK: - SKAction Rotation Tests

@Suite("SKAction Rotation")
struct SKActionRotationTests {

    @Test("rotate(byAngle:) stores rotation delta")
    func testRotateBy() {
        let action = SKAction.rotate(byAngle: .pi / 2, duration: 1.0)

        #expect(action.duration == 1.0)

        if case .rotateBy(let angle) = action.actionType {
            #expect(angle == .pi / 2)
        } else {
            Issue.record("Expected rotateBy action type")
        }
    }

    @Test("rotate(toAngle:) stores target angle with shortestUnitArc false")
    func testRotateTo() {
        let action = SKAction.rotate(toAngle: .pi, duration: 2.0)

        if case .rotateTo(let angle, let shortestArc) = action.actionType {
            #expect(angle == .pi)
            #expect(shortestArc == false)
        } else {
            Issue.record("Expected rotateTo action type")
        }
    }

    @Test("rotate(toAngle:shortestUnitArc:) stores correct flag")
    func testRotateToShortestArc() {
        let action = SKAction.rotate(toAngle: .pi, duration: 1.0, shortestUnitArc: true)

        if case .rotateTo(let angle, let shortestArc) = action.actionType {
            #expect(angle == .pi)
            #expect(shortestArc == true)
        } else {
            Issue.record("Expected rotateTo action type")
        }
    }
}

// MARK: - SKAction Scale Tests

@Suite("SKAction Scale")
struct SKActionScaleTests {

    @Test("scale(by:) stores uniform scale delta")
    func testScaleBy() {
        let action = SKAction.scale(by: 2.0, duration: 1.0)

        if case .scaleBy(let xScale, let yScale) = action.actionType {
            #expect(xScale == 2.0)
            #expect(yScale == 2.0)
        } else {
            Issue.record("Expected scaleBy action type")
        }
    }

    @Test("scale(to:) with CGFloat stores uniform target scale")
    func testScaleToFloat() {
        let action = SKAction.scale(to: 1.5, duration: 0.5)

        if case .scaleTo(let xScale, let yScale) = action.actionType {
            #expect(xScale == 1.5)
            #expect(yScale == 1.5)
        } else {
            Issue.record("Expected scaleTo action type")
        }
    }

    @Test("scale(to:) with CGSize stores target size")
    func testScaleToSize() {
        let targetSize = CGSize(width: 100, height: 200)
        let action = SKAction.scale(to: targetSize, duration: 1.0)

        if case .scaleToSize(let size) = action.actionType {
            #expect(size == targetSize)
        } else {
            Issue.record("Expected scaleToSize action type")
        }
    }

    @Test("scaleX(by:y:) stores separate scale deltas")
    func testScaleXYBy() {
        let action = SKAction.scaleX(by: 1.5, y: 2.0, duration: 1.0)

        // scaleX(by:y:) is additive (unlike scale(by:) which is multiplicative)
        if case .scaleXYBy(let dx, let dy) = action.actionType {
            #expect(dx == 1.5)
            #expect(dy == 2.0)
        } else {
            Issue.record("Expected scaleXYBy action type")
        }
    }

    @Test("scaleX(to:) stores only x scale")
    func testScaleXTo() {
        let action = SKAction.scaleX(to: 2.0, duration: 1.0)

        if case .scaleTo(let xScale, let yScale) = action.actionType {
            #expect(xScale == 2.0)
            #expect(yScale == nil)
        } else {
            Issue.record("Expected scaleTo action type")
        }
    }

    @Test("scaleY(to:) stores only y scale")
    func testScaleYTo() {
        let action = SKAction.scaleY(to: 3.0, duration: 1.0)

        if case .scaleTo(let xScale, let yScale) = action.actionType {
            #expect(xScale == nil)
            #expect(yScale == 3.0)
        } else {
            Issue.record("Expected scaleTo action type")
        }
    }
}

// MARK: - SKAction Fade Tests

@Suite("SKAction Fade")
struct SKActionFadeTests {

    @Test("fadeIn sets target alpha to 1.0")
    func testFadeIn() {
        let action = SKAction.fadeIn(withDuration: 1.0)

        if case .fadeAlphaTo(let alpha) = action.actionType {
            #expect(alpha == 1.0)
        } else {
            Issue.record("Expected fadeAlphaTo action type")
        }
    }

    @Test("fadeOut sets target alpha to 0.0")
    func testFadeOut() {
        let action = SKAction.fadeOut(withDuration: 0.5)

        if case .fadeAlphaTo(let alpha) = action.actionType {
            #expect(alpha == 0.0)
        } else {
            Issue.record("Expected fadeAlphaTo action type")
        }
    }

    @Test("fadeAlpha(by:) stores delta value")
    func testFadeAlphaBy() {
        let action = SKAction.fadeAlpha(by: -0.3, duration: 1.0)

        if case .fadeAlphaBy(let delta) = action.actionType {
            #expect(delta == -0.3)
        } else {
            Issue.record("Expected fadeAlphaBy action type")
        }
    }

    @Test("fadeAlpha(to:) stores target value")
    func testFadeAlphaTo() {
        let action = SKAction.fadeAlpha(to: 0.7, duration: 2.0)

        if case .fadeAlphaTo(let alpha) = action.actionType {
            #expect(alpha == 0.7)
        } else {
            Issue.record("Expected fadeAlphaTo action type")
        }
    }
}

// MARK: - SKAction Visibility Tests

@Suite("SKAction Visibility")
struct SKActionVisibilityTests {

    @Test("hide() creates instant hide action")
    func testHide() {
        let action = SKAction.hide()

        #expect(action.duration == 0)
        if case .hide = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected hide action type")
        }
    }

    @Test("unhide() creates instant unhide action")
    func testUnhide() {
        let action = SKAction.unhide()

        #expect(action.duration == 0)
        if case .unhide = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected unhide action type")
        }
    }
}

// MARK: - SKAction Chaining Tests

@Suite("SKAction Chaining")
struct SKActionChainingTests {

    @Test("sequence calculates total duration by summing child durations")
    func testSequenceDurationSum() {
        let action1 = SKAction.wait(forDuration: 1.0)
        let action2 = SKAction.wait(forDuration: 2.0)
        let action3 = SKAction.wait(forDuration: 0.5)

        let sequence = SKAction.sequence([action1, action2, action3])

        #expect(sequence.duration == 3.5)
    }

    @Test("sequence with empty array has zero duration")
    func testSequenceEmpty() {
        let sequence = SKAction.sequence([])

        #expect(sequence.duration == 0)
    }

    @Test("sequence with single action has that action's duration")
    func testSequenceSingle() {
        let action = SKAction.wait(forDuration: 2.5)
        let sequence = SKAction.sequence([action])

        #expect(sequence.duration == 2.5)
    }

    @Test("group calculates duration as maximum of child durations")
    func testGroupDurationMax() {
        let action1 = SKAction.wait(forDuration: 1.0)
        let action2 = SKAction.wait(forDuration: 3.0)
        let action3 = SKAction.wait(forDuration: 2.0)

        let group = SKAction.group([action1, action2, action3])

        #expect(group.duration == 3.0)
    }

    @Test("group with empty array has zero duration")
    func testGroupEmpty() {
        let group = SKAction.group([])

        #expect(group.duration == 0)
    }

    @Test("group with single action has that action's duration")
    func testGroupSingle() {
        let action = SKAction.wait(forDuration: 1.5)
        let group = SKAction.group([action])

        #expect(group.duration == 1.5)
    }

    @Test("repeat calculates duration by multiplying action duration by count")
    func testRepeatDuration() {
        let action = SKAction.wait(forDuration: 1.0)
        let repeated = SKAction.repeat(action, count: 5)

        #expect(repeated.duration == 5.0)
    }

    @Test("repeat with count 0 has zero duration")
    func testRepeatZero() {
        let action = SKAction.wait(forDuration: 1.0)
        let repeated = SKAction.repeat(action, count: 0)

        #expect(repeated.duration == 0)
    }

    @Test("repeat with count 1 equals original duration")
    func testRepeatOnce() {
        let action = SKAction.wait(forDuration: 2.5)
        let repeated = SKAction.repeat(action, count: 1)

        #expect(repeated.duration == 2.5)
    }

    @Test("repeatForever has infinite duration")
    func testRepeatForever() {
        let action = SKAction.wait(forDuration: 1.0)
        let forever = SKAction.repeatForever(action)

        #expect(forever.duration == .infinity)
    }
}

// MARK: - SKAction Wait Tests

@Suite("SKAction Wait")
struct SKActionWaitTests {

    @Test("wait(forDuration:) creates action with exact duration")
    func testWait() {
        let action = SKAction.wait(forDuration: 2.0)

        #expect(action.duration == 2.0)
    }

    @Test("wait with range creates action within specified range")
    func testWaitWithRange() {
        // Test multiple times to verify randomness stays within bounds
        for _ in 0..<10 {
            let action = SKAction.wait(forDuration: 2.0, withRange: 1.0)

            // Duration should be within [1.5, 2.5] (2.0 +/- 0.5)
            #expect(action.duration >= 1.5)
            #expect(action.duration <= 2.5)
        }
    }

    @Test("wait with zero range has exact duration")
    func testWaitWithZeroRange() {
        let action = SKAction.wait(forDuration: 3.0, withRange: 0)

        #expect(action.duration == 3.0)
    }
}

// MARK: - SKAction Reverse Tests

@Suite("SKAction Reverse")
struct SKActionReverseTests {

    @Test("reversed moveBy negates dx and dy")
    func testReversedMoveBy() {
        let original = SKAction.moveBy(x: 100, y: -50, duration: 1.0)
        let reversed = original.reversed()

        #expect(reversed.duration == original.duration)

        if case .moveBy(let dx, let dy) = reversed.actionType {
            #expect(dx == -100)
            #expect(dy == 50)
        } else {
            Issue.record("Expected moveBy action type in reversed action")
        }
    }

    @Test("reversed rotateBy negates angle")
    func testReversedRotateBy() {
        let original = SKAction.rotate(byAngle: .pi / 4, duration: 1.0)
        let reversed = original.reversed()

        if case .rotateBy(let angle) = reversed.actionType {
            #expect(angle == -.pi / 4)
        } else {
            Issue.record("Expected rotateBy action type in reversed action")
        }
    }

    @Test("reversed scaleXYBy negates scale deltas")
    func testReversedScaleXYBy() {
        // scaleX(by:y:) is additive, so reverse negates the values
        let original = SKAction.scaleX(by: 2.0, y: -1.0, duration: 1.0)
        let reversed = original.reversed()

        if case .scaleXYBy(let dx, let dy) = reversed.actionType {
            #expect(dx == -2.0)
            #expect(dy == 1.0)
        } else {
            Issue.record("Expected scaleXYBy action type in reversed action")
        }
    }

    @Test("reversed scale(by:) uses reciprocal for multiplicative scale")
    func testReversedScaleByMultiplicative() {
        // scale(by:) is multiplicative, so reverse uses 1/x
        let original = SKAction.scale(by: 2.0, duration: 1.0)
        let reversed = original.reversed()

        if case .scaleBy(let xScale, let yScale) = reversed.actionType {
            #expect(xScale == 0.5)  // 1/2
            #expect(yScale == 0.5)  // 1/2
        } else {
            Issue.record("Expected scaleBy action type in reversed action")
        }
    }

    @Test("reversed fadeAlphaBy negates delta")
    func testReversedFadeAlphaBy() {
        let original = SKAction.fadeAlpha(by: 0.5, duration: 1.0)
        let reversed = original.reversed()

        if case .fadeAlphaBy(let delta) = reversed.actionType {
            #expect(delta == -0.5)
        } else {
            Issue.record("Expected fadeAlphaBy action type in reversed action")
        }
    }

    @Test("reversed sequence reverses order and each action")
    func testReversedSequence() {
        let move = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        let rotate = SKAction.rotate(byAngle: .pi, duration: 0.5)
        let sequence = SKAction.sequence([move, rotate])

        let reversed = sequence.reversed()

        // Verify duration preserved
        #expect(reversed.duration == sequence.duration)

        // Verify it's still a sequence
        if case .sequence(let actions) = reversed.actionType {
            #expect(actions.count == 2)

            // First action should be reversed rotate
            if case .rotateBy(let angle) = actions[0].actionType {
                #expect(angle == -.pi)
            } else {
                Issue.record("Expected rotateBy as first action")
            }

            // Second action should be reversed move
            if case .moveBy(let dx, _) = actions[1].actionType {
                #expect(dx == -100)
            } else {
                Issue.record("Expected moveBy as second action")
            }
        } else {
            Issue.record("Expected sequence action type")
        }
    }

    @Test("reversed group reverses each action")
    func testReversedGroup() {
        let move = SKAction.moveBy(x: 50, y: 50, duration: 1.0)
        let scale = SKAction.scale(by: 2.0, duration: 1.0)
        let group = SKAction.group([move, scale])

        let reversed = group.reversed()

        if case .group(let actions) = reversed.actionType {
            #expect(actions.count == 2)

            // Verify each action is reversed
            var foundReversedMove = false
            var foundReversedScale = false

            for action in actions {
                if case .moveBy(let dx, let dy) = action.actionType {
                    #expect(dx == -50)
                    #expect(dy == -50)
                    foundReversedMove = true
                }
                if case .scaleBy(let xScale, let yScale) = action.actionType {
                    // scale(by:) is multiplicative, so reverse uses 1/x
                    #expect(xScale == 0.5)  // 1/2
                    #expect(yScale == 0.5)  // 1/2
                    foundReversedScale = true
                }
            }

            #expect(foundReversedMove)
            #expect(foundReversedScale)
        } else {
            Issue.record("Expected group action type")
        }
    }

    @Test("reversed preserves timing mode")
    func testReversedPreservesTimingMode() {
        let original = SKAction.rotate(byAngle: .pi, duration: 1.0)
        original.timingMode = .easeInEaseOut

        let reversed = original.reversed()

        #expect(reversed.timingMode == .easeInEaseOut)
    }

    @Test("reversed preserves speed")
    func testReversedPreservesSpeed() {
        let original = SKAction.moveBy(x: 100, y: 0, duration: 1.0)
        original.speed = 2.0

        let reversed = original.reversed()

        #expect(reversed.speed == 2.0)
    }
}

// MARK: - SKAction Custom Tests

@Suite("SKAction Custom")
struct SKActionCustomTests {

    @Test("run block creates instant action with block type")
    func testRunBlock() {
        let action = SKAction.run { /* block content */ }

        #expect(action.duration == 0)
        if case .runBlock = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected runBlock action type")
        }
    }

    @Test("customAction stores duration and block")
    func testCustomAction() {
        let action = SKAction.customAction(withDuration: 1.5) { node, elapsed in
            // Custom action logic
        }

        #expect(action.duration == 1.5)
        if case .customAction = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected customAction action type")
        }
    }

    @Test("removeFromParent creates instant action")
    func testRemoveFromParent() {
        let action = SKAction.removeFromParent()

        #expect(action.duration == 0)
        if case .removeFromParent = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected removeFromParent action type")
        }
    }
}

// MARK: - SKAction Speed Tests

@Suite("SKAction Speed")
struct SKActionSpeedTests {

    @Test("speed(by:) stores delta value")
    func testSpeedBy() {
        let action = SKAction.speed(by: 0.5, duration: 1.0)

        if case .speedBy(let delta) = action.actionType {
            #expect(delta == 0.5)
        } else {
            Issue.record("Expected speedBy action type")
        }
    }

    @Test("speed(to:) stores target value")
    func testSpeedTo() {
        let action = SKAction.speed(to: 2.0, duration: 0.5)

        if case .speedTo(let speed) = action.actionType {
            #expect(speed == 2.0)
        } else {
            Issue.record("Expected speedTo action type")
        }
    }
}

// MARK: - SKAction Resize Tests

@Suite("SKAction Resize")
struct SKActionResizeTests {

    @Test("resize(byWidth:height:) stores delta values")
    func testResizeBy() {
        let action = SKAction.resize(byWidth: 50, height: -30, duration: 1.0)

        if case .resizeBy(let width, let height) = action.actionType {
            #expect(width == 50)
            #expect(height == -30)
        } else {
            Issue.record("Expected resizeBy action type")
        }
    }

    @Test("resize(toWidth:) stores only width")
    func testResizeToWidth() {
        let action = SKAction.resize(toWidth: 200, duration: 0.5)

        if case .resizeTo(let width, let height) = action.actionType {
            #expect(width == 200)
            #expect(height == nil)
        } else {
            Issue.record("Expected resizeTo action type")
        }
    }

    @Test("resize(toHeight:) stores only height")
    func testResizeToHeight() {
        let action = SKAction.resize(toHeight: 150, duration: 0.5)

        if case .resizeTo(let width, let height) = action.actionType {
            #expect(width == nil)
            #expect(height == 150)
        } else {
            Issue.record("Expected resizeTo action type")
        }
    }

    @Test("resize(toWidth:height:) stores both values")
    func testResizeToWidthHeight() {
        let action = SKAction.resize(toWidth: 200, height: 150, duration: 1.0)

        if case .resizeTo(let width, let height) = action.actionType {
            #expect(width == 200)
            #expect(height == 150)
        } else {
            Issue.record("Expected resizeTo action type")
        }
    }
}

// MARK: - SKAction Texture Tests

@Suite("SKAction Texture")
struct SKActionTextureTests {

    @Test("setTexture stores texture without resize")
    func testSetTexture() {
        let texture = SKTexture(imageNamed: "test")
        let action = SKAction.setTexture(texture)

        #expect(action.duration == 0)
        if case .setTexture(let tex, let resize) = action.actionType {
            #expect(tex === texture)
            #expect(resize == false)
        } else {
            Issue.record("Expected setTexture action type")
        }
    }

    @Test("setTexture with resize flag")
    func testSetTextureResize() {
        let texture = SKTexture(imageNamed: "test")
        let action = SKAction.setTexture(texture, resize: true)

        if case .setTexture(let tex, let resize) = action.actionType {
            #expect(tex === texture)
            #expect(resize == true)
        } else {
            Issue.record("Expected setTexture action type")
        }
    }

    @Test("animate(with:timePerFrame:) calculates correct duration")
    func testAnimateTextures() {
        let textures = [
            SKTexture(imageNamed: "frame1"),
            SKTexture(imageNamed: "frame2"),
            SKTexture(imageNamed: "frame3")
        ]
        let action = SKAction.animate(with: textures, timePerFrame: 0.1)

        // Duration = timePerFrame * count = 0.1 * 3 = 0.3
        #expect(abs(action.duration - 0.3) < 0.0001)

        if case .animateTextures(let texs, let timePerFrame, _, _) = action.actionType {
            #expect(texs.count == 3)
            #expect(timePerFrame == 0.1)
        } else {
            Issue.record("Expected animateTextures action type")
        }
    }

    @Test("animate with empty textures has zero duration")
    func testAnimateEmptyTextures() {
        let action = SKAction.animate(with: [], timePerFrame: 0.1)

        #expect(action.duration == 0)
    }
}

// MARK: - SKAction Audio Tests

@Suite("SKAction Audio")
struct SKActionAudioTests {

    @Test("play() creates instant play action")
    func testPlay() {
        let action = SKAction.play()

        #expect(action.duration == 0)
        if case .play = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected play action type")
        }
    }

    @Test("pause() creates instant pause action")
    func testPause() {
        let action = SKAction.pause()

        #expect(action.duration == 0)
        if case .pause = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected pause action type")
        }
    }

    @Test("stop() creates instant stop action")
    func testStop() {
        let action = SKAction.stop()

        #expect(action.duration == 0)
        if case .stop = action.actionType {
            // Correct type
        } else {
            Issue.record("Expected stop action type")
        }
    }

    @Test("changeVolume(to:) stores target volume")
    func testChangeVolumeTo() {
        let action = SKAction.changeVolume(to: 0.5, duration: 1.0)

        if case .changeVolume(let to, let by) = action.actionType {
            #expect(to == 0.5)
            #expect(by == nil)
        } else {
            Issue.record("Expected changeVolume action type")
        }
    }

    @Test("changeVolume(by:) stores delta volume")
    func testChangeVolumeBy() {
        let action = SKAction.changeVolume(by: -0.2, duration: 0.5)

        if case .changeVolume(let to, let by) = action.actionType {
            #expect(to == nil)
            #expect(by == -0.2)
        } else {
            Issue.record("Expected changeVolume action type")
        }
    }
}

// MARK: - SKAction Physics Tests

@Suite("SKAction Physics")
struct SKActionPhysicsTests {

    @Test("applyForce stores force vector")
    func testApplyForce() {
        let force = CGVector(dx: 100, dy: 50)
        let action = SKAction.applyForce(force, duration: 1.0)

        if case .applyForce(let f, let point) = action.actionType {
            #expect(f.dx == 100)
            #expect(f.dy == 50)
            #expect(point == nil)
        } else {
            Issue.record("Expected applyForce action type")
        }
    }

    @Test("applyForce at point stores both force and point")
    func testApplyForceAtPoint() {
        let force = CGVector(dx: 100, dy: 50)
        let point = CGPoint(x: 10, y: 20)
        let action = SKAction.applyForce(force, at: point, duration: 1.0)

        if case .applyForce(let f, let p) = action.actionType {
            #expect(f.dx == 100)
            #expect(p?.x == 10)
            #expect(p?.y == 20)
        } else {
            Issue.record("Expected applyForce action type")
        }
    }

    @Test("applyTorque stores torque value")
    func testApplyTorque() {
        let action = SKAction.applyTorque(0.5, duration: 1.0)

        if case .applyTorque(let torque) = action.actionType {
            #expect(torque == 0.5)
        } else {
            Issue.record("Expected applyTorque action type")
        }
    }

    @Test("applyImpulse stores impulse vector")
    func testApplyImpulse() {
        let impulse = CGVector(dx: 50, dy: 25)
        let action = SKAction.applyImpulse(impulse, duration: 0.5)

        if case .applyImpulse(let imp, let point) = action.actionType {
            #expect(imp.dx == 50)
            #expect(imp.dy == 25)
            #expect(point == nil)
        } else {
            Issue.record("Expected applyImpulse action type")
        }
    }

    @Test("applyAngularImpulse stores impulse value")
    func testApplyAngularImpulse() {
        let action = SKAction.applyAngularImpulse(0.3, duration: 0.5)

        if case .applyAngularImpulse(let impulse) = action.actionType {
            #expect(impulse == 0.3)
        } else {
            Issue.record("Expected applyAngularImpulse action type")
        }
    }
}

// MARK: - SKActionTimingMode Tests

@Suite("SKActionTimingMode")
struct SKActionTimingModeTests {

    @Test("Timing mode raw values are correct")
    func testTimingModeRawValues() {
        #expect(SKActionTimingMode.linear.rawValue == 0)
        #expect(SKActionTimingMode.easeIn.rawValue == 1)
        #expect(SKActionTimingMode.easeOut.rawValue == 2)
        #expect(SKActionTimingMode.easeInEaseOut.rawValue == 3)
    }

    @Test("Action timing mode can be set and retrieved")
    func testSetTimingMode() {
        let action = SKAction.wait(forDuration: 1.0)

        action.timingMode = .easeIn
        #expect(action.timingMode == .easeIn)

        action.timingMode = .easeOut
        #expect(action.timingMode == .easeOut)

        action.timingMode = .easeInEaseOut
        #expect(action.timingMode == .easeInEaseOut)

        action.timingMode = .linear
        #expect(action.timingMode == .linear)
    }
}
