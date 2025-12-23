// SKEmitterNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A source of various particle effects.
///
/// A `SKEmitterNode` object is a node that automatically creates and renders small particle sprites.
/// Particles are privately owned by SpriteKit—your game cannot access the generated sprites.
/// Emitter nodes are often used to create smoke, fire, sparks, and other particle effects.
open class SKEmitterNode: SKNode, @unchecked Sendable {

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
    /// On WASM platforms, you must first register the emitter data with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerEmitter(data: emitterData, forName: "Spark")
    /// let emitter = SKEmitterNode.emitter(fileNamed: "Spark")
    /// ```
    ///
    /// - Parameter fileNamed: The name of the emitter file (without extension).
    /// - Returns: A new emitter node, or nil if the file could not be loaded.
    public class func emitter(fileNamed name: String) -> SKEmitterNode? {
        // Try to load from registered emitter data (WASM)
        if let data = SKResourceLoader.shared.emitterData(forName: name) {
            return parseEmitter(from: data)
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension = name.hasSuffix(".sks") ? String(name.dropLast(4)) : name

        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "sks"),
           let data = try? Data(contentsOf: url) {
            return parseEmitter(from: data)
        }

        return nil
    }

    /// Parses an emitter from property list data.
    private class func parseEmitter(from data: Data) -> SKEmitterNode? {
        // Use SKSParser to parse the .sks file
        // The parser will return an SKScene, but for emitter files,
        // the root node or its first child should be the emitter
        guard let scene = SKSParser.scene(from: data) else { return nil }

        // Check if the scene itself has emitter properties applied
        // (This happens when .sks contains a single emitter)
        if scene.children.count == 1, let emitter = scene.children.first as? SKEmitterNode {
            emitter.removeFromParent()
            return emitter
        }

        // Try to find an emitter among all children
        for child in scene.children {
            if let emitter = child as? SKEmitterNode {
                emitter.removeFromParent()
                return emitter
            }
        }

        // Fallback: try to parse directly as a property list
        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            return parseEmitterFromPlist(plist)
        }

        return nil
    }

    /// Parses an emitter from a property list dictionary.
    private class func parseEmitterFromPlist(_ plist: [String: Any]) -> SKEmitterNode? {
        let emitter = SKEmitterNode()

        // Particle count
        if let birthRate = plist["particleBirthRate"] as? CGFloat {
            emitter.particleBirthRate = birthRate
        }
        if let numParticlesToEmit = plist["numParticlesToEmit"] as? Int {
            emitter.numParticlesToEmit = numParticlesToEmit
        }

        // Lifetime
        if let lifetime = plist["particleLifetime"] as? CGFloat {
            emitter.particleLifetime = lifetime
        }
        if let lifetimeRange = plist["particleLifetimeRange"] as? CGFloat {
            emitter.particleLifetimeRange = lifetimeRange
        }

        // Position
        if let xRange = plist["particlePositionRange.x"] as? CGFloat ?? plist["particlePositionRangeX"] as? CGFloat {
            emitter.particlePositionRange = CGVector(dx: xRange, dy: emitter.particlePositionRange.dy)
        }
        if let yRange = plist["particlePositionRange.y"] as? CGFloat ?? plist["particlePositionRangeY"] as? CGFloat {
            emitter.particlePositionRange = CGVector(dx: emitter.particlePositionRange.dx, dy: yRange)
        }

        // Speed
        if let speed = plist["particleSpeed"] as? CGFloat {
            emitter.particleSpeed = speed
        }
        if let speedRange = plist["particleSpeedRange"] as? CGFloat {
            emitter.particleSpeedRange = speedRange
        }

        // Emission angle
        if let angle = plist["emissionAngle"] as? CGFloat {
            emitter.emissionAngle = angle
        }
        if let angleRange = plist["emissionAngleRange"] as? CGFloat {
            emitter.emissionAngleRange = angleRange
        }

        // Acceleration
        if let ax = plist["xAcceleration"] as? CGFloat {
            emitter.xAcceleration = ax
        }
        if let ay = plist["yAcceleration"] as? CGFloat {
            emitter.yAcceleration = ay
        }

        // Scale
        if let scale = plist["particleScale"] as? CGFloat {
            emitter.particleScale = scale
        }
        if let scaleRange = plist["particleScaleRange"] as? CGFloat {
            emitter.particleScaleRange = scaleRange
        }
        if let scaleSpeed = plist["particleScaleSpeed"] as? CGFloat {
            emitter.particleScaleSpeed = scaleSpeed
        }

        // Alpha
        if let alpha = plist["particleAlpha"] as? CGFloat {
            emitter.particleAlpha = alpha
        }
        if let alphaRange = plist["particleAlphaRange"] as? CGFloat {
            emitter.particleAlphaRange = alphaRange
        }
        if let alphaSpeed = plist["particleAlphaSpeed"] as? CGFloat {
            emitter.particleAlphaSpeed = alphaSpeed
        }

        // Rotation
        if let rotation = plist["particleRotation"] as? CGFloat {
            emitter.particleRotation = rotation
        }
        if let rotationRange = plist["particleRotationRange"] as? CGFloat {
            emitter.particleRotationRange = rotationRange
        }
        if let rotationSpeed = plist["particleRotationSpeed"] as? CGFloat {
            emitter.particleRotationSpeed = rotationSpeed
        }

        // Color
        if let colorDict = plist["particleColor"] as? [String: Any],
           let red = colorDict["red"] as? CGFloat,
           let green = colorDict["green"] as? CGFloat,
           let blue = colorDict["blue"] as? CGFloat,
           let alpha = colorDict["alpha"] as? CGFloat {
            emitter.particleColor = SKColor(red: red, green: green, blue: blue, alpha: alpha)
        }

        // Color blend
        if let colorBlendFactor = plist["particleColorBlendFactor"] as? CGFloat {
            emitter.particleColorBlendFactor = colorBlendFactor
        }
        if let colorBlendFactorRange = plist["particleColorBlendFactorRange"] as? CGFloat {
            emitter.particleColorBlendFactorRange = colorBlendFactorRange
        }
        if let colorBlendFactorSpeed = plist["particleColorBlendFactorSpeed"] as? CGFloat {
            emitter.particleColorBlendFactorSpeed = colorBlendFactorSpeed
        }

        // Texture
        if let textureName = plist["particleTextureName"] as? String ?? plist["particleTexture"] as? String {
            emitter.particleTexture = SKTexture(imageNamed: textureName)
        }

        // Blend mode
        if let blendModeRaw = plist["particleBlendMode"] as? Int,
           let blendMode = SKBlendMode(rawValue: blendModeRaw) {
            emitter.particleBlendMode = blendMode
        }

        return emitter
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
open class SKKeyframeSequence: @unchecked Sendable {

    // MARK: - Properties

    /// The keyframe values.
    private var keyframeValues: [Any] = []

    /// The keyframe times (normalized from 0.0 to 1.0).
    private var keyframeTimes: [CGFloat] = []

    /// The interpolation mode for the sequence.
    open var interpolationMode: SKInterpolationMode = .linear

    /// The repeat mode for the sequence.
    open var repeatMode: SKRepeatMode = .clamp

    // MARK: - Initializers

    /// Creates an empty keyframe sequence.
    public init() {
    }

    /// Creates a keyframe sequence with the specified values and times.
    ///
    /// - Parameters:
    ///   - values: The keyframe values.
    ///   - times: The keyframe times (must be sorted and in range 0.0 to 1.0).
    public init(keyframeValues values: [Any], times: [CGFloat]) {
        self.keyframeValues = values
        self.keyframeTimes = times
    }

    /// Creates a keyframe sequence with a single keyframe.
    ///
    /// - Parameter value: The constant value.
    public convenience init(capacity numItems: Int) {
        self.init()
    }

    // MARK: - Copying

    /// Creates a copy of this keyframe sequence.
    ///
    /// - Returns: A new keyframe sequence with the same properties.
    open func copy() -> SKKeyframeSequence {
        let sequenceCopy = SKKeyframeSequence(keyframeValues: keyframeValues, times: keyframeTimes)
        sequenceCopy.interpolationMode = interpolationMode
        sequenceCopy.repeatMode = repeatMode
        return sequenceCopy
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
        keyframeTimes.append(time)
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
        keyframeTimes[index] = time
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
        return keyframeTimes[index]
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
            let keyTime = keyframeTimes[i]
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

        let lowerTime = keyframeTimes[lowerIndex]
        let upperTime = keyframeTimes[upperIndex]
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
