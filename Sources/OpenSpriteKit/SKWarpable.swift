// SKWarpable.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A protocol for nodes that can be distorted by warping.
///
/// Conforming nodes can have their geometry distorted using `SKWarpGeometry` objects.
public protocol SKWarpable {
    /// The warp geometry applied to this node.
    var warpGeometry: SKWarpGeometry? { get set }

    /// The subdivisions used when rendering warped geometry.
    var subdivisionLevels: Int { get set }
}
