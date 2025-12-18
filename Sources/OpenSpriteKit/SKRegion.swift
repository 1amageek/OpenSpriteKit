// SKRegion.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// The definition of an arbitrary area.
///
/// An `SKRegion` object defines a mathematical shape and is typically used to determine whether
/// a particular point lies inside this area. For example, regions are used to define the area
/// that a physics field can affect. Regions are defined using paths and mathematical shapes
/// and can also be combined using constructive solid geometry.
open class SKRegion: NSObject, NSCopying, NSSecureCoding {

    // MARK: - Properties

    /// Returns a Core Graphics path that defines the region.
    open private(set) var path: CGPath?

    /// Whether this is an infinite region.
    private var isInfinite: Bool = false

    /// Whether this region is inverted.
    private var isInverted: Bool = false

    /// The radius for circular regions.
    private var radius: Float?

    /// The size for rectangular regions.
    private var rectSize: CGSize?

    // MARK: - Initializers

    /// Creates a new empty region.
    public override init() {
        super.init()
    }

    /// Returns a region that defines a region that includes all points.
    ///
    /// - Returns: An infinite region.
    public class func infinite() -> SKRegion {
        let region = SKRegion()
        region.isInfinite = true
        return region
    }

    /// Initializes a new region with a rectangular area.
    ///
    /// - Parameter size: The size of the rectangle, centered on the origin.
    public init(size: CGSize) {
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        let mutablePath = CGMutablePath()
        mutablePath.addRect(rect)
        self.path = mutablePath
        self.rectSize = size
        super.init()
    }

    /// Initializes a new region with a circular area.
    ///
    /// - Parameter radius: The radius of the circle, centered on the origin.
    public init(radius: Float) {
        let r = CGFloat(radius)
        let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
        let mutablePath = CGMutablePath()
        mutablePath.addEllipse(in: rect)
        self.path = mutablePath
        self.radius = radius
        super.init()
    }

    /// Initializes a new region using a Core Graphics path.
    ///
    /// - Parameter path: A Core Graphics path that defines the region.
    public init(path: CGPath) {
        self.path = path
        super.init()
    }

    // MARK: - Constructive Solid Geometry

    /// Returns a new region that is the mathematical inverse of an existing region.
    ///
    /// - Returns: A new region containing all points not in this region.
    open func inverse() -> SKRegion {
        let newRegion = SKRegion()
        newRegion.path = self.path
        newRegion.isInfinite = self.isInfinite
        newRegion.isInverted = !self.isInverted
        newRegion.radius = self.radius
        newRegion.rectSize = self.rectSize
        return newRegion
    }

    /// Returns a new region created by subtracting the contents of another region from this region.
    ///
    /// - Parameter region: The region to subtract.
    /// - Returns: A new region containing all points in this region that are not in the other region.
    open func byDifference(from region: SKRegion) -> SKRegion {
        // Difference = A AND (NOT B)
        let newRegion = SKRegion()
        // TODO: Implement proper path difference using CGPath operations
        newRegion.path = self.path
        return newRegion
    }

    /// Returns a new region created by intersecting the contents of this region with another region.
    ///
    /// - Parameter region: The region to intersect with.
    /// - Returns: A new region containing only points that are in both regions.
    open func byIntersection(with region: SKRegion) -> SKRegion {
        let newRegion = SKRegion()
        // TODO: Implement proper path intersection using CGPath operations
        newRegion.path = self.path
        return newRegion
    }

    /// Returns a new region created by combining the contents of this region with another region.
    ///
    /// - Parameter region: The region to combine with.
    /// - Returns: A new region containing all points that are in either region.
    open func byUnion(with region: SKRegion) -> SKRegion {
        let newRegion = SKRegion()
        // TODO: Implement proper path union using CGPath operations
        if let path1 = self.path, let path2 = region.path {
            let mutablePath = CGMutablePath()
            mutablePath.addPath(path1)
            mutablePath.addPath(path2)
            newRegion.path = mutablePath
        } else {
            newRegion.path = self.path ?? region.path
        }
        return newRegion
    }

    // MARK: - Containment Testing

    /// Returns a Boolean value that indicates whether a particular point is contained in the region.
    ///
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point is inside the region; otherwise, `false`.
    open func contains(_ point: CGPoint) -> Bool {
        // Handle infinite region
        if isInfinite {
            return !isInverted
        }

        // Handle path-based region
        if let path = path {
            let contains = path.contains(point)
            return isInverted ? !contains : contains
        }

        return isInverted
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKRegion()
        copy.path = self.path
        copy.isInfinite = self.isInfinite
        copy.isInverted = self.isInverted
        copy.radius = self.radius
        copy.rectSize = self.rectSize
        return copy
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        isInfinite = coder.decodeBool(forKey: "isInfinite")
        isInverted = coder.decodeBool(forKey: "isInverted")

        if coder.containsValue(forKey: "radius") {
            radius = coder.decodeFloat(forKey: "radius")
        }

        if coder.containsValue(forKey: "rectSize.width") {
            rectSize = CGSize(
                width: CGFloat(coder.decodeDouble(forKey: "rectSize.width")),
                height: CGFloat(coder.decodeDouble(forKey: "rectSize.height"))
            )
        }

        // Note: CGPath is not directly codable, so we reconstruct from properties
        super.init()

        // Reconstruct path from stored parameters
        if let r = radius {
            let cgRadius = CGFloat(r)
            let rect = CGRect(x: -cgRadius, y: -cgRadius, width: cgRadius * 2, height: cgRadius * 2)
            let mutablePath = CGMutablePath()
            mutablePath.addEllipse(in: rect)
            self.path = mutablePath
        } else if let size = rectSize {
            let rect = CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            )
            let mutablePath = CGMutablePath()
            mutablePath.addRect(rect)
            self.path = mutablePath
        }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(isInfinite, forKey: "isInfinite")
        coder.encode(isInverted, forKey: "isInverted")

        if let r = radius {
            coder.encode(r, forKey: "radius")
        }

        if let size = rectSize {
            coder.encode(Double(size.width), forKey: "rectSize.width")
            coder.encode(Double(size.height), forKey: "rectSize.height")
        }
    }
}
