// SKShader.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
#if canImport(simd)
import simd
#endif

/// An object that allows you to apply a custom fragment shader to a node.
///
/// An `SKShader` object holds a custom OpenGL ES fragment shader. Shader objects are
/// used to customize the drawing behavior of a node.
open class SKShader: @unchecked Sendable {

    // MARK: - Properties

    /// The source code for the shader.
    open var source: String?

    /// An array of uniforms associated with the shader.
    open var uniforms: [SKUniform] = []

    /// An array of attributes associated with the shader.
    open var attributes: [SKAttribute] = []

    // MARK: - Initializers

    /// Creates a new shader object.
    public init() {
    }

    /// Creates a shader object using the specified source code.
    ///
    /// - Parameter source: A string containing the source code for the fragment shader.
    public init(source: String) {
        self.source = source
    }

    /// Creates a shader object using the specified source code and uniforms.
    ///
    /// - Parameters:
    ///   - source: A string containing the source code for the fragment shader.
    ///   - uniforms: An array of uniform objects.
    public init(source: String, uniforms: [SKUniform]) {
        self.source = source
        self.uniforms = uniforms
    }

    /// Creates a shader object by loading source code from a file.
    ///
    /// On WASM platforms, you must first register the shader source with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerShader(source: shaderCode, forName: "MyShader")
    /// let shader = SKShader(fileNamed: "MyShader")
    /// ```
    ///
    /// - Parameter name: The name of the file containing the shader source code.
    public convenience init(fileNamed name: String) {
        self.init()

        // Try to load from registered shader source (WASM)
        if let source = SKResourceLoader.shared.shaderSource(forName: name) {
            self.source = source
            return
        }

        // Try to load from bundle (native platforms)
        let nameWithoutExtension: String
        let ext: String

        if name.contains(".") {
            let components = name.split(separator: ".", maxSplits: 1)
            nameWithoutExtension = String(components[0])
            ext = components.count > 1 ? String(components[1]) : "fsh"
        } else {
            nameWithoutExtension = name
            ext = "fsh"
        }

        // Try with specified or default extension
        if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: ext),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            self.source = source
            return
        }

        // Try common shader extensions
        for shaderExt in ["fsh", "frag", "glsl", "metal"] where shaderExt != ext {
            if let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: shaderExt),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                self.source = source
                return
            }
        }
    }

    // MARK: - Copying

    /// Creates a copy of this shader.
    ///
    /// - Returns: A new shader with the same properties.
    open func copy() -> SKShader {
        let shaderCopy = SKShader()
        shaderCopy.source = source
        shaderCopy.uniforms = uniforms.map { $0.copy() }
        shaderCopy.attributes = attributes.map { $0.copy() }
        return shaderCopy
    }

    // MARK: - Uniform Management

    /// Adds a uniform to the shader.
    ///
    /// - Parameter uniform: The uniform to add.
    open func addUniform(_ uniform: SKUniform) {
        uniforms.append(uniform)
    }

    /// Returns the uniform object with the specified name.
    ///
    /// - Parameter name: The name of the uniform to retrieve.
    /// - Returns: The uniform object, or nil if no uniform with that name exists.
    open func uniformNamed(_ name: String) -> SKUniform? {
        return uniforms.first { $0.name == name }
    }

    /// Removes a uniform from the shader.
    ///
    /// - Parameter uniform: The uniform to remove.
    open func removeUniformNamed(_ name: String) {
        uniforms.removeAll { $0.name == name }
    }
}

// MARK: - SKUniform

/// A container for uniform shader data.
///
/// An `SKUniform` object contains a value and a name for passing data into a shader.
open class SKUniform: @unchecked Sendable {

    // MARK: - Properties

    /// The name of the uniform variable.
    open var name: String

    /// The type of the uniform.
    open private(set) var uniformType: SKUniformType = .none

    /// The floating-point value of the uniform.
    open var floatValue: Float = 0.0

    /// The vector value of the uniform.
    open var vectorFloat2Value: SIMD2<Float> = .zero

    /// The vector value of the uniform.
    open var vectorFloat3Value: SIMD3<Float> = .zero

    /// The vector value of the uniform.
    open var vectorFloat4Value: SIMD4<Float> = .zero

    /// The matrix value of the uniform.
    open var matrixFloat2x2Value: simd_float2x2 = .init(diagonal: .one)

    /// The matrix value of the uniform.
    open var matrixFloat3x3Value: simd_float3x3 = .init(diagonal: .one)

    /// The matrix value of the uniform.
    open var matrixFloat4x4Value: simd_float4x4 = .init(diagonal: .one)

    /// The texture value of the uniform.
    open var textureValue: SKTexture?

    // MARK: - Initializers

    /// Creates a uniform with the specified name.
    ///
    /// - Parameter name: The name of the uniform variable.
    public init(name: String) {
        self.name = name
    }

    /// Creates a uniform with a float value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The float value.
    public init(name: String, float value: Float) {
        self.name = name
        self.floatValue = value
        self.uniformType = .float
    }

    /// Creates a uniform with a texture value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - texture: The texture value.
    public init(name: String, texture: SKTexture?) {
        self.name = name
        self.textureValue = texture
        self.uniformType = .texture
    }

    /// Creates a uniform with a 2-component vector value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The vector value.
    public init(name: String, vectorFloat2 value: SIMD2<Float>) {
        self.name = name
        self.vectorFloat2Value = value
        self.uniformType = .vectorFloat2
    }

    /// Creates a uniform with a 3-component vector value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The vector value.
    public init(name: String, vectorFloat3 value: SIMD3<Float>) {
        self.name = name
        self.vectorFloat3Value = value
        self.uniformType = .vectorFloat3
    }

    /// Creates a uniform with a 4-component vector value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The vector value.
    public init(name: String, vectorFloat4 value: SIMD4<Float>) {
        self.name = name
        self.vectorFloat4Value = value
        self.uniformType = .vectorFloat4
    }

    // MARK: - Copying

    /// Creates a copy of this uniform.
    ///
    /// - Returns: A new uniform with the same properties.
    open func copy() -> SKUniform {
        let uniformCopy = SKUniform(name: name)
        uniformCopy.uniformType = uniformType
        uniformCopy.floatValue = floatValue
        uniformCopy.vectorFloat2Value = vectorFloat2Value
        uniformCopy.vectorFloat3Value = vectorFloat3Value
        uniformCopy.vectorFloat4Value = vectorFloat4Value
        uniformCopy.matrixFloat2x2Value = matrixFloat2x2Value
        uniformCopy.matrixFloat3x3Value = matrixFloat3x3Value
        uniformCopy.matrixFloat4x4Value = matrixFloat4x4Value
        uniformCopy.textureValue = textureValue
        return uniformCopy
    }
}

// MARK: - SKUniformType

/// An enumerated type to identify the type of a uniform object.
public enum SKUniformType: Int, Sendable, Hashable {
    case none = 0
    case float = 1
    case vectorFloat2 = 2
    case vectorFloat3 = 3
    case vectorFloat4 = 4
    case matrixFloat2x2 = 5
    case matrixFloat3x3 = 6
    case matrixFloat4x4 = 7
    case texture = 8
}

// MARK: - SKAttribute

/// A specification for dynamic per-node data used with a custom shader.
///
/// An `SKAttribute` describes a single attribute in a custom shader. The attribute
/// defines per-node data that you can pass into the shader.
open class SKAttribute: @unchecked Sendable {

    // MARK: - Properties

    /// The name of the attribute.
    open var name: String

    /// The data type of the attribute.
    open var type: SKAttributeType

    // MARK: - Initializers

    /// Creates an attribute with the specified name and type.
    ///
    /// - Parameters:
    ///   - name: The name of the attribute.
    ///   - type: The data type of the attribute.
    public init(name: String, type: SKAttributeType) {
        self.name = name
        self.type = type
    }

    // MARK: - Copying

    /// Creates a copy of this attribute.
    ///
    /// - Returns: A new attribute with the same properties.
    open func copy() -> SKAttribute {
        return SKAttribute(name: name, type: type)
    }
}

// MARK: - SKAttributeType

/// Options that specify an attribute's data type.
public enum SKAttributeType: Int, Sendable, Hashable {
    case none = 0
    case float = 1
    case vectorFloat2 = 2
    case vectorFloat3 = 3
    case vectorFloat4 = 4
    case halfFloat = 5
    case vectorHalfFloat2 = 6
    case vectorHalfFloat3 = 7
    case vectorHalfFloat4 = 8
}
