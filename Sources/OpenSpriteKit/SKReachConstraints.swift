// SKReachConstraints.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A specification of the degree of freedom when solving inverse kinematics.
///
/// `SKReachConstraints` objects work with reach actions to control the rotation
/// limits when performing inverse kinematics calculations.
open class SKReachConstraints: NSObject, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        // TODO: Implement encoding
    }
}
