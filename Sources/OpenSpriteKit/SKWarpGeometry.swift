// SKWarpGeometry.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(simd)
import simd
#endif

/// The base class for objects that define warp transformations.
///
/// `SKWarpGeometry` is the abstract base class for warp transformation definitions.
/// Use the `SKWarpGeometryGrid` subclass to create grid-based warping effects.
open class SKWarpGeometry: @unchecked Sendable, Equatable, Hashable {

    // MARK: - Initializers

    public init() {
    }

    // MARK: - Copying

    /// Creates a copy of this warp geometry.
    ///
    /// - Returns: A new warp geometry with the same properties.
    open func copy() -> SKWarpGeometry {
        return SKWarpGeometry()
    }

    // MARK: - Equatable & Hashable

    public static func == (lhs: SKWarpGeometry, rhs: SKWarpGeometry) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    public func hash(into hasher: inout Hasher) {
        computeHash(into: &hasher)
    }

    /// Override in subclasses to provide equality comparison.
    open func isEqual(to other: SKWarpGeometry) -> Bool {
        return type(of: self) == type(of: other) && type(of: self) == SKWarpGeometry.self
    }

    /// Override in subclasses to provide hash computation.
    open func computeHash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: self)))
    }
}

// MARK: - SKWarpGeometryGrid

/// A warp geometry based on a grid of source and destination positions.
///
/// An `SKWarpGeometryGrid` object defines a warp transformation using a grid of control points.
/// Each control point has a source position and a destination position. During rendering,
/// the source positions are mapped to the destination positions, creating a warping effect.
open class SKWarpGeometryGrid: SKWarpGeometry, @unchecked Sendable {

    // MARK: - Properties

    /// The number of horizontal divisions in the grid.
    open private(set) var numberOfColumns: Int

    /// The number of vertical divisions in the grid.
    open private(set) var numberOfRows: Int

    /// The source positions of the control points.
    ///
    /// These positions are in unit coordinate space (0.0 to 1.0) and define where
    /// each control point originates from in the texture.
    open private(set) var sourcePositions: [SIMD2<Float>]

    /// The destination positions of the control points.
    ///
    /// These positions are in unit coordinate space (0.0 to 1.0) and define where
    /// each control point should be rendered.
    open private(set) var destinationPositions: [SIMD2<Float>]

    // MARK: - Computed Properties

    /// The total number of vertices in the grid.
    public var vertexCount: Int {
        return (numberOfColumns + 1) * (numberOfRows + 1)
    }

    // MARK: - Initializers

    /// Creates a warp geometry grid of a specified size with identity transformation.
    ///
    /// - Parameters:
    ///   - columns: The number of horizontal divisions.
    ///   - rows: The number of vertical divisions.
    public convenience init(columns: Int, rows: Int) {
        let positions = SKWarpGeometryGrid.generateUnitPositions(columns: columns, rows: rows)
        self.init(columns: columns, rows: rows, sourcePositions: positions, destinationPositions: positions)
    }

    /// Creates a warp geometry grid with the specified parameters.
    ///
    /// - Parameters:
    ///   - columns: The number of horizontal divisions.
    ///   - rows: The number of vertical divisions.
    ///   - sourcePositions: An array of source positions in unit coordinate space.
    ///   - destinationPositions: An array of destination positions in unit coordinate space.
    public init(columns: Int, rows: Int, sourcePositions: [SIMD2<Float>], destinationPositions: [SIMD2<Float>]) {
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.sourcePositions = sourcePositions
        self.destinationPositions = destinationPositions
        super.init()
    }

    /// Creates a warp geometry grid using raw float arrays.
    ///
    /// - Parameters:
    ///   - columns: The number of horizontal divisions.
    ///   - rows: The number of vertical divisions.
    ///   - sourcePositions: A pointer to an array of source positions (x, y pairs).
    ///   - destinationPositions: A pointer to an array of destination positions (x, y pairs).
    public convenience init(columns: Int, rows: Int, sourcePositions: UnsafePointer<vector_float2>, destinationPositions: UnsafePointer<vector_float2>) {
        let vertexCount = (columns + 1) * (rows + 1)
        var sources: [SIMD2<Float>] = []
        var destinations: [SIMD2<Float>] = []

        for i in 0..<vertexCount {
            sources.append(sourcePositions[i])
            destinations.append(destinationPositions[i])
        }

        self.init(columns: columns, rows: rows, sourcePositions: sources, destinationPositions: destinations)
    }

    // MARK: - Copying

    /// Creates a copy of this warp geometry grid.
    ///
    /// - Returns: A new warp geometry grid with the same properties.
    open override func copy() -> SKWarpGeometry {
        return SKWarpGeometryGrid(
            columns: numberOfColumns,
            rows: numberOfRows,
            sourcePositions: sourcePositions,
            destinationPositions: destinationPositions
        )
    }

    // MARK: - Equatable & Hashable

    open override func isEqual(to other: SKWarpGeometry) -> Bool {
        guard let otherGrid = other as? SKWarpGeometryGrid else { return false }
        return numberOfColumns == otherGrid.numberOfColumns &&
               numberOfRows == otherGrid.numberOfRows &&
               sourcePositions == otherGrid.sourcePositions &&
               destinationPositions == otherGrid.destinationPositions
    }

    open override func computeHash(into hasher: inout Hasher) {
        hasher.combine(numberOfColumns)
        hasher.combine(numberOfRows)
        for pos in sourcePositions {
            hasher.combine(pos.x)
            hasher.combine(pos.y)
        }
        for pos in destinationPositions {
            hasher.combine(pos.x)
            hasher.combine(pos.y)
        }
    }

    // MARK: - Factory Methods

    /// Creates a grid with unit mapping (no distortion).
    ///
    /// - Parameters:
    ///   - columns: The number of horizontal divisions.
    ///   - rows: The number of vertical divisions.
    /// - Returns: A new warp geometry grid with identity transformation.
    public class func grid(withColumns columns: Int, rows: Int) -> SKWarpGeometryGrid {
        let positions = Self.generateUnitPositions(columns: columns, rows: rows)
        return SKWarpGeometryGrid(
            columns: columns,
            rows: rows,
            sourcePositions: positions,
            destinationPositions: positions
        )
    }

    // MARK: - Position Manipulation

    /// Returns a new grid by replacing the source positions.
    ///
    /// - Parameter sourcePositions: The new source positions.
    /// - Returns: A new warp geometry grid with the updated source positions.
    open func replacingBySourcePositions(positions sourcePositions: [SIMD2<Float>]) -> SKWarpGeometryGrid {
        return SKWarpGeometryGrid(
            columns: numberOfColumns,
            rows: numberOfRows,
            sourcePositions: sourcePositions,
            destinationPositions: destinationPositions
        )
    }

    /// Returns a new grid by replacing the destination positions.
    ///
    /// - Parameter destinationPositions: The new destination positions.
    /// - Returns: A new warp geometry grid with the updated destination positions.
    open func replacingByDestinationPositions(positions destinationPositions: [SIMD2<Float>]) -> SKWarpGeometryGrid {
        return SKWarpGeometryGrid(
            columns: numberOfColumns,
            rows: numberOfRows,
            sourcePositions: sourcePositions,
            destinationPositions: destinationPositions
        )
    }

    /// Returns the source position at the specified index.
    ///
    /// - Parameter index: The index of the control point.
    /// - Returns: The source position.
    open func sourcePosition(at index: Int) -> SIMD2<Float> {
        guard index >= 0 && index < sourcePositions.count else {
            return .zero
        }
        return sourcePositions[index]
    }

    /// Returns the destination position at the specified index.
    ///
    /// - Parameter index: The index of the control point.
    /// - Returns: The destination position.
    open func destPosition(at index: Int) -> SIMD2<Float> {
        guard index >= 0 && index < destinationPositions.count else {
            return .zero
        }
        return destinationPositions[index]
    }

    // MARK: - Private Helpers

    /// Generates unit positions for a grid.
    /// Positions are in row-major order from top-left to bottom-right
    /// (first item is top-left vertex, last item is bottom-right vertex).
    private class func generateUnitPositions(columns: Int, rows: Int) -> [SIMD2<Float>] {
        // Guard against invalid grid dimensions
        guard columns > 0 && rows > 0 else {
            // Return single vertex at origin for degenerate cases
            return [SIMD2<Float>(0, 0)]
        }

        var positions: [SIMD2<Float>] = []
        positions.reserveCapacity((columns + 1) * (rows + 1))

        // Generate positions from top to bottom (reversed row order)
        // to match Apple's specification: first item is top-left, last is bottom-right
        for row in (0...rows).reversed() {
            for col in 0...columns {
                let x = Float(col) / Float(columns)
                let y = Float(row) / Float(rows)
                positions.append(SIMD2<Float>(x, y))
            }
        }

        return positions
    }
}

