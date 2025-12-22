// SimdCompatibility.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

#if canImport(simd)
import simd
#else
// WASM fallback implementations for simd functions

/// Calculates the length of a 3D vector.
@inlinable
func simd_length(_ v: vector_float3) -> Float {
    sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

/// Normalizes a 3D vector.
@inlinable
func simd_normalize(_ v: vector_float3) -> vector_float3 {
    let len = simd_length(v)
    guard len > 0 else { return .zero }
    return vector_float3(v.x / len, v.y / len, v.z / len)
}

/// Calculates the cross product of two 3D vectors.
@inlinable
func simd_cross(_ a: vector_float3, _ b: vector_float3) -> vector_float3 {
    vector_float3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}

/// A 3D floating-point vector.
public struct vector_float3: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = vector_float3(0, 0, 0)
    public static let one = vector_float3(1, 1, 1)

    /// Element subscript access.
    public subscript(index: Int) -> Float {
        get {
            switch index {
            case 0: return x
            case 1: return y
            case 2: return z
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: x = newValue
            case 1: y = newValue
            case 2: z = newValue
            default: fatalError("Index out of range")
            }
        }
    }

    public static func + (lhs: vector_float3, rhs: vector_float3) -> vector_float3 {
        vector_float3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    public static func - (lhs: vector_float3, rhs: vector_float3) -> vector_float3 {
        vector_float3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    public static func * (lhs: vector_float3, rhs: Float) -> vector_float3 {
        vector_float3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    public static func * (lhs: Float, rhs: vector_float3) -> vector_float3 {
        vector_float3(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    public static prefix func - (v: vector_float3) -> vector_float3 {
        vector_float3(-v.x, -v.y, -v.z)
    }

    public static func += (lhs: inout vector_float3, rhs: vector_float3) {
        lhs = lhs + rhs
    }
}

public typealias simd_float3 = vector_float3

/// A quaternion for 3D rotations.
public struct simd_quatf: Sendable, Equatable {
    public var vector: vector_float4

    /// The real (scalar) component of the quaternion.
    public var real: Float {
        get { vector.w }
        set { vector.w = newValue }
    }

    /// The imaginary (vector) component of the quaternion.
    public var imag: vector_float3 {
        get { vector_float3(vector.x, vector.y, vector.z) }
        set {
            vector.x = newValue.x
            vector.y = newValue.y
            vector.z = newValue.z
        }
    }

    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        self.vector = vector_float4(ix, iy, iz, r)
    }

    public init(angle: Float, axis: vector_float3) {
        let halfAngle = angle * 0.5
        let s = sin(halfAngle)
        let normalizedAxis = simd_normalize(axis)
        self.vector = vector_float4(
            normalizedAxis.x * s,
            normalizedAxis.y * s,
            normalizedAxis.z * s,
            cos(halfAngle)
        )
    }
}

/// A 4D floating-point vector.
public struct vector_float4: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let zero = vector_float4(0, 0, 0, 0)
    public static let one = vector_float4(1, 1, 1, 1)
}

/// Protocol for SIMD scalar types.
public protocol SIMDScalar: Sendable {}
extension Float: SIMDScalar {}
extension Double: SIMDScalar {}
extension Int: SIMDScalar {}
extension Int32: SIMDScalar {}

/// A 2D SIMD vector.
public struct SIMD2<Scalar>: Sendable, Equatable where Scalar: SIMDScalar & Equatable {
    public var x: Scalar
    public var y: Scalar

    public init(_ x: Scalar, _ y: Scalar) {
        self.x = x
        self.y = y
    }

    public init(x: Scalar, y: Scalar) {
        self.x = x
        self.y = y
    }
}

extension SIMD2 where Scalar == Float {
    public static var zero: SIMD2<Float> { SIMD2(0, 0) }
    public static var one: SIMD2<Float> { SIMD2(1, 1) }
}

public typealias vector_float2 = SIMD2<Float>
public typealias simd_float2 = SIMD2<Float>

/// A 4x4 floating-point matrix.
public struct simd_float4x4: Sendable {
    public var columns: (vector_float4, vector_float4, vector_float4, vector_float4)

    public init(_ columns: (vector_float4, vector_float4, vector_float4, vector_float4)) {
        self.columns = columns
    }

    public init(diagonal: vector_float4) {
        self.columns = (
            vector_float4(diagonal.x, 0, 0, 0),
            vector_float4(0, diagonal.y, 0, 0),
            vector_float4(0, 0, diagonal.z, 0),
            vector_float4(0, 0, 0, diagonal.w)
        )
    }

    public static var identity: simd_float4x4 {
        simd_float4x4(diagonal: vector_float4(1, 1, 1, 1))
    }
}

extension simd_float4x4: Equatable {
    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0 &&
        lhs.columns.1 == rhs.columns.1 &&
        lhs.columns.2 == rhs.columns.2 &&
        lhs.columns.3 == rhs.columns.3
    }
}

/// A 3x3 floating-point matrix.
public struct simd_float3x3: Sendable {
    public var columns: (vector_float3, vector_float3, vector_float3)

    public init(_ columns: (vector_float3, vector_float3, vector_float3)) {
        self.columns = columns
    }

    public init(columns: (vector_float3, vector_float3, vector_float3)) {
        self.columns = columns
    }

    public init(diagonal: vector_float3) {
        self.columns = (
            vector_float3(diagonal.x, 0, 0),
            vector_float3(0, diagonal.y, 0),
            vector_float3(0, 0, diagonal.z)
        )
    }

    public static var identity: simd_float3x3 {
        simd_float3x3(diagonal: .one)
    }

    /// Column subscript access.
    public subscript(column: Int) -> vector_float3 {
        get {
            switch column {
            case 0: return columns.0
            case 1: return columns.1
            case 2: return columns.2
            default: fatalError("Index out of range")
            }
        }
        set {
            switch column {
            case 0: columns.0 = newValue
            case 1: columns.1 = newValue
            case 2: columns.2 = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

extension simd_float3x3: Equatable {
    public static func == (lhs: simd_float3x3, rhs: simd_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0 &&
        lhs.columns.1 == rhs.columns.1 &&
        lhs.columns.2 == rhs.columns.2
    }
}
#endif
