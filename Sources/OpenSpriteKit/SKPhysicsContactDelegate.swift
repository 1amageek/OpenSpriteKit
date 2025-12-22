// SKPhysicsContactDelegate.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics

/// Methods your app can implement to respond when physics bodies come into contact.
///
/// The `SKPhysicsContactDelegate` protocol allows your app to respond when two physics
/// bodies begin or end contact with each other.
public protocol SKPhysicsContactDelegate: AnyObject {

    /// Called when two physics bodies begin contact.
    ///
    /// - Parameter contact: An object describing the contact between the two bodies.
    func didBegin(_ contact: SKPhysicsContact)

    /// Called when two physics bodies end contact.
    ///
    /// - Parameter contact: An object describing the contact between the two bodies.
    func didEnd(_ contact: SKPhysicsContact)
}

// MARK: - Default Implementations

public extension SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {}
    func didEnd(_ contact: SKPhysicsContact) {}
}

// MARK: - SKPhysicsContact

/// A description of the contact between two physics bodies.
///
/// An `SKPhysicsContact` object describes the contact between two physics bodies.
/// The contact object is passed to the contact delegate's methods.
open class SKPhysicsContact: @unchecked Sendable {

    // MARK: - Properties

    /// The first physics body in the contact.
    open private(set) var bodyA: SKPhysicsBody

    /// The second physics body in the contact.
    open private(set) var bodyB: SKPhysicsBody

    /// The point at which the two bodies are in contact.
    open private(set) var contactPoint: CGPoint

    /// The normal vector between the two bodies at the point of contact.
    open private(set) var contactNormal: CGVector

    /// The collision impulse applied at the contact point.
    open private(set) var collisionImpulse: CGFloat

    // MARK: - Initializers

    /// Creates a physics contact with the specified bodies and contact information.
    ///
    /// - Parameters:
    ///   - bodyA: The first physics body.
    ///   - bodyB: The second physics body.
    ///   - contactPoint: The point of contact.
    ///   - contactNormal: The normal vector at the contact point.
    ///   - collisionImpulse: The collision impulse.
    internal init(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, contactPoint: CGPoint, contactNormal: CGVector, collisionImpulse: CGFloat) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.contactPoint = contactPoint
        self.contactNormal = contactNormal
        self.collisionImpulse = collisionImpulse
    }
}
