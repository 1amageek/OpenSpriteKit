// SKAttributeValue.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(simd)
import simd
#endif

/// A container for dynamic shader data associated with a node.
///
/// `SKAttributeValue` objects store per-node data that is passed to a custom shader.
/// Each node can have multiple attribute values, allowing you to customize how
/// a shader renders different nodes.
///
/// Unlike uniforms, which are shared across all nodes using the same shader,
/// attribute values are per-node. This means each node using the same shader
/// can have different attribute values.
///
/// ## Example
///
/// ```swift
/// // Create a shader with an attribute
/// let shader = SKShader(source: myShaderSource)
/// shader.attributes = [SKAttribute(name: "a_size", type: .vectorFloat2)]
///
/// // Set different attribute values for each node
/// sprite1.setValue(SKAttributeValue(vectorFloat2: vector_float2(100, 100)),
///                  forAttribute: "a_size")
/// sprite2.setValue(SKAttributeValue(vectorFloat2: vector_float2(200, 50)),
///                  forAttribute: "a_size")
/// ```
open class SKAttributeValue: @unchecked Sendable {

    // MARK: - Properties

    /// The floating-point value of this attribute.
    open var floatValue: Float = 0.0

    /// The 2-component vector value of this attribute.
    open var vectorFloat2Value: SIMD2<Float> = .zero

    /// The 3-component vector value of this attribute.
    open var vectorFloat3Value: SIMD3<Float> = .zero

    /// The 4-component vector value of this attribute.
    open var vectorFloat4Value: SIMD4<Float> = .zero

    // MARK: - Internal Type Tracking

    /// The type of value stored in this attribute.
    internal enum ValueType {
        case none
        case float
        case vectorFloat2
        case vectorFloat3
        case vectorFloat4
    }

    /// The type of value currently stored.
    internal var valueType: ValueType = .none

    // MARK: - Initializers

    /// Creates an empty attribute value.
    public init() {
    }

    /// Creates an attribute value with a float.
    ///
    /// - Parameter value: The float value.
    public init(float value: Float) {
        self.floatValue = value
        self.valueType = .float
    }

    /// Creates an attribute value with a 2-component vector.
    ///
    /// - Parameter value: The vector value.
    public init(vectorFloat2 value: SIMD2<Float>) {
        self.vectorFloat2Value = value
        self.valueType = .vectorFloat2
    }

    /// Creates an attribute value with a 3-component vector.
    ///
    /// - Parameter value: The vector value.
    public init(vectorFloat3 value: SIMD3<Float>) {
        self.vectorFloat3Value = value
        self.valueType = .vectorFloat3
    }

    /// Creates an attribute value with a 4-component vector.
    ///
    /// - Parameter value: The vector value.
    public init(vectorFloat4 value: SIMD4<Float>) {
        self.vectorFloat4Value = value
        self.valueType = .vectorFloat4
    }

    // MARK: - Copying

    /// Creates a copy of this attribute value.
    ///
    /// - Returns: A new attribute value with the same properties.
    open func copy() -> SKAttributeValue {
        let valueCopy = SKAttributeValue()
        valueCopy.floatValue = floatValue
        valueCopy.vectorFloat2Value = vectorFloat2Value
        valueCopy.vectorFloat3Value = vectorFloat3Value
        valueCopy.vectorFloat4Value = vectorFloat4Value
        valueCopy.valueType = valueType
        return valueCopy
    }
}
