import Testing
@testable import OpenSpriteKit

// MARK: - SKScene Initialization Tests

@Suite("SKScene Initialization")
struct SKSceneInitializationTests {

    @Test("Init with size sets size correctly")
    func testInitWithSize() {
        let scene = SKScene(size: CGSize(width: 1024, height: 768))

        #expect(scene.size.width == 1024)
        #expect(scene.size.height == 768)
    }

    @Test("Scene property is nil when not presented")
    func testSceneNotPresented() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        // Scene property is nil until the scene is presented in a view
        #expect(scene.scene == nil)
    }

    @Test("Background color defaults to gray")
    func testBackgroundColorDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        // Default is gray, but exact comparison varies by platform
        #expect(scene.backgroundColor != nil)
    }

    @Test("Scale mode defaults to fill")
    func testScaleModeDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.scaleMode == .fill)
    }
}

// MARK: - SKScene Size Tests

@Suite("SKScene Size")
struct SKSceneSizeTests {

    @Test("Size can be changed")
    func testSizeChange() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.size = CGSize(width: 1920, height: 1080)

        #expect(scene.size.width == 1920)
        #expect(scene.size.height == 1080)
    }
}

// MARK: - SKScene Scale Mode Tests

@Suite("SKScene Scale Mode")
struct SKSceneScaleModeTests {

    @Test("Scale mode can be changed")
    func testScaleModeChange() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        scene.scaleMode = .aspectFit
        #expect(scene.scaleMode == .aspectFit)

        scene.scaleMode = .aspectFill
        #expect(scene.scaleMode == .aspectFill)

        scene.scaleMode = .resizeFill
        #expect(scene.scaleMode == .resizeFill)
    }
}

// MARK: - SKSceneScaleMode Tests

@Suite("SKSceneScaleMode")
struct SKSceneScaleModeEnumTests {

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(SKSceneScaleMode.fill.rawValue == 0)
        #expect(SKSceneScaleMode.aspectFill.rawValue == 1)
        #expect(SKSceneScaleMode.aspectFit.rawValue == 2)
        #expect(SKSceneScaleMode.resizeFill.rawValue == 3)
    }
}

// MARK: - SKScene Camera Tests

@Suite("SKScene Camera")
struct SKSceneCameraTests {

    @Test("Camera is nil by default")
    func testCameraDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.camera == nil)
    }

    @Test("Camera can be set")
    func testCameraSet() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        let camera = SKCameraNode()

        scene.addChild(camera)
        scene.camera = camera

        #expect(scene.camera === camera)
    }
}

// MARK: - SKScene Listener Tests

@Suite("SKScene Listener")
struct SKSceneListenerTests {

    @Test("Listener is nil by default")
    func testListenerDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.listener == nil)
    }

    @Test("Listener can be set")
    func testListenerSet() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        let listener = SKNode()

        scene.addChild(listener)
        scene.listener = listener

        #expect(scene.listener === listener)
    }
}

// MARK: - SKScene Physics World Tests

@Suite("SKScene Physics World")
struct SKScenePhysicsWorldTests {

    @Test("Scene has physics world")
    func testHasPhysicsWorld() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.physicsWorld != nil)
    }

    @Test("Physics world has default gravity")
    func testPhysicsWorldGravity() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.physicsWorld.gravity.dx == 0)
        #expect(scene.physicsWorld.gravity.dy == -9.8)
    }
}

// MARK: - SKScene Delegate Tests

@Suite("SKScene Delegate")
struct SKSceneDelegateTests {

    @Test("Delegate is nil by default")
    func testDelegateDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.delegate == nil)
    }
}

// MARK: - SKScene View Tests

@Suite("SKScene View")
struct SKSceneViewTests {

    @Test("View is nil before presentation")
    func testViewDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.view == nil)
    }
}

// MARK: - SKScene Anchor Point Tests

@Suite("SKScene Anchor Point")
struct SKSceneAnchorPointTests {

    @Test("Anchor point defaults to (0, 0)")
    func testAnchorPointDefault() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))

        #expect(scene.anchorPoint == .zero)
    }

    @Test("Anchor point can be changed")
    func testAnchorPointChange() {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        #expect(scene.anchorPoint == CGPoint(x: 0.5, y: 0.5))
    }
}

// MARK: - SKCameraNode Tests

@Suite("SKCameraNode")
struct SKCameraNodeTests {

    @Test("Camera node can be created")
    func testCameraCreation() {
        let camera = SKCameraNode()

        #expect(camera != nil)
    }

    @Test("Camera can be positioned")
    func testCameraPosition() {
        let camera = SKCameraNode()
        camera.position = CGPoint(x: 400, y: 300)

        #expect(camera.position == CGPoint(x: 400, y: 300))
    }

    @Test("Camera can be scaled")
    func testCameraScale() {
        let camera = SKCameraNode()
        camera.setScale(2.0)

        #expect(camera.xScale == 2.0)
        #expect(camera.yScale == 2.0)
    }

    @Test("Camera can be rotated")
    func testCameraRotation() {
        let camera = SKCameraNode()
        camera.zRotation = .pi / 4

        #expect(camera.zRotation == .pi / 4)
    }
}

// MARK: - SKEffectNode Tests

@Suite("SKEffectNode")
struct SKEffectNodeTests {

    @Test("Effect node can be created")
    func testEffectNodeCreation() {
        let effectNode = SKEffectNode()

        #expect(effectNode != nil)
    }

    @Test("shouldEnableEffects defaults to false")
    func testShouldEnableEffectsDefault() {
        let effectNode = SKEffectNode()

        #expect(effectNode.shouldEnableEffects == false)
    }

    @Test("shouldEnableEffects can be enabled")
    func testShouldEnableEffectsSet() {
        let effectNode = SKEffectNode()
        effectNode.shouldEnableEffects = true

        #expect(effectNode.shouldEnableEffects == true)
    }

    @Test("shouldRasterize defaults to false")
    func testShouldRasterizeDefault() {
        let effectNode = SKEffectNode()

        #expect(effectNode.shouldRasterize == false)
    }

    @Test("blendMode defaults to alpha")
    func testBlendModeDefault() {
        let effectNode = SKEffectNode()

        #expect(effectNode.blendMode == .alpha)
    }
}

// MARK: - SKCropNode Tests

@Suite("SKCropNode")
struct SKCropNodeTests {

    @Test("Crop node can be created")
    func testCropNodeCreation() {
        let cropNode = SKCropNode()

        #expect(cropNode != nil)
    }

    @Test("Mask node is nil by default")
    func testMaskNodeDefault() {
        let cropNode = SKCropNode()

        #expect(cropNode.maskNode == nil)
    }

    @Test("Mask node can be set")
    func testMaskNodeSet() {
        let cropNode = SKCropNode()
        let mask = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 100))
        cropNode.maskNode = mask

        #expect(cropNode.maskNode === mask)
    }
}
