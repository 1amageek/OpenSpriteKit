// SKSParser.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreGraphics

/// Errors that can occur during .sks file parsing.
public enum SKSParserError: Error {
    /// The data could not be decoded as a valid plist.
    case invalidPlist

    /// The plist structure is not a valid NSKeyedArchiver format.
    case invalidArchiveFormat

    /// A required key is missing from the archive.
    case missingKey(String)

    /// An unsupported class type was encountered.
    case unsupportedClass(String)

    /// The scene could not be reconstructed from the archive.
    case reconstructionFailed(String)
}

/// A parser for .sks files (SpriteKit Scene archives).
///
/// `.sks` files are created by Xcode's SpriteKit Scene Editor and use the
/// NSKeyedArchiver format (Binary Plist). This parser provides a pure Swift
/// implementation that works in WASM environments without Objective-C runtime.
///
/// ## Usage
///
/// ```swift
/// // Register scene data with SKResourceLoader
/// SKResourceLoader.shared.registerScene(data: sksData, forName: "GameScene")
///
/// // Load the scene
/// if let scene = SKSParser.scene(from: sksData) {
///     view.presentScene(scene)
/// }
/// ```
///
/// ## Supported Node Types
///
/// The parser currently supports:
/// - SKScene (root node)
/// - SKNode (basic node)
/// - SKSpriteNode (textured sprites)
/// - SKLabelNode (text labels)
/// - SKShapeNode (vector shapes)
/// - SKEmitterNode (particle emitters)
/// - SKCameraNode (cameras)
/// - SKLightNode (lights)
///
/// ## Limitations
///
/// - Custom subclasses of SpriteKit nodes are not supported
/// - Some advanced properties may not be preserved
/// - Physics bodies are reconstructed with basic shapes
///
public final class SKSParser: @unchecked Sendable {

    // MARK: - Public API

    /// Parses a scene from .sks file data.
    ///
    /// - Parameter data: The raw bytes of a .sks file.
    /// - Returns: The parsed scene, or nil if parsing failed.
    public static func scene(from data: Data) -> SKScene? {
        do {
            return try parseScene(from: data)
        } catch {
            print("SKSParser: Failed to parse scene - \(error)")
            return nil
        }
    }

    /// Parses a scene from .sks file data.
    ///
    /// - Parameter data: The raw bytes of a .sks file.
    /// - Returns: The parsed scene.
    /// - Throws: `SKSParserError` if parsing fails.
    public static func parseScene(from data: Data) throws -> SKScene {
        // Step 1: Parse the Binary Plist
        guard let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw SKSParserError.invalidPlist
        }

        // Step 2: Validate NSKeyedArchiver format
        guard let archiver = plist["$archiver"] as? String,
              archiver == "NSKeyedArchiver" else {
            throw SKSParserError.invalidArchiveFormat
        }

        guard let objects = plist["$objects"] as? [Any],
              let top = plist["$top"] as? [String: Any] else {
            throw SKSParserError.invalidArchiveFormat
        }

        // Step 3: Find root object
        guard let rootRef = top["root"] as? [String: Any],
              let rootUID = rootRef["CF$UID"] as? Int else {
            throw SKSParserError.missingKey("root")
        }

        // Step 4: Create context and parse
        let context = ParserContext(objects: objects)

        guard let rootObject = context.object(at: rootUID) as? [String: Any] else {
            throw SKSParserError.reconstructionFailed("Could not find root object")
        }

        // Step 5: Reconstruct scene
        guard let scene = try context.reconstructNode(from: rootObject) as? SKScene else {
            // If root is not a scene, wrap it in a scene
            let scene = SKScene()
            if let node = try? context.reconstructNode(from: rootObject) {
                scene.addChild(node)
            }
            return scene
        }

        return scene
    }

    /// Loads a scene by name from SKResourceLoader.
    ///
    /// - Parameter name: The name of the scene (with or without .sks extension).
    /// - Returns: The parsed scene, or nil if not found or parsing failed.
    public static func scene(fileNamed name: String) -> SKScene? {
        let nameWithoutExtension = name.hasSuffix(".sks") ? String(name.dropLast(4)) : name

        // Try to load from registered scene data
        if let data = SKResourceLoader.shared.sceneData(forName: nameWithoutExtension) {
            return scene(from: data)
        }

        return nil
    }
}

// MARK: - Parser Context

/// Internal context for parsing NSKeyedArchiver data.
private class ParserContext {
    let objects: [Any]
    private var cache: [Int: Any] = [:]

    init(objects: [Any]) {
        self.objects = objects
    }

    /// Gets an object from the objects array by UID.
    func object(at uid: Int) -> Any? {
        guard uid >= 0 && uid < objects.count else { return nil }
        return objects[uid]
    }

    /// Resolves a UID reference to its actual object.
    func resolveUID(_ ref: Any?) -> Any? {
        guard let dict = ref as? [String: Any],
              let uid = dict["CF$UID"] as? Int else {
            return ref
        }
        return object(at: uid)
    }

    /// Gets a string value from the archive.
    func string(from ref: Any?) -> String? {
        guard let resolved = resolveUID(ref) else { return nil }
        return resolved as? String
    }

    /// Gets an integer value from the archive.
    func integer(from ref: Any?) -> Int? {
        if let dict = ref as? [String: Any], let uid = dict["CF$UID"] as? Int {
            return object(at: uid) as? Int
        }
        return ref as? Int
    }

    /// Gets a double value from the archive.
    func double(from ref: Any?) -> Double? {
        if let dict = ref as? [String: Any], let uid = dict["CF$UID"] as? Int {
            return object(at: uid) as? Double
        }
        return ref as? Double
    }

    /// Gets a CGFloat value from the archive.
    func cgFloat(from ref: Any?) -> CGFloat? {
        if let d = double(from: ref) {
            return CGFloat(d)
        }
        return nil
    }

    /// Reconstructs a node from its archived dictionary.
    func reconstructNode(from dict: [String: Any]) throws -> SKNode {
        // Get the class name
        guard let classRef = dict["$class"] as? [String: Any],
              let classUID = classRef["CF$UID"] as? Int,
              let classDict = object(at: classUID) as? [String: Any],
              let className = classDict["$classname"] as? String else {
            throw SKSParserError.missingKey("$class")
        }

        // Create appropriate node type
        let node: SKNode

        switch className {
        case "SKScene":
            node = try reconstructScene(from: dict)
        case "SKSpriteNode":
            node = try reconstructSpriteNode(from: dict)
        case "SKLabelNode":
            node = try reconstructLabelNode(from: dict)
        case "SKShapeNode":
            node = try reconstructShapeNode(from: dict)
        case "SKEmitterNode":
            node = try reconstructEmitterNode(from: dict)
        case "SKCameraNode":
            node = SKCameraNode()
        case "SKLightNode":
            node = SKLightNode()
        case "SKCropNode":
            node = SKCropNode()
        case "SKEffectNode":
            node = SKEffectNode()
        case "SKNode":
            node = SKNode()
        default:
            // Unknown class - create basic SKNode
            print("SKSParser: Unknown class '\(className)', creating SKNode")
            node = SKNode()
        }

        // Apply common node properties
        try applyNodeProperties(to: node, from: dict)

        // Add children
        if let childrenRef = dict["children"] as? [String: Any],
           let childrenUID = childrenRef["CF$UID"] as? Int,
           let childrenDict = object(at: childrenUID) as? [String: Any],
           let childRefs = childrenDict["NS.objects"] as? [[String: Any]] {

            for childRef in childRefs {
                if let childUID = childRef["CF$UID"] as? Int,
                   let childDict = object(at: childUID) as? [String: Any] {
                    let childNode = try reconstructNode(from: childDict)
                    node.addChild(childNode)
                }
            }
        }

        return node
    }

    /// Applies common SKNode properties.
    private func applyNodeProperties(to node: SKNode, from dict: [String: Any]) throws {
        // Name
        if let name = string(from: dict["name"]) {
            node.name = name
        }

        // Position
        if let positionData = dict["position"] as? Data, positionData.count >= 16 {
            let x = positionData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) }
            let y = positionData.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Double.self) }
            node.position = CGPoint(x: x, y: y)
        }

        // Z Position
        if let zPosition = cgFloat(from: dict["zPosition"]) {
            node.zPosition = zPosition
        }

        // Z Rotation
        if let zRotation = cgFloat(from: dict["zRotation"]) {
            node.zRotation = zRotation
        }

        // Scale
        if let xScale = cgFloat(from: dict["xScale"]) {
            node.xScale = xScale
        }
        if let yScale = cgFloat(from: dict["yScale"]) {
            node.yScale = yScale
        }

        // Alpha
        if let alpha = cgFloat(from: dict["alpha"]) {
            node.alpha = alpha
        }

        // Hidden
        if let hidden = dict["hidden"] as? Bool {
            node.isHidden = hidden
        }

        // Speed
        if let speed = cgFloat(from: dict["speed"]) {
            node.speed = speed
        }

        // User interaction
        if let userInteractionEnabled = dict["userInteractionEnabled"] as? Bool {
            node.isUserInteractionEnabled = userInteractionEnabled
        }
    }

    /// Reconstructs an SKScene.
    private func reconstructScene(from dict: [String: Any]) throws -> SKScene {
        var size = CGSize(width: 1024, height: 768) // Default size

        // Get size
        if let sizeData = dict["size"] as? Data, sizeData.count >= 16 {
            let width = sizeData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) }
            let height = sizeData.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Double.self) }
            size = CGSize(width: width, height: height)
        }

        let scene = SKScene(size: size)

        // Scale mode
        if let scaleMode = integer(from: dict["scaleMode"]) {
            scene.scaleMode = SKSceneScaleMode(rawValue: scaleMode) ?? .fill
        }

        // Background color
        if let bgColorRef = dict["backgroundColor"] as? [String: Any],
           let bgColorUID = bgColorRef["CF$UID"] as? Int,
           let bgColorDict = object(at: bgColorUID) as? [String: Any] {
            if let red = cgFloat(from: bgColorDict["red"]),
               let green = cgFloat(from: bgColorDict["green"]),
               let blue = cgFloat(from: bgColorDict["blue"]),
               let alpha = cgFloat(from: bgColorDict["alpha"]) {
                scene.backgroundColor = SKColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }

        return scene
    }

    /// Reconstructs an SKSpriteNode.
    private func reconstructSpriteNode(from dict: [String: Any]) throws -> SKSpriteNode {
        let sprite = SKSpriteNode()

        // Size
        if let sizeData = dict["size"] as? Data, sizeData.count >= 16 {
            let width = sizeData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) }
            let height = sizeData.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Double.self) }
            sprite.size = CGSize(width: width, height: height)
        }

        // Anchor point
        if let anchorData = dict["anchorPoint"] as? Data, anchorData.count >= 16 {
            let x = anchorData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) }
            let y = anchorData.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Double.self) }
            sprite.anchorPoint = CGPoint(x: x, y: y)
        }

        // Texture name
        if let textureRef = dict["texture"] as? [String: Any],
           let textureUID = textureRef["CF$UID"] as? Int,
           let textureDict = object(at: textureUID) as? [String: Any],
           let textureName = string(from: textureDict["name"]) {
            sprite.texture = SKTexture(imageNamed: textureName)
        }

        // Color
        if let colorRef = dict["color"] as? [String: Any],
           let colorUID = colorRef["CF$UID"] as? Int,
           let colorDict = object(at: colorUID) as? [String: Any] {
            if let red = cgFloat(from: colorDict["red"]),
               let green = cgFloat(from: colorDict["green"]),
               let blue = cgFloat(from: colorDict["blue"]),
               let alpha = cgFloat(from: colorDict["alpha"]) {
                sprite.color = SKColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }

        // Color blend factor
        if let colorBlendFactor = cgFloat(from: dict["colorBlendFactor"]) {
            sprite.colorBlendFactor = colorBlendFactor
        }

        return sprite
    }

    /// Reconstructs an SKLabelNode.
    private func reconstructLabelNode(from dict: [String: Any]) throws -> SKLabelNode {
        let label = SKLabelNode()

        // Text
        if let text = string(from: dict["text"]) {
            label.text = text
        }

        // Font name
        if let fontName = string(from: dict["fontName"]) {
            label.fontName = fontName
        }

        // Font size
        if let fontSize = cgFloat(from: dict["fontSize"]) {
            label.fontSize = fontSize
        }

        // Font color
        if let colorRef = dict["fontColor"] as? [String: Any],
           let colorUID = colorRef["CF$UID"] as? Int,
           let colorDict = object(at: colorUID) as? [String: Any] {
            if let red = cgFloat(from: colorDict["red"]),
               let green = cgFloat(from: colorDict["green"]),
               let blue = cgFloat(from: colorDict["blue"]),
               let alpha = cgFloat(from: colorDict["alpha"]) {
                label.fontColor = SKColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }

        // Alignment modes
        if let horizontal = integer(from: dict["horizontalAlignmentMode"]) {
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode(rawValue: horizontal) ?? .center
        }
        if let vertical = integer(from: dict["verticalAlignmentMode"]) {
            label.verticalAlignmentMode = SKLabelVerticalAlignmentMode(rawValue: vertical) ?? .baseline
        }

        return label
    }

    /// Reconstructs an SKShapeNode.
    private func reconstructShapeNode(from dict: [String: Any]) throws -> SKShapeNode {
        let shape = SKShapeNode()

        // Reconstruct path from serialized data
        if let pathRef = dict["path"] as? [String: Any],
           let pathUID = pathRef["CF$UID"] as? Int,
           let pathDict = object(at: pathUID) as? [String: Any] {
            if let path = reconstructPath(from: pathDict) {
                shape.path = path
            }
        }

        // Fill color
        if let colorRef = dict["fillColor"] as? [String: Any],
           let colorUID = colorRef["CF$UID"] as? Int,
           let colorDict = object(at: colorUID) as? [String: Any] {
            if let red = cgFloat(from: colorDict["red"]),
               let green = cgFloat(from: colorDict["green"]),
               let blue = cgFloat(from: colorDict["blue"]),
               let alpha = cgFloat(from: colorDict["alpha"]) {
                shape.fillColor = SKColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }

        // Stroke color
        if let colorRef = dict["strokeColor"] as? [String: Any],
           let colorUID = colorRef["CF$UID"] as? Int,
           let colorDict = object(at: colorUID) as? [String: Any] {
            if let red = cgFloat(from: colorDict["red"]),
               let green = cgFloat(from: colorDict["green"]),
               let blue = cgFloat(from: colorDict["blue"]),
               let alpha = cgFloat(from: colorDict["alpha"]) {
                shape.strokeColor = SKColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }

        // Line width
        if let lineWidth = cgFloat(from: dict["lineWidth"]) {
            shape.lineWidth = lineWidth
        }

        return shape
    }

    /// Reconstructs an SKEmitterNode.
    private func reconstructEmitterNode(from dict: [String: Any]) throws -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle properties
        if let birthRate = cgFloat(from: dict["particleBirthRate"]) {
            emitter.particleBirthRate = birthRate
        }
        if let lifetime = cgFloat(from: dict["particleLifetime"]) {
            emitter.particleLifetime = lifetime
        }
        if let lifetimeRange = cgFloat(from: dict["particleLifetimeRange"]) {
            emitter.particleLifetimeRange = lifetimeRange
        }

        // Position range
        if let positionRangeX = cgFloat(from: dict["particlePositionRangeX"]) {
            emitter.particlePositionRange.dx = positionRangeX
        }
        if let positionRangeY = cgFloat(from: dict["particlePositionRangeY"]) {
            emitter.particlePositionRange.dy = positionRangeY
        }

        // Speed
        if let speed = cgFloat(from: dict["particleSpeed"]) {
            emitter.particleSpeed = speed
        }
        if let speedRange = cgFloat(from: dict["particleSpeedRange"]) {
            emitter.particleSpeedRange = speedRange
        }

        // Emission angle
        if let emissionAngle = cgFloat(from: dict["emissionAngle"]) {
            emitter.emissionAngle = emissionAngle
        }
        if let emissionAngleRange = cgFloat(from: dict["emissionAngleRange"]) {
            emitter.emissionAngleRange = emissionAngleRange
        }

        // Scale
        if let scale = cgFloat(from: dict["particleScale"]) {
            emitter.particleScale = scale
        }
        if let scaleRange = cgFloat(from: dict["particleScaleRange"]) {
            emitter.particleScaleRange = scaleRange
        }

        // Alpha
        if let alpha = cgFloat(from: dict["particleAlpha"]) {
            emitter.particleAlpha = alpha
        }
        if let alphaRange = cgFloat(from: dict["particleAlphaRange"]) {
            emitter.particleAlphaRange = alphaRange
        }

        // Rotation
        if let rotation = cgFloat(from: dict["particleRotation"]) {
            emitter.particleRotation = rotation
        }
        if let rotationRange = cgFloat(from: dict["particleRotationRange"]) {
            emitter.particleRotationRange = rotationRange
        }

        // Texture
        if let textureRef = dict["particleTexture"] as? [String: Any],
           let textureUID = textureRef["CF$UID"] as? Int,
           let textureDict = object(at: textureUID) as? [String: Any],
           let textureName = string(from: textureDict["name"]) {
            emitter.particleTexture = SKTexture(imageNamed: textureName)
        }

        return emitter
    }

    // MARK: - Path Reconstruction

    /// Reconstructs a CGPath from serialized path data.
    ///
    /// CGPath in .sks files is typically serialized as:
    /// - A "pathElements" array containing path element dictionaries
    /// - Each element has "type" (moveTo, lineTo, curveToPoint, etc.) and "points" array
    /// - Or as raw "pathData" bytes that encode the path
    private func reconstructPath(from dict: [String: Any]) -> CGPath? {
        // Try to get path elements array first
        if let elementsRef = dict["pathElements"] as? [String: Any],
           let elementsUID = elementsRef["CF$UID"] as? Int,
           let elements = object(at: elementsUID) as? [[String: Any]] {
            return reconstructPathFromElements(elements)
        }

        // Try direct elements array
        if let elements = dict["pathElements"] as? [[String: Any]] {
            return reconstructPathFromElements(elements)
        }

        // Try raw path data (serialized as binary)
        if let pathDataRef = dict["pathData"] as? [String: Any],
           let pathDataUID = pathDataRef["CF$UID"] as? Int,
           let pathData = object(at: pathDataUID) as? Data {
            return reconstructPathFromData(pathData)
        }

        // Try direct data
        if let pathData = dict["pathData"] as? Data {
            return reconstructPathFromData(pathData)
        }

        // Try reconstructing from common shapes
        if let shapeType = dict["shapeType"] as? Int {
            return reconstructPathFromShapeType(shapeType, dict: dict)
        }

        return nil
    }

    /// Reconstructs a path from an array of path element dictionaries.
    private func reconstructPathFromElements(_ elements: [[String: Any]]) -> CGPath? {
        let path = CGMutablePath()

        for element in elements {
            guard let type = element["type"] as? Int else { continue }

            switch type {
            case 0: // moveToPoint
                if let point = extractPoint(from: element, key: "point") {
                    path.move(to: point)
                }
            case 1: // addLineToPoint
                if let point = extractPoint(from: element, key: "point") {
                    path.addLine(to: point)
                }
            case 2: // addQuadCurveToPoint
                if let endPoint = extractPoint(from: element, key: "point"),
                   let controlPoint = extractPoint(from: element, key: "controlPoint") {
                    path.addQuadCurve(to: endPoint, control: controlPoint)
                }
            case 3: // addCurveToPoint
                if let endPoint = extractPoint(from: element, key: "point"),
                   let controlPoint1 = extractPoint(from: element, key: "controlPoint1"),
                   let controlPoint2 = extractPoint(from: element, key: "controlPoint2") {
                    path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
                }
            case 4: // closeSubpath
                path.closeSubpath()
            default:
                break
            }
        }

        return path.isEmpty ? nil : path
    }

    /// Extracts a CGPoint from a dictionary.
    private func extractPoint(from element: [String: Any], key: String) -> CGPoint? {
        if let pointDict = element[key] as? [String: Any] {
            if let x = cgFloat(from: pointDict["x"]),
               let y = cgFloat(from: pointDict["y"]) {
                return CGPoint(x: x, y: y)
            }
        }
        // Try as CGPoint-encoded string (e.g., "{100, 200}")
        if let pointString = element[key] as? String {
            return parsePointString(pointString)
        }
        return nil
    }

    /// Parses a CGPoint from a string like "{100, 200}".
    private func parsePointString(_ string: String) -> CGPoint? {
        let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
        let components = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let x = Double(components[0]),
              let y = Double(components[1]) else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    /// Reconstructs a path from raw serialized data.
    ///
    /// This handles paths serialized as binary data containing path elements.
    private func reconstructPathFromData(_ data: Data) -> CGPath? {
        // Binary path data format varies; this is a basic implementation
        // that handles common cases where path data is a simple structure
        guard data.count >= 8 else { return nil }

        let path = CGMutablePath()

        // Try to interpret as a series of path commands
        var offset = 0
        while offset + 4 <= data.count {
            let command = data[offset]
            offset += 1

            switch command {
            case 0: // moveTo (followed by 2 floats: x, y)
                guard offset + 8 <= data.count else { break }
                let x = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self) }
                let y = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: Float.self) }
                path.move(to: CGPoint(x: CGFloat(x), y: CGFloat(y)))
                offset += 8
            case 1: // lineTo
                guard offset + 8 <= data.count else { break }
                let x = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self) }
                let y = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: Float.self) }
                path.addLine(to: CGPoint(x: CGFloat(x), y: CGFloat(y)))
                offset += 8
            case 4: // closeSubpath
                path.closeSubpath()
            default:
                // Unknown command, skip remaining
                return path.isEmpty ? nil : path
            }
        }

        return path.isEmpty ? nil : path
    }

    /// Reconstructs a path from a predefined shape type.
    private func reconstructPathFromShapeType(_ shapeType: Int, dict: [String: Any]) -> CGPath? {
        switch shapeType {
        case 0: // Rectangle
            if let width = cgFloat(from: dict["width"]),
               let height = cgFloat(from: dict["height"]) {
                let cornerRadius = cgFloat(from: dict["cornerRadius"]) ?? 0
                let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                if cornerRadius > 0 {
                    return CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                } else {
                    return CGPath(rect: rect, transform: nil)
                }
            }
        case 1: // Circle/Ellipse
            if let width = cgFloat(from: dict["width"]),
               let height = cgFloat(from: dict["height"]) {
                let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                return CGPath(ellipseIn: rect, transform: nil)
            }
        default:
            break
        }
        return nil
    }
}
