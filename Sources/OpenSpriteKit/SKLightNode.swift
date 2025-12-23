// SKLightNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A node that lights surrounding nodes.
///
/// To use lighting, add a light node to the scene. Because lights are nodes, they can be moved
/// or perform actions just like other nodes. However, light nodes are invisible except through
/// their effects on sprite nodes configured to interact with them.
///
/// An `SKLightNode` object and an `SKSpriteNode` object add lighting to the scene if all of the following are true:
/// 1. The light node and the sprite node are both in the scene.
/// 2. The light node's `isEnabled` property is `true`.
/// 3. The light node's `categoryBitMask` property and one of the sprite's lighting masks are
///    logically combined using an AND operation, and the result is a nonzero number.
open class SKLightNode: SKNode, @unchecked Sendable {

    // MARK: - Activation Properties

    /// A Boolean value that indicates whether the node is casting light.
    ///
    /// When set to `false`, the light node has no effect on the scene. The default value is `true`.
    open var isEnabled: Bool = true

    /// A mask that defines which categories this light belongs to.
    ///
    /// When SpriteKit processes lighting, it performs a logical AND between this property's
    /// value and the lighting masks of sprite nodes in the scene. If the result is a nonzero
    /// value, the sprite is affected by this light. The default value is `0xFFFFFFFF` (all bits set).
    open var categoryBitMask: UInt32 = 0xFFFFFFFF

    // MARK: - Lighting Properties

    /// The ambient color of the light.
    ///
    /// The ambient light uniformly lights all objects in the scene. All surfaces facing any
    /// direction are lit by the same amount. The default value is black (no ambient light).
    open var ambientColor: SKColor = .black

    /// The diffuse and specular color of the light source.
    ///
    /// The light color determines how the light affects surfaces that face it. The default
    /// value is white.
    open var lightColor: SKColor = .white

    /// The color of any shadow cast by a sprite.
    ///
    /// When a sprite with a `shadowCastBitMask` matching this light's `categoryBitMask`
    /// blocks the light, a shadow is cast. The shadow color is blended with the scene
    /// content beneath the shadow. The default value is black with 50% alpha.
    open var shadowColor: SKColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.5)

    /// The exponent for the rate of decay of the light source.
    ///
    /// The falloff determines how quickly the light dims as distance from the light
    /// increases. A value of 0 means no falloff (constant intensity). A value of 1 means
    /// linear falloff. Higher values create faster falloff. The default value is 1.
    open var falloff: CGFloat = 1.0

    // MARK: - Initializers

    /// Creates a new light node.
    public override init() {
        super.init()
    }
}
