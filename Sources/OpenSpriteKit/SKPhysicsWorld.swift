// SKPhysicsWorld.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(simd)
import simd
#endif

/// The driver of the physics engine in a scene; it exposes the ability for you to configure and query the physics system.
///
/// `SKPhysicsWorld` runs the physics engine of a scene and is the place that contact detection occurs.
/// Do not create a `SKPhysicsWorld` directly; the system creates a physics world and adds it to the scene's
/// `physicsWorld` property.
open class SKPhysicsWorld: NSObject, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

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

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        gravity = coder.decodeCGVector(forKey: "gravity")
        speed = CGFloat(coder.decodeDouble(forKey: "speed"))
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(gravity, forKey: "gravity")
        coder.encode(Double(speed), forKey: "speed")
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
        // TODO: Implement field sampling
        return .zero
    }
}

// MARK: - NSCoder Extensions for CGVector

extension NSCoder {
    func decodeCGVector(forKey key: String) -> CGVector {
        let dx = decodeDouble(forKey: "\(key).dx")
        let dy = decodeDouble(forKey: "\(key).dy")
        return CGVector(dx: dx, dy: dy)
    }

    func encode(_ vector: CGVector, forKey key: String) {
        encode(Double(vector.dx), forKey: "\(key).dx")
        encode(Double(vector.dy), forKey: "\(key).dy")
    }
}
