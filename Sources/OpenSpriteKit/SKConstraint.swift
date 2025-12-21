// SKConstraint.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A specification for constraining a node's position or rotation.
///
/// An `SKConstraint` object describes a mathematical constraint on a node's position
/// or orientation. Constraints are evaluated each time a new frame is processed for a scene,
/// after any actions have been processed but before the physics simulation is processed.
open class SKConstraint: @unchecked Sendable {

    // MARK: - Properties

    /// A Boolean value that specifies whether the constraint is applied.
    open var enabled: Bool = true

    /// The node whose coordinate system should be used to apply the constraint.
    open weak var referenceNode: SKNode?

    // MARK: - Weak Node Wrapper

    /// A wrapper class to hold a weak reference to an SKNode.
    /// Used in enum cases where weak references cannot be directly stored.
    internal class WeakNode {
        weak var node: SKNode?

        init(_ node: SKNode) {
            self.node = node
        }
    }

    // MARK: - Internal Constraint Type

    internal enum ConstraintType {
        case positionX(SKRange)
        case positionY(SKRange)
        case positionXY(xRange: SKRange, yRange: SKRange)
        case zRotation(SKRange)
        case orientToNode(WeakNode, offset: SKRange)
        case orientToPoint(CGPoint, offset: SKRange)
        case orientToPointInNode(CGPoint, WeakNode, offset: SKRange)
        case distanceToNode(SKRange, WeakNode)
        case distanceToPoint(SKRange, CGPoint)
        case distanceToPointInNode(SKRange, CGPoint, WeakNode)
    }

    internal var constraintType: ConstraintType?

    // MARK: - Initializers

    public init() {
    }

    // MARK: - Copying

    /// Creates a copy of this constraint.
    ///
    /// - Returns: A new constraint with the same properties.
    open func copy() -> SKConstraint {
        let constraintCopy = SKConstraint()
        constraintCopy.enabled = enabled
        constraintCopy.referenceNode = referenceNode
        constraintCopy.constraintType = constraintType
        return constraintCopy
    }

    // MARK: - Position Constraints

    /// Creates a constraint that restricts both coordinates of a node's position.
    ///
    /// - Parameters:
    ///   - xRange: The range of allowed x values.
    ///   - yRange: The range of allowed y values.
    /// - Returns: A new position constraint.
    public class func positionX(_ xRange: SKRange, y yRange: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .positionXY(xRange: xRange, yRange: yRange)
        return constraint
    }

    /// Creates a constraint that restricts the x-coordinate of a node's position.
    ///
    /// - Parameter range: The range of allowed x values.
    /// - Returns: A new position constraint.
    public class func positionX(_ range: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .positionX(range)
        return constraint
    }

    /// Creates a constraint that restricts the y-coordinate of a node's position.
    ///
    /// - Parameter range: The range of allowed y values.
    /// - Returns: A new position constraint.
    public class func positionY(_ range: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .positionY(range)
        return constraint
    }

    // MARK: - Orientation Constraints

    /// Creates a constraint that forces a node to rotate to face another node.
    ///
    /// - Parameters:
    ///   - node: The target node to face. This is stored as a weak reference.
    ///   - offset: The range of allowed rotation offsets from directly facing the target.
    /// - Returns: A new orientation constraint.
    ///
    /// - Note: The target node is held weakly. If the node is deallocated, the constraint
    ///   will have no effect until a new target is set.
    public class func orient(to node: SKNode, offset: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .orientToNode(WeakNode(node), offset: offset)
        return constraint
    }

    /// Creates a constraint that forces a node to rotate to face a fixed point.
    ///
    /// - Parameters:
    ///   - point: The target point to face.
    ///   - offset: The range of allowed rotation offsets from directly facing the target.
    /// - Returns: A new orientation constraint.
    public class func orient(to point: CGPoint, offset: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .orientToPoint(point, offset: offset)
        return constraint
    }

    /// Creates a constraint that forces a node to rotate to face a point in another node's coordinate system.
    ///
    /// - Parameters:
    ///   - point: The target point to face.
    ///   - node: The node whose coordinate system contains the point. Stored as weak reference.
    ///   - offset: The range of allowed rotation offsets from directly facing the target.
    /// - Returns: A new orientation constraint.
    public class func orient(to point: CGPoint, in node: SKNode, offset: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .orientToPointInNode(point, WeakNode(node), offset: offset)
        return constraint
    }

    /// Creates a constraint that limits the orientation of a node.
    ///
    /// - Parameter range: The range of allowed rotation values in radians.
    /// - Returns: A new rotation constraint.
    public class func zRotation(_ range: SKRange) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .zRotation(range)
        return constraint
    }

    // MARK: - Distance Constraints

    /// Creates a constraint that keeps a node within a certain distance of another node.
    ///
    /// - Parameters:
    ///   - range: The range of allowed distances.
    ///   - node: The target node. Stored as weak reference.
    /// - Returns: A new distance constraint.
    public class func distance(_ range: SKRange, to node: SKNode) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .distanceToNode(range, WeakNode(node))
        return constraint
    }

    /// Creates a constraint that keeps a node within a certain distance of a point.
    ///
    /// - Parameters:
    ///   - range: The range of allowed distances.
    ///   - point: The target point.
    /// - Returns: A new distance constraint.
    public class func distance(_ range: SKRange, to point: CGPoint) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .distanceToPoint(range, point)
        return constraint
    }

    /// Creates a constraint that keeps a node within a certain distance of a point in another node's coordinate system.
    ///
    /// - Parameters:
    ///   - range: The range of allowed distances.
    ///   - point: The target point.
    ///   - node: The node whose coordinate system contains the point. Stored as weak reference.
    /// - Returns: A new distance constraint.
    public class func distance(_ range: SKRange, to point: CGPoint, in node: SKNode) -> SKConstraint {
        let constraint = SKConstraint()
        constraint.constraintType = .distanceToPointInNode(range, point, WeakNode(node))
        return constraint
    }
}
