// SKResourceLoader.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenImageIO

#if arch(wasm32)
import JavaScriptKit
#endif

/// Manages resource loading for OpenSpriteKit in WASM environments.
///
/// Since WASM cannot directly access bundle resources like native platforms,
/// this class provides a registry-based approach where resources can be:
/// 1. Pre-registered with raw data
/// 2. Loaded from URLs (async)
/// 3. Generated procedurally
///
/// ## Usage
/// ```swift
/// // Pre-register a texture
/// SKResourceLoader.shared.registerImage(data: pngData, forName: "player")
///
/// // Later, create texture using the name
/// let texture = SKTexture(imageNamed: "player")
/// ```
public final class SKResourceLoader {

    // MARK: - Singleton

    /// The shared resource loader instance.
    nonisolated(unsafe) public static let shared = SKResourceLoader()

    // MARK: - Properties

    /// Registered image data keyed by name.
    private var imageRegistry: [String: Data] = [:]

    /// Registered CGImages keyed by name.
    private var cgImageRegistry: [String: CGImage] = [:]

    /// Registered texture atlases keyed by name.
    private var atlasRegistry: [String: AtlasData] = [:]

    /// Registered action data keyed by name.
    private var actionRegistry: [String: Data] = [:]

    /// Registered scene data keyed by name.
    private var sceneRegistry: [String: Data] = [:]

    /// Registered shader source code keyed by name.
    private var shaderRegistry: [String: String] = [:]

    /// Registered tile set data keyed by name.
    private var tileSetRegistry: [String: Data] = [:]

    /// Registered emitter data keyed by name.
    private var emitterRegistry: [String: Data] = [:]

    /// Atlas data structure.
    public struct AtlasData {
        public let image: CGImage
        public let frames: [String: CGRect]  // Frame name -> rect in normalized coordinates (0-1)

        public init(image: CGImage, frames: [String: CGRect]) {
            self.image = image
            self.frames = frames
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Image Registration

    /// Registers image data for a given name.
    ///
    /// - Parameters:
    ///   - data: PNG or JPEG image data.
    ///   - name: The name to associate with the image.
    public func registerImage(data: Data, forName name: String) {
        imageRegistry[name] = data
    }

    /// Registers a CGImage for a given name.
    ///
    /// - Parameters:
    ///   - image: The CGImage to register.
    ///   - name: The name to associate with the image.
    public func registerImage(_ image: CGImage, forName name: String) {
        cgImageRegistry[name] = image
    }

    /// Retrieves a CGImage for a given name.
    ///
    /// - Parameter name: The name of the registered image.
    /// - Returns: The CGImage, or nil if not found.
    public func image(forName name: String) -> CGImage? {
        // First check direct CGImage registry
        if let image = cgImageRegistry[name] {
            return image
        }

        // Then check data registry and decode
        if let data = imageRegistry[name] {
            return decodeImage(from: data)
        }

        // Try with common extensions
        for ext in ["png", "jpg", "jpeg"] {
            let nameWithExt = name.hasSuffix(".\(ext)") ? name : "\(name).\(ext)"
            if let data = imageRegistry[nameWithExt] {
                return decodeImage(from: data)
            }
        }

        return nil
    }

    /// Decodes image data to CGImage.
    ///
    /// Supports PNG, JPEG, GIF, BMP, TIFF, and WebP formats via ImageIO/OpenImageIO.
    private func decodeImage(from data: Data) -> CGImage? {
        // CGImageSourceCreateWithData is available via OpenImageIO
        // Supports PNG, JPEG, GIF, BMP, TIFF, WebP
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            print("SKResourceLoader: Failed to create image source from \(data.count) bytes of data")
            return nil
        }

        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            let status = CGImageSourceGetStatus(source)
            print("SKResourceLoader: Failed to create image at index 0, status=\(status)")
            return nil
        }

        // Verify the image has valid dimensions and data
        if image.width == 0 || image.height == 0 {
            print("SKResourceLoader: Decoded image has zero dimensions (\(image.width)x\(image.height))")
            return nil
        }

        if image.data == nil {
            print("SKResourceLoader: WARNING - Decoded image has nil data (\(image.width)x\(image.height))")
            // Don't return nil here - the image might still be usable via dataProvider
        }

        return image
    }

    // MARK: - Texture Atlas Registration

    /// Registers a texture atlas.
    ///
    /// - Parameters:
    ///   - atlas: The atlas data containing the image and frame definitions.
    ///   - name: The name to associate with the atlas.
    public func registerAtlas(_ atlas: AtlasData, forName name: String) {
        atlasRegistry[name] = atlas
    }

    /// Registers a texture atlas from image data and frame definitions.
    ///
    /// - Parameters:
    ///   - imageData: PNG or JPEG data for the atlas image.
    ///   - frames: Dictionary mapping frame names to their rects in normalized coordinates.
    ///   - name: The name to associate with the atlas.
    public func registerAtlas(imageData: Data, frames: [String: CGRect], forName name: String) {
        if let image = decodeImage(from: imageData) {
            let atlas = AtlasData(image: image, frames: frames)
            atlasRegistry[name] = atlas
        }
    }

    /// Retrieves atlas data for a given name.
    ///
    /// - Parameter name: The name of the registered atlas.
    /// - Returns: The atlas data, or nil if not found.
    public func atlas(forName name: String) -> AtlasData? {
        return atlasRegistry[name] ?? atlasRegistry["\(name).atlas"]
    }

    // MARK: - Action Registration

    /// Registers action data for a given name.
    ///
    /// - Parameters:
    ///   - data: The action file data (property list format).
    ///   - name: The name to associate with the action.
    public func registerAction(data: Data, forName name: String) {
        actionRegistry[name] = data
    }

    /// Retrieves action data for a given name.
    public func actionData(forName name: String) -> Data? {
        return actionRegistry[name]
    }

    // MARK: - Scene Registration

    /// Registers scene data for a given name.
    ///
    /// - Parameters:
    ///   - data: The scene file data (.sks format).
    ///   - name: The name to associate with the scene.
    public func registerScene(data: Data, forName name: String) {
        sceneRegistry[name] = data
    }

    /// Retrieves scene data for a given name.
    public func sceneData(forName name: String) -> Data? {
        return sceneRegistry[name] ?? sceneRegistry["\(name).sks"]
    }

    // MARK: - Shader Registration

    /// Registers shader source code for a given name.
    ///
    /// - Parameters:
    ///   - source: The shader source code.
    ///   - name: The name to associate with the shader.
    public func registerShader(source: String, forName name: String) {
        shaderRegistry[name] = source
    }

    /// Retrieves shader source code for a given name.
    ///
    /// - Parameter name: The name of the registered shader.
    /// - Returns: The shader source code, or nil if not found.
    public func shaderSource(forName name: String) -> String? {
        // Try exact name
        if let source = shaderRegistry[name] {
            return source
        }
        // Try with common extensions
        for ext in ["fsh", "frag", "glsl", "metal"] {
            let nameWithExt = "\(name).\(ext)"
            if let source = shaderRegistry[nameWithExt] {
                return source
            }
        }
        return nil
    }

    // MARK: - TileSet Registration

    /// Registers tile set data for a given name.
    ///
    /// - Parameters:
    ///   - data: The tile set file data (.sks format).
    ///   - name: The name to associate with the tile set.
    public func registerTileSet(data: Data, forName name: String) {
        tileSetRegistry[name] = data
    }

    /// Retrieves tile set data for a given name.
    ///
    /// - Parameter name: The name of the registered tile set.
    /// - Returns: The tile set data, or nil if not found.
    public func tileSetData(forName name: String) -> Data? {
        return tileSetRegistry[name] ?? tileSetRegistry["\(name).sks"]
    }

    // MARK: - Emitter Registration

    /// Registers emitter data for a given name.
    ///
    /// - Parameters:
    ///   - data: The emitter file data (.sks format).
    ///   - name: The name to associate with the emitter.
    public func registerEmitter(data: Data, forName name: String) {
        emitterRegistry[name] = data
    }

    /// Retrieves emitter data for a given name.
    ///
    /// - Parameter name: The name of the registered emitter.
    /// - Returns: The emitter data, or nil if not found.
    public func emitterData(forName name: String) -> Data? {
        return emitterRegistry[name] ?? emitterRegistry["\(name).sks"]
    }

    // MARK: - Cache Management

    /// Clears all registered resources.
    public func clearAll() {
        imageRegistry.removeAll()
        cgImageRegistry.removeAll()
        atlasRegistry.removeAll()
        actionRegistry.removeAll()
        sceneRegistry.removeAll()
        shaderRegistry.removeAll()
        tileSetRegistry.removeAll()
        emitterRegistry.removeAll()
    }

    /// Clears only image resources.
    public func clearImages() {
        imageRegistry.removeAll()
        cgImageRegistry.removeAll()
    }

    /// Removes a specific image by name.
    public func removeImage(forName name: String) {
        imageRegistry.removeValue(forKey: name)
        cgImageRegistry.removeValue(forKey: name)
    }

    /// Removes a specific atlas by name.
    public func removeAtlas(forName name: String) {
        atlasRegistry.removeValue(forKey: name)
    }

    // MARK: - WASM URL Loading

    #if arch(wasm32)
    /// Loads an image from a URL asynchronously.
    ///
    /// - Parameters:
    ///   - url: The URL to load from.
    ///   - name: The name to register the loaded image under.
    /// - Returns: The loaded CGImage.
    public func loadImage(from url: String, as name: String) async throws -> CGImage {
        let response = try await fetch(url: url)
        guard let image = decodeImage(from: response) else {
            throw SKResourceError.decodingFailed
        }
        cgImageRegistry[name] = image
        return image
    }

    /// Fetches data from a URL using JavaScript fetch API.
    private func fetch(url: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let promise = JSObject.global.fetch.function!(url)
            _ = promise.then.function!(
                JSClosure { args in
                    let response = args[0]
                    let arrayBufferPromise = response.arrayBuffer.function!()
                    _ = arrayBufferPromise.then.function!(
                        JSClosure { bufferArgs in
                            let arrayBuffer = bufferArgs[0]
                            let uint8Array = JSObject.global.Uint8Array.function!.new(arrayBuffer)
                            let length = Int(uint8Array.length.number!)
                            var data = Data(count: length)
                            for i in 0..<length {
                                data[i] = UInt8(uint8Array[i].number!)
                            }
                            continuation.resume(returning: data)
                            return JSValue.undefined
                        }
                    )
                    return JSValue.undefined
                },
                JSClosure { _ in
                    continuation.resume(throwing: SKResourceError.networkFailed)
                    return JSValue.undefined
                }
            )
        }
    }
    #endif
}

// MARK: - Error Types

/// Errors that can occur during resource loading.
public enum SKResourceError: Error {
    case notFound
    case decodingFailed
    case networkFailed
    case invalidFormat
}

