// SKPhysicsJoint.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// The abstract base class for objects that connect physics bodies.
///
/// An `SKPhysicsJoint` object connects two physics bodies so that they are simulated together
/// by the physics world. You never create instances of `SKPhysicsJoint` directly; instead,
/// you create one of the subclasses.
open class SKPhysicsJoint: NSObject, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Properties

    /// The first physics body connected by the joint.
    open weak var bodyA: SKPhysicsBody?

    /// The second physics body connected by the joint.
    open weak var bodyB: SKPhysicsBody?

    /// The reaction force of the joint (computed during simulation).
    internal var _reactionForce: CGVector = .zero

    /// The reaction torque of the joint (computed during simulation).
    internal var _reactionTorque: CGFloat = 0.0

    /// The reaction force of the joint.
    open var reactionForce: CGVector { _reactionForce }

    /// The reaction torque of the joint.
    open var reactionTorque: CGFloat { _reactionTorque }

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        // Base class encoding - bodies are not encoded (weak references)
    }

    // MARK: - Internal

    /// Resets reaction force and torque (called before simulation).
    internal func resetReaction() {
        _reactionForce = .zero
        _reactionTorque = 0.0
    }
}

// MARK: - SKPhysicsJointPin

/// A joint that pins two bodies together at a single point, allowing them to rotate around that point.
///
/// A pin joint allows the two bodies to rotate independently around the anchor point.
open class SKPhysicsJointPin: SKPhysicsJoint {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint = .zero

    /// The rotation speed of the joint.
    open var rotationSpeed: CGFloat = 0.0

    /// Whether the rotation speed should be maintained.
    open var shouldEnableLimits: Bool = false

    /// The lower angle limit of the joint.
    open var lowerAngleLimit: CGFloat = 0.0

    /// The upper angle limit of the joint.
    open var upperAngleLimit: CGFloat = 0.0

    /// The resistance to friction of the joint.
    open var frictionTorque: CGFloat = 0.0

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        anchor = coder.decodeCGPoint(forKey: "anchor")
        rotationSpeed = CGFloat(coder.decodeDouble(forKey: "rotationSpeed"))
        shouldEnableLimits = coder.decodeBool(forKey: "shouldEnableLimits")
        lowerAngleLimit = CGFloat(coder.decodeDouble(forKey: "lowerAngleLimit"))
        upperAngleLimit = CGFloat(coder.decodeDouble(forKey: "upperAngleLimit"))
        frictionTorque = CGFloat(coder.decodeDouble(forKey: "frictionTorque"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(anchor, forKey: "anchor")
        coder.encode(Double(rotationSpeed), forKey: "rotationSpeed")
        coder.encode(shouldEnableLimits, forKey: "shouldEnableLimits")
        coder.encode(Double(lowerAngleLimit), forKey: "lowerAngleLimit")
        coder.encode(Double(upperAngleLimit), forKey: "upperAngleLimit")
        coder.encode(Double(frictionTorque), forKey: "frictionTorque")
    }

    // MARK: - Factory Methods

    /// Creates a pin joint connecting two physics bodies at the specified point.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - anchor: The anchor point in scene coordinates.
    /// - Returns: A new pin joint.
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) -> SKPhysicsJointPin {
        let joint = SKPhysicsJointPin()
        joint.bodyA = bodyA
        joint.bodyB = bodyB
        joint.anchor = anchor
        return joint
    }
}

// MARK: - SKPhysicsJointSpring

/// A joint that simulates a spring connecting two physics bodies.
///
/// A spring joint simulates a spring that connects two physics bodies.
open class SKPhysicsJointSpring: SKPhysicsJoint {

    // MARK: - Properties

    /// The anchor point on the first body in scene coordinates.
    internal var anchorA: CGPoint = .zero

    /// The anchor point on the second body in scene coordinates.
    internal var anchorB: CGPoint = .zero

    /// The rest length of the spring (calculated from initial anchor positions).
    internal var restLength: CGFloat = 0.0

    /// The damping of the spring.
    open var damping: CGFloat = 0.0

    /// The frequency of the spring oscillation.
    open var frequency: CGFloat = 0.0

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        anchorA = coder.decodeCGPoint(forKey: "anchorA")
        anchorB = coder.decodeCGPoint(forKey: "anchorB")
        restLength = CGFloat(coder.decodeDouble(forKey: "restLength"))
        damping = CGFloat(coder.decodeDouble(forKey: "damping"))
        frequency = CGFloat(coder.decodeDouble(forKey: "frequency"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(anchorA, forKey: "anchorA")
        coder.encode(anchorB, forKey: "anchorB")
        coder.encode(Double(restLength), forKey: "restLength")
        coder.encode(Double(damping), forKey: "damping")
        coder.encode(Double(frequency), forKey: "frequency")
    }

    // MARK: - Factory Methods

    /// Creates a spring joint connecting two physics bodies.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - anchorA: The anchor point on the first body in scene coordinates.
    ///   - anchorB: The anchor point on the second body in scene coordinates.
    /// - Returns: A new spring joint.
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchorA: CGPoint, anchorB: CGPoint) -> SKPhysicsJointSpring {
        let joint = SKPhysicsJointSpring()
        joint.bodyA = bodyA
        joint.bodyB = bodyB
        joint.anchorA = anchorA
        joint.anchorB = anchorB
        // Calculate rest length from initial positions
        let dx = anchorB.x - anchorA.x
        let dy = anchorB.y - anchorA.y
        joint.restLength = sqrt(dx * dx + dy * dy)
        return joint
    }
}

// MARK: - SKPhysicsJointFixed

/// A joint that fuses two physics bodies together at a reference point.
///
/// A fixed joint connects two physics bodies so that they cannot move relative to each other.
open class SKPhysicsJointFixed: SKPhysicsJoint {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint = .zero

    /// The relative offset from bodyA to bodyB (stored at creation time).
    internal var relativeOffset: CGVector = .zero

    /// The relative rotation difference (stored at creation time).
    internal var relativeRotation: CGFloat = 0.0

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        anchor = coder.decodeCGPoint(forKey: "anchor")
        relativeOffset = coder.decodeCGVector(forKey: "relativeOffset")
        relativeRotation = CGFloat(coder.decodeDouble(forKey: "relativeRotation"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(anchor, forKey: "anchor")
        coder.encode(relativeOffset, forKey: "relativeOffset")
        coder.encode(Double(relativeRotation), forKey: "relativeRotation")
    }

    // MARK: - Factory Methods

    /// Creates a fixed joint connecting two physics bodies.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - anchor: The anchor point in scene coordinates.
    /// - Returns: A new fixed joint.
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) -> SKPhysicsJointFixed {
        let joint = SKPhysicsJointFixed()
        joint.bodyA = bodyA
        joint.bodyB = bodyB
        joint.anchor = anchor

        // Store the relative offset and rotation at creation time
        if let nodeA = bodyA.node, let nodeB = bodyB.node {
            joint.relativeOffset = CGVector(
                dx: nodeB.position.x - nodeA.position.x,
                dy: nodeB.position.y - nodeA.position.y
            )
            joint.relativeRotation = nodeB.zRotation - nodeA.zRotation
        }

        return joint
    }
}

// MARK: - SKPhysicsJointSliding

/// A joint that allows two physics bodies to slide along an axis.
///
/// A sliding joint allows two physics bodies to slide along a common axis.
open class SKPhysicsJointSliding: SKPhysicsJoint {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint = .zero

    /// The axis along which the bodies can slide (normalized).
    internal var axis: CGVector = CGVector(dx: 1, dy: 0)

    /// Whether limits should be enabled.
    open var shouldEnableLimits: Bool = false

    /// The lower distance limit.
    open var lowerDistanceLimit: CGFloat = 0.0

    /// The upper distance limit.
    open var upperDistanceLimit: CGFloat = 0.0

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        anchor = coder.decodeCGPoint(forKey: "anchor")
        axis = coder.decodeCGVector(forKey: "axis")
        shouldEnableLimits = coder.decodeBool(forKey: "shouldEnableLimits")
        lowerDistanceLimit = CGFloat(coder.decodeDouble(forKey: "lowerDistanceLimit"))
        upperDistanceLimit = CGFloat(coder.decodeDouble(forKey: "upperDistanceLimit"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(anchor, forKey: "anchor")
        coder.encode(axis, forKey: "axis")
        coder.encode(shouldEnableLimits, forKey: "shouldEnableLimits")
        coder.encode(Double(lowerDistanceLimit), forKey: "lowerDistanceLimit")
        coder.encode(Double(upperDistanceLimit), forKey: "upperDistanceLimit")
    }

    // MARK: - Factory Methods

    /// Creates a sliding joint connecting two physics bodies.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - anchor: The anchor point in scene coordinates.
    ///   - axis: The axis along which the bodies can slide.
    /// - Returns: A new sliding joint.
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint, axis: CGVector) -> SKPhysicsJointSliding {
        let joint = SKPhysicsJointSliding()
        joint.bodyA = bodyA
        joint.bodyB = bodyB
        joint.anchor = anchor
        // Normalize the axis
        let length = sqrt(axis.dx * axis.dx + axis.dy * axis.dy)
        if length > 0.0001 {
            joint.axis = CGVector(dx: axis.dx / length, dy: axis.dy / length)
        }
        return joint
    }
}

// MARK: - SKPhysicsJointLimit

/// A joint that limits the distance between two physics bodies.
///
/// A limit joint connects two physics bodies with a maximum allowed distance.
open class SKPhysicsJointLimit: SKPhysicsJoint {

    // MARK: - Properties

    /// The anchor point on the first body in scene coordinates.
    internal var anchorA: CGPoint = .zero

    /// The anchor point on the second body in scene coordinates.
    internal var anchorB: CGPoint = .zero

    /// The maximum distance between the two bodies.
    open var maxLength: CGFloat = 0.0

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        anchorA = coder.decodeCGPoint(forKey: "anchorA")
        anchorB = coder.decodeCGPoint(forKey: "anchorB")
        maxLength = CGFloat(coder.decodeDouble(forKey: "maxLength"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(anchorA, forKey: "anchorA")
        coder.encode(anchorB, forKey: "anchorB")
        coder.encode(Double(maxLength), forKey: "maxLength")
    }

    // MARK: - Factory Methods

    /// Creates a limit joint connecting two physics bodies.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - anchorA: The anchor point on the first body in scene coordinates.
    ///   - anchorB: The anchor point on the second body in scene coordinates.
    /// - Returns: A new limit joint.
    public class func joint(withBodyA bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchorA: CGPoint, anchorB: CGPoint) -> SKPhysicsJointLimit {
        let joint = SKPhysicsJointLimit()
        joint.bodyA = bodyA
        joint.bodyB = bodyB
        joint.anchorA = anchorA
        joint.anchorB = anchorB
        // Calculate initial length as maxLength
        let dx = anchorB.x - anchorA.x
        let dy = anchorB.y - anchorA.y
        joint.maxLength = sqrt(dx * dx + dy * dy)
        return joint
    }
}
