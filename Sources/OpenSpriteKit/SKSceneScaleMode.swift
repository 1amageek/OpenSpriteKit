// SKSceneScaleMode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// The modes that determine how the scene's area is mapped to the view that presents it.
///
/// Scale modes determine how a scene is sized to fit its view when the two have different sizes.
public enum SKSceneScaleMode: Int, Sendable, Hashable {
    /// Each axis of the scene is scaled independently so that each axis in the scene exactly maps to the length of that axis in the view.
    case fill = 0

    /// The scaling factor of each dimension is calculated and the larger of the two is chosen.
    /// Each axis of the scene is scaled by the same scaling factor.
    /// This guarantees that the entire area of the view is filled but may cause parts of the scene to be cropped.
    case aspectFill = 1

    /// The scaling factor of each dimension is calculated and the smaller of the two is chosen.
    /// Each axis of the scene is scaled by the same scaling factor.
    /// This guarantees that the entire scene is visible but may require letterboxing in the view.
    case aspectFit = 2

    /// The scene is not scaled to match the view.
    /// Instead, the scene is automatically resized so that its dimensions always match those of the view.
    case resizeFill = 3
}
