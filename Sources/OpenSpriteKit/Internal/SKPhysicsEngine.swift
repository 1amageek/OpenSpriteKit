// SKPhysicsEngine.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

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

        // Collect all physics bodies in the scene
        var bodies: [SKPhysicsBody] = []
        collectBodies(from: scene, into: &bodies)

        // Apply accumulated forces (with deltaTime)
        applyAccumulatedForces(to: bodies, deltaTime: dt)

        // Apply gravity to dynamic bodies
        applyGravity(to: bodies, gravity: gravity, deltaTime: dt)

        // Integrate velocities (update positions)
        integrateVelocities(bodies: bodies, deltaTime: dt)

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
                let momentOfInertia = body.mass * body.area
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

    /// Circle vs Rectangle collision test.
    private func circleVsRect(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody,
                               circlePos: CGPoint, circleRadius: CGFloat, circleOffset: CGPoint,
                               rectCenter: CGPoint, rectSize: CGSize,
                               shouldCollide: Bool) -> SKPhysicsContact? {
        // Actual circle center
        let circleCenterX = circlePos.x + circleOffset.x
        let circleCenterY = circlePos.y + circleOffset.y

        // Find closest point on rectangle to circle center
        let halfWidth = rectSize.width / 2
        let halfHeight = rectSize.height / 2

        let closestX = max(rectCenter.x - halfWidth, min(circleCenterX, rectCenter.x + halfWidth))
        let closestY = max(rectCenter.y - halfHeight, min(circleCenterY, rectCenter.y + halfHeight))

        // Distance from circle center to closest point
        let dx = circleCenterX - closestX
        let dy = circleCenterY - closestY
        let distSq = dx * dx + dy * dy

        // Check if distance is less than radius
        if distSq > circleRadius * circleRadius {
            return nil // No collision
        }

        let dist = sqrt(distSq)

        // Calculate normal (from rect to circle)
        let normal: CGVector
        if dist > 0.0001 {
            normal = CGVector(dx: dx / dist, dy: dy / dist)
        } else {
            // Circle center is inside rectangle, find closest edge
            let toLeft = circleCenterX - (rectCenter.x - halfWidth)
            let toRight = (rectCenter.x + halfWidth) - circleCenterX
            let toBottom = circleCenterY - (rectCenter.y - halfHeight)
            let toTop = (rectCenter.y + halfHeight) - circleCenterY

            let minDist = min(min(toLeft, toRight), min(toBottom, toTop))
            if minDist == toLeft {
                normal = CGVector(dx: -1, dy: 0)
            } else if minDist == toRight {
                normal = CGVector(dx: 1, dy: 0)
            } else if minDist == toBottom {
                normal = CGVector(dx: 0, dy: -1)
            } else {
                normal = CGVector(dx: 0, dy: 1)
            }
        }

        let contactPoint = CGPoint(x: closestX, y: closestY)

        return SKPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            contactNormal: normal,
            collisionImpulse: shouldCollide ? 1.0 : 0.0
        )
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

// MARK: - Impulse Application

extension SKPhysicsBody {
    /// Applies an impulse to the center of gravity (immediate velocity change).
    internal func applyImpulseInternal(_ impulse: CGVector) {
        guard isDynamic && !pinned else { return }
        // Impulse = m * dv, so dv = impulse / m
        velocity.dx += impulse.dx / mass
        velocity.dy += impulse.dy / mass
    }

    /// Applies angular impulse (immediate angular velocity change).
    internal func applyAngularImpulseInternal(_ impulse: CGFloat) {
        guard isDynamic && allowsRotation && !pinned else { return }
        // For simplicity, assume moment of inertia = mass * area
        let momentOfInertia = mass * area
        if momentOfInertia > 0 {
            angularVelocity += impulse / momentOfInertia
        }
    }
}
