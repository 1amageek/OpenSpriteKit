// SKTransformNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
#if canImport(simd)
import simd
#endif

/// A node that allows its children to rotate in 3D.
///
/// `SKTransformNode` adds the ability to rotate nodes across the x and y axes.
/// When combined with `SKNode`'s `zRotation` property, nodes added as children
/// to a transform node have the ability to rotate in 3D.
open class SKTransformNode: SKNode, @unchecked Sendable {

    // MARK: - Rotation Properties

    /// The rotation about the x-axis in radians.
    open var xRotation: CGFloat = 0.0

    /// The rotation about the y-axis in radians.
    open var yRotation: CGFloat = 0.0

    // MARK: - Initializers

    /// Creates a new transform node.
    public override init() {
        super.init()
    }

    // MARK: - Copying

    /// Creates a copy of this transform node.
    open override func copy() -> SKNode {
        let transformCopy = SKTransformNode()
        transformCopy._copyNodeProperties(from: self)
        return transformCopy
    }

    /// Internal helper to copy SKTransformNode properties.
    internal override func _copyNodeProperties(from node: SKNode) {
        super._copyNodeProperties(from: node)
        guard let transformNode = node as? SKTransformNode else { return }

        self.xRotation = transformNode.xRotation
        self.yRotation = transformNode.yRotation
    }

    // MARK: - Setting Rotation

    /// Sets the rotation using Euler angles.
    ///
    /// - Parameter euler: A 3D vector containing rotation angles (x, y, z) in radians.
    open func setEulerAngles(_ euler: vector_float3) {
        xRotation = CGFloat(euler.x)
        yRotation = CGFloat(euler.y)
        zRotation = CGFloat(euler.z)
    }

    /// Sets the rotation using a quaternion.
    ///
    /// - Parameter quaternion: A quaternion representing the rotation.
    open func setQuaternion(_ quaternion: simd_quatf) {
        // Convert quaternion to Euler angles
        let angles = quaternionToEulerAngles(quaternion)
        setEulerAngles(angles)
    }

    /// Sets the rotation using a rotation matrix.
    ///
    /// - Parameter matrix: A 3x3 rotation matrix.
    open func setRotationMatrix(_ matrix: matrix_float3x3) {
        // Convert rotation matrix to Euler angles
        let euler = rotationMatrixToEulerAngles(matrix)
        setEulerAngles(euler)
    }

    // MARK: - Reading Rotation

    /// Returns the current rotation as Euler angles.
    ///
    /// - Returns: A 3D vector containing rotation angles (x, y, z) in radians.
    open func eulerAngles() -> vector_float3 {
        return vector_float3(Float(xRotation), Float(yRotation), Float(zRotation))
    }

    /// Returns the current rotation as a quaternion.
    ///
    /// - Returns: A quaternion representing the current rotation.
    open func quaternion() -> simd_quatf {
        let euler = eulerAngles()
        return eulerAnglesToQuaternion(euler)
    }

    /// Returns the current rotation as a rotation matrix.
    ///
    /// - Returns: A 3x3 rotation matrix representing the current rotation.
    open func rotationMatrix() -> matrix_float3x3 {
        let euler = eulerAngles()
        return eulerAnglesToRotationMatrix(euler)
    }

    // MARK: - Private Conversion Methods

    /// Converts a quaternion to Euler angles.
    private func quaternionToEulerAngles(_ q: simd_quatf) -> vector_float3 {
        let sinr_cosp = 2 * (q.real * q.imag.x + q.imag.y * q.imag.z)
        let cosr_cosp = 1 - 2 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        let sinp = 2 * (q.real * q.imag.y - q.imag.z * q.imag.x)
        let pitch: Float
        if abs(sinp) >= 1 {
            pitch = copysign(.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }

        let siny_cosp = 2 * (q.real * q.imag.z + q.imag.x * q.imag.y)
        let cosy_cosp = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        return vector_float3(roll, pitch, yaw)
    }

    /// Converts Euler angles to a quaternion.
    private func eulerAnglesToQuaternion(_ euler: vector_float3) -> simd_quatf {
        let cx = cos(euler.x * 0.5)
        let sx = sin(euler.x * 0.5)
        let cy = cos(euler.y * 0.5)
        let sy = sin(euler.y * 0.5)
        let cz = cos(euler.z * 0.5)
        let sz = sin(euler.z * 0.5)

        let w = cx * cy * cz + sx * sy * sz
        let x = sx * cy * cz - cx * sy * sz
        let y = cx * sy * cz + sx * cy * sz
        let z = cx * cy * sz - sx * sy * cz

        return simd_quatf(ix: x, iy: y, iz: z, r: w)
    }

    /// Converts a rotation matrix to Euler angles.
    private func rotationMatrixToEulerAngles(_ matrix: matrix_float3x3) -> vector_float3 {
        let sy = sqrt(matrix[0][0] * matrix[0][0] + matrix[1][0] * matrix[1][0])

        let singular = sy < 1e-6

        let x: Float
        let y: Float
        let z: Float

        if !singular {
            x = atan2(matrix[2][1], matrix[2][2])
            y = atan2(-matrix[2][0], sy)
            z = atan2(matrix[1][0], matrix[0][0])
        } else {
            x = atan2(-matrix[1][2], matrix[1][1])
            y = atan2(-matrix[2][0], sy)
            z = 0
        }

        return vector_float3(x, y, z)
    }

    /// Converts Euler angles to a rotation matrix.
    private func eulerAnglesToRotationMatrix(_ euler: vector_float3) -> matrix_float3x3 {
        let cx = cos(euler.x)
        let sx = sin(euler.x)
        let cy = cos(euler.y)
        let sy = sin(euler.y)
        let cz = cos(euler.z)
        let sz = sin(euler.z)

        // Rotation matrix = Rz * Ry * Rx
        let r00 = cy * cz
        let r01 = sx * sy * cz - cx * sz
        let r02 = cx * sy * cz + sx * sz

        let r10 = cy * sz
        let r11 = sx * sy * sz + cx * cz
        let r12 = cx * sy * sz - sx * cz

        let r20 = -sy
        let r21 = sx * cy
        let r22 = cx * cy

        return matrix_float3x3(columns: (
            SIMD3<Float>(r00, r10, r20),
            SIMD3<Float>(r01, r11, r21),
            SIMD3<Float>(r02, r12, r22)
        ))
    }
}
