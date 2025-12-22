// SKPhysicsWorld.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics
#if canImport(simd)
import simd
#endif

/// The driver of the physics engine in a scene; it exposes the ability for you to configure and query the physics system.
///
/// `SKPhysicsWorld` runs the physics engine of a scene and is the place that contact detection occurs.
/// Do not create a `SKPhysicsWorld` directly; the system creates a physics world and adds it to the scene's
/// `physicsWorld` property.
open class SKPhysicsWorld: @unchecked Sendable {

    // MARK: - Properties

    /// A vector that specifies the gravitational acceleration applied to physics bodies in the physics world.
    open var gravity: CGVector = CGVector(dx: 0, dy: -9.8)

    /// The rate at which the simulation executes.
    open var speed: CGFloat = 1.0

    /// A delegate that is called when two physics bodies come in contact with each other.
    open weak var contactDelegate: SKPhysicsContactDelegate?

    // MARK: - Internal Properties

    /// The scene that owns this physics world.
    internal weak var scene: SKScene?

    /// The joints in this physics world.
    private var joints: [SKPhysicsJoint] = []

    /// Internal accessor for physics engine.
    internal var allJoints: [SKPhysicsJoint] { joints }

    // MARK: - Contact Tracking State (per-scene)

    /// A unique identifier for a contact pair.
    internal struct ContactPair: Hashable {
        let bodyA: ObjectIdentifier
        let bodyB: ObjectIdentifier

        init(_ a: SKPhysicsBody, _ b: SKPhysicsBody) {
            // Order consistently to avoid duplicates
            let idA = ObjectIdentifier(a)
            let idB = ObjectIdentifier(b)
            if idA < idB {
                self.bodyA = idA
                self.bodyB = idB
            } else {
                self.bodyA = idB
                self.bodyB = idA
            }
        }
    }

    /// Active contacts from the current frame.
    internal var activeContacts: Set<ContactPair> = []

    /// Previous frame's contacts (for detecting begin/end).
    internal var previousContacts: Set<ContactPair> = []

    /// Cache of active contacts for end-contact callbacks.
    internal var contactCache: [ContactPair: SKPhysicsContact] = [:]

    /// Resets all contact tracking state.
    internal func resetContactState() {
        activeContacts.removeAll()
        previousContacts.removeAll()
        contactCache.removeAll()
    }

    // MARK: - Initializers

    public init() {
    }

    // MARK: - Joint Management

    /// Adds a joint to the physics world.
    ///
    /// - Parameter joint: The joint to add.
    open func add(_ joint: SKPhysicsJoint) {
        joints.append(joint)
    }

    /// Removes all joints from the physics world.
    open func removeAllJoints() {
        joints.removeAll()
    }

    /// Removes a specific joint from the physics world.
    ///
    /// - Parameter joint: The joint to remove.
    open func remove(_ joint: SKPhysicsJoint) {
        joints.removeAll { $0 === joint }
    }

    // MARK: - Body Searching

    /// Searches for the first physics body that intersects a ray.
    ///
    /// - Parameters:
    ///   - start: The start point of the ray.
    ///   - end: The end point of the ray.
    /// - Returns: The first physics body that intersects the ray, or nil if none intersect.
    open func body(alongRayStart start: CGPoint, end: CGPoint) -> SKPhysicsBody? {
        var result: SKPhysicsBody? = nil
        var closestDistance: CGFloat = .infinity

        enumerateBodies(alongRayStart: start, end: end) { body, hitPoint, _, stop in
            let dx = hitPoint.x - start.x
            let dy = hitPoint.y - start.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < closestDistance {
                closestDistance = distance
                result = body
            }
        }

        return result
    }

    /// Searches for the first physics body that contains a point.
    ///
    /// - Parameter point: The point to search.
    /// - Returns: The first physics body that contains the point, or nil if none contain it.
    open func body(at point: CGPoint) -> SKPhysicsBody? {
        var result: SKPhysicsBody? = nil

        enumerateBodies(at: point) { body, stop in
            result = body
            stop.pointee = true
        }

        return result
    }

    /// Searches for the first physics body that intersects the specified rectangle.
    ///
    /// - Parameter rect: The rectangle to search.
    /// - Returns: The first physics body that intersects the rectangle, or nil if none intersect.
    open func body(in rect: CGRect) -> SKPhysicsBody? {
        var result: SKPhysicsBody? = nil

        enumerateBodies(in: rect) { body, stop in
            result = body
            stop.pointee = true
        }

        return result
    }

    /// Enumerates all the physics bodies in the scene that intersect a ray.
    ///
    /// - Parameters:
    ///   - start: The start point of the ray.
    ///   - end: The end point of the ray.
    ///   - block: A block to call for each body that intersects the ray.
    open func enumerateBodies(alongRayStart start: CGPoint, end: CGPoint, using block: (SKPhysicsBody, CGPoint, CGVector, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let scene = scene else { return }

        var bodies: [SKPhysicsBody] = []
        collectBodies(from: scene, into: &bodies)

        var stop = ObjCBool(false)

        for body in bodies {
            guard let node = body.node else { continue }
            guard let aabb = getAABB(for: body, node: node) else { continue }

            if let (hitPoint, normal) = rayIntersectsAABB(start: start, end: end, rect: aabb) {
                block(body, hitPoint, normal, &stop)
                if stop.boolValue { break }
            }
        }
    }

    /// Enumerates all the physics bodies in the scene that contain a point.
    ///
    /// - Parameters:
    ///   - point: The point to search.
    ///   - block: A block to call for each body that contains the point.
    open func enumerateBodies(at point: CGPoint, using block: (SKPhysicsBody, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let scene = scene else { return }

        var bodies: [SKPhysicsBody] = []
        collectBodies(from: scene, into: &bodies)

        var stop = ObjCBool(false)

        for body in bodies {
            guard let node = body.node else { continue }

            if bodyContainsPoint(body, node: node, point: point) {
                block(body, &stop)
                if stop.boolValue { break }
            }
        }
    }

    /// Enumerates all the physics bodies in the scene that intersect the specified rectangle.
    ///
    /// - Parameters:
    ///   - rect: The rectangle to search.
    ///   - block: A block to call for each body that intersects the rectangle.
    open func enumerateBodies(in rect: CGRect, using block: (SKPhysicsBody, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let scene = scene else { return }

        var bodies: [SKPhysicsBody] = []
        collectBodies(from: scene, into: &bodies)

        var stop = ObjCBool(false)

        for body in bodies {
            guard let node = body.node else { continue }
            guard let aabb = getAABB(for: body, node: node) else { continue }

            if aabb.intersects(rect) {
                block(body, &stop)
                if stop.boolValue { break }
            }
        }
    }

    // MARK: - Private Query Helpers

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

    /// Gets the axis-aligned bounding box for a physics body.
    private func getAABB(for body: SKPhysicsBody, node: SKNode) -> CGRect? {
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

    /// Checks if a body contains a point.
    private func bodyContainsPoint(_ body: SKPhysicsBody, node: SKNode, point: CGPoint) -> Bool {
        let position = node.position

        switch body.shape {
        case .circle(let radius):
            let dx = point.x - position.x
            let dy = point.y - position.y
            return (dx * dx + dy * dy) <= (radius * radius)

        case .circleWithCenter(let radius, let center):
            let dx = point.x - (position.x + center.x)
            let dy = point.y - (position.y + center.y)
            return (dx * dx + dy * dy) <= (radius * radius)

        case .rectangle(let size):
            let rect = CGRect(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return rect.contains(point)

        case .rectangleWithCenter(let size, let center):
            let rect = CGRect(
                x: position.x + center.x - size.width / 2,
                y: position.y + center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return rect.contains(point)

        default:
            // For complex shapes, use AABB containment as approximation
            if let aabb = getAABB(for: body, node: node) {
                return aabb.contains(point)
            }
            return false
        }
    }

    /// Tests if a ray intersects an AABB and returns the hit point and normal.
    private func rayIntersectsAABB(start: CGPoint, end: CGPoint, rect: CGRect) -> (CGPoint, CGVector)? {
        let dx = end.x - start.x
        let dy = end.y - start.y

        var tmin: CGFloat = 0
        var tmax: CGFloat = 1
        var normal = CGVector(dx: 0, dy: 0)

        // X axis
        if abs(dx) < 0.0001 {
            if start.x < rect.minX || start.x > rect.maxX {
                return nil
            }
        } else {
            let t1 = (rect.minX - start.x) / dx
            let t2 = (rect.maxX - start.x) / dx
            let tEnter = min(t1, t2)
            let tExit = max(t1, t2)

            if tEnter > tmin {
                tmin = tEnter
                normal = CGVector(dx: dx > 0 ? -1 : 1, dy: 0)
            }
            tmax = min(tmax, tExit)
        }

        // Y axis
        if abs(dy) < 0.0001 {
            if start.y < rect.minY || start.y > rect.maxY {
                return nil
            }
        } else {
            let t1 = (rect.minY - start.y) / dy
            let t2 = (rect.maxY - start.y) / dy
            let tEnter = min(t1, t2)
            let tExit = max(t1, t2)

            if tEnter > tmin {
                tmin = tEnter
                normal = CGVector(dx: 0, dy: dy > 0 ? -1 : 1)
            }
            tmax = min(tmax, tExit)
        }

        if tmin > tmax || tmax < 0 || tmin > 1 {
            return nil
        }

        let hitPoint = CGPoint(
            x: start.x + dx * tmin,
            y: start.y + dy * tmin
        )

        return (hitPoint, normal)
    }

    // MARK: - Field Sampling

    /// Samples all of the field nodes in the scene and returns the summation of their forces at that point.
    ///
    /// - Parameter position: The position at which to sample the fields.
    /// - Returns: The total force vector at that position.
    open func sampleFields(at position: vector_float3) -> vector_float3 {
        guard let scene = scene else { return .zero }

        var totalForce = vector_float3.zero
        var hasExclusiveField = false
        var exclusiveForce = vector_float3.zero

        // Collect all field nodes in the scene
        var fieldNodes: [SKFieldNode] = []
        collectFieldNodes(from: scene, into: &fieldNodes)

        let positionPoint = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))

        for field in fieldNodes {
            guard field.isEnabled else { continue }

            // Check if position is within the field's region
            if let region = field.region {
                // Convert position to field's local coordinate space
                let localPoint = field.convert(positionPoint, from: scene)
                guard region.contains(localPoint) else { continue }
            }

            // Calculate field position in scene coordinates
            let fieldPos = scene.convert(.zero, from: field)
            let fieldPosition = vector_float3(Float(fieldPos.x), Float(fieldPos.y), 0)

            // Calculate force from this field
            let force = calculateFieldForce(
                field: field,
                fieldPosition: fieldPosition,
                samplePosition: position
            )

            if field.isExclusive {
                // Exclusive fields override all others
                if !hasExclusiveField {
                    hasExclusiveField = true
                    exclusiveForce = force
                } else {
                    // Multiple exclusive fields - add them together
                    exclusiveForce += force
                }
            } else {
                totalForce += force
            }
        }

        return hasExclusiveField ? exclusiveForce : totalForce
    }

    /// Recursively collects all SKFieldNode instances in a node tree.
    private func collectFieldNodes(from node: SKNode, into fieldNodes: inout [SKFieldNode]) {
        if let field = node as? SKFieldNode {
            fieldNodes.append(field)
        }
        for child in node.children {
            collectFieldNodes(from: child, into: &fieldNodes)
        }
    }

    /// Calculates the force applied by a field at a given position.
    private func calculateFieldForce(field: SKFieldNode, fieldPosition: vector_float3, samplePosition: vector_float3) -> vector_float3 {
        // Calculate displacement from field to sample position
        let displacement = samplePosition - fieldPosition
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
            // Attracts toward the field node
            if distance > 0.0001 {
                let direction = -simd_normalize(displacement)
                return direction * strength
            }
            return .zero

        case .linearGravity(let direction):
            // Applies force in a constant direction
            return simd_normalize(direction) * strength

        case .drag:
            // Drag depends on velocity, but for sampling we return zero
            // since we don't have velocity information
            return .zero

        case .vortex:
            // Perpendicular force (tangent to circle around field)
            if distance > 0.0001 {
                // 2D: rotate displacement 90 degrees
                let perpendicular = vector_float3(-displacement.y, displacement.x, 0)
                return simd_normalize(perpendicular) * strength
            }
            return .zero

        case .electric:
            // Electric field: force proportional to charge
            // For sampling, we assume charge = 1.0
            if distance > 0.0001 {
                let direction = simd_normalize(displacement)
                return direction * strength
            }
            return .zero

        case .magnetic:
            // Magnetic field depends on velocity (Lorentz force)
            // For sampling without velocity, we return zero
            return .zero

        case .spring:
            // Spring force toward the field node (F = -kx)
            return -displacement * strength

        case .velocityWithVector(let direction):
            // Sets velocity, not force - return the direction scaled by strength
            return simd_normalize(direction) * strength

        case .velocityWithTexture:
            // Texture-based velocity field would require texture sampling
            // Return zero for now as it needs texture coordinate lookup
            return .zero

        case .noise(let smoothness, let animationSpeed):
            // Simple noise-based force
            // Use position as seed for deterministic noise
            let noiseX = simplexNoise(x: samplePosition.x * Float(1.0 / (smoothness + 0.1)),
                                       y: samplePosition.y * Float(1.0 / (smoothness + 0.1)),
                                       z: Float(animationSpeed))
            let noiseY = simplexNoise(x: samplePosition.y * Float(1.0 / (smoothness + 0.1)),
                                       y: samplePosition.x * Float(1.0 / (smoothness + 0.1)),
                                       z: Float(animationSpeed) + 1000)
            return vector_float3(noiseX, noiseY, 0) * strength

        case .turbulence(let smoothness, let animationSpeed):
            // Turbulence is similar to noise but potentially more chaotic
            let noiseX = simplexNoise(x: samplePosition.x * Float(1.0 / (smoothness + 0.1)) * 2,
                                       y: samplePosition.y * Float(1.0 / (smoothness + 0.1)) * 2,
                                       z: Float(animationSpeed))
            let noiseY = simplexNoise(x: samplePosition.y * Float(1.0 / (smoothness + 0.1)) * 2,
                                       y: samplePosition.x * Float(1.0 / (smoothness + 0.1)) * 2,
                                       z: Float(animationSpeed) + 1000)
            return vector_float3(noiseX, noiseY, 0) * strength

        case .custom(let evaluator):
            // Custom evaluator - pass default values since we don't have body info
            return evaluator(samplePosition, .zero, 1.0, 1.0, 0)
        }
    }

    /// Simple noise function for field sampling.
    /// This is a simplified Perlin-like noise for basic randomization.
    private func simplexNoise(x: Float, y: Float, z: Float) -> Float {
        // Simple hash-based noise approximation
        let ix = Int(floor(x)) & 255
        let iy = Int(floor(y)) & 255
        let iz = Int(floor(z)) & 255

        let fx = x - floor(x)
        let fy = y - floor(y)
        let fz = z - floor(z)

        // Smooth interpolation
        let u = fx * fx * (3 - 2 * fx)
        let v = fy * fy * (3 - 2 * fy)
        let w = fz * fz * (3 - 2 * fz)

        // Hash function
        func hash(_ n: Int) -> Float {
            var x = n
            x = ((x >> 16) ^ x) &* 0x45d9f3b
            x = ((x >> 16) ^ x) &* 0x45d9f3b
            x = (x >> 16) ^ x
            return Float(x & 0xFFFF) / 32768.0 - 1.0
        }

        // Trilinear interpolation
        let n000 = hash(ix + iy * 57 + iz * 113)
        let n100 = hash(ix + 1 + iy * 57 + iz * 113)
        let n010 = hash(ix + (iy + 1) * 57 + iz * 113)
        let n110 = hash(ix + 1 + (iy + 1) * 57 + iz * 113)
        let n001 = hash(ix + iy * 57 + (iz + 1) * 113)
        let n101 = hash(ix + 1 + iy * 57 + (iz + 1) * 113)
        let n011 = hash(ix + (iy + 1) * 57 + (iz + 1) * 113)
        let n111 = hash(ix + 1 + (iy + 1) * 57 + (iz + 1) * 113)

        let nx00 = n000 + u * (n100 - n000)
        let nx10 = n010 + u * (n110 - n010)
        let nx01 = n001 + u * (n101 - n001)
        let nx11 = n011 + u * (n111 - n011)

        let nxy0 = nx00 + v * (nx10 - nx00)
        let nxy1 = nx01 + v * (nx11 - nx01)

        return nxy0 + w * (nxy1 - nxy0)
    }
}

