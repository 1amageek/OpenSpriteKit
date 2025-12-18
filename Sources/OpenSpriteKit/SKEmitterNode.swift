// SKEmitterNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(QuartzCore)
import QuartzCore
#else
import OpenCoreAnimation
#endif

/// A source of various particle effects.
///
/// A `SKEmitterNode` object is a node that automatically creates and renders small particle sprites.
/// Particles are privately owned by SpriteKit—your game cannot access the generated sprites.
/// Emitter nodes are often used to create smoke, fire, sparks, and other particle effects.
open class SKEmitterNode: SKNode {

    // MARK: - Layer Class Override

    /// Returns CAEmitterLayer as the backing layer class.
    open override class var layerClass: CALayer.Type {
        return CAEmitterLayer.self
    }

    /// The backing CAEmitterLayer for rendering.
    public var emitterLayer: CAEmitterLayer {
        return layer as! CAEmitterLayer
    }

    /// The backing CAEmitterCell that defines particle properties.
    private lazy var emitterCell: CAEmitterCell = {
        let cell = CAEmitterCell()
        return cell
    }()

    // MARK: - Layer Synchronization

    /// Updates the emitter layer with current particle properties.
    private func updateEmitterLayer() {
        // Configure emitter cell with particle properties
        emitterCell.birthRate = Float(particleBirthRate)
        emitterCell.lifetime = Float(particleLifetime)
        emitterCell.lifetimeRange = Float(particleLifetimeRange)
        emitterCell.velocity = particleSpeed
        emitterCell.velocityRange = particleSpeedRange
        emitterCell.emissionLongitude = emissionAngle
        emitterCell.emissionRange = emissionAngleRange
        emitterCell.xAcceleration = xAcceleration
        emitterCell.yAcceleration = yAcceleration
        emitterCell.spin = particleRotationSpeed
        emitterCell.spinRange = particleRotationRange
        emitterCell.scale = particleScale
        emitterCell.scaleRange = particleScaleRange
        emitterCell.scaleSpeed = particleScaleSpeed
        emitterCell.alphaSpeed = Float(particleAlphaSpeed)
        emitterCell.alphaRange = Float(particleAlphaRange)
        emitterCell.color = particleColor.cgColor
        emitterCell.contents = particleTexture?.cgImage

        // Set the emitter cell
        emitterLayer.emitterCells = [emitterCell]

        // Configure emitter layer
        emitterLayer.emitterPosition = particlePosition
        emitterLayer.birthRate = 1.0
        emitterLayer.lifetime = 1.0
    }

    // MARK: - Target Node

    /// The target node that renders the emitter's particles.
    open weak var targetNode: SKNode?

    // MARK: - Particle Creation Properties

    /// The rate at which new particles are created.
    open var particleBirthRate: CGFloat = 0.0 {
        didSet {
            emitterCell.birthRate = Float(particleBirthRate)
        }
    }

    /// The number of particles the emitter should emit before stopping.
    open var numParticlesToEmit: Int = 0

    /// The order in which the emitter's particles are rendered.
    open var particleRenderOrder: SKParticleRenderOrder = .oldestFirst

    // MARK: - Particle Lifetime Properties

    /// The average lifetime of a particle, in seconds.
    open var particleLifetime: CGFloat = 0.0

    /// The range of allowed random values for a particle's lifetime.
    open var particleLifetimeRange: CGFloat = 0.0

    // MARK: - Particle Position Properties

    /// The average starting position for a particle.
    open var particlePosition: CGPoint = .zero

    /// The range of allowed random values for a particle's position.
    open var particlePositionRange: CGVector = .zero

    /// The average starting depth of a particle.
    open var particleZPosition: CGFloat = 0.0

    /// The range of allowed random values for a particle's depth.
    open var particleZPositionRange: CGFloat = 0.0

    // MARK: - Particle Velocity Properties

    /// The average initial speed of a new particle, in points per second.
    open var particleSpeed: CGFloat = 0.0

    /// The range of allowed random values for a particle's initial speed.
    open var particleSpeedRange: CGFloat = 0.0

    /// The average initial direction of a particle, expressed as an angle in radians.
    open var emissionAngle: CGFloat = 0.0

    /// The range of allowed random values for a particle's initial direction.
    open var emissionAngleRange: CGFloat = 0.0

    /// The acceleration to apply to a particle's horizontal velocity.
    open var xAcceleration: CGFloat = 0.0

    /// The acceleration to apply to a particle's vertical velocity.
    open var yAcceleration: CGFloat = 0.0

    /// The speed at which the particle's depth changes.
    open var particleZPositionSpeed: CGFloat = 0.0

    // MARK: - Particle Rotation Properties

    /// The average initial rotation of a particle, expressed as an angle in radians.
    open var particleRotation: CGFloat = 0.0

    /// The range of allowed random values for a particle's initial rotation.
    open var particleRotationRange: CGFloat = 0.0

    /// The speed at which a particle rotates, expressed in radians per second.
    open var particleRotationSpeed: CGFloat = 0.0

    // MARK: - Particle Scale Properties

    /// The average initial scale factor of a particle.
    open var particleScale: CGFloat = 1.0

    /// The range of allowed random values for a particle's initial scale.
    open var particleScaleRange: CGFloat = 0.0

    /// The rate at which a particle's scale factor changes per second.
    open var particleScaleSpeed: CGFloat = 0.0

    /// The sequence used to specify the scale factor of a particle over its lifetime.
    open var particleScaleSequence: SKKeyframeSequence?

    // MARK: - Particle Texture Properties

    /// The texture to use to render a particle.
    open var particleTexture: SKTexture?

    /// The starting size of each particle.
    open var particleSize: CGSize = .zero

    // MARK: - Particle Color Properties

    /// The sequence used to specify the color components of a particle over its lifetime.
    open var particleColorSequence: SKKeyframeSequence?

    /// The average initial color for a particle.
    open var particleColor: SKColor = .white

    /// The range of allowed random values for the alpha component of a particle's initial color.
    open var particleColorAlphaRange: CGFloat = 0.0

    /// The range of allowed random values for the blue component of a particle's initial color.
    open var particleColorBlueRange: CGFloat = 0.0

    /// The range of allowed random values for the green component of a particle's initial color.
    open var particleColorGreenRange: CGFloat = 0.0

    /// The range of allowed random values for the red component of a particle's initial color.
    open var particleColorRedRange: CGFloat = 0.0

    /// The rate at which the alpha component of a particle's color changes per second.
    open var particleColorAlphaSpeed: CGFloat = 0.0

    /// The rate at which the blue component of a particle's color changes per second.
    open var particleColorBlueSpeed: CGFloat = 0.0

    /// The rate at which the green component of a particle's color changes per second.
    open var particleColorGreenSpeed: CGFloat = 0.0

    /// The rate at which the red component of a particle's color changes per second.
    open var particleColorRedSpeed: CGFloat = 0.0

    // MARK: - Particle Color Blend Properties

    /// The sequence used to specify the color blend factor of a particle over its lifetime.
    open var particleColorBlendFactorSequence: SKKeyframeSequence?

    /// The average starting value for the color blend factor.
    open var particleColorBlendFactor: CGFloat = 0.0

    /// The range of allowed random values for a particle's starting color blend factor.
    open var particleColorBlendFactorRange: CGFloat = 0.0

    /// The rate at which the color blend factor changes per second.
    open var particleColorBlendFactorSpeed: CGFloat = 0.0

    // MARK: - Particle Blending Properties

    /// The blending mode used to blend particles into the framebuffer.
    open var particleBlendMode: SKBlendMode = .alpha

    /// The sequence used to specify the alpha value of a particle over its lifetime.
    open var particleAlphaSequence: SKKeyframeSequence?

    /// The average starting alpha value for a particle.
    open var particleAlpha: CGFloat = 1.0

    /// The range of allowed random values for a particle's starting alpha value.
    open var particleAlphaRange: CGFloat = 0.0

    /// The rate at which the alpha value of a particle changes per second.
    open var particleAlphaSpeed: CGFloat = 0.0

    // MARK: - Particle Action

    /// An action executed by new particles.
    open var particleAction: SKAction?

    // MARK: - Physics Field Properties

    /// A mask that defines which categories of physics fields can exert forces on the particles.
    open var fieldBitMask: UInt32 = 0

    // MARK: - Shader Properties

    /// A custom shader used to determine how particles are rendered.
    open var shader: SKShader?

    /// The values of each attribute associated with the node's attached shader.
    open var attributeValues: [String: SKAttributeValue] = [:]

    // MARK: - Internal Particle System

    /// The internal particle system for simulation.
    internal lazy var particleSystem: SKParticleSystem = {
        return SKParticleSystem(emitter: self)
    }()

    /// Sprite nodes used to render particles.
    private var particleSprites: [SKSpriteNode] = []

    /// The maximum number of particle sprites to reuse.
    private let maxParticleSprites: Int = 1000

    // MARK: - Initializers

    /// Creates a new emitter node.
    public override init() {
        super.init()
    }

    /// Creates an emitter node from an archived file.
    ///
    /// - Parameter fileNamed: The name of the emitter file (without extension).
    /// - Returns: A new emitter node, or nil if the file could not be loaded.
    public class func emitter(fileNamed name: String) -> SKEmitterNode? {
        // TODO: Load from file
        return nil
    }

    public required init?(coder: NSCoder) {
        // Creation properties
        particleBirthRate = CGFloat(coder.decodeDouble(forKey: "particleBirthRate"))
        numParticlesToEmit = coder.decodeInteger(forKey: "numParticlesToEmit")
        particleRenderOrder = SKParticleRenderOrder(rawValue: coder.decodeInteger(forKey: "particleRenderOrder")) ?? .oldestFirst

        // Lifetime
        particleLifetime = CGFloat(coder.decodeDouble(forKey: "particleLifetime"))
        particleLifetimeRange = CGFloat(coder.decodeDouble(forKey: "particleLifetimeRange"))

        // Position
        particlePosition = coder.decodeCGPoint(forKey: "particlePosition")
        particlePositionRange = coder.decodeCGVector(forKey: "particlePositionRange")
        particleZPosition = CGFloat(coder.decodeDouble(forKey: "particleZPosition"))
        particleZPositionRange = CGFloat(coder.decodeDouble(forKey: "particleZPositionRange"))
        particleZPositionSpeed = CGFloat(coder.decodeDouble(forKey: "particleZPositionSpeed"))

        // Velocity
        particleSpeed = CGFloat(coder.decodeDouble(forKey: "particleSpeed"))
        particleSpeedRange = CGFloat(coder.decodeDouble(forKey: "particleSpeedRange"))
        emissionAngle = CGFloat(coder.decodeDouble(forKey: "emissionAngle"))
        emissionAngleRange = CGFloat(coder.decodeDouble(forKey: "emissionAngleRange"))
        xAcceleration = CGFloat(coder.decodeDouble(forKey: "xAcceleration"))
        yAcceleration = CGFloat(coder.decodeDouble(forKey: "yAcceleration"))

        // Rotation
        particleRotation = CGFloat(coder.decodeDouble(forKey: "particleRotation"))
        particleRotationRange = CGFloat(coder.decodeDouble(forKey: "particleRotationRange"))
        particleRotationSpeed = CGFloat(coder.decodeDouble(forKey: "particleRotationSpeed"))

        // Scale
        particleScale = CGFloat(coder.decodeDouble(forKey: "particleScale"))
        particleScaleRange = CGFloat(coder.decodeDouble(forKey: "particleScaleRange"))
        particleScaleSpeed = CGFloat(coder.decodeDouble(forKey: "particleScaleSpeed"))
        particleScaleSequence = coder.decodeObject(of: SKKeyframeSequence.self, forKey: "particleScaleSequence")

        // Texture and size
        particleTexture = coder.decodeObject(of: SKTexture.self, forKey: "particleTexture")
        particleSize = coder.decodeCGSize(forKey: "particleSize")

        // Color
        if let colorData = coder.decodeObject(of: NSData.self, forKey: "particleColor") as Data?,
           let unarchivedColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SKColor.self, from: colorData) {
            particleColor = unarchivedColor
        }
        particleColorAlphaRange = CGFloat(coder.decodeDouble(forKey: "particleColorAlphaRange"))
        particleColorBlueRange = CGFloat(coder.decodeDouble(forKey: "particleColorBlueRange"))
        particleColorGreenRange = CGFloat(coder.decodeDouble(forKey: "particleColorGreenRange"))
        particleColorRedRange = CGFloat(coder.decodeDouble(forKey: "particleColorRedRange"))
        particleColorAlphaSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorAlphaSpeed"))
        particleColorBlueSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorBlueSpeed"))
        particleColorGreenSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorGreenSpeed"))
        particleColorRedSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorRedSpeed"))
        particleColorSequence = coder.decodeObject(of: SKKeyframeSequence.self, forKey: "particleColorSequence")

        // Color blend
        particleColorBlendFactor = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactor"))
        particleColorBlendFactorRange = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactorRange"))
        particleColorBlendFactorSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactorSpeed"))
        particleColorBlendFactorSequence = coder.decodeObject(of: SKKeyframeSequence.self, forKey: "particleColorBlendFactorSequence")

        // Alpha
        particleAlpha = CGFloat(coder.decodeDouble(forKey: "particleAlpha"))
        particleAlphaRange = CGFloat(coder.decodeDouble(forKey: "particleAlphaRange"))
        particleAlphaSpeed = CGFloat(coder.decodeDouble(forKey: "particleAlphaSpeed"))
        particleAlphaSequence = coder.decodeObject(of: SKKeyframeSequence.self, forKey: "particleAlphaSequence")

        // Blending
        particleBlendMode = SKBlendMode(rawValue: coder.decodeInteger(forKey: "particleBlendMode")) ?? .alpha

        // Physics
        fieldBitMask = UInt32(coder.decodeInt32(forKey: "fieldBitMask"))

        // Shader
        shader = coder.decodeObject(of: SKShader.self, forKey: "shader")

        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        // Creation properties
        coder.encode(Double(particleBirthRate), forKey: "particleBirthRate")
        coder.encode(numParticlesToEmit, forKey: "numParticlesToEmit")
        coder.encode(particleRenderOrder.rawValue, forKey: "particleRenderOrder")

        // Lifetime
        coder.encode(Double(particleLifetime), forKey: "particleLifetime")
        coder.encode(Double(particleLifetimeRange), forKey: "particleLifetimeRange")

        // Position
        coder.encode(particlePosition, forKey: "particlePosition")
        coder.encode(particlePositionRange, forKey: "particlePositionRange")
        coder.encode(Double(particleZPosition), forKey: "particleZPosition")
        coder.encode(Double(particleZPositionRange), forKey: "particleZPositionRange")
        coder.encode(Double(particleZPositionSpeed), forKey: "particleZPositionSpeed")

        // Velocity
        coder.encode(Double(particleSpeed), forKey: "particleSpeed")
        coder.encode(Double(particleSpeedRange), forKey: "particleSpeedRange")
        coder.encode(Double(emissionAngle), forKey: "emissionAngle")
        coder.encode(Double(emissionAngleRange), forKey: "emissionAngleRange")
        coder.encode(Double(xAcceleration), forKey: "xAcceleration")
        coder.encode(Double(yAcceleration), forKey: "yAcceleration")

        // Rotation
        coder.encode(Double(particleRotation), forKey: "particleRotation")
        coder.encode(Double(particleRotationRange), forKey: "particleRotationRange")
        coder.encode(Double(particleRotationSpeed), forKey: "particleRotationSpeed")

        // Scale
        coder.encode(Double(particleScale), forKey: "particleScale")
        coder.encode(Double(particleScaleRange), forKey: "particleScaleRange")
        coder.encode(Double(particleScaleSpeed), forKey: "particleScaleSpeed")
        coder.encode(particleScaleSequence, forKey: "particleScaleSequence")

        // Texture and size
        coder.encode(particleTexture, forKey: "particleTexture")
        coder.encode(particleSize, forKey: "particleSize")

        // Color
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: particleColor, requiringSecureCoding: true) {
            coder.encode(colorData, forKey: "particleColor")
        }
        coder.encode(Double(particleColorAlphaRange), forKey: "particleColorAlphaRange")
        coder.encode(Double(particleColorBlueRange), forKey: "particleColorBlueRange")
        coder.encode(Double(particleColorGreenRange), forKey: "particleColorGreenRange")
        coder.encode(Double(particleColorRedRange), forKey: "particleColorRedRange")
        coder.encode(Double(particleColorAlphaSpeed), forKey: "particleColorAlphaSpeed")
        coder.encode(Double(particleColorBlueSpeed), forKey: "particleColorBlueSpeed")
        coder.encode(Double(particleColorGreenSpeed), forKey: "particleColorGreenSpeed")
        coder.encode(Double(particleColorRedSpeed), forKey: "particleColorRedSpeed")
        coder.encode(particleColorSequence, forKey: "particleColorSequence")

        // Color blend
        coder.encode(Double(particleColorBlendFactor), forKey: "particleColorBlendFactor")
        coder.encode(Double(particleColorBlendFactorRange), forKey: "particleColorBlendFactorRange")
        coder.encode(Double(particleColorBlendFactorSpeed), forKey: "particleColorBlendFactorSpeed")
        coder.encode(particleColorBlendFactorSequence, forKey: "particleColorBlendFactorSequence")

        // Alpha
        coder.encode(Double(particleAlpha), forKey: "particleAlpha")
        coder.encode(Double(particleAlphaRange), forKey: "particleAlphaRange")
        coder.encode(Double(particleAlphaSpeed), forKey: "particleAlphaSpeed")
        coder.encode(particleAlphaSequence, forKey: "particleAlphaSequence")

        // Blending
        coder.encode(particleBlendMode.rawValue, forKey: "particleBlendMode")

        // Physics
        coder.encode(Int32(fieldBitMask), forKey: "fieldBitMask")

        // Shader
        coder.encode(shader, forKey: "shader")
    }

    // MARK: - Simulation Methods

    /// Advances the emitter particle simulation.
    ///
    /// - Parameter sec: The number of seconds to advance the simulation.
    open func advanceSimulationTime(_ sec: TimeInterval) {
        particleSystem.advanceSimulation(by: sec)
        updateParticleSprites()
    }

    /// Removes all existing particles and restarts the simulation.
    open func resetSimulation() {
        particleSystem.reset()
        // Remove all particle sprites
        for sprite in particleSprites {
            sprite.removeFromParent()
        }
        particleSprites.removeAll()
    }

    /// Updates the particle simulation for the current frame.
    ///
    /// This is called internally by the frame cycle.
    internal func updateParticles(deltaTime: TimeInterval) {
        particleSystem.update(deltaTime: deltaTime)
        updateParticleSprites()
    }

    /// Updates particle sprite nodes to match the particle system state.
    private func updateParticleSprites() {
        // Get particles sorted by render order
        let sortedParticles = particleSystem.sortedParticles(order: particleRenderOrder)
        let targetNode = self.targetNode ?? self

        // Calculate emitter's position in target node's coordinate space
        // When targetNode is set, particles are positioned relative to the target,
        // but their birth position is relative to the emitter
        let emitterPositionInTarget: CGPoint
        if let target = self.targetNode, target !== self {
            // Convert emitter's position to target node's coordinate space
            if let scene = self.scene {
                let emitterWorldPos = scene.convert(self.position, from: self.parent ?? scene)
                emitterPositionInTarget = scene.convert(emitterWorldPos, to: target)
            } else {
                emitterPositionInTarget = self.position
            }
        } else {
            emitterPositionInTarget = .zero
        }

        // Ensure we have enough sprites
        while particleSprites.count < sortedParticles.count && particleSprites.count < maxParticleSprites {
            let sprite = SKSpriteNode()
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            particleSprites.append(sprite)
        }

        // Update active sprites
        for (index, particle) in sortedParticles.enumerated() {
            guard index < particleSprites.count else { break }

            let sprite = particleSprites[index]

            // Add to target node if needed
            if sprite.parent == nil {
                targetNode.addChild(sprite)
            } else if sprite.parent !== targetNode {
                sprite.removeFromParent()
                targetNode.addChild(sprite)
            }

            // Update sprite position (offset by emitter position when using targetNode)
            if self.targetNode != nil && self.targetNode !== self {
                sprite.position = CGPoint(
                    x: emitterPositionInTarget.x + particle.position.x,
                    y: emitterPositionInTarget.y + particle.position.y
                )
            } else {
                sprite.position = particle.position
            }

            // Update Z position
            sprite.zPosition = particle.zPosition

            // Update scale
            sprite.xScale = particle.scale
            sprite.yScale = particle.scale

            // Update rotation
            sprite.zRotation = particle.rotation

            // Update alpha (particle alpha * color alpha)
            sprite.alpha = particle.alpha * particle.color.a

            // Update texture and size
            if let texture = particleTexture {
                sprite.texture = texture
                if particleSize != .zero {
                    sprite.size = particleSize
                } else {
                    sprite.size = texture.size
                }
            } else {
                // Use a default size for untextured particles
                sprite.texture = nil
                sprite.size = particleSize != .zero ? particleSize : CGSize(width: 8, height: 8)
            }

            // Update color with blend factor
            let blendFactor = particle.colorBlendFactor
            if blendFactor > 0 {
                sprite.color = SKColor(
                    red: particle.color.r,
                    green: particle.color.g,
                    blue: particle.color.b,
                    alpha: 1.0
                )
                sprite.colorBlendFactor = blendFactor
            } else {
                sprite.colorBlendFactor = 0.0
            }

            sprite.isHidden = false
        }

        // Hide unused sprites
        for index in sortedParticles.count..<particleSprites.count {
            particleSprites[index].isHidden = true
        }
    }

    // MARK: - Shader Attribute Methods

    /// Sets an attribute value for an attached shader.
    ///
    /// - Parameters:
    ///   - value: The attribute value to set.
    ///   - key: The name of the attribute.
    open func setValue(_ value: SKAttributeValue, forAttribute key: String) {
        attributeValues[key] = value
    }

    /// Gets the value of a shader attribute.
    ///
    /// - Parameter name: The name of the attribute.
    /// - Returns: The attribute value, or nil if not found.
    open func value(forAttributeNamed name: String) -> SKAttributeValue? {
        return attributeValues[name]
    }
}

// MARK: - SKParticleRenderOrder

/// The order to use when the emitter's particles are rendered.
public enum SKParticleRenderOrder: Int, Sendable, Hashable {
    /// Particles are rendered in the order they were created (oldest first).
    case oldestFirst = 0

    /// Particles are rendered in reverse order (oldest last).
    case oldestLast = 1

    /// Particles are rendered front to back based on their z-position.
    case dontCare = 2
}

// MARK: - SKKeyframeSequence

/// A sequence of values that controls properties over time.
///
/// An `SKKeyframeSequence` defines a series of keyframe values and times that can
/// be used to animate particle properties.
open class SKKeyframeSequence: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Properties

    /// The keyframe values.
    private var keyframeValues: [Any] = []

    /// The keyframe times (normalized from 0.0 to 1.0).
    private var keyframeTimes: [NSNumber] = []

    /// The interpolation mode for the sequence.
    open var interpolationMode: SKInterpolationMode = .linear

    /// The repeat mode for the sequence.
    open var repeatMode: SKRepeatMode = .clamp

    // MARK: - Initializers

    /// Creates an empty keyframe sequence.
    public override init() {
        super.init()
    }

    /// Creates a keyframe sequence with the specified values and times.
    ///
    /// - Parameters:
    ///   - values: The keyframe values.
    ///   - times: The keyframe times (must be sorted and in range 0.0 to 1.0).
    public init(keyframeValues values: [Any], times: [NSNumber]) {
        self.keyframeValues = values
        self.keyframeTimes = times
        super.init()
    }

    /// Creates a keyframe sequence with a single keyframe.
    ///
    /// - Parameter value: The constant value.
    public convenience init(capacity numItems: Int) {
        self.init()
    }

    public required init?(coder: NSCoder) {
        keyframeValues = coder.decodeObject(forKey: "keyframeValues") as? [Any] ?? []
        keyframeTimes = coder.decodeObject(forKey: "keyframeTimes") as? [NSNumber] ?? []
        interpolationMode = SKInterpolationMode(rawValue: coder.decodeInteger(forKey: "interpolationMode")) ?? .linear
        repeatMode = SKRepeatMode(rawValue: coder.decodeInteger(forKey: "repeatMode")) ?? .clamp
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(keyframeValues, forKey: "keyframeValues")
        coder.encode(keyframeTimes, forKey: "keyframeTimes")
        coder.encode(interpolationMode.rawValue, forKey: "interpolationMode")
        coder.encode(repeatMode.rawValue, forKey: "repeatMode")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKKeyframeSequence(keyframeValues: keyframeValues, times: keyframeTimes)
        copy.interpolationMode = interpolationMode
        copy.repeatMode = repeatMode
        return copy
    }

    // MARK: - Keyframe Management

    /// Returns the number of keyframes in the sequence.
    open func count() -> Int {
        return keyframeValues.count
    }

    /// Adds a keyframe to the sequence.
    ///
    /// - Parameters:
    ///   - value: The keyframe value.
    ///   - time: The keyframe time.
    open func addKeyframeValue(_ value: Any, time: CGFloat) {
        keyframeValues.append(value)
        keyframeTimes.append(NSNumber(value: Float(time)))
    }

    /// Removes the last keyframe from the sequence.
    open func removeLastKeyframe() {
        if !keyframeValues.isEmpty {
            keyframeValues.removeLast()
            keyframeTimes.removeLast()
        }
    }

    /// Removes the keyframe at the specified index.
    ///
    /// - Parameter index: The index of the keyframe to remove.
    open func removeKeyframe(at index: Int) {
        guard index < keyframeValues.count else { return }
        keyframeValues.remove(at: index)
        keyframeTimes.remove(at: index)
    }

    /// Sets the keyframe value at the specified index.
    ///
    /// - Parameters:
    ///   - value: The new keyframe value.
    ///   - index: The index of the keyframe.
    open func setKeyframeValue(_ value: Any, for index: Int) {
        guard index < keyframeValues.count else { return }
        keyframeValues[index] = value
    }

    /// Sets the keyframe time at the specified index.
    ///
    /// - Parameters:
    ///   - time: The new keyframe time.
    ///   - index: The index of the keyframe.
    open func setKeyframeTime(_ time: CGFloat, for index: Int) {
        guard index < keyframeTimes.count else { return }
        keyframeTimes[index] = NSNumber(value: Float(time))
    }

    /// Sets the keyframe value and time at the specified index.
    ///
    /// - Parameters:
    ///   - value: The new keyframe value.
    ///   - time: The new keyframe time.
    ///   - index: The index of the keyframe.
    open func setKeyframeValue(_ value: Any, time: CGFloat, for index: Int) {
        setKeyframeValue(value, for: index)
        setKeyframeTime(time, for: index)
    }

    /// Returns the keyframe value at the specified index.
    ///
    /// - Parameter index: The index of the keyframe.
    /// - Returns: The keyframe value.
    open func getKeyframeValue(for index: Int) -> Any? {
        guard index < keyframeValues.count else { return nil }
        return keyframeValues[index]
    }

    /// Returns the keyframe time at the specified index.
    ///
    /// - Parameter index: The index of the keyframe.
    /// - Returns: The keyframe time.
    open func getKeyframeTime(for index: Int) -> CGFloat {
        guard index < keyframeTimes.count else { return 0 }
        return CGFloat(keyframeTimes[index].floatValue)
    }

    /// Samples the sequence at the specified time.
    ///
    /// - Parameter time: The time to sample (0.0 to 1.0).
    /// - Returns: The interpolated value at the specified time.
    open func sample(atTime time: CGFloat) -> Any? {
        guard !keyframeValues.isEmpty, !keyframeTimes.isEmpty else { return nil }
        guard keyframeValues.count == keyframeTimes.count else { return keyframeValues.first }

        // Handle repeat mode
        var normalizedTime = time
        switch repeatMode {
        case .clamp:
            normalizedTime = max(0, min(1, time))
        case .loop:
            normalizedTime = time - floor(time)
        }

        // Find the two keyframes to interpolate between
        var lowerIndex = 0
        var upperIndex = keyframeTimes.count - 1

        for i in 0..<keyframeTimes.count {
            let keyTime = CGFloat(keyframeTimes[i].floatValue)
            if keyTime <= normalizedTime {
                lowerIndex = i
            }
            if keyTime >= normalizedTime {
                upperIndex = i
                break
            }
        }

        // If same index or step mode, return the lower value
        if lowerIndex == upperIndex || interpolationMode == .step {
            return keyframeValues[lowerIndex]
        }

        let lowerTime = CGFloat(keyframeTimes[lowerIndex].floatValue)
        let upperTime = CGFloat(keyframeTimes[upperIndex].floatValue)
        let lowerValue = keyframeValues[lowerIndex]
        let upperValue = keyframeValues[upperIndex]

        // Calculate interpolation factor
        let timeDiff = upperTime - lowerTime
        guard timeDiff > 0 else { return lowerValue }

        let t = (normalizedTime - lowerTime) / timeDiff

        // Interpolate based on value type and mode
        return interpolate(from: lowerValue, to: upperValue, t: t)
    }

    /// Interpolates between two values.
    private func interpolate(from: Any, to: Any, t: CGFloat) -> Any {
        // Handle CGFloat
        if let fromFloat = from as? CGFloat, let toFloat = to as? CGFloat {
            return interpolateFloat(fromFloat, toFloat, t: t)
        }

        // Handle NSNumber
        if let fromNumber = from as? NSNumber, let toNumber = to as? NSNumber {
            let fromFloat = CGFloat(fromNumber.doubleValue)
            let toFloat = CGFloat(toNumber.doubleValue)
            return NSNumber(value: Double(interpolateFloat(fromFloat, toFloat, t: t)))
        }

        // Handle Double
        if let fromDouble = from as? Double, let toDouble = to as? Double {
            return Double(interpolateFloat(CGFloat(fromDouble), CGFloat(toDouble), t: t))
        }

        // Handle Float
        if let fromFloat = from as? Float, let toFloat = to as? Float {
            return Float(interpolateFloat(CGFloat(fromFloat), CGFloat(toFloat), t: t))
        }

        // Handle SKColor/UIColor
        if let fromColor = from as? SKColor, let toColor = to as? SKColor {
            return interpolateColor(fromColor, toColor, t: t)
        }

        // Handle CGPoint
        if let fromPoint = from as? CGPoint, let toPoint = to as? CGPoint {
            return CGPoint(
                x: interpolateFloat(fromPoint.x, toPoint.x, t: t),
                y: interpolateFloat(fromPoint.y, toPoint.y, t: t)
            )
        }

        // Handle CGSize
        if let fromSize = from as? CGSize, let toSize = to as? CGSize {
            return CGSize(
                width: interpolateFloat(fromSize.width, toSize.width, t: t),
                height: interpolateFloat(fromSize.height, toSize.height, t: t)
            )
        }

        // Handle CGVector
        if let fromVector = from as? CGVector, let toVector = to as? CGVector {
            return CGVector(
                dx: interpolateFloat(fromVector.dx, toVector.dx, t: t),
                dy: interpolateFloat(fromVector.dy, toVector.dy, t: t)
            )
        }

        // Default: return from value (no interpolation possible)
        return from
    }

    /// Interpolates between two float values.
    private func interpolateFloat(_ from: CGFloat, _ to: CGFloat, t: CGFloat) -> CGFloat {
        switch interpolationMode {
        case .linear:
            return from + (to - from) * t
        case .spline:
            // Smooth step interpolation (ease in-out)
            let smoothT = t * t * (3 - 2 * t)
            return from + (to - from) * smoothT
        case .step:
            return from
        }
    }

    /// Interpolates between two colors.
    private func interpolateColor(_ from: SKColor, _ to: SKColor, t: CGFloat) -> SKColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0

        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)

        return SKColor(
            red: interpolateFloat(fromR, toR, t: t),
            green: interpolateFloat(fromG, toG, t: t),
            blue: interpolateFloat(fromB, toB, t: t),
            alpha: interpolateFloat(fromA, toA, t: t)
        )
    }
}

// MARK: - SKInterpolationMode

/// The modes used to interpolate between keyframes in the sequence.
public enum SKInterpolationMode: Int, Sendable, Hashable {
    /// Linear interpolation between keyframes.
    case linear = 0

    /// Spline interpolation between keyframes.
    case spline = 1

    /// Step function interpolation (no interpolation).
    case step = 2
}

// MARK: - SKRepeatMode

/// The modes used to determine how the sequence repeats.
public enum SKRepeatMode: Int, Sendable, Hashable {
    /// The sequence clamps to the first/last value outside the range.
    case clamp = 0

    /// The sequence loops back to the beginning.
    case loop = 1
}
