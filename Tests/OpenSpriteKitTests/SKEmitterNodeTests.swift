import Testing
@testable import OpenSpriteKit

// MARK: - SKEmitterNode Initialization Tests

@Suite("SKEmitterNode Initialization")
struct SKEmitterNodeInitializationTests {

    @Test("Default initialization has correct values")
    func testDefaultInit() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleTexture == nil)
        #expect(emitter.particleBirthRate == 0.0)
        #expect(emitter.numParticlesToEmit == 0)
        #expect(emitter.particleLifetime == 0.0)
        #expect(emitter.particleLifetimeRange == 0.0)
    }
}

// MARK: - SKEmitterNode Particle Birth Tests

@Suite("SKEmitterNode Particle Birth")
struct SKEmitterNodeParticleBirthTests {

    @Test("Birth rate can be set")
    func testBirthRateSet() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 100.0

        #expect(emitter.particleBirthRate == 100.0)
    }

    @Test("numParticlesToEmit can be set")
    func testNumParticlesToEmitSet() {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 500

        #expect(emitter.numParticlesToEmit == 500)
    }

    @Test("Zero numParticlesToEmit means infinite")
    func testZeroNumParticles() {
        let emitter = SKEmitterNode()
        emitter.numParticlesToEmit = 0

        #expect(emitter.numParticlesToEmit == 0)
    }
}

// MARK: - SKEmitterNode Particle Lifetime Tests

@Suite("SKEmitterNode Particle Lifetime")
struct SKEmitterNodeParticleLifetimeTests {

    @Test("Lifetime can be set")
    func testLifetimeSet() {
        let emitter = SKEmitterNode()
        emitter.particleLifetime = 2.0

        #expect(emitter.particleLifetime == 2.0)
    }

    @Test("Lifetime range can be set")
    func testLifetimeRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particleLifetimeRange = 0.5

        #expect(emitter.particleLifetimeRange == 0.5)
    }
}

// MARK: - SKEmitterNode Particle Position Tests

@Suite("SKEmitterNode Particle Position")
struct SKEmitterNodeParticlePositionTests {

    @Test("Position range defaults to zero")
    func testPositionRangeDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particlePositionRange == .zero)
    }

    @Test("Position range can be set")
    func testPositionRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particlePositionRange = CGVector(dx: 50, dy: 50)

        #expect(emitter.particlePositionRange.dx == 50)
        #expect(emitter.particlePositionRange.dy == 50)
    }

    @Test("Z position can be set")
    func testZPositionSet() {
        let emitter = SKEmitterNode()
        emitter.particleZPosition = 10.0

        #expect(emitter.particleZPosition == 10.0)
    }

    @Test("Z position range can be set")
    func testZPositionRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particleZPositionRange = 5.0

        #expect(emitter.particleZPositionRange == 5.0)
    }
}

// MARK: - SKEmitterNode Particle Rendering Tests

@Suite("SKEmitterNode Particle Rendering")
struct SKEmitterNodeParticleRenderingTests {

    @Test("Render order defaults to oldest first")
    func testRenderOrderDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleRenderOrder == .oldestFirst)
    }

    @Test("Render order can be changed")
    func testRenderOrderChange() {
        let emitter = SKEmitterNode()
        emitter.particleRenderOrder = .oldestFirst

        #expect(emitter.particleRenderOrder == .oldestFirst)
    }

    @Test("Blend mode defaults to alpha")
    func testBlendModeDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleBlendMode == .alpha)
    }

    @Test("Blend mode can be changed")
    func testBlendModeChange() {
        let emitter = SKEmitterNode()
        emitter.particleBlendMode = .add

        #expect(emitter.particleBlendMode == .add)
    }
}

// MARK: - SKEmitterNode Particle Speed Tests

@Suite("SKEmitterNode Particle Speed")
struct SKEmitterNodeParticleSpeedTests {

    @Test("Speed defaults to zero")
    func testSpeedDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleSpeed == 0.0)
    }

    @Test("Speed can be set")
    func testSpeedSet() {
        let emitter = SKEmitterNode()
        emitter.particleSpeed = 100.0

        #expect(emitter.particleSpeed == 100.0)
    }

    @Test("Speed range can be set")
    func testSpeedRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particleSpeedRange = 20.0

        #expect(emitter.particleSpeedRange == 20.0)
    }
}

// MARK: - SKEmitterNode Emission Angle Tests

@Suite("SKEmitterNode Emission Angle")
struct SKEmitterNodeEmissionAngleTests {

    @Test("Emission angle defaults to zero")
    func testEmissionAngleDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.emissionAngle == 0.0)
    }

    @Test("Emission angle can be set")
    func testEmissionAngleSet() {
        let emitter = SKEmitterNode()
        emitter.emissionAngle = .pi / 2

        #expect(emitter.emissionAngle == .pi / 2)
    }

    @Test("Emission angle range can be set")
    func testEmissionAngleRangeSet() {
        let emitter = SKEmitterNode()
        emitter.emissionAngleRange = .pi / 4

        #expect(emitter.emissionAngleRange == .pi / 4)
    }
}

// MARK: - SKEmitterNode Particle Scale Tests

@Suite("SKEmitterNode Particle Scale")
struct SKEmitterNodeParticleScaleTests {

    @Test("Scale defaults to 1.0")
    func testScaleDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleScale == 1.0)
    }

    @Test("Scale can be set")
    func testScaleSet() {
        let emitter = SKEmitterNode()
        emitter.particleScale = 2.0

        #expect(emitter.particleScale == 2.0)
    }

    @Test("Scale range can be set")
    func testScaleRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particleScaleRange = 0.5

        #expect(emitter.particleScaleRange == 0.5)
    }

    @Test("Scale speed can be set")
    func testScaleSpeedSet() {
        let emitter = SKEmitterNode()
        emitter.particleScaleSpeed = -0.1

        #expect(emitter.particleScaleSpeed == -0.1)
    }
}

// MARK: - SKEmitterNode Particle Rotation Tests

@Suite("SKEmitterNode Particle Rotation")
struct SKEmitterNodeParticleRotationTests {

    @Test("Rotation defaults to zero")
    func testRotationDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleRotation == 0.0)
    }

    @Test("Rotation can be set")
    func testRotationSet() {
        let emitter = SKEmitterNode()
        emitter.particleRotation = .pi

        #expect(emitter.particleRotation == .pi)
    }

    @Test("Rotation range can be set")
    func testRotationRangeSet() {
        let emitter = SKEmitterNode()
        emitter.particleRotationRange = .pi / 2

        #expect(emitter.particleRotationRange == .pi / 2)
    }

    @Test("Rotation speed can be set")
    func testRotationSpeedSet() {
        let emitter = SKEmitterNode()
        emitter.particleRotationSpeed = 1.0

        #expect(emitter.particleRotationSpeed == 1.0)
    }
}

// MARK: - SKEmitterNode Particle Color Tests

@Suite("SKEmitterNode Particle Color")
struct SKEmitterNodeParticleColorTests {

    @Test("Color defaults to white")
    func testColorDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.particleColor == .white)
    }

    @Test("Color can be changed")
    func testColorChange() {
        let emitter = SKEmitterNode()
        emitter.particleColor = .red

        #expect(emitter.particleColor != .white)
    }

    @Test("Color alpha speed can be set")
    func testColorAlphaSpeedSet() {
        let emitter = SKEmitterNode()
        emitter.particleColorAlphaSpeed = -0.5

        #expect(emitter.particleColorAlphaSpeed == -0.5)
    }

    @Test("Color blend factor can be set")
    func testColorBlendFactorSet() {
        let emitter = SKEmitterNode()
        emitter.particleColorBlendFactor = 0.5

        #expect(emitter.particleColorBlendFactor == 0.5)
    }
}

// MARK: - SKEmitterNode Target Node Tests

@Suite("SKEmitterNode Target Node")
struct SKEmitterNodeTargetNodeTests {

    @Test("Target node is nil by default")
    func testTargetNodeDefault() {
        let emitter = SKEmitterNode()

        #expect(emitter.targetNode == nil)
    }

    @Test("Target node can be set")
    func testTargetNodeSet() {
        let emitter = SKEmitterNode()
        let target = SKNode()
        emitter.targetNode = target

        #expect(emitter.targetNode === target)
    }
}

// MARK: - SKParticleRenderOrder Tests

@Suite("SKParticleRenderOrder")
struct SKParticleRenderOrderTests {

    @Test("Raw values are correct")
    func testRawValues() {
        #expect(SKParticleRenderOrder.oldestFirst.rawValue == 0)
        #expect(SKParticleRenderOrder.oldestLast.rawValue == 1)
        #expect(SKParticleRenderOrder.dontCare.rawValue == 2)
    }
}

// MARK: - SKKeyframeSequence Tests

@Suite("SKKeyframeSequence")
struct SKKeyframeSequenceTests {

    @Test("Keyframe sequence can be created with values and times")
    func testKeyframeSequenceCreation() {
        let keyframes = SKKeyframeSequence(keyframeValues: [0.0, 1.0, 0.0] as [NSNumber], times: [0.0, 0.5, 1.0])

        #expect(keyframes.count() == 3)
    }

    @Test("Interpolation mode defaults to linear")
    func testInterpolationModeDefault() {
        let keyframes = SKKeyframeSequence(keyframeValues: [0.0, 1.0] as [NSNumber], times: [0.0, 1.0])

        #expect(keyframes.interpolationMode == .linear)
    }

    @Test("Repeat mode defaults to clamp")
    func testRepeatModeDefault() {
        let keyframes = SKKeyframeSequence(keyframeValues: [0.0, 1.0] as [NSNumber], times: [0.0, 1.0])

        #expect(keyframes.repeatMode == .clamp)
    }
}
