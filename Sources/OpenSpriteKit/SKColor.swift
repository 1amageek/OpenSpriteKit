//
//  SKColor.swift
//  OpenSpriteKit
//
//  Created by 1amageek on 2025/12/22.
//

import Foundation

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

    /// Creates a color object using the specified opacity and grayscale values.
    ///
    /// - Parameters:
    ///   - white: The grayscale value of the color object, specified as a value from 0.0 to 1.0.
    ///   - alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0.
    public init(white: CGFloat, alpha: CGFloat) {
        self.red = white
        self.green = white
        self.blue = white
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
    /// A color object with RGB values of 1.0, 1.0, and 0.0, and an alpha value of 1.0.
    public static let yellow = SKColor(red: 1, green: 1, blue: 0, alpha: 1)
    /// A color object with RGB values of 0.0, 1.0, and 1.0, and an alpha value of 1.0.
    public static let cyan = SKColor(red: 0, green: 1, blue: 1, alpha: 1)
    /// A color object with RGB values of 1.0, 0.0, and 1.0, and an alpha value of 1.0.
    public static let magenta = SKColor(red: 1, green: 0, blue: 1, alpha: 1)
    /// A color object with RGB values of 1.0, 0.5, and 0.0, and an alpha value of 1.0.
    public static let orange = SKColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    /// A color object with RGB values of 0.5, 0.0, and 0.5, and an alpha value of 1.0.
    public static let purple = SKColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    /// A color object with RGB values of 0.6, 0.4, and 0.2, and an alpha value of 1.0.
    public static let brown = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
    /// A color object with a grayscale value of 1/3 and an alpha value of 1.0.
    public static let darkGray = SKColor(red: 1.0/3.0, green: 1.0/3.0, blue: 1.0/3.0, alpha: 1)
    /// A color object with a grayscale value of 2/3 and an alpha value of 1.0.
    public static let lightGray = SKColor(red: 2.0/3.0, green: 2.0/3.0, blue: 2.0/3.0, alpha: 1)
}
