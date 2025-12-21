// SKRange.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A definition of a range of floating-point values.
///
/// You typically use a `SKRange` to clamp a value so that it is within the specified range.
open class SKRange: @unchecked Sendable {

    // MARK: - Properties

    /// The minimum possible value.
    open var lowerLimit: CGFloat

    /// The maximum possible value.
    open var upperLimit: CGFloat

    // MARK: - Initializers

    /// Initializes a new range object.
    ///
    /// - Parameters:
    ///   - lower: The minimum value of the range. Use `-CGFloat.infinity` for no lower limit.
    ///   - upper: The maximum value of the range. Use `CGFloat.infinity` for no upper limit.
    public required init(lowerLimit lower: CGFloat, upperLimit upper: CGFloat) {
        self.lowerLimit = lower
        self.upperLimit = upper
    }

    /// Creates and initializes a new range object using a value and a maximum distance from that value.
    ///
    /// - Parameters:
    ///   - value: The center value of the range.
    ///   - variance: The maximum distance from the center value.
    public convenience init(value: CGFloat, variance: CGFloat) {
        self.init(lowerLimit: value - variance, upperLimit: value + variance)
    }

    /// Creates and initializes a new range object that encompasses all possible values.
    ///
    /// - Returns: A range with no limits.
    public class func withNoLimits() -> Self {
        return self.init(lowerLimit: -.infinity, upperLimit: .infinity)
    }

    /// Creates and initializes a new range object that specifies only a minimum value.
    ///
    /// - Parameter lower: The minimum value of the range.
    public convenience init(lowerLimit lower: CGFloat) {
        self.init(lowerLimit: lower, upperLimit: .infinity)
    }

    /// Creates and initializes a new range object that specifies only a maximum value.
    ///
    /// - Parameter upper: The maximum value of the range.
    public convenience init(upperLimit upper: CGFloat) {
        self.init(lowerLimit: -.infinity, upperLimit: upper)
    }

    /// Creates and initializes a new range object that specifies a constant value.
    ///
    /// - Parameter value: The constant value of the range (both lower and upper limits are the same).
    public convenience init(constantValue value: CGFloat) {
        self.init(lowerLimit: value, upperLimit: value)
    }

    // MARK: - Copying

    /// Creates a copy of this range.
    ///
    /// - Returns: A new range with the same limits.
    open func copy() -> SKRange {
        return SKRange(lowerLimit: lowerLimit, upperLimit: upperLimit)
    }
}
