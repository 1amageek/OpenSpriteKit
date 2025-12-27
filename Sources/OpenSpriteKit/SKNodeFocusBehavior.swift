// SKNodeFocusBehavior.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// Constants that define the focus behavior for a node.
///
/// These values describe how a node should respond to focus navigation
/// in the SpriteKit scene.
public enum SKNodeFocusBehavior: Int, Sendable, Hashable {
    /// The node's focus behavior is determined by its properties.
    ///
    /// When this value is set, the system determines whether the node can
    /// receive focus based on its `isUserInteractionEnabled` property.
    /// This is the default for a node.
    case none = 0

    /// The node is not focusable and prevents nodes that it visually
    /// obscures from becoming focusable.
    case occluding = 1

    /// The node is focusable and prevents nodes that it visually
    /// obscures from becoming focusable.
    case focusable = 2
}
