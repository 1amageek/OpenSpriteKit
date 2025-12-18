// SKBlendMode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// The modes that describe how the source and destination pixel colors are used to calculate the new destination color.
///
/// Blend modes determine how a node's colors are combined with the colors already in the framebuffer.
public enum SKBlendMode: Int, Sendable, Hashable {
    /// The source and destination colors are blended by multiplying the source alpha value.
    case alpha = 0

    /// The source and destination colors are added together.
    case add = 1

    /// The source color is subtracted from the destination color.
    case subtract = 2

    /// The source color is multiplied by the destination color.
    case multiply = 3

    /// The source color is multiplied by the destination color and then doubled.
    case multiplyX2 = 4

    /// The source color is added to the destination color times the inverted source color.
    case screen = 5

    /// The source color replaces the destination color.
    case replace = 6

    /// The source color is multiplied by the alpha value.
    case multiplyAlpha = 7
}
