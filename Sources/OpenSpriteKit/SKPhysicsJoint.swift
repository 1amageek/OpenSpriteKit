// SKPhysicsJoint.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// The abstract base class for objects that connect physics bodies.
///
/// An `SKPhysicsJoint` object connects two physics bodies so that they are simulated together
/// by the physics world. You never create instances of `SKPhysicsJoint` directly; instead,
/// you create one of the subclasses.
open class SKPhysicsJoint: @unchecked Sendable {

    // MARK: - Properties

    /// The first physics body connected by the joint.
    open var bodyA: SKPhysicsBody

    /// The second physics body connected by the joint.
    open var bodyB: SKPhysicsBody

    /// The reaction force of the joint (computed during simulation).
    internal var _reactionForce: CGVector = .zero

    /// The reaction torque of the joint (computed during simulation).
    internal var _reactionTorque: CGFloat = 0.0

    /// The reaction force of the joint.
    open var reactionForce: CGVector { _reactionForce }

    /// The reaction torque of the joint.
    open var reactionTorque: CGFloat { _reactionTorque }

    // MARK: - Initializers

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody) {
        self.bodyA = bodyA
        self.bodyB = bodyB
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
open class SKPhysicsJointPin: SKPhysicsJoint, @unchecked Sendable {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint

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

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) {
        self.anchor = anchor
        super.init(bodyA: bodyA, bodyB: bodyB)
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
        return SKPhysicsJointPin(bodyA: bodyA, bodyB: bodyB, anchor: anchor)
    }
}

// MARK: - SKPhysicsJointSpring

/// A joint that simulates a spring connecting two physics bodies.
///
/// A spring joint simulates a spring that connects two physics bodies.
open class SKPhysicsJointSpring: SKPhysicsJoint, @unchecked Sendable {

    // MARK: - Properties

    /// The anchor point on the first body in scene coordinates.
    internal var anchorA: CGPoint

    /// The anchor point on the second body in scene coordinates.
    internal var anchorB: CGPoint

    /// The rest length of the spring (calculated from initial anchor positions).
    internal var restLength: CGFloat

    /// The damping of the spring.
    open var damping: CGFloat = 0.0

    /// The frequency of the spring oscillation.
    open var frequency: CGFloat = 0.0

    // MARK: - Initializers

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchorA: CGPoint, anchorB: CGPoint) {
        self.anchorA = anchorA
        self.anchorB = anchorB
        let dx = anchorB.x - anchorA.x
        let dy = anchorB.y - anchorA.y
        self.restLength = sqrt(dx * dx + dy * dy)
        super.init(bodyA: bodyA, bodyB: bodyB)
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
        return SKPhysicsJointSpring(bodyA: bodyA, bodyB: bodyB, anchorA: anchorA, anchorB: anchorB)
    }
}

// MARK: - SKPhysicsJointFixed

/// A joint that fuses two physics bodies together at a reference point.
///
/// A fixed joint connects two physics bodies so that they cannot move relative to each other.
open class SKPhysicsJointFixed: SKPhysicsJoint, @unchecked Sendable {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint

    /// The relative offset from bodyA to bodyB (stored at creation time).
    internal var relativeOffset: CGVector

    /// The relative rotation difference (stored at creation time).
    internal var relativeRotation: CGFloat

    // MARK: - Initializers

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint) {
        self.anchor = anchor
        if let nodeA = bodyA.node, let nodeB = bodyB.node {
            self.relativeOffset = CGVector(
                dx: nodeB.position.x - nodeA.position.x,
                dy: nodeB.position.y - nodeA.position.y
            )
            self.relativeRotation = nodeB.zRotation - nodeA.zRotation
        } else {
            self.relativeOffset = .zero
            self.relativeRotation = 0.0
        }
        super.init(bodyA: bodyA, bodyB: bodyB)
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
        return SKPhysicsJointFixed(bodyA: bodyA, bodyB: bodyB, anchor: anchor)
    }
}

// MARK: - SKPhysicsJointSliding

/// A joint that allows two physics bodies to slide along an axis.
///
/// A sliding joint allows two physics bodies to slide along a common axis.
open class SKPhysicsJointSliding: SKPhysicsJoint, @unchecked Sendable {

    // MARK: - Properties

    /// The anchor point of the joint in scene coordinates.
    internal var anchor: CGPoint

    /// The axis along which the bodies can slide (normalized).
    internal var axis: CGVector

    /// Whether limits should be enabled.
    open var shouldEnableLimits: Bool = false

    /// The lower distance limit.
    open var lowerDistanceLimit: CGFloat = 0.0

    /// The upper distance limit.
    open var upperDistanceLimit: CGFloat = 0.0

    // MARK: - Initializers

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchor: CGPoint, axis: CGVector) {
        self.anchor = anchor
        let length = sqrt(axis.dx * axis.dx + axis.dy * axis.dy)
        if length > 0.0001 {
            self.axis = CGVector(dx: axis.dx / length, dy: axis.dy / length)
        } else {
            self.axis = CGVector(dx: 1, dy: 0)
        }
        super.init(bodyA: bodyA, bodyB: bodyB)
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
        return SKPhysicsJointSliding(bodyA: bodyA, bodyB: bodyB, anchor: anchor, axis: axis)
    }
}

// MARK: - SKPhysicsJointLimit

/// A joint that limits the distance between two physics bodies.
///
/// A limit joint connects two physics bodies with a maximum allowed distance.
open class SKPhysicsJointLimit: SKPhysicsJoint, @unchecked Sendable {

    // MARK: - Properties

    /// The anchor point on the first body in scene coordinates.
    internal var anchorA: CGPoint

    /// The anchor point on the second body in scene coordinates.
    internal var anchorB: CGPoint

    /// The maximum distance between the two bodies.
    open var maxLength: CGFloat

    // MARK: - Initializers

    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, anchorA: CGPoint, anchorB: CGPoint) {
        self.anchorA = anchorA
        self.anchorB = anchorB
        let dx = anchorB.x - anchorA.x
        let dy = anchorB.y - anchorA.y
        self.maxLength = sqrt(dx * dx + dy * dy)
        super.init(bodyA: bodyA, bodyB: bodyB)
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
        return SKPhysicsJointLimit(bodyA: bodyA, bodyB: bodyB, anchorA: anchorA, anchorB: anchorB)
    }
}
