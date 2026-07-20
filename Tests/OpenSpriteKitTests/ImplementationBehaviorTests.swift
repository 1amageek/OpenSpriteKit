import Testing
@testable import OpenSpriteKit

@Suite("Implemented runtime behavior", .serialized)
struct ImplementationBehaviorTests {
    @Test("Texture normal sampling decodes signed RGB vectors")
    func textureNormalSampling() throws {
        let pixels = Data([
            255, 128, 128, 255,
            128, 255, 128, 255,
        ])
        let texture = SKTexture(data: pixels, size: CGSize(width: 2, height: 1))
        texture.filteringMode = .nearest

        let left = try #require(texture.velocityNormal(at: CGPoint(x: 0, y: 0.5)))
        let right = try #require(texture.velocityNormal(at: CGPoint(x: 1, y: 0.5)))

        #expect(left.x > 0.99)
        #expect(abs(left.y) < 0.01)
        #expect(right.y > 0.99)
        #expect(abs(right.x) < 0.01)
    }

    @MainActor
    @Test("Texture velocity field sets velocity from sampled normal")
    func textureVelocityField() throws {
        let scene = SKScene(size: CGSize(width: 100, height: 100))
        scene.physicsWorld.gravity = .zero

        var velocityPixels = Data()
        velocityPixels.reserveCapacity(20 * 20 * 4)
        for _ in 0..<(20 * 20) {
            velocityPixels.append(contentsOf: [255, 128, 128, 255])
        }
        let texture = SKTexture(data: velocityPixels, size: CGSize(width: 20, height: 20))
        texture.filteringMode = .nearest
        let field = SKFieldNode.velocityField(with: texture)
        field.strength = 3
        scene.addChild(field)

        let node = SKNode()
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 2, height: 2))
        body.affectedByGravity = false
        body.linearDamping = 0
        node.physicsBody = body
        scene.addChild(node)

        SKPhysicsEngine.shared.simulate(scene: scene, deltaTime: 0.1)

        #expect(abs(body.velocity.dx - 3) < 0.02, "velocity=\(body.velocity)")
        #expect(abs(body.velocity.dy) < 0.02)
        #expect(field.region?.contains(CGPoint(x: 9.9, y: 0)) == true)
        #expect(field.region?.contains(CGPoint(x: 10.1, y: 0)) == false)
    }

    @MainActor
    @Test("Physics world samples texture velocity fields")
    func physicsWorldSamplesTextureVelocityField() {
        let pixels = Data([255, 128, 128, 255])
        let texture = SKTexture(data: pixels, size: CGSize(width: 1, height: 1))
        texture.filteringMode = .nearest
        let field = SKFieldNode.velocityField(with: texture)
        field.strength = 3

        let scene = SKScene(size: CGSize(width: 10, height: 10))
        scene.addChild(field)

        let sample = scene.physicsWorld.sampleFields(at: .zero)

        #expect(sample.x > 2.9)
        #expect(abs(sample.y) < 0.03)
        #expect(abs(sample.z) < 0.03)
    }

    @Test("Audio actions interpolate mixing state without changing positional mode")
    func audioActionState() {
        SKActionRunner.shared.reset()
        let scene = SKScene(size: CGSize(width: 100, height: 100))
        let audio = SKAudioNode()
        audio.isPositional = true
        scene.addChild(audio)

        audio.run(SKAction.changeVolume(to: 0.2, duration: 1))
        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(audio.volume - 0.6) < 0.01)

        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(audio.volume - 0.2) < 0.01)

        audio.run(SKAction.play())
        SKActionRunner.shared.update(scene: scene, deltaTime: 0)
        #expect(audio.isPositional)
        #expect(audio.playbackState == .failed("No decoded audio asset is available"))
    }

    @Test("Follow-path action evaluates curve geometry instead of endpoint chords")
    func curvedPathAction() {
        SKActionRunner.shared.reset()
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 100, y: 0), control: CGPoint(x: 50, y: 100))

        let scene = SKScene(size: CGSize(width: 200, height: 200))
        let node = SKNode()
        scene.addChild(node)
        node.run(SKAction.follow(path, asOffset: false, orientToPath: false, duration: 1))

        SKActionRunner.shared.update(scene: scene, deltaTime: 0.5)
        #expect(abs(node.position.x - 50) < 2)
        #expect(node.position.y > 45)
    }

    @MainActor
    @Test("Software label rendering writes visible pixels")
    func softwareLabelRendering() throws {
        let scene = SKScene(size: CGSize(width: 64, height: 64))
        scene.backgroundColor = .red
        let label = SKLabelNode()
        label.text = "A1"
        label.fontSize = 14
        label.fontColor = .white
        label.position = CGPoint(x: 32, y: 32)
        scene.addChild(label)

        let renderer = SKRenderer()
        renderer.scene = scene
        let image = try #require(renderer.renderToCGImage())
        let data = try #require(image.data ?? image.dataProvider?.data)

        var labelPixelCount = 0
        var backgroundPixelCount = 0
        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for offset in stride(from: 0, to: data.count - 3, by: 4) {
                if baseAddress[offset] > 200 && baseAddress[offset + 1] > 200 && baseAddress[offset + 2] > 200 {
                    labelPixelCount += 1
                } else if baseAddress[offset] > 200 && baseAddress[offset + 1] < 20 && baseAddress[offset + 2] < 20 {
                    backgroundPixelCount += 1
                }
            }
        }
        #expect(backgroundPixelCount > 3_000, "backgroundPixelCount=\(backgroundPixelCount)")
        #expect(labelPixelCount > 20, "labelPixelCount=\(labelPixelCount), bytes=\(data.count), prefix=\(Array(data.prefix(16)))")
    }

    @MainActor
    @Test("Native GPU renderer reports unsupported platform")
    func nativeRendererFailure() async {
        let renderer = SKRenderer()
        do {
            try await renderer.initialize()
            Issue.record("Native GPU initialization unexpectedly succeeded")
        } catch let error as SKRendererError {
            #expect(error == .unsupportedPlatform)
        } catch {
            Issue.record("Unexpected renderer error: \(error)")
        }

        renderer.scene = SKScene(size: CGSize(width: 10, height: 10))
        renderer.render()
        #expect(renderer.lastRenderError == .unsupportedPlatform)
    }
}
