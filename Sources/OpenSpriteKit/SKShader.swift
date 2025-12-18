// SKShader.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

#if canImport(simd)
import simd
#endif

/// An object that allows you to apply a custom fragment shader to a node.
///
/// An `SKShader` object holds a custom OpenGL ES fragment shader. Shader objects are
/// used to customize the drawing behavior of a node.
open class SKShader: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Properties

    /// The source code for the shader.
    open var source: String?

    /// An array of uniforms associated with the shader.
    open var uniforms: [SKUniform] = []

    /// An array of attributes associated with the shader.
    open var attributes: [SKAttribute] = []

    // MARK: - Initializers

    /// Creates a new shader object.
    public override init() {
        super.init()
    }

    /// Creates a shader object using the specified source code.
    ///
    /// - Parameter source: A string containing the source code for the fragment shader.
    public init(source: String) {
        self.source = source
        super.init()
    }

    /// Creates a shader object using the specified source code and uniforms.
    ///
    /// - Parameters:
    ///   - source: A string containing the source code for the fragment shader.
    ///   - uniforms: An array of uniform objects.
    public init(source: String, uniforms: [SKUniform]) {
        self.source = source
        self.uniforms = uniforms
        super.init()
    }

    /// Creates a shader object by loading source code from a file.
    ///
    /// - Parameter name: The name of the file containing the shader source code.
    public convenience init(fileNamed name: String) {
        self.init()
        // TODO: Load shader from file
    }

    public required init?(coder: NSCoder) {
        source = coder.decodeObject(forKey: "source") as? String
        uniforms = coder.decodeObject(forKey: "uniforms") as? [SKUniform] ?? []
        attributes = coder.decodeObject(forKey: "attributes") as? [SKAttribute] ?? []
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(source, forKey: "source")
        coder.encode(uniforms, forKey: "uniforms")
        coder.encode(attributes, forKey: "attributes")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKShader()
        copy.source = source
        copy.uniforms = uniforms.map { $0.copy() as! SKUniform }
        copy.attributes = attributes.map { $0.copy() as! SKAttribute }
        return copy
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
open class SKUniform: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

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
        super.init()
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
        super.init()
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
        super.init()
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
        super.init()
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
        super.init()
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
        super.init()
    }

    public required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        uniformType = SKUniformType(rawValue: coder.decodeInteger(forKey: "uniformType")) ?? .none
        floatValue = coder.decodeFloat(forKey: "floatValue")
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(uniformType.rawValue, forKey: "uniformType")
        coder.encode(floatValue, forKey: "floatValue")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKUniform(name: name)
        copy.uniformType = uniformType
        copy.floatValue = floatValue
        copy.vectorFloat2Value = vectorFloat2Value
        copy.vectorFloat3Value = vectorFloat3Value
        copy.vectorFloat4Value = vectorFloat4Value
        copy.matrixFloat2x2Value = matrixFloat2x2Value
        copy.matrixFloat3x3Value = matrixFloat3x3Value
        copy.matrixFloat4x4Value = matrixFloat4x4Value
        copy.textureValue = textureValue
        return copy
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
open class SKAttribute: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

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
        super.init()
    }

    public required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        type = SKAttributeType(rawValue: coder.decodeInteger(forKey: "type")) ?? .none
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(type.rawValue, forKey: "type")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
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
