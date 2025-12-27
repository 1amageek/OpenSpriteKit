// SKReachConstraints.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A specification of the degree of freedom when solving inverse kinematics.
///
/// `SKReachConstraints` objects work with reach actions to control the rotation
/// limits when performing inverse kinematics calculations. These constraints
/// limit how much a joint can rotate when solving an IK chain.
///
/// ## Example
/// ```swift
/// // Create constraints that limit rotation to ±45 degrees
/// let constraints = SKReachConstraints(
///     lowerAngleLimit: -CGFloat.pi / 4,
///     upperAngleLimit: CGFloat.pi / 4
/// )
/// node.reachConstraints = constraints
/// ```
open class SKReachConstraints: @unchecked Sendable {

    // MARK: - Properties

    /// The lower limit of the rotation angle, in radians.
    ///
    /// This value defines the minimum rotation the joint can achieve during
    /// inverse kinematics solving. Negative values represent clockwise rotation.
    open var lowerAngleLimit: CGFloat

    /// The upper limit of the rotation angle, in radians.
    ///
    /// This value defines the maximum rotation the joint can achieve during
    /// inverse kinematics solving. Positive values represent counter-clockwise rotation.
    open var upperAngleLimit: CGFloat

    // MARK: - Initializers

    /// Creates reach constraints with the specified angle limits.
    ///
    /// - Parameters:
    ///   - lowerAngleLimit: The minimum rotation angle in radians.
    ///   - upperAngleLimit: The maximum rotation angle in radians.
    public init(lowerAngleLimit: CGFloat, upperAngleLimit: CGFloat) {
        self.lowerAngleLimit = lowerAngleLimit
        self.upperAngleLimit = upperAngleLimit
    }

    /// Creates reach constraints with no limits.
    public init() {
        self.lowerAngleLimit = -CGFloat.pi
        self.upperAngleLimit = CGFloat.pi
    }

    // MARK: - Copying

    /// Creates a copy of this reach constraints object.
    ///
    /// - Returns: A new reach constraints object with the same properties.
    open func copy() -> SKReachConstraints {
        return SKReachConstraints(lowerAngleLimit: lowerAngleLimit, upperAngleLimit: upperAngleLimit)
    }
}
