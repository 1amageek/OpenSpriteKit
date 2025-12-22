// SKParticleSystem.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics

/// A single particle in the particle system.
internal struct SKParticle {
    // MARK: - Position

    /// Current position relative to emitter or target node.
    var position: CGPoint

    /// Current Z position (depth).
    var zPosition: CGFloat

    /// Initial Z position (for sequence interpolation).
    var initialZPosition: CGFloat

    /// Rate of Z position change per second.
    var zPositionSpeed: CGFloat

    // MARK: - Velocity

    /// Current velocity in points per second.
    var velocity: CGVector

    // MARK: - Scale

    /// Current scale factor.
    var scale: CGFloat

    /// Initial scale (for sequence interpolation).
    var initialScale: CGFloat

    /// Rate of scale change per second (used when no sequence).
    var scaleSpeed: CGFloat

    // MARK: - Rotation

    /// Current rotation in radians.
    var rotation: CGFloat

    /// Initial rotation (for sequence interpolation).
    var initialRotation: CGFloat

    /// Rate of rotation change per second (spin).
    var rotationSpeed: CGFloat

    // MARK: - Alpha

    /// Current alpha value (0.0-1.0).
    var alpha: CGFloat

    /// Initial alpha (for sequence interpolation).
    var initialAlpha: CGFloat

    /// Rate of alpha change per second (used when no sequence).
    var alphaSpeed: CGFloat

    // MARK: - Color

    /// Current color components (RGBA).
    var color: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    /// Initial color (for sequence interpolation).
    var initialColor: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    /// Rate of color change per second (used when no sequence).
    var colorSpeed: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    // MARK: - Color Blend

    /// Current color blend factor (0.0-1.0).
    var colorBlendFactor: CGFloat

    /// Initial color blend factor.
    var initialColorBlendFactor: CGFloat

    /// Rate of color blend factor change per second.
    var colorBlendFactorSpeed: CGFloat

    // MARK: - Lifetime

    /// Total lifetime in seconds.
    var lifetime: CGFloat

    /// Time since birth in seconds.
    var age: CGFloat

    /// Whether the particle is still alive.
    var isAlive: Bool {
        return age < lifetime
    }

    /// Normalized age (0.0-1.0).
    var normalizedAge: CGFloat {
        guard lifetime > 0 else { return 1.0 }
        return min(age / lifetime, 1.0)
    }
}

/// Internal particle system for SKEmitterNode.
///
/// This class manages the lifecycle and simulation of particles:
/// - Emitting new particles based on birthRate
/// - Updating particle positions, velocities, and properties
/// - Applying keyframe sequences for animated properties
/// - Removing dead particles
internal final class SKParticleSystem {

    // MARK: - Properties

    /// All active particles.
    private(set) var particles: [SKParticle] = []

    /// Time since last particle emission.
    private var timeSinceLastEmission: TimeInterval = 0

    /// Total particles emitted (for numParticlesToEmit tracking).
    private(set) var totalEmitted: Int = 0

    /// Reference to the emitter node for reading properties.
    private weak var emitter: SKEmitterNode?

    // MARK: - Initialization

    init(emitter: SKEmitterNode) {
        self.emitter = emitter
    }

    // MARK: - Simulation

    /// Updates the particle system for the given time step.
    ///
    /// - Parameter deltaTime: Time elapsed since last update in seconds.
    func update(deltaTime: TimeInterval) {
        guard let emitter = emitter else { return }

        let dt = CGFloat(deltaTime)

        // Emit new particles
        emitParticles(deltaTime: deltaTime)

        // Update existing particles
        updateParticles(deltaTime: dt, emitter: emitter)

        // Remove dead particles
        particles.removeAll { !$0.isAlive }
    }

    /// Resets the particle system, removing all particles.
    func reset() {
        particles.removeAll()
        timeSinceLastEmission = 0
        totalEmitted = 0
    }

    /// Advances the simulation by the given time without rendering.
    func advanceSimulation(by seconds: TimeInterval) {
        // Break into smaller steps for accuracy
        let stepSize: TimeInterval = 1.0 / 60.0
        var remaining = seconds

        while remaining > 0 {
            let step = min(remaining, stepSize)
            update(deltaTime: step)
            remaining -= step
        }
    }

    /// Returns particles sorted by render order.
    func sortedParticles(order: SKParticleRenderOrder) -> [SKParticle] {
        switch order {
        case .oldestFirst:
            return particles // Already in creation order
        case .oldestLast:
            return particles.reversed()
        case .dontCare:
            // Sort by zPosition (front to back)
            return particles.sorted { $0.zPosition < $1.zPosition }
        }
    }

    // MARK: - Emission

    /// Emits new particles based on birth rate.
    private func emitParticles(deltaTime: TimeInterval) {
        guard let emitter = emitter else { return }

        let birthRate = emitter.particleBirthRate
        guard birthRate > 0 else { return }

        // Check emission limit
        let maxParticles = emitter.numParticlesToEmit
        if maxParticles > 0 && totalEmitted >= maxParticles {
            return
        }

        timeSinceLastEmission += deltaTime
        let emissionInterval = 1.0 / Double(birthRate)

        while timeSinceLastEmission >= emissionInterval {
            timeSinceLastEmission -= emissionInterval

            // Check limit again
            if maxParticles > 0 && totalEmitted >= maxParticles {
                break
            }

            // Create new particle
            if let particle = createParticle(emitter: emitter) {
                particles.append(particle)
                totalEmitted += 1
            }
        }
    }

    /// Creates a new particle with randomized properties.
    private func createParticle(emitter: SKEmitterNode) -> SKParticle? {
        // Position with random variation
        let posX = emitter.particlePosition.x + randomRange(-emitter.particlePositionRange.dx / 2, emitter.particlePositionRange.dx / 2)
        let posY = emitter.particlePosition.y + randomRange(-emitter.particlePositionRange.dy / 2, emitter.particlePositionRange.dy / 2)

        // Z Position with random variation
        let zPos = emitter.particleZPosition + randomRange(-emitter.particleZPositionRange / 2, emitter.particleZPositionRange / 2)

        // Speed with random variation
        let speed = emitter.particleSpeed + randomRange(-emitter.particleSpeedRange / 2, emitter.particleSpeedRange / 2)

        // Emission angle with random variation
        let angle = emitter.emissionAngle + randomRange(-emitter.emissionAngleRange / 2, emitter.emissionAngleRange / 2)

        // Calculate velocity from speed and angle
        let velocityX = speed * cos(angle)
        let velocityY = speed * sin(angle)

        // Scale with random variation
        let scale = emitter.particleScale + randomRange(-emitter.particleScaleRange / 2, emitter.particleScaleRange / 2)

        // Rotation with random variation
        let rotation = emitter.particleRotation + randomRange(-emitter.particleRotationRange / 2, emitter.particleRotationRange / 2)
        let rotationSpeed = emitter.particleRotationSpeed

        // Alpha with random variation
        let alpha = clamp(emitter.particleAlpha + randomRange(-emitter.particleAlphaRange / 2, emitter.particleAlphaRange / 2), 0, 1)

        // Color with random variation
        let baseColor = emitter.particleColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        r = clamp(r + randomRange(-emitter.particleColorRedRange / 2, emitter.particleColorRedRange / 2), 0, 1)
        g = clamp(g + randomRange(-emitter.particleColorGreenRange / 2, emitter.particleColorGreenRange / 2), 0, 1)
        b = clamp(b + randomRange(-emitter.particleColorBlueRange / 2, emitter.particleColorBlueRange / 2), 0, 1)
        a = clamp(a + randomRange(-emitter.particleColorAlphaRange / 2, emitter.particleColorAlphaRange / 2), 0, 1)

        // Color blend factor with random variation
        let colorBlendFactor = clamp(emitter.particleColorBlendFactor + randomRange(-emitter.particleColorBlendFactorRange / 2, emitter.particleColorBlendFactorRange / 2), 0, 1)

        // Lifetime with random variation
        let lifetime = max(0.001, emitter.particleLifetime + randomRange(-emitter.particleLifetimeRange / 2, emitter.particleLifetimeRange / 2))

        return SKParticle(
            position: CGPoint(x: posX, y: posY),
            zPosition: zPos,
            initialZPosition: zPos,
            zPositionSpeed: emitter.particleZPositionSpeed,
            velocity: CGVector(dx: velocityX, dy: velocityY),
            scale: scale,
            initialScale: scale,
            scaleSpeed: emitter.particleScaleSpeed,
            rotation: rotation,
            initialRotation: rotation,
            rotationSpeed: rotationSpeed,
            alpha: alpha,
            initialAlpha: alpha,
            alphaSpeed: emitter.particleAlphaSpeed,
            color: (r, g, b, a),
            initialColor: (r, g, b, a),
            colorSpeed: (
                emitter.particleColorRedSpeed,
                emitter.particleColorGreenSpeed,
                emitter.particleColorBlueSpeed,
                emitter.particleColorAlphaSpeed
            ),
            colorBlendFactor: colorBlendFactor,
            initialColorBlendFactor: colorBlendFactor,
            colorBlendFactorSpeed: emitter.particleColorBlendFactorSpeed,
            lifetime: lifetime,
            age: 0
        )
    }

    // MARK: - Update

    /// Updates all particles for the given time step.
    private func updateParticles(deltaTime: CGFloat, emitter: SKEmitterNode) {
        let hasScaleSequence = emitter.particleScaleSequence != nil && emitter.particleScaleSequence!.count() > 0
        let hasAlphaSequence = emitter.particleAlphaSequence != nil && emitter.particleAlphaSequence!.count() > 0
        let hasColorSequence = emitter.particleColorSequence != nil && emitter.particleColorSequence!.count() > 0
        let hasBlendSequence = emitter.particleColorBlendFactorSequence != nil && emitter.particleColorBlendFactorSequence!.count() > 0

        for i in particles.indices {
            var particle = particles[i]

            // Update age
            particle.age += deltaTime

            // Skip dead particles
            guard particle.isAlive else {
                particles[i] = particle
                continue
            }

            let normalizedAge = particle.normalizedAge

            // Apply acceleration
            particle.velocity.dx += emitter.xAcceleration * deltaTime
            particle.velocity.dy += emitter.yAcceleration * deltaTime

            // Update position
            particle.position.x += particle.velocity.dx * deltaTime
            particle.position.y += particle.velocity.dy * deltaTime

            // Update Z position
            particle.zPosition += particle.zPositionSpeed * deltaTime

            // Update scale (sequence or speed)
            if hasScaleSequence, let sequence = emitter.particleScaleSequence,
               let sampledValue = sequence.sample(atTime: normalizedAge) {
                if let scaleValue = sampledValue as? CGFloat {
                    particle.scale = scaleValue
                } else if let scaleDouble = sampledValue as? Double {
                    particle.scale = CGFloat(scaleDouble)
                } else if let scaleFloat = sampledValue as? Float {
                    particle.scale = CGFloat(scaleFloat)
                }
            } else {
                particle.scale += particle.scaleSpeed * deltaTime
            }

            // Update rotation
            particle.rotation += particle.rotationSpeed * deltaTime

            // Update alpha (sequence or speed)
            if hasAlphaSequence, let sequence = emitter.particleAlphaSequence,
               let sampledValue = sequence.sample(atTime: normalizedAge) {
                if let alphaValue = sampledValue as? CGFloat {
                    particle.alpha = clamp(alphaValue, 0, 1)
                } else if let alphaDouble = sampledValue as? Double {
                    particle.alpha = clamp(CGFloat(alphaDouble), 0, 1)
                } else if let alphaFloat = sampledValue as? Float {
                    particle.alpha = clamp(CGFloat(alphaFloat), 0, 1)
                }
            } else {
                particle.alpha += particle.alphaSpeed * deltaTime
                particle.alpha = clamp(particle.alpha, 0, 1)
            }

            // Update color (sequence or speed)
            if hasColorSequence, let sequence = emitter.particleColorSequence,
               let sampledValue = sequence.sample(atTime: normalizedAge),
               let sampledColor = sampledValue as? SKColor {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                sampledColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                particle.color = (r, g, b, a)
            } else {
                particle.color.r = clamp(particle.color.r + particle.colorSpeed.r * deltaTime, 0, 1)
                particle.color.g = clamp(particle.color.g + particle.colorSpeed.g * deltaTime, 0, 1)
                particle.color.b = clamp(particle.color.b + particle.colorSpeed.b * deltaTime, 0, 1)
                particle.color.a = clamp(particle.color.a + particle.colorSpeed.a * deltaTime, 0, 1)
            }

            // Update color blend factor (sequence or speed)
            if hasBlendSequence, let sequence = emitter.particleColorBlendFactorSequence,
               let sampledValue = sequence.sample(atTime: normalizedAge) {
                if let blendValue = sampledValue as? CGFloat {
                    particle.colorBlendFactor = clamp(blendValue, 0, 1)
                } else if let blendDouble = sampledValue as? Double {
                    particle.colorBlendFactor = clamp(CGFloat(blendDouble), 0, 1)
                } else if let blendFloat = sampledValue as? Float {
                    particle.colorBlendFactor = clamp(CGFloat(blendFloat), 0, 1)
                }
            } else {
                particle.colorBlendFactor += particle.colorBlendFactorSpeed * deltaTime
                particle.colorBlendFactor = clamp(particle.colorBlendFactor, 0, 1)
            }

            particles[i] = particle
        }
    }

    // MARK: - Helpers

    /// Generates a random value in the given range.
    private func randomRange(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        guard max > min else { return min }
        return CGFloat.random(in: min...max)
    }

    /// Clamps a value to a range.
    private func clamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
        return Swift.max(min, Swift.min(max, value))
    }
}

// MARK: - SKColor Extension for getRed

extension SKColor {
    /// Gets the RGBA components of the color.
    func getRed(_ red: inout CGFloat, green: inout CGFloat, blue: inout CGFloat, alpha: inout CGFloat) {
        // SKColor is a simple struct with direct properties
        red = self.red
        green = self.green
        blue = self.blue
        alpha = self.alpha
    }
}
