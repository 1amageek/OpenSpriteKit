//
//  SKColor.swift
//  OpenSpriteKit
//
//  Created by 1amageek on 2025/12/22.
//

import Foundation
import OpenCoreGraphics

// MARK: - SKColor

/// A color type for SpriteKit.
public struct SKColor: Sendable, Hashable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Returns the CGColor representation of this color.
    public var cgColor: CGColor {
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static let white = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = SKColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = SKColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let red = SKColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = SKColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let gray = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
}
