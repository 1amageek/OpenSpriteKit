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
open class SKRegion: @unchecked Sendable {

    // MARK: - Properties

    /// Returns a Core Graphics path that defines the region.
    open internal(set) var path: CGPath?

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
    public init() {
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
    }

    /// Initializes a new region using a Core Graphics path.
    ///
    /// - Parameter path: A Core Graphics path that defines the region.
    public init(path: CGPath) {
        self.path = path
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
    ///
    /// - Note: This implementation uses a composite region approach since CGPath doesn't
    ///   have native boolean operations. The resulting region correctly tests containment
    ///   but the path property may not represent the exact geometric difference.
    open func byDifference(from region: SKRegion) -> SKRegion {
        let newRegion = CompositeRegion(
            type: .difference,
            regionA: self,
            regionB: region
        )
        // Keep the original path for rendering purposes
        newRegion.path = self.path
        return newRegion
    }

    /// Returns a new region created by intersecting the contents of this region with another region.
    ///
    /// - Parameter region: The region to intersect with.
    /// - Returns: A new region containing only points that are in both regions.
    ///
    /// - Note: This implementation uses a composite region approach. The resulting region
    ///   correctly tests containment but the path property may not represent the exact
    ///   geometric intersection.
    open func byIntersection(with region: SKRegion) -> SKRegion {
        let newRegion = CompositeRegion(
            type: .intersection,
            regionA: self,
            regionB: region
        )

        // Approximate the intersection path by using the smaller bounding box
        if let path1 = self.path, let path2 = region.path {
            let bounds1 = path1.boundingBox
            let bounds2 = path2.boundingBox
            let intersection = bounds1.intersection(bounds2)

            if !intersection.isEmpty {
                let mutablePath = CGMutablePath()
                mutablePath.addRect(intersection)
                newRegion.path = mutablePath
            }
        }

        return newRegion
    }

    /// Returns a new region created by combining the contents of this region with another region.
    ///
    /// - Parameter region: The region to combine with.
    /// - Returns: A new region containing all points that are in either region.
    open func byUnion(with region: SKRegion) -> SKRegion {
        let newRegion = CompositeRegion(
            type: .union,
            regionA: self,
            regionB: region
        )

        // Combine paths for rendering
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

    // MARK: - Copying

    /// Creates a copy of this region.
    ///
    /// - Returns: A new region with the same properties.
    open func copy() -> SKRegion {
        let regionCopy = SKRegion()
        regionCopy.path = self.path
        regionCopy.isInfinite = self.isInfinite
        regionCopy.isInverted = self.isInverted
        regionCopy.radius = self.radius
        regionCopy.rectSize = self.rectSize
        return regionCopy
    }

    // MARK: - Path Serialization Helpers

    /// Serializes a CGPath to an array of dictionaries representing path elements.
    private func serializePath(_ path: CGPath) -> [[String: Any]] {
        var elements: [[String: Any]] = []

        path.applyWithBlock { element in
            var dict: [String: Any] = [:]
            let type = element.pointee.type

            switch type {
            case .moveToPoint:
                guard let pts = element.pointee.points else { return }
                dict["type"] = "move"
                dict["x"] = Double(pts[0].x)
                dict["y"] = Double(pts[0].y)

            case .addLineToPoint:
                guard let pts = element.pointee.points else { return }
                dict["type"] = "line"
                dict["x"] = Double(pts[0].x)
                dict["y"] = Double(pts[0].y)

            case .addQuadCurveToPoint:
                guard let pts = element.pointee.points else { return }
                dict["type"] = "quad"
                dict["cpx"] = Double(pts[0].x)
                dict["cpy"] = Double(pts[0].y)
                dict["x"] = Double(pts[1].x)
                dict["y"] = Double(pts[1].y)

            case .addCurveToPoint:
                guard let pts = element.pointee.points else { return }
                dict["type"] = "curve"
                dict["cp1x"] = Double(pts[0].x)
                dict["cp1y"] = Double(pts[0].y)
                dict["cp2x"] = Double(pts[1].x)
                dict["cp2y"] = Double(pts[1].y)
                dict["x"] = Double(pts[2].x)
                dict["y"] = Double(pts[2].y)

            case .closeSubpath:
                dict["type"] = "close"

            @unknown default:
                dict["type"] = "unknown"
            }

            if !dict.isEmpty && dict["type"] as? String != "unknown" {
                elements.append(dict)
            }
        }

        return elements
    }

    /// Deserializes an array of dictionaries to a CGPath.
    private static func deserializePath(from elements: [[String: Any]]) -> CGPath? {
        let mutablePath = CGMutablePath()

        for element in elements {
            guard let type = element["type"] as? String else { continue }

            switch type {
            case "move":
                if let x = element["x"] as? Double, let y = element["y"] as? Double {
                    mutablePath.move(to: CGPoint(x: x, y: y))
                }

            case "line":
                if let x = element["x"] as? Double, let y = element["y"] as? Double {
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                }

            case "quad":
                if let cpx = element["cpx"] as? Double, let cpy = element["cpy"] as? Double,
                   let x = element["x"] as? Double, let y = element["y"] as? Double {
                    mutablePath.addQuadCurve(to: CGPoint(x: x, y: y),
                                             control: CGPoint(x: cpx, y: cpy))
                }

            case "curve":
                if let cp1x = element["cp1x"] as? Double, let cp1y = element["cp1y"] as? Double,
                   let cp2x = element["cp2x"] as? Double, let cp2y = element["cp2y"] as? Double,
                   let x = element["x"] as? Double, let y = element["y"] as? Double {
                    mutablePath.addCurve(to: CGPoint(x: x, y: y),
                                         control1: CGPoint(x: cp1x, y: cp1y),
                                         control2: CGPoint(x: cp2x, y: cp2y))
                }

            case "close":
                mutablePath.closeSubpath()

            default:
                break
            }
        }

        return mutablePath.isEmpty ? nil : mutablePath
    }
}

// MARK: - Composite Region (for CSG Operations)

/// A region that represents the result of a boolean operation between two regions.
///
/// This class handles containment testing for union, intersection, and difference operations.
internal final class CompositeRegion: SKRegion, @unchecked Sendable {

    enum CompositeType {
        case union
        case intersection
        case difference
    }

    private let type: CompositeType
    private let regionA: SKRegion
    private let regionB: SKRegion

    init(type: CompositeType, regionA: SKRegion, regionB: SKRegion) {
        self.type = type
        self.regionA = regionA
        self.regionB = regionB
        super.init()
    }

    override func contains(_ point: CGPoint) -> Bool {
        let inA = regionA.contains(point)
        let inB = regionB.contains(point)

        switch type {
        case .union:
            return inA || inB
        case .intersection:
            return inA && inB
        case .difference:
            return inA && !inB
        }
    }

    override func inverse() -> SKRegion {
        // De Morgan's laws for set operations:
        // ¬(A ∪ B) = ¬A ∩ ¬B
        // ¬(A ∩ B) = ¬A ∪ ¬B
        // ¬(A - B) = ¬A ∪ B
        switch type {
        case .union:
            return CompositeRegion(
                type: .intersection,
                regionA: regionA.inverse(),
                regionB: regionB.inverse()
            )
        case .intersection:
            return CompositeRegion(
                type: .union,
                regionA: regionA.inverse(),
                regionB: regionB.inverse()
            )
        case .difference:
            return CompositeRegion(
                type: .union,
                regionA: regionA.inverse(),
                regionB: regionB
            )
        }
    }

    override func copy() -> SKRegion {
        let regionCopy = CompositeRegion(
            type: type,
            regionA: regionA.copy(),
            regionB: regionB.copy()
        )
        regionCopy.path = self.path
        return regionCopy
    }
}
