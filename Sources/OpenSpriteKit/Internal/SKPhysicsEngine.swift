// SKPhysicsEngine.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics
#if canImport(simd)
import simd
#endif

/// The internal physics simulation engine for SpriteKit.
///
/// This engine handles:
/// - Gravity application
/// - Velocity integration
/// - Collision detection (AABB broad phase, shape narrow phase)
/// - Collision resolution
/// - Contact delegate callbacks
internal final class SKPhysicsEngine {

    // MARK: - Singleton

    /// The shared physics engine instance.
    nonisolated(unsafe) static let shared = SKPhysicsEngine()

    // MARK: - Initialization

    private init() {}

    /// Accumulated simulation time for animated field effects.
    private var simulationTime: TimeInterval = 0

    // MARK: - Simulation

    /// Runs one step of physics simulation for a scene.
    ///
    /// - Parameters:
    ///   - scene: The scene to simulate.
    ///   - deltaTime: The time step in seconds.
    func simulate(scene: SKScene, deltaTime: TimeInterval) {
        let world = scene.physicsWorld
        let gravity = world.gravity
        let speed = world.speed

        // Skip if paused
        guard speed > 0, deltaTime > 0 else { return }

        let dt = deltaTime * Double(speed)

        // Update simulation time for animated field effects
        simulationTime += dt

        // Collect all physics bodies in the scene
        var bodies: [SKPhysicsBody] = []
        collectBodies(from: scene, into: &bodies)

        // Collect all field nodes in the scene
        var fieldNodes: [SKFieldNode] = []
        collectFieldNodes(from: scene, into: &fieldNodes)

        // Apply accumulated forces (with deltaTime)
        applyAccumulatedForces(to: bodies, deltaTime: dt)

        // Apply gravity to dynamic bodies
        applyGravity(to: bodies, gravity: gravity, deltaTime: dt)

        // Apply field forces to dynamic bodies
        applyFieldForces(to: bodies, fieldNodes: fieldNodes, scene: scene, deltaTime: dt)

        // Integrate velocities (update positions)
        integrateVelocities(bodies: bodies, deltaTime: dt)

        // Apply joint constraints
        applyJointConstraints(world: world, deltaTime: dt)

        // Detect collisions
        let contacts = detectCollisions(bodies: bodies)

        // Resolve collisions
        resolveCollisions(contacts: contacts)

        // Update contact tracking for begin/end callbacks
        updateContactTracking(contacts: contacts, world: world)
    }

    /// Resets the physics engine state for a scene.
    func reset(for scene: SKScene) {
        scene.physicsWorld.resetContactState()
    }

    // MARK: - Body Collection

    /// Recursively collects all physics bodies in a node tree.
    private func collectBodies(from node: SKNode, into bodies: inout [SKPhysicsBody]) {
        if let body = node.physicsBody {
            body.node = node
            bodies.append(body)
        }
        for child in node.children {
            collectBodies(from: child, into: &bodies)
        }
    }

    // MARK: - Force Application

    /// Applies accumulated forces to all dynamic bodies and clears the accumulators.
    private func applyAccumulatedForces(to bodies: [SKPhysicsBody], deltaTime: TimeInterval) {
        for body in bodies {
            guard body.isDynamic && !body.pinned else { continue }

            // Apply accumulated linear force: F = ma, so dv = (F/m) * dt
            if body.accumulatedForce.dx != 0 || body.accumulatedForce.dy != 0 {
                body.velocity.dx += (body.accumulatedForce.dx / body.mass) * CGFloat(deltaTime)
                body.velocity.dy += (body.accumulatedForce.dy / body.mass) * CGFloat(deltaTime)
                body.accumulatedForce = .zero
            }

            // Apply accumulated torque: τ = Iα, so dω = (τ/I) * dt
            if body.accumulatedTorque != 0 && body.allowsRotation {
                let momentOfInertia = body.calculateMomentOfInertia()
                if momentOfInertia > 0 {
                    body.angularVelocity += (body.accumulatedTorque / momentOfInertia) * CGFloat(deltaTime)
                }
                body.accumulatedTorque = 0
            }
        }
    }

    // MARK: - Gravity

    /// Applies gravity to all dynamic bodies.
    private func applyGravity(to bodies: [SKPhysicsBody], gravity: CGVector, deltaTime: TimeInterval) {
        for body in bodies {
            guard body.isDynamic && body.affectedByGravity && !body.pinned else { continue }

            // Apply gravity as acceleration: v += g * dt
            body.velocity.dx += gravity.dx * CGFloat(deltaTime)
            body.velocity.dy += gravity.dy * CGFloat(deltaTime)
        }
    }

    // MARK: - Field Node Collection

    /// Recursively collects all field nodes in a node tree.
    private func collectFieldNodes(from node: SKNode, into fieldNodes: inout [SKFieldNode]) {
        if let field = node as? SKFieldNode {
            fieldNodes.append(field)
        }
        for child in node.children {
            collectFieldNodes(from: child, into: &fieldNodes)
        }
    }

    // MARK: - Field Forces

    /// Applies forces from field nodes to all dynamic bodies.
    private func applyFieldForces(to bodies: [SKPhysicsBody], fieldNodes: [SKFieldNode], scene: SKScene, deltaTime: TimeInterval) {
        // Skip if no field nodes
        guard !fieldNodes.isEmpty else { return }

        for body in bodies {
            guard body.isDynamic && !body.pinned else { continue }
            guard let node = body.node else { continue }

            // Check if body is affected by fields
            // If fieldBitMask is 0, body is not affected by any fields
            guard body.fieldBitMask != 0 else { continue }

            // Get body position in scene coordinates
            let bodyPosition = scene.convert(node.position, from: node.parent ?? scene)
            let position3D = vector_float3(Float(bodyPosition.x), Float(bodyPosition.y), 0)
            let velocity3D = vector_float3(Float(body.velocity.dx), Float(body.velocity.dy), 0)

            var totalForce = vector_float3.zero
            var hasExclusiveField = false
            var exclusiveForce = vector_float3.zero

            for field in fieldNodes {
                guard field.isEnabled else { continue }

                // Check if field affects this body (category bit mask check)
                guard (field.categoryBitMask & body.fieldBitMask) != 0 else { continue }

                // Check if body is within field's region
                if let region = field.region {
                    let localPoint = field.convert(bodyPosition, from: scene)
                    guard region.contains(localPoint) else { continue }
                }

                // Calculate field position in scene coordinates
                let fieldPos = scene.convert(.zero, from: field)
                let fieldPosition = vector_float3(Float(fieldPos.x), Float(fieldPos.y), 0)

                // Calculate force from this field
                let force = calculateFieldForce(
                    field: field,
                    fieldPosition: fieldPosition,
                    bodyPosition: position3D,
                    bodyVelocity: velocity3D,
                    bodyMass: Float(body.mass),
                    bodyCharge: Float(body.charge),
                    deltaTime: deltaTime
                )

                if field.isExclusive {
                    if !hasExclusiveField {
                        hasExclusiveField = true
                        exclusiveForce = force
                    } else {
                        exclusiveForce += force
                    }
                } else {
                    totalForce += force
                }
            }

            // Apply the final force
            let finalForce = hasExclusiveField ? exclusiveForce : totalForce

            // Convert force to velocity change: dv = (F/m) * dt
            if body.mass > 0 {
                body.velocity.dx += CGFloat(finalForce.x / Float(body.mass)) * CGFloat(deltaTime)
                body.velocity.dy += CGFloat(finalForce.y / Float(body.mass)) * CGFloat(deltaTime)
            }
        }
    }

    /// Calculates the force applied by a field to a body.
    private func calculateFieldForce(
        field: SKFieldNode,
        fieldPosition: vector_float3,
        bodyPosition: vector_float3,
        bodyVelocity: vector_float3,
        bodyMass: Float,
        bodyCharge: Float,
        deltaTime: TimeInterval
    ) -> vector_float3 {
        // Calculate displacement from field to body
        let displacement = bodyPosition - fieldPosition
        var distance = simd_length(displacement)

        // Apply minimum radius
        distance = max(distance, field.minimumRadius)

        // Calculate falloff factor
        let falloffFactor: Float
        if field.falloff == 0 || distance <= field.minimumRadius {
            falloffFactor = 1.0
        } else {
            falloffFactor = pow(field.minimumRadius / distance, field.falloff)
        }

        let strength = field.strength * falloffFactor

        // Calculate force based on field type
        switch field.fieldType {
        case .radialGravity:
            // Attracts toward the field node (force proportional to mass)
            if distance > 0.0001 {
                let direction = -simd_normalize(displacement)
                return direction * strength * bodyMass
            }
            return .zero

        case .linearGravity(let direction):
            // Applies force in a constant direction (proportional to mass)
            return simd_normalize(direction) * strength * bodyMass

        case .drag:
            // Drag force opposing velocity: F = -k * v
            let speed = simd_length(bodyVelocity)
            if speed > 0.0001 {
                let dragDirection = -simd_normalize(bodyVelocity)
                return dragDirection * strength * speed * bodyMass
            }
            return .zero

        case .vortex:
            // Perpendicular force (tangent to circle around field)
            if distance > 0.0001 {
                let perpendicular = vector_float3(-displacement.y, displacement.x, 0)
                return simd_normalize(perpendicular) * strength * bodyMass
            }
            return .zero

        case .electric:
            // Electric field: force proportional to charge (F = qE)
            if distance > 0.0001 {
                let direction = simd_normalize(displacement)
                return direction * strength * bodyCharge
            }
            return .zero

        case .magnetic:
            // Magnetic field: Lorentz force F = q(v × B)
            // B is along z-axis, so F is perpendicular to velocity in xy plane
            let magneticField = vector_float3(0, 0, strength)
            let lorentzForce = simd_cross(bodyVelocity, magneticField)
            return lorentzForce * bodyCharge

        case .spring:
            // Spring force toward the field node: F = -k * x
            return -displacement * strength

        case .velocityWithVector(let direction):
            // Velocity field: applies force to match target velocity
            let targetVelocity = simd_normalize(direction) * strength
            let velocityDiff = targetVelocity - bodyVelocity
            return velocityDiff * bodyMass * 10.0 // Spring-like force to reach target

        case .velocityWithTexture:
            // Texture-based velocity field (not implemented - would require texture sampling)
            return .zero

        case .noise(let smoothness, let animationSpeed):
            // Noise field: smooth random force based on position
            // smoothness: higher = smoother (lower frequency), default ~0.5
            // animationSpeed: how fast the noise evolves over time
            let frequency = max(0.01, 1.0 - Float(smoothness)) * 0.2
            let timeOffset = Float(simulationTime * Double(animationSpeed))
            let noiseX = simpleNoise(x: bodyPosition.x * frequency + timeOffset,
                                     y: bodyPosition.y * frequency)
            let noiseY = simpleNoise(x: bodyPosition.y * frequency,
                                     y: bodyPosition.x * frequency + timeOffset)
            return vector_float3(noiseX, noiseY, 0) * strength * bodyMass

        case .turbulence(let smoothness, let animationSpeed):
            // Turbulence: more chaotic noise that varies with velocity
            // Uses higher frequency than noise for more rapid changes
            let frequency = max(0.01, 1.0 - Float(smoothness)) * 0.4
            let timeOffset = Float(simulationTime * Double(animationSpeed))
            let speed = simd_length(bodyVelocity)
            let turbulenceFactor = 1.0 + speed * 0.1

            // Multiple octaves for more chaotic effect
            let noiseX1 = simpleNoise(x: bodyPosition.x * frequency + timeOffset,
                                      y: bodyPosition.y * frequency)
            let noiseX2 = simpleNoise(x: bodyPosition.x * frequency * 2 + timeOffset * 1.5,
                                      y: bodyPosition.y * frequency * 2) * 0.5
            let noiseY1 = simpleNoise(x: bodyPosition.y * frequency,
                                      y: bodyPosition.x * frequency + timeOffset)
            let noiseY2 = simpleNoise(x: bodyPosition.y * frequency * 2,
                                      y: bodyPosition.x * frequency * 2 + timeOffset * 1.5) * 0.5

            let noiseX = noiseX1 + noiseX2
            let noiseY = noiseY1 + noiseY2
            return vector_float3(noiseX, noiseY, 0) * strength * bodyMass * turbulenceFactor

        case .custom(let evaluator):
            // Custom field: call the evaluator function
            return evaluator(bodyPosition, bodyVelocity, bodyMass, bodyCharge, deltaTime)
        }
    }

    /// Simple noise function for field effects.
    private func simpleNoise(x: Float, y: Float) -> Float {
        let ix = Int(floor(x)) & 255
        let iy = Int(floor(y)) & 255
        let fx = x - floor(x)
        let fy = y - floor(y)

        let u = fx * fx * (3 - 2 * fx)
        let v = fy * fy * (3 - 2 * fy)

        func hash(_ n: Int) -> Float {
            var x = n
            x = ((x >> 16) ^ x) &* 0x45d9f3b
            x = ((x >> 16) ^ x) &* 0x45d9f3b
            x = (x >> 16) ^ x
            return Float(x & 0xFFFF) / 32768.0 - 1.0
        }

        let n00 = hash(ix + iy * 57)
        let n10 = hash(ix + 1 + iy * 57)
        let n01 = hash(ix + (iy + 1) * 57)
        let n11 = hash(ix + 1 + (iy + 1) * 57)

        let nx0 = n00 + u * (n10 - n00)
        let nx1 = n01 + u * (n11 - n01)

        return nx0 + v * (nx1 - nx0)
    }

    // MARK: - Velocity Integration

    /// Integrates velocities to update node positions.
    private func integrateVelocities(bodies: [SKPhysicsBody], deltaTime: TimeInterval) {
        for body in bodies {
            guard body.isDynamic && !body.pinned else { continue }
            guard let node = body.node else { continue }

            // Apply linear damping
            let linearFactor = 1.0 - body.linearDamping * CGFloat(deltaTime)
            body.velocity.dx *= max(0, linearFactor)
            body.velocity.dy *= max(0, linearFactor)

            // Update position: p += v * dt
            node.position.x += body.velocity.dx * CGFloat(deltaTime)
            node.position.y += body.velocity.dy * CGFloat(deltaTime)

            // Apply angular damping
            if body.allowsRotation {
                let angularFactor = 1.0 - body.angularDamping * CGFloat(deltaTime)
                body.angularVelocity *= max(0, angularFactor)

                // Update rotation
                node.zRotation += body.angularVelocity * CGFloat(deltaTime)
            }

            // Check for resting state
            let velocityMagnitude = sqrt(body.velocity.dx * body.velocity.dx +
                                        body.velocity.dy * body.velocity.dy)
            body.isResting = velocityMagnitude < 0.01 && abs(body.angularVelocity) < 0.01
        }
    }

    // MARK: - Joint Constraints

    /// Applies all joint constraints to connected bodies.
    private func applyJointConstraints(world: SKPhysicsWorld, deltaTime: TimeInterval) {
        let joints = world.allJoints

        // Reset reaction forces
        for joint in joints {
            joint.resetReaction()
        }

        // Apply each joint type
        for joint in joints {
            guard let bodyA = joint.bodyA, let bodyB = joint.bodyB else { continue }
            guard let nodeA = bodyA.node, let nodeB = bodyB.node else { continue }

            if let pinJoint = joint as? SKPhysicsJointPin {
                applyPinJoint(pinJoint, bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB, deltaTime: deltaTime)
            } else if let springJoint = joint as? SKPhysicsJointSpring {
                applySpringJoint(springJoint, bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB, deltaTime: deltaTime)
            } else if let fixedJoint = joint as? SKPhysicsJointFixed {
                applyFixedJoint(fixedJoint, bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB, deltaTime: deltaTime)
            } else if let slidingJoint = joint as? SKPhysicsJointSliding {
                applySlidingJoint(slidingJoint, bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB, deltaTime: deltaTime)
            } else if let limitJoint = joint as? SKPhysicsJointLimit {
                applyLimitJoint(limitJoint, bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB, deltaTime: deltaTime)
            }
        }
    }

    /// Applies a pin joint constraint - bodies rotate around a common anchor point.
    private func applyPinJoint(_ joint: SKPhysicsJointPin, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                nodeA: SKNode, nodeB: SKNode, deltaTime: TimeInterval) {
        let anchor = joint.anchor

        // Calculate current positions relative to anchor
        let deltaA = CGVector(dx: nodeA.position.x - anchor.x, dy: nodeA.position.y - anchor.y)
        let deltaB = CGVector(dx: nodeB.position.x - anchor.x, dy: nodeB.position.y - anchor.y)

        // Calculate required correction to bring both bodies to anchor
        // The bodies should maintain their distance from the anchor
        let invMassA = bodyA.isDynamic && !bodyA.pinned ? 1.0 / bodyA.mass : 0
        let invMassB = bodyB.isDynamic && !bodyB.pinned ? 1.0 / bodyB.mass : 0
        let invMassSum = invMassA + invMassB

        if invMassSum > 0 {
            // Calculate correction impulse
            let correction = CGVector(
                dx: deltaB.dx - deltaA.dx,
                dy: deltaB.dy - deltaA.dy
            )

            let correctionMagnitude = sqrt(correction.dx * correction.dx + correction.dy * correction.dy)
            if correctionMagnitude > 0.0001 {
                let normal = CGVector(dx: correction.dx / correctionMagnitude, dy: correction.dy / correctionMagnitude)
                let impulse = correctionMagnitude * 0.5 / invMassSum

                // Apply position correction
                if bodyA.isDynamic && !bodyA.pinned {
                    nodeA.position.x += impulse * invMassA * normal.dx
                    nodeA.position.y += impulse * invMassA * normal.dy
                }
                if bodyB.isDynamic && !bodyB.pinned {
                    nodeB.position.x -= impulse * invMassB * normal.dx
                    nodeB.position.y -= impulse * invMassB * normal.dy
                }

                // Store reaction force
                joint._reactionForce = CGVector(dx: impulse * normal.dx / CGFloat(deltaTime),
                                                dy: impulse * normal.dy / CGFloat(deltaTime))
            }
        }

        // Apply rotation limits if enabled
        if joint.shouldEnableLimits {
            let relativeAngle = nodeB.zRotation - nodeA.zRotation
            var correctionAngle: CGFloat = 0

            if relativeAngle < joint.lowerAngleLimit {
                correctionAngle = joint.lowerAngleLimit - relativeAngle
            } else if relativeAngle > joint.upperAngleLimit {
                correctionAngle = joint.upperAngleLimit - relativeAngle
            }

            if correctionAngle != 0 && invMassSum > 0 {
                if bodyA.isDynamic && bodyA.allowsRotation && !bodyA.pinned {
                    nodeA.zRotation -= correctionAngle * CGFloat(invMassA / invMassSum)
                }
                if bodyB.isDynamic && bodyB.allowsRotation && !bodyB.pinned {
                    nodeB.zRotation += correctionAngle * CGFloat(invMassB / invMassSum)
                }
                joint._reactionTorque = correctionAngle / CGFloat(deltaTime)
            }
        }

        // Apply friction torque
        if joint.frictionTorque > 0 {
            let relativeAngularVel = bodyB.angularVelocity - bodyA.angularVelocity
            let frictionImpulse = min(abs(relativeAngularVel), joint.frictionTorque * CGFloat(deltaTime))
            let frictionSign = relativeAngularVel > 0 ? CGFloat(-1) : CGFloat(1)

            if bodyA.isDynamic && bodyA.allowsRotation && !bodyA.pinned {
                bodyA.angularVelocity -= frictionImpulse * frictionSign * CGFloat(invMassA / invMassSum)
            }
            if bodyB.isDynamic && bodyB.allowsRotation && !bodyB.pinned {
                bodyB.angularVelocity += frictionImpulse * frictionSign * CGFloat(invMassB / invMassSum)
            }
        }
    }

    /// Applies a spring joint constraint - elastic force between anchor points.
    private func applySpringJoint(_ joint: SKPhysicsJointSpring, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                   nodeA: SKNode, nodeB: SKNode, deltaTime: TimeInterval) {
        // Calculate current anchor positions in world space
        let worldAnchorA = CGPoint(x: nodeA.position.x, y: nodeA.position.y)
        let worldAnchorB = CGPoint(x: nodeB.position.x, y: nodeB.position.y)

        // Calculate displacement
        let dx = worldAnchorB.x - worldAnchorA.x
        let dy = worldAnchorB.y - worldAnchorA.y
        let currentLength = sqrt(dx * dx + dy * dy)

        guard currentLength > 0.0001 else { return }

        // Calculate spring force (Hooke's law: F = -kx)
        let displacement = currentLength - joint.restLength

        // Convert frequency to spring constant: k = (2π * f)² * m
        let effectiveMass = 1.0 / (1.0 / max(bodyA.mass, 0.001) + 1.0 / max(bodyB.mass, 0.001))
        let omega = 2.0 * .pi * joint.frequency
        let springConstant = omega * omega * effectiveMass

        let springForce = springConstant * displacement

        // Calculate damping force
        let relVelX = bodyB.velocity.dx - bodyA.velocity.dx
        let relVelY = bodyB.velocity.dy - bodyA.velocity.dy
        let normalX = dx / currentLength
        let normalY = dy / currentLength
        let relVelAlongSpring = relVelX * normalX + relVelY * normalY

        let dampingForce = joint.damping * relVelAlongSpring * 2.0 * sqrt(springConstant * effectiveMass)

        // Total force
        let totalForce = springForce + dampingForce

        // Apply force to both bodies
        let forceX = totalForce * normalX
        let forceY = totalForce * normalY

        if bodyA.isDynamic && !bodyA.pinned {
            bodyA.velocity.dx += (forceX / bodyA.mass) * CGFloat(deltaTime)
            bodyA.velocity.dy += (forceY / bodyA.mass) * CGFloat(deltaTime)
        }
        if bodyB.isDynamic && !bodyB.pinned {
            bodyB.velocity.dx -= (forceX / bodyB.mass) * CGFloat(deltaTime)
            bodyB.velocity.dy -= (forceY / bodyB.mass) * CGFloat(deltaTime)
        }

        // Store reaction force
        joint._reactionForce = CGVector(dx: forceX, dy: forceY)
    }

    /// Applies a fixed joint constraint - rigid connection between bodies.
    private func applyFixedJoint(_ joint: SKPhysicsJointFixed, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                  nodeA: SKNode, nodeB: SKNode, deltaTime: TimeInterval) {
        let invMassA = bodyA.isDynamic && !bodyA.pinned ? 1.0 / bodyA.mass : 0
        let invMassB = bodyB.isDynamic && !bodyB.pinned ? 1.0 / bodyB.mass : 0
        let invMassSum = invMassA + invMassB

        guard invMassSum > 0 else { return }

        // Calculate expected position of B based on A and stored relative offset
        let expectedPosB = CGPoint(
            x: nodeA.position.x + joint.relativeOffset.dx,
            y: nodeA.position.y + joint.relativeOffset.dy
        )

        // Calculate position correction
        let errorX = expectedPosB.x - nodeB.position.x
        let errorY = expectedPosB.y - nodeB.position.y

        // Apply position correction
        let correctionFactor: CGFloat = 0.8
        if bodyA.isDynamic && !bodyA.pinned {
            nodeA.position.x -= errorX * CGFloat(invMassA / invMassSum) * correctionFactor
            nodeA.position.y -= errorY * CGFloat(invMassA / invMassSum) * correctionFactor
        }
        if bodyB.isDynamic && !bodyB.pinned {
            nodeB.position.x += errorX * CGFloat(invMassB / invMassSum) * correctionFactor
            nodeB.position.y += errorY * CGFloat(invMassB / invMassSum) * correctionFactor
        }

        // Store reaction force
        joint._reactionForce = CGVector(
            dx: errorX * correctionFactor / CGFloat(deltaTime),
            dy: errorY * correctionFactor / CGFloat(deltaTime)
        )

        // Apply rotation constraint
        let expectedRotB = nodeA.zRotation + joint.relativeRotation
        let rotError = expectedRotB - nodeB.zRotation

        if abs(rotError) > 0.0001 {
            if bodyA.isDynamic && bodyA.allowsRotation && !bodyA.pinned {
                nodeA.zRotation -= rotError * CGFloat(invMassA / invMassSum) * correctionFactor
            }
            if bodyB.isDynamic && bodyB.allowsRotation && !bodyB.pinned {
                nodeB.zRotation += rotError * CGFloat(invMassB / invMassSum) * correctionFactor
            }
            joint._reactionTorque = rotError * correctionFactor / CGFloat(deltaTime)
        }

        // Match velocities
        let avgVelX = (bodyA.velocity.dx * bodyA.mass + bodyB.velocity.dx * bodyB.mass) / (bodyA.mass + bodyB.mass)
        let avgVelY = (bodyA.velocity.dy * bodyA.mass + bodyB.velocity.dy * bodyB.mass) / (bodyA.mass + bodyB.mass)

        if bodyA.isDynamic && !bodyA.pinned {
            bodyA.velocity.dx = avgVelX
            bodyA.velocity.dy = avgVelY
        }
        if bodyB.isDynamic && !bodyB.pinned {
            bodyB.velocity.dx = avgVelX
            bodyB.velocity.dy = avgVelY
        }

        // Match angular velocities
        if bodyA.allowsRotation && bodyB.allowsRotation {
            let avgAngVel = (bodyA.angularVelocity + bodyB.angularVelocity) / 2
            if bodyA.isDynamic && !bodyA.pinned {
                bodyA.angularVelocity = avgAngVel
            }
            if bodyB.isDynamic && !bodyB.pinned {
                bodyB.angularVelocity = avgAngVel
            }
        }
    }

    /// Applies a sliding joint constraint - movement restricted to an axis.
    private func applySlidingJoint(_ joint: SKPhysicsJointSliding, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                    nodeA: SKNode, nodeB: SKNode, deltaTime: TimeInterval) {
        let invMassA = bodyA.isDynamic && !bodyA.pinned ? 1.0 / bodyA.mass : 0
        let invMassB = bodyB.isDynamic && !bodyB.pinned ? 1.0 / bodyB.mass : 0
        let invMassSum = invMassA + invMassB

        guard invMassSum > 0 else { return }

        let axis = joint.axis
        let anchor = joint.anchor

        // Calculate perpendicular to axis
        let perpX = -axis.dy
        let perpY = axis.dx

        // Calculate displacement from anchor to each body
        let dispA = CGVector(dx: nodeA.position.x - anchor.x, dy: nodeA.position.y - anchor.y)
        let dispB = CGVector(dx: nodeB.position.x - anchor.x, dy: nodeB.position.y - anchor.y)

        // Project displacements onto perpendicular
        let perpDistA = dispA.dx * perpX + dispA.dy * perpY
        let perpDistB = dispB.dx * perpX + dispB.dy * perpY

        // Correct perpendicular component
        let correctionFactor: CGFloat = 0.8
        if bodyA.isDynamic && !bodyA.pinned {
            nodeA.position.x -= perpDistA * perpX * correctionFactor
            nodeA.position.y -= perpDistA * perpY * correctionFactor
        }
        if bodyB.isDynamic && !bodyB.pinned {
            nodeB.position.x -= perpDistB * perpX * correctionFactor
            nodeB.position.y -= perpDistB * perpY * correctionFactor
        }

        // Apply distance limits if enabled
        if joint.shouldEnableLimits {
            let distA = dispA.dx * axis.dx + dispA.dy * axis.dy
            let distB = dispB.dx * axis.dx + dispB.dy * axis.dy
            let relDist = distB - distA

            var correction: CGFloat = 0
            if relDist < joint.lowerDistanceLimit {
                correction = joint.lowerDistanceLimit - relDist
            } else if relDist > joint.upperDistanceLimit {
                correction = joint.upperDistanceLimit - relDist
            }

            if correction != 0 {
                if bodyA.isDynamic && !bodyA.pinned {
                    nodeA.position.x -= correction * CGFloat(invMassA / invMassSum) * axis.dx * correctionFactor
                    nodeA.position.y -= correction * CGFloat(invMassA / invMassSum) * axis.dy * correctionFactor
                }
                if bodyB.isDynamic && !bodyB.pinned {
                    nodeB.position.x += correction * CGFloat(invMassB / invMassSum) * axis.dx * correctionFactor
                    nodeB.position.y += correction * CGFloat(invMassB / invMassSum) * axis.dy * correctionFactor
                }
            }
        }

        // Constrain velocity perpendicular to axis
        let velPerpA = bodyA.velocity.dx * perpX + bodyA.velocity.dy * perpY
        let velPerpB = bodyB.velocity.dx * perpX + bodyB.velocity.dy * perpY

        if bodyA.isDynamic && !bodyA.pinned {
            bodyA.velocity.dx -= velPerpA * perpX
            bodyA.velocity.dy -= velPerpA * perpY
        }
        if bodyB.isDynamic && !bodyB.pinned {
            bodyB.velocity.dx -= velPerpB * perpX
            bodyB.velocity.dy -= velPerpB * perpY
        }

        // Store reaction force (perpendicular constraint force)
        joint._reactionForce = CGVector(
            dx: (perpDistA + perpDistB) * perpX / CGFloat(deltaTime),
            dy: (perpDistA + perpDistB) * perpY / CGFloat(deltaTime)
        )
    }

    /// Applies a limit joint constraint - maximum distance constraint.
    private func applyLimitJoint(_ joint: SKPhysicsJointLimit, bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                  nodeA: SKNode, nodeB: SKNode, deltaTime: TimeInterval) {
        // Calculate current distance
        let dx = nodeB.position.x - nodeA.position.x
        let dy = nodeB.position.y - nodeA.position.y
        let currentLength = sqrt(dx * dx + dy * dy)

        // Only apply constraint if distance exceeds maxLength
        guard currentLength > joint.maxLength else {
            return
        }

        let invMassA = bodyA.isDynamic && !bodyA.pinned ? 1.0 / bodyA.mass : 0
        let invMassB = bodyB.isDynamic && !bodyB.pinned ? 1.0 / bodyB.mass : 0
        let invMassSum = invMassA + invMassB

        guard invMassSum > 0 else { return }

        // Calculate correction
        let excess = currentLength - joint.maxLength
        let normalX = dx / currentLength
        let normalY = dy / currentLength

        let correctionFactor: CGFloat = 0.8

        // Apply position correction
        if bodyA.isDynamic && !bodyA.pinned {
            nodeA.position.x += excess * CGFloat(invMassA / invMassSum) * normalX * correctionFactor
            nodeA.position.y += excess * CGFloat(invMassA / invMassSum) * normalY * correctionFactor
        }
        if bodyB.isDynamic && !bodyB.pinned {
            nodeB.position.x -= excess * CGFloat(invMassB / invMassSum) * normalX * correctionFactor
            nodeB.position.y -= excess * CGFloat(invMassB / invMassSum) * normalY * correctionFactor
        }

        // Apply velocity correction (prevent separation)
        let relVelX = bodyB.velocity.dx - bodyA.velocity.dx
        let relVelY = bodyB.velocity.dy - bodyA.velocity.dy
        let relVelAlongNormal = relVelX * normalX + relVelY * normalY

        if relVelAlongNormal > 0 {
            // Bodies are separating, apply impulse to prevent
            let impulse = relVelAlongNormal / CGFloat(invMassSum)

            if bodyA.isDynamic && !bodyA.pinned {
                bodyA.velocity.dx += impulse * CGFloat(invMassA) * normalX
                bodyA.velocity.dy += impulse * CGFloat(invMassA) * normalY
            }
            if bodyB.isDynamic && !bodyB.pinned {
                bodyB.velocity.dx -= impulse * CGFloat(invMassB) * normalX
                bodyB.velocity.dy -= impulse * CGFloat(invMassB) * normalY
            }
        }

        // Store reaction force
        joint._reactionForce = CGVector(
            dx: excess * normalX * correctionFactor / CGFloat(deltaTime),
            dy: excess * normalY * correctionFactor / CGFloat(deltaTime)
        )
    }

    // MARK: - Collision Detection

    /// Detects all collisions between bodies.
    private func detectCollisions(bodies: [SKPhysicsBody]) -> [SKPhysicsContact] {
        var contacts: [SKPhysicsContact] = []

        // Broad phase: AABB overlap test
        for i in 0..<bodies.count {
            for j in (i + 1)..<bodies.count {
                let bodyA = bodies[i]
                let bodyB = bodies[j]

                // Skip if both are static
                if !bodyA.isDynamic && !bodyB.isDynamic { continue }

                // Skip if collision masks don't match
                let shouldCollide = (bodyA.collisionBitMask & bodyB.categoryBitMask) != 0 ||
                                   (bodyB.collisionBitMask & bodyA.categoryBitMask) != 0
                let shouldContact = (bodyA.contactTestBitMask & bodyB.categoryBitMask) != 0 ||
                                   (bodyB.contactTestBitMask & bodyA.categoryBitMask) != 0

                if !shouldCollide && !shouldContact { continue }

                // Get AABBs
                guard let aabbA = getAABB(for: bodyA),
                      let aabbB = getAABB(for: bodyB) else { continue }

                // AABB overlap test
                if aabbA.intersects(aabbB) {
                    // Narrow phase: shape-specific test
                    if let contact = narrowPhaseTest(bodyA: bodyA, bodyB: bodyB,
                                                     aabbA: aabbA, aabbB: aabbB,
                                                     shouldCollide: shouldCollide) {
                        contacts.append(contact)
                    }
                }
            }
        }

        return contacts
    }

    /// Gets the axis-aligned bounding box for a physics body.
    private func getAABB(for body: SKPhysicsBody) -> CGRect? {
        guard let node = body.node else { return nil }
        let position = node.position

        switch body.shape {
        case .circle(let radius):
            return CGRect(
                x: position.x - radius,
                y: position.y - radius,
                width: radius * 2,
                height: radius * 2
            )

        case .circleWithCenter(let radius, let center):
            return CGRect(
                x: position.x + center.x - radius,
                y: position.y + center.y - radius,
                width: radius * 2,
                height: radius * 2
            )

        case .rectangle(let size):
            return CGRect(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2,
                width: size.width,
                height: size.height
            )

        case .rectangleWithCenter(let size, let center):
            return CGRect(
                x: position.x + center.x - size.width / 2,
                y: position.y + center.y - size.height / 2,
                width: size.width,
                height: size.height
            )

        case .edgeLoopRect(let rect):
            return CGRect(
                x: position.x + rect.minX,
                y: position.y + rect.minY,
                width: rect.width,
                height: rect.height
            )

        case .edge(let from, let to):
            let minX = min(from.x, to.x)
            let maxX = max(from.x, to.x)
            let minY = min(from.y, to.y)
            let maxY = max(from.y, to.y)
            return CGRect(
                x: position.x + minX,
                y: position.y + minY,
                width: max(maxX - minX, 1),
                height: max(maxY - minY, 1)
            )

        default:
            // For complex shapes, use a simple bounding box based on area
            let size = sqrt(body.area)
            return CGRect(
                x: position.x - size / 2,
                y: position.y - size / 2,
                width: size,
                height: size
            )
        }
    }

    /// Performs narrow phase collision test between two bodies.
    private func narrowPhaseTest(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                  aabbA: CGRect, aabbB: CGRect,
                                  shouldCollide: Bool) -> SKPhysicsContact? {
        guard let nodeA = bodyA.node, let nodeB = bodyB.node else { return nil }

        // Get shape info for both bodies
        let shapeA = bodyA.shape
        let shapeB = bodyB.shape
        let posA = nodeA.position
        let posB = nodeB.position

        // Dispatch to shape-specific collision tests
        switch (shapeA, shapeB) {
        case (.circle(let radiusA), .circle(let radiusB)):
            return circleVsCircle(bodyA: bodyA, bodyB: bodyB,
                                   posA: posA, posB: posB,
                                   radiusA: radiusA, radiusB: radiusB,
                                   centerA: .zero, centerB: .zero,
                                   shouldCollide: shouldCollide)

        case (.circleWithCenter(let radiusA, let centerA), .circle(let radiusB)):
            return circleVsCircle(bodyA: bodyA, bodyB: bodyB,
                                   posA: posA, posB: posB,
                                   radiusA: radiusA, radiusB: radiusB,
                                   centerA: centerA, centerB: .zero,
                                   shouldCollide: shouldCollide)

        case (.circle(let radiusA), .circleWithCenter(let radiusB, let centerB)):
            return circleVsCircle(bodyA: bodyA, bodyB: bodyB,
                                   posA: posA, posB: posB,
                                   radiusA: radiusA, radiusB: radiusB,
                                   centerA: .zero, centerB: centerB,
                                   shouldCollide: shouldCollide)

        case (.circleWithCenter(let radiusA, let centerA), .circleWithCenter(let radiusB, let centerB)):
            return circleVsCircle(bodyA: bodyA, bodyB: bodyB,
                                   posA: posA, posB: posB,
                                   radiusA: radiusA, radiusB: radiusB,
                                   centerA: centerA, centerB: centerB,
                                   shouldCollide: shouldCollide)

        case (.circle(let radius), .rectangle(let size)),
             (.circle(let radius), .rectangleWithCenter(let size, _)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeB {
                rectCenter = CGPoint(x: posB.x + center.x, y: posB.y + center.y)
            } else {
                rectCenter = posB
            }
            return circleVsRect(bodyA: bodyA, bodyB: bodyB,
                                 circlePos: posA, circleRadius: radius, circleOffset: .zero,
                                 rectCenter: rectCenter, rectSize: size,
                                 shouldCollide: shouldCollide)

        case (.circleWithCenter(let radius, let offset), .rectangle(let size)),
             (.circleWithCenter(let radius, let offset), .rectangleWithCenter(let size, _)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeB {
                rectCenter = CGPoint(x: posB.x + center.x, y: posB.y + center.y)
            } else {
                rectCenter = posB
            }
            return circleVsRect(bodyA: bodyA, bodyB: bodyB,
                                 circlePos: posA, circleRadius: radius, circleOffset: offset,
                                 rectCenter: rectCenter, rectSize: size,
                                 shouldCollide: shouldCollide)

        case (.rectangle(let size), .circle(let radius)),
             (.rectangleWithCenter(let size, _), .circle(let radius)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeA {
                rectCenter = CGPoint(x: posA.x + center.x, y: posA.y + center.y)
            } else {
                rectCenter = posA
            }
            // Swap order for consistent normal direction
            if let contact = circleVsRect(bodyA: bodyB, bodyB: bodyA,
                                           circlePos: posB, circleRadius: radius, circleOffset: .zero,
                                           rectCenter: rectCenter, rectSize: size,
                                           shouldCollide: shouldCollide) {
                // Swap bodies back and invert normal
                return SKPhysicsContact(
                    bodyA: bodyA,
                    bodyB: bodyB,
                    contactPoint: contact.contactPoint,
                    contactNormal: CGVector(dx: -contact.contactNormal.dx, dy: -contact.contactNormal.dy),
                    collisionImpulse: contact.collisionImpulse
                )
            }
            return nil

        case (.rectangle(let size), .circleWithCenter(let radius, let offset)),
             (.rectangleWithCenter(let size, _), .circleWithCenter(let radius, let offset)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeA {
                rectCenter = CGPoint(x: posA.x + center.x, y: posA.y + center.y)
            } else {
                rectCenter = posA
            }
            if let contact = circleVsRect(bodyA: bodyB, bodyB: bodyA,
                                           circlePos: posB, circleRadius: radius, circleOffset: offset,
                                           rectCenter: rectCenter, rectSize: size,
                                           shouldCollide: shouldCollide) {
                return SKPhysicsContact(
                    bodyA: bodyA,
                    bodyB: bodyB,
                    contactPoint: contact.contactPoint,
                    contactNormal: CGVector(dx: -contact.contactNormal.dx, dy: -contact.contactNormal.dy),
                    collisionImpulse: contact.collisionImpulse
                )
            }
            return nil

        case (.rectangle(let sizeA), .rectangle(let sizeB)),
             (.rectangleWithCenter(let sizeA, _), .rectangle(let sizeB)),
             (.rectangle(let sizeA), .rectangleWithCenter(let sizeB, _)),
             (.rectangleWithCenter(let sizeA, _), .rectangleWithCenter(let sizeB, _)):
            let centerA: CGPoint
            let centerB: CGPoint
            if case .rectangleWithCenter(_, let offset) = shapeA {
                centerA = CGPoint(x: posA.x + offset.x, y: posA.y + offset.y)
            } else {
                centerA = posA
            }
            if case .rectangleWithCenter(_, let offset) = shapeB {
                centerB = CGPoint(x: posB.x + offset.x, y: posB.y + offset.y)
            } else {
                centerB = posB
            }
            return rectVsRect(bodyA: bodyA, bodyB: bodyB,
                               centerA: centerA, sizeA: sizeA, rotationA: nodeA.zRotation,
                               centerB: centerB, sizeB: sizeB, rotationB: nodeB.zRotation,
                               shouldCollide: shouldCollide)

        default:
            // Fallback: use AABB intersection for other shapes
            return aabbFallback(bodyA: bodyA, bodyB: bodyB,
                                 nodeA: nodeA, nodeB: nodeB,
                                 aabbA: aabbA, aabbB: aabbB,
                                 shouldCollide: shouldCollide)
        }
    }

    // MARK: - Shape-Specific Collision Tests

    /// Circle vs Circle collision test.
    private func circleVsCircle(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                 posA: CGPoint, posB: CGPoint,
                                 radiusA: CGFloat, radiusB: CGFloat,
                                 centerA: CGPoint, centerB: CGPoint,
                                 shouldCollide: Bool) -> SKPhysicsContact? {
        // Calculate actual circle centers
        let actualCenterA = CGPoint(x: posA.x + centerA.x, y: posA.y + centerA.y)
        let actualCenterB = CGPoint(x: posB.x + centerB.x, y: posB.y + centerB.y)

        // Distance between centers
        let dx = actualCenterA.x - actualCenterB.x
        let dy = actualCenterA.y - actualCenterB.y
        let distSq = dx * dx + dy * dy
        let sumRadii = radiusA + radiusB

        // Check if circles actually overlap
        if distSq > sumRadii * sumRadii {
            return nil // No collision
        }

        let dist = sqrt(distSq)

        // Calculate normal (from B to A)
        let normal: CGVector
        if dist > 0.0001 {
            normal = CGVector(dx: dx / dist, dy: dy / dist)
        } else {
            // Circles are at same position, use arbitrary normal
            normal = CGVector(dx: 0, dy: 1)
        }

        // Contact point is on the line between centers, at the boundary
        let contactPoint = CGPoint(
            x: actualCenterB.x + normal.dx * radiusB,
            y: actualCenterB.y + normal.dy * radiusB
        )

        return SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            contactNormal: normal,
            collisionImpulse: shouldCollide ? 1.0 : 0.0
        )
    }

    /// Circle vs Rectangle collision test with rotation support.
    private func circleVsRect(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                               circlePos: CGPoint, circleRadius: CGFloat, circleOffset: CGPoint,
                               rectCenter: CGPoint, rectSize: CGSize,
                               shouldCollide: Bool) -> SKPhysicsContact? {
        // Actual circle center in world space
        let circleCenterX = circlePos.x + circleOffset.x
        let circleCenterY = circlePos.y + circleOffset.y

        // Get rectangle rotation from node
        let rectRotation = bodyB.node?.zRotation ?? 0

        // Transform circle center to rectangle's local coordinate space
        let localCircle = transformToLocalSpace(
            point: CGPoint(x: circleCenterX, y: circleCenterY),
            center: rectCenter,
            rotation: rectRotation
        )

        // Find closest point on axis-aligned rectangle to circle center (in local space)
        let halfWidth = rectSize.width / 2
        let halfHeight = rectSize.height / 2

        let closestLocalX = max(-halfWidth, min(localCircle.x, halfWidth))
        let closestLocalY = max(-halfHeight, min(localCircle.y, halfHeight))

        // Distance from circle center to closest point (in local space)
        let localDx = localCircle.x - closestLocalX
        let localDy = localCircle.y - closestLocalY
        let distSq = localDx * localDx + localDy * localDy

        // Check if distance is less than radius
        if distSq > circleRadius * circleRadius {
            return nil // No collision
        }

        let dist = sqrt(distSq)

        // Calculate normal (in local space, from rect to circle)
        var localNormal: CGVector
        if dist > 0.0001 {
            localNormal = CGVector(dx: localDx / dist, dy: localDy / dist)
        } else {
            // Circle center is inside rectangle, find closest edge
            let toLeft = localCircle.x - (-halfWidth)
            let toRight = halfWidth - localCircle.x
            let toBottom = localCircle.y - (-halfHeight)
            let toTop = halfHeight - localCircle.y

            let minDist = min(min(toLeft, toRight), min(toBottom, toTop))
            if minDist == toLeft {
                localNormal = CGVector(dx: -1, dy: 0)
            } else if minDist == toRight {
                localNormal = CGVector(dx: 1, dy: 0)
            } else if minDist == toBottom {
                localNormal = CGVector(dx: 0, dy: -1)
            } else {
                localNormal = CGVector(dx: 0, dy: 1)
            }
        }

        // Transform contact point and normal back to world space
        let localContact = CGPoint(x: closestLocalX, y: closestLocalY)
        let worldContact = transformToWorldSpace(
            point: localContact,
            center: rectCenter,
            rotation: rectRotation
        )
        let worldNormal = rotateVector(localNormal, by: rectRotation)

        return SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: worldContact,
            contactNormal: worldNormal,
            collisionImpulse: shouldCollide ? 1.0 : 0.0
        )
    }

    // MARK: - Coordinate Transformation Helpers

    /// Transforms a point from world space to local space (rotated around center).
    private func transformToLocalSpace(point: CGPoint, center: CGPoint, rotation: CGFloat) -> CGPoint {
        let cosR = cos(-rotation)
        let sinR = sin(-rotation)
        let dx = point.x - center.x
        let dy = point.y - center.y
        return CGPoint(
            x: dx * cosR - dy * sinR,
            y: dx * sinR + dy * cosR
        )
    }

    /// Transforms a point from local space to world space.
    private func transformToWorldSpace(point: CGPoint, center: CGPoint, rotation: CGFloat) -> CGPoint {
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        return CGPoint(
            x: center.x + point.x * cosR - point.y * sinR,
            y: center.y + point.x * sinR + point.y * cosR
        )
    }

    /// Rotates a vector by an angle.
    private func rotateVector(_ vector: CGVector, by angle: CGFloat) -> CGVector {
        let cosR = cos(angle)
        let sinR = sin(angle)
        return CGVector(
            dx: vector.dx * cosR - vector.dy * sinR,
            dy: vector.dx * sinR + vector.dy * cosR
        )
    }

    /// Rectangle vs Rectangle collision test using Separating Axis Theorem (SAT).
    private func rectVsRect(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                             centerA: CGPoint, sizeA: CGSize, rotationA: CGFloat,
                             centerB: CGPoint, sizeB: CGSize, rotationB: CGFloat,
                             shouldCollide: Bool) -> SKPhysicsContact? {
        // Get the four corners of each rectangle
        let cornersA = getRectCorners(center: centerA, size: sizeA, rotation: rotationA)
        let cornersB = getRectCorners(center: centerB, size: sizeB, rotation: rotationB)

        // Get the four axes to test (2 from each rectangle's edges)
        let axesA = getRectAxes(rotation: rotationA)
        let axesB = getRectAxes(rotation: rotationB)
        let axes = axesA + axesB

        // Track minimum overlap for contact normal
        var minOverlap: CGFloat = .infinity
        var minAxis: CGVector = CGVector(dx: 1, dy: 0)

        // Test each axis
        for axis in axes {
            let projA = projectCorners(cornersA, onto: axis)
            let projB = projectCorners(cornersB, onto: axis)

            // Check for overlap
            let overlap = min(projA.max, projB.max) - max(projA.min, projB.min)
            if overlap <= 0 {
                // Separating axis found - no collision
                return nil
            }

            if overlap < minOverlap {
                minOverlap = overlap
                minAxis = axis
            }
        }

        // Collision detected!
        // Ensure normal points from B to A
        let centerDiff = CGVector(dx: centerA.x - centerB.x, dy: centerA.y - centerB.y)
        let dotProduct = minAxis.dx * centerDiff.dx + minAxis.dy * centerDiff.dy
        if dotProduct < 0 {
            minAxis = CGVector(dx: -minAxis.dx, dy: -minAxis.dy)
        }

        // Calculate contact point (approximate as midpoint of overlap region)
        let contactPoint = CGPoint(
            x: (centerA.x + centerB.x) / 2,
            y: (centerA.y + centerB.y) / 2
        )

        return SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            contactNormal: minAxis,
            collisionImpulse: shouldCollide ? 1.0 : 0.0
        )
    }

    /// Gets the four corners of a rotated rectangle.
    private func getRectCorners(center: CGPoint, size: CGSize, rotation: CGFloat) -> [CGPoint] {
        let hw = size.width / 2
        let hh = size.height / 2
        let cosR = cos(rotation)
        let sinR = sin(rotation)

        // Local corners before rotation
        let localCorners = [
            CGPoint(x: -hw, y: -hh),
            CGPoint(x: hw, y: -hh),
            CGPoint(x: hw, y: hh),
            CGPoint(x: -hw, y: hh)
        ]

        // Transform to world space
        return localCorners.map { local in
            CGPoint(
                x: center.x + local.x * cosR - local.y * sinR,
                y: center.y + local.x * sinR + local.y * cosR
            )
        }
    }

    /// Gets the two perpendicular axes (normals of edges) for a rotated rectangle.
    private func getRectAxes(rotation: CGFloat) -> [CGVector] {
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        return [
            CGVector(dx: cosR, dy: sinR),      // x-axis rotated
            CGVector(dx: -sinR, dy: cosR)      // y-axis rotated
        ]
    }

    /// Projects corners onto an axis and returns min/max values.
    private func projectCorners(_ corners: [CGPoint], onto axis: CGVector) -> (min: CGFloat, max: CGFloat) {
        var minVal: CGFloat = .infinity
        var maxVal: CGFloat = -.infinity

        for corner in corners {
            let projection = corner.x * axis.dx + corner.y * axis.dy
            minVal = min(minVal, projection)
            maxVal = max(maxVal, projection)
        }

        return (minVal, maxVal)
    }

    /// AABB fallback for complex shapes.
    private func aabbFallback(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                               nodeA: SKNode, nodeB: SKNode,
                               aabbA: CGRect, aabbB: CGRect,
                               shouldCollide: Bool) -> SKPhysicsContact? {
        let intersection = aabbA.intersection(aabbB)
        guard !intersection.isNull else { return nil }

        let contactPoint = CGPoint(
            x: intersection.midX,
            y: intersection.midY
        )

        // Calculate contact normal (from B to A)
        let dx = nodeA.position.x - nodeB.position.x
        let dy = nodeA.position.y - nodeB.position.y
        let dist = sqrt(dx * dx + dy * dy)
        let normal: CGVector
        if dist > 0 {
            normal = CGVector(dx: dx / dist, dy: dy / dist)
        } else {
            normal = CGVector(dx: 0, dy: 1)
        }

        return SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            contactNormal: normal,
            collisionImpulse: shouldCollide ? 1.0 : 0.0
        )
    }

    // MARK: - Collision Resolution

    /// Resolves all collisions by separating bodies and applying impulses.
    private func resolveCollisions(contacts: [SKPhysicsContact]) {
        for contact in contacts {
            guard contact.collisionImpulse > 0 else { continue }
            let bodyA = contact.bodyA
            let bodyB = contact.bodyB
            guard let nodeA = bodyA.node, let nodeB = bodyB.node else { continue }

            let normal = contact.contactNormal

            // Calculate relative velocity
            let relVelX = bodyA.velocity.dx - bodyB.velocity.dx
            let relVelY = bodyA.velocity.dy - bodyB.velocity.dy
            let relVelAlongNormal = relVelX * normal.dx + relVelY * normal.dy

            // Only resolve if bodies are approaching
            if relVelAlongNormal > 0 { continue }

            // Calculate restitution (use minimum)
            let restitution = min(bodyA.restitution, bodyB.restitution)

            // Calculate impulse scalar
            let invMassA = bodyA.isDynamic && !bodyA.pinned ? 1.0 / bodyA.mass : 0
            let invMassB = bodyB.isDynamic && !bodyB.pinned ? 1.0 / bodyB.mass : 0
            let invMassSum = invMassA + invMassB

            if invMassSum == 0 { continue }

            let j = -(1.0 + restitution) * relVelAlongNormal / invMassSum

            // Apply impulse
            if bodyA.isDynamic && !bodyA.pinned {
                bodyA.velocity.dx += j * invMassA * normal.dx
                bodyA.velocity.dy += j * invMassA * normal.dy
            }
            if bodyB.isDynamic && !bodyB.pinned {
                bodyB.velocity.dx -= j * invMassB * normal.dx
                bodyB.velocity.dy -= j * invMassB * normal.dy
            }

            // Positional correction to prevent sinking
            let penetration = calculatePenetration(bodyA: bodyA, bodyB: bodyB,
                                                   nodeA: nodeA, nodeB: nodeB)
            if penetration > 0 {
                let correction = penetration * 0.8 / invMassSum // 80% correction
                if bodyA.isDynamic && !bodyA.pinned {
                    nodeA.position.x += correction * invMassA * normal.dx
                    nodeA.position.y += correction * invMassA * normal.dy
                }
                if bodyB.isDynamic && !bodyB.pinned {
                    nodeB.position.x -= correction * invMassB * normal.dx
                    nodeB.position.y -= correction * invMassB * normal.dy
                }
            }
        }
    }

    /// Calculates penetration depth between two bodies.
    private func calculatePenetration(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                                       nodeA: SKNode, nodeB: SKNode) -> CGFloat {
        let shapeA = bodyA.shape
        let shapeB = bodyB.shape
        let posA = nodeA.position
        let posB = nodeB.position

        // Shape-specific penetration calculation
        switch (shapeA, shapeB) {
        case (.circle(let radiusA), .circle(let radiusB)):
            return circlePenetration(posA: posA, posB: posB,
                                      radiusA: radiusA, radiusB: radiusB,
                                      centerA: .zero, centerB: .zero)

        case (.circleWithCenter(let radiusA, let centerA), .circle(let radiusB)):
            return circlePenetration(posA: posA, posB: posB,
                                      radiusA: radiusA, radiusB: radiusB,
                                      centerA: centerA, centerB: .zero)

        case (.circle(let radiusA), .circleWithCenter(let radiusB, let centerB)):
            return circlePenetration(posA: posA, posB: posB,
                                      radiusA: radiusA, radiusB: radiusB,
                                      centerA: .zero, centerB: centerB)

        case (.circleWithCenter(let radiusA, let centerA), .circleWithCenter(let radiusB, let centerB)):
            return circlePenetration(posA: posA, posB: posB,
                                      radiusA: radiusA, radiusB: radiusB,
                                      centerA: centerA, centerB: centerB)

        case (.circle(let radius), .rectangle(let size)),
             (.circle(let radius), .rectangleWithCenter(let size, _)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeB {
                rectCenter = CGPoint(x: posB.x + center.x, y: posB.y + center.y)
            } else {
                rectCenter = posB
            }
            return circleRectPenetration(circlePos: posA, circleRadius: radius, circleOffset: .zero,
                                          rectCenter: rectCenter, rectSize: size)

        case (.circleWithCenter(let radius, let offset), .rectangle(let size)),
             (.circleWithCenter(let radius, let offset), .rectangleWithCenter(let size, _)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeB {
                rectCenter = CGPoint(x: posB.x + center.x, y: posB.y + center.y)
            } else {
                rectCenter = posB
            }
            return circleRectPenetration(circlePos: posA, circleRadius: radius, circleOffset: offset,
                                          rectCenter: rectCenter, rectSize: size)

        case (.rectangle(let size), .circle(let radius)),
             (.rectangleWithCenter(let size, _), .circle(let radius)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeA {
                rectCenter = CGPoint(x: posA.x + center.x, y: posA.y + center.y)
            } else {
                rectCenter = posA
            }
            return circleRectPenetration(circlePos: posB, circleRadius: radius, circleOffset: .zero,
                                          rectCenter: rectCenter, rectSize: size)

        case (.rectangle(let size), .circleWithCenter(let radius, let offset)),
             (.rectangleWithCenter(let size, _), .circleWithCenter(let radius, let offset)):
            let rectCenter: CGPoint
            if case .rectangleWithCenter(_, let center) = shapeA {
                rectCenter = CGPoint(x: posA.x + center.x, y: posA.y + center.y)
            } else {
                rectCenter = posA
            }
            return circleRectPenetration(circlePos: posB, circleRadius: radius, circleOffset: offset,
                                          rectCenter: rectCenter, rectSize: size)

        default:
            // Fallback: AABB overlap
            guard let aabbA = getAABB(for: bodyA),
                  let aabbB = getAABB(for: bodyB) else { return 0 }

            let overlapX = min(aabbA.maxX - aabbB.minX, aabbB.maxX - aabbA.minX)
            let overlapY = min(aabbA.maxY - aabbB.minY, aabbB.maxY - aabbA.minY)

            return min(max(overlapX, 0), max(overlapY, 0))
        }
    }

    /// Calculates penetration depth for circle vs circle.
    private func circlePenetration(posA: CGPoint, posB: CGPoint,
                                    radiusA: CGFloat, radiusB: CGFloat,
                                    centerA: CGPoint, centerB: CGPoint) -> CGFloat {
        let actualCenterA = CGPoint(x: posA.x + centerA.x, y: posA.y + centerA.y)
        let actualCenterB = CGPoint(x: posB.x + centerB.x, y: posB.y + centerB.y)

        let dx = actualCenterA.x - actualCenterB.x
        let dy = actualCenterA.y - actualCenterB.y
        let dist = sqrt(dx * dx + dy * dy)
        let sumRadii = radiusA + radiusB

        return max(0, sumRadii - dist)
    }

    /// Calculates penetration depth for circle vs rectangle.
    private func circleRectPenetration(circlePos: CGPoint, circleRadius: CGFloat, circleOffset: CGPoint,
                                        rectCenter: CGPoint, rectSize: CGSize) -> CGFloat {
        let circleCenterX = circlePos.x + circleOffset.x
        let circleCenterY = circlePos.y + circleOffset.y

        let halfWidth = rectSize.width / 2
        let halfHeight = rectSize.height / 2

        let closestX = max(rectCenter.x - halfWidth, min(circleCenterX, rectCenter.x + halfWidth))
        let closestY = max(rectCenter.y - halfHeight, min(circleCenterY, rectCenter.y + halfHeight))

        let dx = circleCenterX - closestX
        let dy = circleCenterY - closestY
        let dist = sqrt(dx * dx + dy * dy)

        return max(0, circleRadius - dist)
    }

    // MARK: - Contact Tracking

    /// Updates contact tracking and fires delegate callbacks.
    private func updateContactTracking(contacts: [SKPhysicsContact],
                                        world: SKPhysicsWorld) {
        let delegate = world.contactDelegate

        // Build current contact set
        world.previousContacts = world.activeContacts
        world.activeContacts.removeAll()

        var newContactCache: [SKPhysicsWorld.ContactPair: SKPhysicsContact] = [:]

        for contact in contacts {
            let bodyA = contact.bodyA
            let bodyB = contact.bodyB
            let pair = SKPhysicsWorld.ContactPair(bodyA, bodyB)
            world.activeContacts.insert(pair)
            newContactCache[pair] = contact

            // Check if this is a new contact
            if !world.previousContacts.contains(pair) {
                delegate?.didBegin(contact)
            }
        }

        // Find ended contacts
        for pair in world.previousContacts {
            if !world.activeContacts.contains(pair) {
                // Use cached contact for the callback
                if let cachedContact = world.contactCache[pair] {
                    delegate?.didEnd(cachedContact)
                }
            }
        }

        // Update cache
        world.contactCache = newContactCache
    }
}

