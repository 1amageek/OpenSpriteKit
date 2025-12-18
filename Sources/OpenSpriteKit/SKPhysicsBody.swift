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
open class SKPhysicsBody: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

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

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        // Decode shape
        let shapeType = coder.decodeInteger(forKey: "shapeType")
        area = CGFloat(coder.decodeDouble(forKey: "area"))

        switch shapeType {
        case 0: // circle
            let radius = CGFloat(coder.decodeDouble(forKey: "radius"))
            shape = .circle(radius: radius)
        case 1: // circleWithCenter
            let radius = CGFloat(coder.decodeDouble(forKey: "radius"))
            let centerX = CGFloat(coder.decodeDouble(forKey: "centerX"))
            let centerY = CGFloat(coder.decodeDouble(forKey: "centerY"))
            shape = .circleWithCenter(radius: radius, center: CGPoint(x: centerX, y: centerY))
        case 2: // rectangle
            let width = CGFloat(coder.decodeDouble(forKey: "sizeWidth"))
            let height = CGFloat(coder.decodeDouble(forKey: "sizeHeight"))
            shape = .rectangle(size: CGSize(width: width, height: height))
        case 3: // rectangleWithCenter
            let width = CGFloat(coder.decodeDouble(forKey: "sizeWidth"))
            let height = CGFloat(coder.decodeDouble(forKey: "sizeHeight"))
            let centerX = CGFloat(coder.decodeDouble(forKey: "centerX"))
            let centerY = CGFloat(coder.decodeDouble(forKey: "centerY"))
            shape = .rectangleWithCenter(size: CGSize(width: width, height: height),
                                          center: CGPoint(x: centerX, y: centerY))
        case 4: // edgeLoopRect
            let x = CGFloat(coder.decodeDouble(forKey: "rectX"))
            let y = CGFloat(coder.decodeDouble(forKey: "rectY"))
            let width = CGFloat(coder.decodeDouble(forKey: "rectWidth"))
            let height = CGFloat(coder.decodeDouble(forKey: "rectHeight"))
            shape = .edgeLoopRect(rect: CGRect(x: x, y: y, width: width, height: height))
        case 5: // edge
            let fromX = CGFloat(coder.decodeDouble(forKey: "fromX"))
            let fromY = CGFloat(coder.decodeDouble(forKey: "fromY"))
            let toX = CGFloat(coder.decodeDouble(forKey: "toX"))
            let toY = CGFloat(coder.decodeDouble(forKey: "toY"))
            shape = .edge(from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
        default:
            shape = .rectangle(size: .zero)
        }

        affectedByGravity = coder.decodeBool(forKey: "affectedByGravity")
        allowsRotation = coder.decodeBool(forKey: "allowsRotation")
        isDynamic = coder.decodeBool(forKey: "isDynamic")
        mass = CGFloat(coder.decodeDouble(forKey: "mass"))
        density = CGFloat(coder.decodeDouble(forKey: "density"))
        friction = CGFloat(coder.decodeDouble(forKey: "friction"))
        restitution = CGFloat(coder.decodeDouble(forKey: "restitution"))
        linearDamping = CGFloat(coder.decodeDouble(forKey: "linearDamping"))
        angularDamping = CGFloat(coder.decodeDouble(forKey: "angularDamping"))
        categoryBitMask = UInt32(coder.decodeInt32(forKey: "categoryBitMask"))
        collisionBitMask = UInt32(coder.decodeInt32(forKey: "collisionBitMask"))
        contactTestBitMask = UInt32(coder.decodeInt32(forKey: "contactTestBitMask"))
        fieldBitMask = UInt32(coder.decodeInt32(forKey: "fieldBitMask"))
        usesPreciseCollisionDetection = coder.decodeBool(forKey: "usesPreciseCollisionDetection")
        pinned = coder.decodeBool(forKey: "pinned")
        charge = CGFloat(coder.decodeDouble(forKey: "charge"))
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        // Encode shape
        coder.encode(Double(area), forKey: "area")
        switch shape {
        case .circle(let radius):
            coder.encode(0, forKey: "shapeType")
            coder.encode(Double(radius), forKey: "radius")
        case .circleWithCenter(let radius, let center):
            coder.encode(1, forKey: "shapeType")
            coder.encode(Double(radius), forKey: "radius")
            coder.encode(Double(center.x), forKey: "centerX")
            coder.encode(Double(center.y), forKey: "centerY")
        case .rectangle(let size):
            coder.encode(2, forKey: "shapeType")
            coder.encode(Double(size.width), forKey: "sizeWidth")
            coder.encode(Double(size.height), forKey: "sizeHeight")
        case .rectangleWithCenter(let size, let center):
            coder.encode(3, forKey: "shapeType")
            coder.encode(Double(size.width), forKey: "sizeWidth")
            coder.encode(Double(size.height), forKey: "sizeHeight")
            coder.encode(Double(center.x), forKey: "centerX")
            coder.encode(Double(center.y), forKey: "centerY")
        case .edgeLoopRect(let rect):
            coder.encode(4, forKey: "shapeType")
            coder.encode(Double(rect.origin.x), forKey: "rectX")
            coder.encode(Double(rect.origin.y), forKey: "rectY")
            coder.encode(Double(rect.width), forKey: "rectWidth")
            coder.encode(Double(rect.height), forKey: "rectHeight")
        case .edge(let from, let to):
            coder.encode(5, forKey: "shapeType")
            coder.encode(Double(from.x), forKey: "fromX")
            coder.encode(Double(from.y), forKey: "fromY")
            coder.encode(Double(to.x), forKey: "toX")
            coder.encode(Double(to.y), forKey: "toY")
        default:
            coder.encode(-1, forKey: "shapeType")
        }

        coder.encode(affectedByGravity, forKey: "affectedByGravity")
        coder.encode(allowsRotation, forKey: "allowsRotation")
        coder.encode(isDynamic, forKey: "isDynamic")
        coder.encode(Double(mass), forKey: "mass")
        coder.encode(Double(density), forKey: "density")
        coder.encode(Double(friction), forKey: "friction")
        coder.encode(Double(restitution), forKey: "restitution")
        coder.encode(Double(linearDamping), forKey: "linearDamping")
        coder.encode(Double(angularDamping), forKey: "angularDamping")
        coder.encode(Int32(categoryBitMask), forKey: "categoryBitMask")
        coder.encode(Int32(collisionBitMask), forKey: "collisionBitMask")
        coder.encode(Int32(contactTestBitMask), forKey: "contactTestBitMask")
        coder.encode(Int32(fieldBitMask), forKey: "fieldBitMask")
        coder.encode(usesPreciseCollisionDetection, forKey: "usesPreciseCollisionDetection")
        coder.encode(pinned, forKey: "pinned")
        coder.encode(Double(charge), forKey: "charge")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKPhysicsBody()
        copy.shape = shape
        copy.area = area
        copy.affectedByGravity = affectedByGravity
        copy.allowsRotation = allowsRotation
        copy.isDynamic = isDynamic
        copy.mass = mass
        copy.density = density
        copy.friction = friction
        copy.restitution = restitution
        copy.linearDamping = linearDamping
        copy.angularDamping = angularDamping
        copy.categoryBitMask = categoryBitMask
        copy.collisionBitMask = collisionBitMask
        copy.contactTestBitMask = contactTestBitMask
        copy.fieldBitMask = fieldBitMask
        copy.usesPreciseCollisionDetection = usesPreciseCollisionDetection
        copy.pinned = pinned
        copy.charge = charge
        return copy
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
        // TODO: Calculate area from path
        return body
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
    public class func bodyFrom(texture: SKTexture, size: CGSize) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .rectangle(size: size)
        body.area = size.width * size.height
        return body
    }

    /// Creates a physics body from a texture with alpha threshold.
    ///
    /// - Parameters:
    ///   - texture: The texture defining the shape.
    ///   - alphaThreshold: The minimum alpha value to consider.
    ///   - size: The size of the texture.
    /// - Returns: A new physics body.
    public class func bodyFrom(texture: SKTexture, alphaThreshold: Float, size: CGSize) -> SKPhysicsBody {
        let body = SKPhysicsBody()
        body.shape = .rectangle(size: size)
        body.area = size.width * size.height
        return body
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
}
