// SKCropNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A node that masks pixels drawn by its children so that only some pixels are seen.
///
/// An `SKCropNode` object uses a mask to crop pixels from its children.
/// The crop node's children are rendered into a framebuffer, then the mask is rendered into the framebuffer.
/// When the mask is rendered, SpriteKit uses a special blending mode that only keeps pixels where the mask
/// was drawn over them.
open class SKCropNode: SKNode {

    // MARK: - Properties

    /// The mask node used to crop the node's children.
    ///
    /// Only the portion of the children that lies inside the mask is rendered.
    /// The mask node can be any type of node. You can use a sprite node with a texture,
    /// a shape node, or any other node that produces visible content.
    open var maskNode: SKNode?

    // MARK: - Initializers

    /// Creates a new crop node.
    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        maskNode = coder.decodeObject(forKey: "maskNode") as? SKNode
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(maskNode, forKey: "maskNode")
    }
}
