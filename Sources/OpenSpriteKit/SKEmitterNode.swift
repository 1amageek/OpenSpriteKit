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
        particleBirthRate = CGFloat(coder.decodeDouble(forKey: "particleBirthRate"))
        numParticlesToEmit = coder.decodeInteger(forKey: "numParticlesToEmit")
        particleRenderOrder = SKParticleRenderOrder(rawValue: coder.decodeInteger(forKey: "particleRenderOrder")) ?? .oldestFirst
        particleLifetime = CGFloat(coder.decodeDouble(forKey: "particleLifetime"))
        particleLifetimeRange = CGFloat(coder.decodeDouble(forKey: "particleLifetimeRange"))
        particleSpeed = CGFloat(coder.decodeDouble(forKey: "particleSpeed"))
        particleSpeedRange = CGFloat(coder.decodeDouble(forKey: "particleSpeedRange"))
        emissionAngle = CGFloat(coder.decodeDouble(forKey: "emissionAngle"))
        emissionAngleRange = CGFloat(coder.decodeDouble(forKey: "emissionAngleRange"))
        xAcceleration = CGFloat(coder.decodeDouble(forKey: "xAcceleration"))
        yAcceleration = CGFloat(coder.decodeDouble(forKey: "yAcceleration"))
        particleRotation = CGFloat(coder.decodeDouble(forKey: "particleRotation"))
        particleRotationRange = CGFloat(coder.decodeDouble(forKey: "particleRotationRange"))
        particleRotationSpeed = CGFloat(coder.decodeDouble(forKey: "particleRotationSpeed"))
        particleScale = CGFloat(coder.decodeDouble(forKey: "particleScale"))
        particleScaleRange = CGFloat(coder.decodeDouble(forKey: "particleScaleRange"))
        particleScaleSpeed = CGFloat(coder.decodeDouble(forKey: "particleScaleSpeed"))
        particleAlpha = CGFloat(coder.decodeDouble(forKey: "particleAlpha"))
        particleAlphaRange = CGFloat(coder.decodeDouble(forKey: "particleAlphaRange"))
        particleAlphaSpeed = CGFloat(coder.decodeDouble(forKey: "particleAlphaSpeed"))
        particleColorBlendFactor = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactor"))
        particleColorBlendFactorRange = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactorRange"))
        particleColorBlendFactorSpeed = CGFloat(coder.decodeDouble(forKey: "particleColorBlendFactorSpeed"))
        particleBlendMode = SKBlendMode(rawValue: coder.decodeInteger(forKey: "particleBlendMode")) ?? .alpha
        fieldBitMask = UInt32(coder.decodeInt32(forKey: "fieldBitMask"))
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(particleBirthRate), forKey: "particleBirthRate")
        coder.encode(numParticlesToEmit, forKey: "numParticlesToEmit")
        coder.encode(particleRenderOrder.rawValue, forKey: "particleRenderOrder")
        coder.encode(Double(particleLifetime), forKey: "particleLifetime")
        coder.encode(Double(particleLifetimeRange), forKey: "particleLifetimeRange")
        coder.encode(Double(particleSpeed), forKey: "particleSpeed")
        coder.encode(Double(particleSpeedRange), forKey: "particleSpeedRange")
        coder.encode(Double(emissionAngle), forKey: "emissionAngle")
        coder.encode(Double(emissionAngleRange), forKey: "emissionAngleRange")
        coder.encode(Double(xAcceleration), forKey: "xAcceleration")
        coder.encode(Double(yAcceleration), forKey: "yAcceleration")
        coder.encode(Double(particleRotation), forKey: "particleRotation")
        coder.encode(Double(particleRotationRange), forKey: "particleRotationRange")
        coder.encode(Double(particleRotationSpeed), forKey: "particleRotationSpeed")
        coder.encode(Double(particleScale), forKey: "particleScale")
        coder.encode(Double(particleScaleRange), forKey: "particleScaleRange")
        coder.encode(Double(particleScaleSpeed), forKey: "particleScaleSpeed")
        coder.encode(Double(particleAlpha), forKey: "particleAlpha")
        coder.encode(Double(particleAlphaRange), forKey: "particleAlphaRange")
        coder.encode(Double(particleAlphaSpeed), forKey: "particleAlphaSpeed")
        coder.encode(Double(particleColorBlendFactor), forKey: "particleColorBlendFactor")
        coder.encode(Double(particleColorBlendFactorRange), forKey: "particleColorBlendFactorRange")
        coder.encode(Double(particleColorBlendFactorSpeed), forKey: "particleColorBlendFactorSpeed")
        coder.encode(particleBlendMode.rawValue, forKey: "particleBlendMode")
        coder.encode(Int32(fieldBitMask), forKey: "fieldBitMask")
    }

    // MARK: - Simulation Methods

    /// Advances the emitter particle simulation.
    ///
    /// - Parameter sec: The number of seconds to advance the simulation.
    open func advanceSimulationTime(_ sec: TimeInterval) {
        // TODO: Implement simulation advancement
    }

    /// Removes all existing particles and restarts the simulation.
    open func resetSimulation() {
        // TODO: Implement simulation reset
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
        // TODO: Implement sampling with interpolation
        guard !keyframeValues.isEmpty else { return nil }
        return keyframeValues.first
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
