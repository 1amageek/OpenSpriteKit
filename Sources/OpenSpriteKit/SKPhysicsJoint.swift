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

    /// The reaction force of the joint.
    open var reactionForce: CGVector { .zero }

    /// The reaction torque of the joint.
    open var reactionTorque: CGFloat { 0.0 }

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        // Base class encoding
    }
}

// MARK: - SKPhysicsJointPin

/// A joint that pins two bodies together at a single point, allowing them to rotate around that point.
///
/// A pin joint allows the two bodies to rotate independently around the anchor point.
open class SKPhysicsJointPin: SKPhysicsJoint {

    // MARK: - Properties

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
        return joint
    }
}

// MARK: - SKPhysicsJointSpring

/// A joint that simulates a spring connecting two physics bodies.
///
/// A spring joint simulates a spring that connects two physics bodies.
open class SKPhysicsJointSpring: SKPhysicsJoint {

    // MARK: - Properties

    /// The damping of the spring.
    open var damping: CGFloat = 0.0

    /// The frequency of the spring oscillation.
    open var frequency: CGFloat = 0.0

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
        return joint
    }
}

// MARK: - SKPhysicsJointFixed

/// A joint that fuses two physics bodies together at a reference point.
///
/// A fixed joint connects two physics bodies so that they cannot move relative to each other.
open class SKPhysicsJointFixed: SKPhysicsJoint {

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
        return joint
    }
}

// MARK: - SKPhysicsJointSliding

/// A joint that allows two physics bodies to slide along an axis.
///
/// A sliding joint allows two physics bodies to slide along a common axis.
open class SKPhysicsJointSliding: SKPhysicsJoint {

    // MARK: - Properties

    /// Whether limits should be enabled.
    open var shouldEnableLimits: Bool = false

    /// The lower distance limit.
    open var lowerDistanceLimit: CGFloat = 0.0

    /// The upper distance limit.
    open var upperDistanceLimit: CGFloat = 0.0

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
        return joint
    }
}

// MARK: - SKPhysicsJointLimit

/// A joint that limits the distance between two physics bodies.
///
/// A limit joint connects two physics bodies with a maximum allowed distance.
open class SKPhysicsJointLimit: SKPhysicsJoint {

    // MARK: - Properties

    /// The maximum distance between the two bodies.
    open var maxLength: CGFloat = 0.0

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
        return joint
    }
}
