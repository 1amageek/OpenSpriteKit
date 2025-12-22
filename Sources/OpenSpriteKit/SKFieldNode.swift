// SKFieldNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics
#if canImport(simd)
import simd
#endif

/// The definition for a custom block that processes a single physics body's interaction with the field.
///
/// - Parameters:
///   - position: The position of the physics body, in scene coordinates.
///   - velocity: The current velocity of the physics body.
///   - mass: The mass of the physics body.
///   - charge: The electrical charge of the physics body.
///   - deltaTime: The elapsed time since the last simulation step.
/// - Returns: A force vector to apply to the physics body.
public typealias SKFieldForceEvaluator = (
    _ position: vector_float3,
    _ velocity: vector_float3,
    _ mass: Float,
    _ charge: Float,
    _ deltaTime: TimeInterval
) -> vector_float3

/// A node that applies physics effects to nearby nodes.
///
/// There are many different kinds of field nodes that can be created, each with different effects.
/// Instantiate the appropriate kind of field node and then add it to the scene's node tree.
open class SKFieldNode: SKNode, @unchecked Sendable {

    // MARK: - Field Type

    /// The type of field this node represents.
    internal enum FieldType {
        case drag
        case electric
        case linearGravity(direction: vector_float3)
        case magnetic
        case noise(smoothness: CGFloat, animationSpeed: CGFloat)
        case radialGravity
        case spring
        case turbulence(smoothness: CGFloat, animationSpeed: CGFloat)
        case velocityWithTexture(texture: SKTexture)
        case velocityWithVector(direction: vector_float3)
        case vortex
        case custom(evaluator: SKFieldForceEvaluator)
    }

    internal var fieldType: FieldType = .radialGravity

    // MARK: - Activation Properties

    /// A Boolean value that indicates whether the field is active.
    ///
    /// When set to `false`, the field node has no effect on the scene. The default value is `true`.
    open var isEnabled: Bool = true

    /// A Boolean value that indicates whether the field node should override all other field nodes
    /// that might otherwise affect physics bodies.
    ///
    /// When set to `true`, any physics body inside this field's region is only affected by this
    /// field. Other fields are ignored. The default value is `false`.
    open var isExclusive: Bool = false

    /// The area (relative to the node's origin) that the field affects.
    ///
    /// The default value is an infinite region.
    open var region: SKRegion?

    /// The minimum value for distance-based effects.
    ///
    /// When calculating distance-based effects, if the distance is less than this value,
    /// this minimum value is used instead. The default value is very small (0.01).
    open var minimumRadius: Float = 0.01

    /// A mask that defines which categories this field belongs to.
    ///
    /// When SpriteKit processes physics fields, it performs a logical AND between this property's
    /// value and the `fieldBitMask` of physics bodies. If the result is a nonzero value, the body
    /// is affected by this field. The default value is `0xFFFFFFFF` (all bits set).
    open var categoryBitMask: UInt32 = 0xFFFFFFFF

    // MARK: - Strength Properties

    /// The strength of the field.
    ///
    /// The strength determines how powerful the field's effect is. Higher values create
    /// stronger effects. The default value is 1.0.
    open var strength: Float = 1.0

    /// The exponent that defines the rate of decay for the strength of the field as the distance
    /// increases between the node and the physics body being affected.
    ///
    /// A value of 0 means no falloff (constant strength). A value of 1 means linear falloff.
    /// Higher values create faster falloff. The default value is 0 (no falloff).
    open var falloff: Float = 0.0

    // MARK: - Field-Specific Properties

    /// The rate at which a noise or turbulence field node changes.
    ///
    /// This property is only used by noise and turbulence fields. The default value is 0.
    open var animationSpeed: Float = 0.0

    /// The smoothness of the noise used to generate the forces.
    ///
    /// This property is only used by noise and turbulence fields. The default value is 0.
    open var smoothness: Float = 0.0

    /// The direction of a velocity field node.
    ///
    /// This property is only used by linear gravity and velocity fields.
    open var direction: vector_float3 = vector_float3(0, -1, 0)

    /// A normal texture that specifies the velocities at different points in a velocity field node.
    ///
    /// This property is only used by texture-based velocity fields.
    open var texture: SKTexture?

    // MARK: - Custom Field Evaluator

    /// The custom force evaluator block.
    private var customEvaluator: SKFieldForceEvaluator?

    // MARK: - Initializers

    /// Creates a new field node.
    public override init() {
        self.region = SKRegion.infinite()
        super.init()
    }

    // MARK: - Factory Methods

    /// Creates a field node that applies a force that resists the motion of physics bodies.
    ///
    /// - Returns: A new drag field node.
    public class func dragField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .drag
        return field
    }

    /// Creates a field node that applies an electrical force proportional to the electrical
    /// charge of physics bodies.
    ///
    /// - Returns: A new electric field node.
    public class func electricField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .electric
        return field
    }

    /// Creates a field node that accelerates physics bodies in a specific direction.
    ///
    /// - Parameter direction: The direction of the gravity force.
    /// - Returns: A new linear gravity field node.
    public class func linearGravityField(withVector direction: vector_float3) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .linearGravity(direction: direction)
        field.direction = direction
        return field
    }

    /// Creates a field node that applies a magnetic force based on the velocity and electrical
    /// charge of the physics bodies.
    ///
    /// - Returns: A new magnetic field node.
    public class func magneticField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .magnetic
        return field
    }

    /// Creates a field node that applies a randomized acceleration to physics bodies.
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the noise.
    ///   - animationSpeed: The speed at which the noise changes.
    /// - Returns: A new noise field node.
    public class func noiseField(withSmoothness smoothness: CGFloat, animationSpeed speed: CGFloat) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .noise(smoothness: smoothness, animationSpeed: speed)
        field.smoothness = Float(smoothness)
        field.animationSpeed = Float(speed)
        return field
    }

    /// Creates a field node that accelerates physics bodies toward the field node.
    ///
    /// - Returns: A new radial gravity field node.
    public class func radialGravityField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .radialGravity
        return field
    }

    /// Creates a field node that applies a spring-like force that pulls physics bodies
    /// toward the field node.
    ///
    /// - Returns: A new spring field node.
    public class func springField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .spring
        return field
    }

    /// Creates a field node that applies a randomized acceleration to physics bodies.
    ///
    /// Turbulence is similar to noise but varies based on the velocity of the physics body.
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the turbulence.
    ///   - animationSpeed: The speed at which the turbulence changes.
    /// - Returns: A new turbulence field node.
    public class func turbulenceField(withSmoothness smoothness: CGFloat, animationSpeed speed: CGFloat) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .turbulence(smoothness: smoothness, animationSpeed: speed)
        field.smoothness = Float(smoothness)
        field.animationSpeed = Float(speed)
        return field
    }

    /// Creates a field node that sets the velocity of physics bodies that enter the node's area
    /// based on the pixel values of a texture.
    ///
    /// - Parameter texture: A texture that specifies velocities.
    /// - Returns: A new velocity field node.
    public class func velocityField(with texture: SKTexture) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .velocityWithTexture(texture: texture)
        field.texture = texture
        return field
    }

    /// Creates a field node that gives physics bodies a constant velocity.
    ///
    /// - Parameter direction: The velocity to apply to physics bodies.
    /// - Returns: A new velocity field node.
    public class func velocityField(withVector direction: vector_float3) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .velocityWithVector(direction: direction)
        field.direction = direction
        return field
    }

    /// Creates a field node that applies a perpendicular force to physics bodies.
    ///
    /// - Returns: A new vortex field node.
    public class func vortexField() -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .vortex
        return field
    }

    /// Creates a field node that calculates and applies a custom force to the physics body.
    ///
    /// - Parameter evaluationBlock: A block that calculates the force to apply.
    /// - Returns: A new custom field node.
    public class func customField(evaluationBlock: @escaping SKFieldForceEvaluator) -> SKFieldNode {
        let field = SKFieldNode()
        field.fieldType = .custom(evaluator: evaluationBlock)
        field.customEvaluator = evaluationBlock
        return field
    }
}
