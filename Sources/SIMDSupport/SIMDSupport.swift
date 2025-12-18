// SIMDSupport.swift
// SIMDSupport
//
// SIMD compatibility types for platforms without the simd module (e.g., WASM).

#if canImport(simd)
@_exported import simd
#else

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

// MARK: - Vector Type Aliases

public typealias simd_float2 = SIMD2<Float>
public typealias simd_float3 = SIMD3<Float>
public typealias simd_float4 = SIMD4<Float>
public typealias vector_float2 = SIMD2<Float>
public typealias vector_float3 = SIMD3<Float>

// MARK: - Matrix Type Aliases

public typealias simd_float2x2 = matrix_float2x2
public typealias simd_float3x3 = matrix_float3x3
public typealias simd_float4x4 = matrix_float4x4

// MARK: - Matrix Types

public struct matrix_float2x2: Sendable, Equatable {
    public var columns: (SIMD2<Float>, SIMD2<Float>)

    public init() {
        columns = (.zero, .zero)
    }

    public init(columns: (SIMD2<Float>, SIMD2<Float>)) {
        self.columns = columns
    }

    public init(diagonal: SIMD2<Float>) {
        columns = (
            SIMD2<Float>(diagonal.x, 0),
            SIMD2<Float>(0, diagonal.y)
        )
    }

    public static var identity: matrix_float2x2 {
        matrix_float2x2(diagonal: SIMD2<Float>(1, 1))
    }

    public static func == (lhs: matrix_float2x2, rhs: matrix_float2x2) -> Bool {
        lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1
    }
}

public struct matrix_float3x3: Sendable, Equatable {
    public var columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)

    public init() {
        columns = (.zero, .zero, .zero)
    }

    public init(columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) {
        self.columns = columns
    }

    public init(diagonal: SIMD3<Float>) {
        columns = (
            SIMD3<Float>(diagonal.x, 0, 0),
            SIMD3<Float>(0, diagonal.y, 0),
            SIMD3<Float>(0, 0, diagonal.z)
        )
    }

    public static var identity: matrix_float3x3 {
        matrix_float3x3(diagonal: SIMD3<Float>(1, 1, 1))
    }

    public subscript(column: Int) -> SIMD3<Float> {
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

    public static func == (lhs: matrix_float3x3, rhs: matrix_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0 &&
        lhs.columns.1 == rhs.columns.1 &&
        lhs.columns.2 == rhs.columns.2
    }
}

public struct matrix_float4x4: Sendable, Equatable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init() {
        columns = (.zero, .zero, .zero, .zero)
    }

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public init(diagonal: SIMD4<Float>) {
        columns = (
            SIMD4<Float>(diagonal.x, 0, 0, 0),
            SIMD4<Float>(0, diagonal.y, 0, 0),
            SIMD4<Float>(0, 0, diagonal.z, 0),
            SIMD4<Float>(0, 0, 0, diagonal.w)
        )
    }

    public static var identity: matrix_float4x4 {
        matrix_float4x4(diagonal: SIMD4<Float>(1, 1, 1, 1))
    }

    public static func == (lhs: matrix_float4x4, rhs: matrix_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0 &&
        lhs.columns.1 == rhs.columns.1 &&
        lhs.columns.2 == rhs.columns.2 &&
        lhs.columns.3 == rhs.columns.3
    }
}

// MARK: - Quaternion Type

public struct simd_quatf: Sendable, Equatable {
    public var real: Float
    public var imag: SIMD3<Float>

    public init() {
        real = 1
        imag = .zero
    }

    public init(real: Float, imag: SIMD3<Float>) {
        self.real = real
        self.imag = imag
    }

    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        self.real = r
        self.imag = SIMD3<Float>(ix, iy, iz)
    }

    public init(angle: Float, axis: SIMD3<Float>) {
        let halfAngle = angle * 0.5
        let sinHalf = sin(halfAngle)
        self.real = cos(halfAngle)
        self.imag = axis * sinHalf
    }

    public static var identity: simd_quatf {
        simd_quatf(real: 1, imag: .zero)
    }

    public static func == (lhs: simd_quatf, rhs: simd_quatf) -> Bool {
        lhs.real == rhs.real && lhs.imag == rhs.imag
    }
}

#endif
