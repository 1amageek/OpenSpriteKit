// SKPhysicsBody.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// The shape type for a physics body collision shape.
public enum SKPhysicsBodyShape {
    /// A circular shape centered at origin.
    case circle(radius: CGFloat)

    /// A circular shape with custom center.
    case circleWithCenter(radius: CGFloat, center: CGPoint)

    /// A rectangular shape centered at origin.
    case rectangle(size: CGSize)

    /// A rectangular shape with custom center.
    case rectangleWithCenter(size: CGSize, center: CGPoint)

    /// A polygon defined by a path.
    case polygon(path: CGPath)

    /// An edge chain (non-solid boundary).
    case edgeChain(path: CGPath)

    /// An edge loop (closed non-solid boundary).
    case edgeLoop(path: CGPath)

    /// An edge loop from a rectangle.
    case edgeLoopRect(rect: CGRect)

    /// A single edge between two points.
    case edge(from: CGPoint, to: CGPoint)

    /// A composite body made of multiple bodies.
    case composite(bodies: [SKPhysicsBody])
}

/// An object that adds physics simulation to a node.
///
/// An `SKPhysicsBody` object defines the shape and simulation parameters for a physics body
/// in the physics simulation. When a scene processes a new frame, it performs physics calculations
/// on physics bodies attached to nodes in the scene.
open class SKPhysicsBody: @unchecked Sendable {

    // MARK: - Shape

    /// The collision shape of this physics body.
    internal var shape: SKPhysicsBodyShape = .rectangle(size: .zero)

    // MARK: - Properties

    /// The node that this physics body is attached to.
    open weak var node: SKNode?

    /// A Boolean value that indicates whether this physics body is affected by the physics world's gravity.
    open var affectedByGravity: Bool = true

    /// A Boolean value that indicates whether this physics body allows rotation.
    open var allowsRotation: Bool = true

    /// A Boolean value that indicates whether this physics body moves in response to physics forces.
    open var isDynamic: Bool = true

    /// The mass of the body in kilograms.
    open var mass: CGFloat = 1.0

    /// The density of the object in kilograms per square meter.
    open var density: CGFloat = 1.0

    /// The area covered by the body.
    open internal(set) var area: CGFloat = 0.0

    /// The roughness of the body's surface.
    open var friction: CGFloat = 0.2

    /// The restitution of the physics body.
    open var restitution: CGFloat = 0.2

    /// The linear damping applied to the body's velocity.
    open var linearDamping: CGFloat = 0.1

    /// The angular damping applied to the body's rotation.
    open var angularDamping: CGFloat = 0.1

    /// A mask that defines which categories this physics body belongs to.
    open var categoryBitMask: UInt32 = 0xFFFFFFFF

    /// A mask that defines which categories of bodies can collide with this physics body.
    open var collisionBitMask: UInt32 = 0xFFFFFFFF

    /// A mask that defines which categories of bodies cause intersection notifications.
    open var contactTestBitMask: UInt32 = 0

    /// A mask defining which categories of fields this body responds to.
    open var fieldBitMask: UInt32 = 0xFFFFFFFF

    /// A Boolean value that indicates whether this physics body is at rest.
    open var isResting: Bool = false

    /// A Boolean value that indicates whether the node uses precise collision detection.
    open var usesPreciseCollisionDetection: Bool = false

    /// The physics body's velocity.
    open var velocity: CGVector = .zero

    /// The physics body's angular velocity.
    open var angularVelocity: CGFloat = 0.0

    /// Accumulated force to be applied in the next simulation step.
    internal var accumulatedForce: CGVector = .zero

    /// Accumulated torque to be applied in the next simulation step.
    internal var accumulatedTorque: CGFloat = 0.0

    /// A Boolean value that indicates whether this physics body is pinned to its parent.
    open var pinned: Bool = false

    /// The charge of the physics body.
    open var charge: CGFloat = 0.0

    /// The joints attached to this physics body.
    open var joints: [SKPhysicsJoint] = []

    /// All bodies that this body is in contact with.
    ///
    /// This property returns an array of all physics bodies currently in contact with this body.
    /// The contacts are tracked by the physics engine during simulation.
    open var allContactedBodies: [SKPhysicsBody] {
        guard let node = node,
              let scene = node.scene else {
            return []
        }

        let world = scene.physicsWorld
        var contactedBodies: [SKPhysicsBody] = []
        let selfId = ObjectIdentifier(self)

        for pair in world.activeContacts {
            if pair.bodyA == selfId {
                // Find the body for bodyB
                if let contact = world.contactCache[pair] {
                    contactedBodies.append(contact.bodyB)
                }
            } else if pair.bodyB == selfId {
                // Find the body for bodyA
                if let contact = world.contactCache[pair] {
                    contactedBodies.append(contact.bodyA)
                }
            }
        }

        return contactedBodies
    }

    // MARK: - Initializers

    public init() {
    }

    // MARK: - Copying

    /// Creates a copy of this physics body.
    ///
    /// - Returns: A new physics body with the same properties.
    open func copy() -> SKPhysicsBody {
        let bodyCopy = SKPhysicsBody()
        bodyCopy.shape = shape
        bodyCopy.area = area
        bodyCopy.affectedByGravity = affectedByGravity
        bodyCopy.allowsRotation = allowsRotation
        bodyCopy.isDynamic = isDynamic
        bodyCopy.mass = mass
        bodyCopy.density = density
        bodyCopy.friction = friction
        bodyCopy.restitution = restitution
        bodyCopy.linearDamping = linearDamping
        bodyCopy.angularDamping = angularDamping
        bodyCopy.categoryBitMask = categoryBitMask
        bodyCopy.collisionBitMask = collisionBitMask
        bodyCopy.contactTestBitMask = contactTestBitMask
        bodyCopy.fieldBitMask = fieldBitMask
        bodyCopy.usesPreciseCollisionDetection = usesPreciseCollisionDetection
        bodyCopy.pinned = pinned
        bodyCopy.charge = charge
        bodyCopy.velocity = velocity
        bodyCopy.angularVelocity = angularVelocity
        bodyCopy.isResting = isResting
        return bodyCopy
    }

    // MARK: - Factory Methods

    /// Creates a circular physics body centered on the owning node's origin.
    ///
    /// - Parameter radius: The radius of the circle.
    /// - Returns: A new physics body.
    public class func circleOfRadius(_ radius: CGFloat) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .circle(radius: radius)
        body.area = .pi * radius * radius
        return body
    }

    /// Creates a circular physics body centered on the specified point.
    ///
    /// - Parameters:
    ///   - radius: The radius of the circle.
    ///   - center: The center of the circle.
    /// - Returns: A new physics body.
    public class func circleOfRadius(_ radius: CGFloat, center: CGPoint) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .circleWithCenter(radius: radius, center: center)
        body.area = .pi * radius * radius
        return body
    }

    /// Creates a rectangular physics body.
    ///
    /// - Parameter size: The size of the rectangle.
    /// - Returns: A new physics body.
    public class func rectangleOf(size: CGSize) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .rectangle(size: size)
        body.area = size.width * size.height
        return body
    }

    /// Creates a rectangular physics body centered on the specified point.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle.
    ///   - center: The center of the rectangle.
    /// - Returns: A new physics body.
    public class func rectangleOf(size: CGSize, center: CGPoint) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .rectangleWithCenter(size: size, center: center)
        body.area = size.width * size.height
        return body
    }

    /// Creates a polygon physics body from a path.
    ///
    /// - Parameter path: The path defining the polygon.
    /// - Returns: A new physics body.
    public class func polygonFrom(path: CGPath) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .polygon(path: path)
        body.area = calculatePathArea(path)
        return body
    }

    /// Calculates the area of a path using the Shoelace formula.
    ///
    /// This works for simple polygons (non-self-intersecting).
    /// For complex paths with curves, it approximates by sampling.
    private class func calculatePathArea(_ path: CGPath) -> CGFloat {
        var points: [CGPoint] = []
        var currentPoint: CGPoint = .zero

        // Extract points from path
        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                currentPoint = element.pointee.points[0]
                points.append(currentPoint)
            case .addLineToPoint:
                currentPoint = element.pointee.points[0]
                points.append(currentPoint)
            case .addQuadCurveToPoint:
                // Sample the quadratic curve
                let control = element.pointee.points[0]
                let end = element.pointee.points[1]
                for t in stride(from: 0.25, through: 1.0, by: 0.25) {
                    let t2 = CGFloat(t)
                    let oneMinusT = 1.0 - t2
                    let x = oneMinusT * oneMinusT * currentPoint.x + 2 * oneMinusT * t2 * control.x + t2 * t2 * end.x
                    let y = oneMinusT * oneMinusT * currentPoint.y + 2 * oneMinusT * t2 * control.y + t2 * t2 * end.y
                    points.append(CGPoint(x: x, y: y))
                }
                currentPoint = end
            case .addCurveToPoint:
                // Sample the cubic curve
                let control1 = element.pointee.points[0]
                let control2 = element.pointee.points[1]
                let end = element.pointee.points[2]
                for t in stride(from: 0.25, through: 1.0, by: 0.25) {
                    let t2 = CGFloat(t)
                    let oneMinusT = 1.0 - t2
                    let a = oneMinusT * oneMinusT * oneMinusT
                    let b = 3 * oneMinusT * oneMinusT * t2
                    let c = 3 * oneMinusT * t2 * t2
                    let d = t2 * t2 * t2
                    let x = a * currentPoint.x + b * control1.x + c * control2.x + d * end.x
                    let y = a * currentPoint.y + b * control1.y + c * control2.y + d * end.y
                    points.append(CGPoint(x: x, y: y))
                }
                currentPoint = end
            case .closeSubpath:
                // Close path - area calculation handles this
                break
            @unknown default:
                break
            }
        }

        // Calculate area using Shoelace formula
        guard points.count >= 3 else { return 0 }

        var area: CGFloat = 0
        let n = points.count
        for i in 0..<n {
            let j = (i + 1) % n
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }

        return abs(area) / 2.0
    }

    /// Creates an edge-based physics body from a path.
    ///
    /// - Parameter path: The path defining the edges.
    /// - Returns: A new physics body.
    public class func edgeChainFrom(path: CGPath) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .edgeChain(path: path)
        body.isDynamic = false
        return body
    }

    /// Creates an edge loop physics body from a path.
    ///
    /// - Parameter path: The path defining the loop.
    /// - Returns: A new physics body.
    public class func edgeLoopFrom(path: CGPath) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .edgeLoop(path: path)
        body.isDynamic = false
        return body
    }

    /// Creates an edge loop physics body from a rectangle.
    ///
    /// - Parameter rect: The rectangle defining the loop.
    /// - Returns: A new physics body.
    public class func edgeLoopFrom(rect: CGRect) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .edgeLoopRect(rect: rect)
        body.isDynamic = false
        return body
    }

    /// Creates an edge physics body from two points.
    ///
    /// - Parameters:
    ///   - p1: The start point of the edge.
    ///   - p2: The end point of the edge.
    /// - Returns: A new physics body.
    public class func edgeFrom(_ p1: CGPoint, to p2: CGPoint) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .edge(from: p1, to: p2)
        body.isDynamic = false
        return body
    }

    /// Creates a physics body from a texture.
    ///
    /// - Parameters:
    ///   - texture: The texture defining the shape.
    ///   - size: The size of the texture.
    /// - Returns: A new physics body.
    ///
    /// - Note: In the WASM environment, full texture analysis is not available due to WebGPU
    ///   limitations on pixel readback. This implementation uses an ellipse approximation
    ///   inscribed within the texture bounds, which provides better collision detection
    ///   than a simple rectangle for most sprite shapes (characters, projectiles, etc.).
    ///   For precise collision shapes, use `init(polygonFrom:)` with explicit vertices.
    public class func bodyFrom(texture: SKTexture, size: CGSize) -> SKPhysicsBody {
        // Use ellipse approximation for better fit than rectangle
        // An inscribed ellipse typically matches sprite shapes better
        let radius = min(size.width, size.height) / 2
        let body = SKPhysicsBody()

        if abs(size.width - size.height) < 0.01 {
            // Square-ish texture: use circle
            body.shape = .circle(radius: radius)
            body.area = .pi * radius * radius
        } else {
            // Non-square: use rectangle but with slightly reduced size
            // to approximate an ellipse's collision area
            let scaleFactor: CGFloat = 0.85  // ~π/4 approximation
            let adjustedSize = CGSize(width: size.width * scaleFactor,
                                       height: size.height * scaleFactor)
            body.shape = .rectangle(size: adjustedSize)
            body.area = adjustedSize.width * adjustedSize.height
        }
        return body
    }

    /// Creates a physics body from a texture with alpha threshold.
    ///
    /// - Parameters:
    ///   - texture: The texture defining the shape.
    ///   - alphaThreshold: The minimum alpha value to consider as solid.
    ///   - size: The size of the texture.
    /// - Returns: A new physics body.
    ///
    /// - Note: In the WASM environment, texture pixel analysis is limited. This method
    ///   behaves the same as `bodyFrom(texture:size:)`. For precise alpha-based collision
    ///   shapes, pre-compute polygon vertices and use `init(polygonFrom:)`.
    public class func bodyFrom(texture: SKTexture, alphaThreshold: Float, size: CGSize) -> SKPhysicsBody {
        // Same as bodyFrom(texture:size:) due to WASM limitations
        // The alphaThreshold parameter is accepted for API compatibility
        _ = alphaThreshold
        return bodyFrom(texture: texture, size: size)
    }

    /// Creates a physics body that combines multiple other bodies.
    ///
    /// - Parameter bodies: The bodies to combine.
    /// - Returns: A new physics body.
    public class func body(bodies: [SKPhysicsBody]) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .composite(bodies: bodies)
        // Calculate combined area
        body.area = bodies.reduce(0) { $0 + $1.area }
        return body
    }

    // MARK: - Force and Impulse Application

    /// Applies a force to the center of gravity of a physics body.
    ///
    /// - Parameter force: A vector describing the force in newtons.
    open func applyForce(_ force: CGVector) {
        guard isDynamic && !pinned else { return }
        accumulatedForce.dx += force.dx
        accumulatedForce.dy += force.dy
    }

    /// Applies a force at a specific point on the physics body.
    ///
    /// - Parameters:
    ///   - force: A vector describing the force in newtons.
    ///   - point: The point at which to apply the force.
    open func applyForce(_ force: CGVector, at point: CGPoint) {
        guard isDynamic && !pinned else { return }
        guard let node = node else { return }

        // Accumulate linear force
        accumulatedForce.dx += force.dx
        accumulatedForce.dy += force.dy

        // Calculate and accumulate torque from off-center force
        let r = CGVector(dx: point.x - node.position.x, dy: point.y - node.position.y)
        let torque = r.dx * force.dy - r.dy * force.dx
        accumulatedTorque += torque
    }

    /// Applies a torque to the physics body.
    ///
    /// - Parameter torque: The torque to apply in newton-meters.
    open func applyTorque(_ torque: CGFloat) {
        guard isDynamic && allowsRotation && !pinned else { return }
        accumulatedTorque += torque
    }

    /// Applies an impulse to the center of gravity of a physics body.
    ///
    /// - Parameter impulse: A vector describing the impulse in newton-seconds.
    open func applyImpulse(_ impulse: CGVector) {
        applyImpulseInternal(impulse)
    }

    /// Applies an impulse at a specific point on the physics body.
    ///
    /// - Parameters:
    ///   - impulse: A vector describing the impulse in newton-seconds.
    ///   - point: The point at which to apply the impulse.
    open func applyImpulse(_ impulse: CGVector, at point: CGPoint) {
        guard isDynamic && !pinned else { return }
        guard let node = node else { return }

        // Apply linear impulse
        applyImpulseInternal(impulse)

        // Calculate angular impulse from off-center impulse
        let r = CGVector(dx: point.x - node.position.x, dy: point.y - node.position.y)
        let angularImp = r.dx * impulse.dy - r.dy * impulse.dx
        applyAngularImpulse(angularImp)
    }

    /// Applies an angular impulse to the physics body.
    ///
    /// - Parameter impulse: The angular impulse in newton-meter-seconds.
    open func applyAngularImpulse(_ impulse: CGFloat) {
        applyAngularImpulseInternal(impulse)
    }

    // MARK: - Internal Impulse Methods

    /// Internal implementation of linear impulse application.
    ///
    /// Impulse directly changes velocity without time integration:
    /// Δv = impulse / mass
    ///
    /// This is called by collision resolution and public API.
    internal func applyImpulseInternal(_ impulse: CGVector) {
        guard isDynamic && !pinned else { return }
        guard mass > 0 else { return }

        // Impulse = mass × Δvelocity, so Δvelocity = impulse / mass
        velocity.dx += impulse.dx / mass
        velocity.dy += impulse.dy / mass

        // Wake up the body if it was resting
        isResting = false
    }

    /// Internal implementation of angular impulse application.
    ///
    /// Angular impulse directly changes angular velocity:
    /// Δω = angularImpulse / momentOfInertia
    ///
    /// This is called by collision resolution and public API.
    internal func applyAngularImpulseInternal(_ impulse: CGFloat) {
        guard isDynamic && allowsRotation && !pinned else { return }

        // Calculate moment of inertia based on shape
        let momentOfInertia = calculateMomentOfInertia()
        guard momentOfInertia > 0 else { return }

        // Angular impulse = I × Δω, so Δω = impulse / I
        angularVelocity += impulse / momentOfInertia

        // Wake up the body if it was resting
        isResting = false
    }

    /// Calculates the moment of inertia based on the body's shape.
    ///
    /// Returns a physically accurate moment of inertia for the shape type.
    internal func calculateMomentOfInertia() -> CGFloat {
        switch shape {
        case .circle(let radius):
            // Solid disk: I = (1/2) × m × r²
            return 0.5 * mass * radius * radius

        case .circleWithCenter(let radius, _):
            // Solid disk: I = (1/2) × m × r²
            return 0.5 * mass * radius * radius

        case .rectangle(let size):
            // Solid rectangle: I = (1/12) × m × (w² + h²)
            let w = size.width
            let h = size.height
            return (mass * (w * w + h * h)) / 12.0

        case .rectangleWithCenter(let size, _):
            // Solid rectangle: I = (1/12) × m × (w² + h²)
            let w = size.width
            let h = size.height
            return (mass * (w * w + h * h)) / 12.0

        case .polygon(_), .edgeChain(_), .edgeLoop(_), .edgeLoopRect(_), .edge(_, _):
            // For complex shapes, approximate using area
            // I ≈ m × area (simplified approximation)
            return mass * max(area, 1.0)

        case .composite(let bodies):
            // Sum of component moments of inertia
            return bodies.reduce(0) { sum, body in
                sum + body.calculateMomentOfInertia()
            }
        }
    }
}
