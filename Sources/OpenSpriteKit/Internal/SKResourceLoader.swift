// SKResourceLoader.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import Synchronization
#if arch(wasm32)
import JavaScriptKit
#endif

/// Internal resource loader for OpenSpriteKit in WASM environments.
///
/// Since WASM cannot directly access bundle resources like native platforms,
/// this class provides a registry-based approach where resources can be:
/// 1. Pre-registered with raw data
/// 2. Loaded from URLs (async)
/// 3. Generated procedurally
///
/// This class is used internally by SKTexture(imageNamed:) and related APIs.
/// External code should use SKTexture(imageData:) for direct texture creation.
internal final class SKResourceLoader: Sendable {

    // MARK: - Singleton

    /// The shared resource loader instance.
    static let shared = SKResourceLoader()

    // MARK: - Properties

    private struct State: Sendable {
        var imageRegistry: [String: Data] = [:]
        var cgImageRegistry: [String: SKRegisteredImage] = [:]
        var atlasRegistry: [String: RegisteredAtlas] = [:]
        var actionRegistry: [String: Data] = [:]
        var sceneRegistry: [String: Data] = [:]
        var shaderRegistry: [String: String] = [:]
        var tileSetRegistry: [String: Data] = [:]
        var emitterRegistry: [String: Data] = [:]
    }

    private let state = Mutex(State())

    /// Atlas data structure.
    struct AtlasData {
        let image: CGImage
        let frames: [String: CGRect]  // Frame name -> rect in normalized coordinates (0-1)

        init(image: CGImage, frames: [String: CGRect]) {
            self.image = image
            self.frames = frames
        }
    }

    private struct RegisteredAtlas: Sendable {
        let image: SKRegisteredImage
        let frames: [String: CGRect]

        init?(_ atlas: AtlasData) {
            guard let image = SKRegisteredImage(atlas.image) else { return nil }
            self.image = image
            self.frames = atlas.frames
        }

        func makeAtlasData() -> AtlasData? {
            guard let image = image.makeImage() else { return nil }
            return AtlasData(image: image, frames: frames)
        }
    }

    // MARK: - Initialization

    private init() {}

    private func withLock<T: Sendable>(
        _ body: (inout sending State) throws -> sending T
    ) rethrows -> sending T {
        try state.withLock(body)
    }

    // MARK: - Cache Management

    /// Clears all registered resources.
    func clearAll() {
        withLock { state in
            state.imageRegistry.removeAll()
            state.cgImageRegistry.removeAll()
            state.atlasRegistry.removeAll()
            state.actionRegistry.removeAll()
            state.sceneRegistry.removeAll()
            state.shaderRegistry.removeAll()
            state.tileSetRegistry.removeAll()
            state.emitterRegistry.removeAll()
        }
    }

    /// Clears all registered images.
    func clearImages() {
        withLock { state in
            state.imageRegistry.removeAll()
            state.cgImageRegistry.removeAll()
        }
    }

    /// Clears all registered texture atlases.
    func clearAtlases() {
        withLock { state in
            state.atlasRegistry.removeAll()
        }
    }

    /// Clears all registered actions.
    func clearActions() {
        withLock { state in
            state.actionRegistry.removeAll()
        }
    }

    /// Clears all registered scenes.
    func clearScenes() {
        withLock { state in
            state.sceneRegistry.removeAll()
        }
    }

    /// Clears all registered shaders.
    func clearShaders() {
        withLock { state in
            state.shaderRegistry.removeAll()
        }
    }

    /// Clears all registered tile sets.
    func clearTileSets() {
        withLock { state in
            state.tileSetRegistry.removeAll()
        }
    }

    /// Clears all registered emitters.
    func clearEmitters() {
        withLock { state in
            state.emitterRegistry.removeAll()
        }
    }

    /// Returns counts of registered resource types (for diagnostics).
    func resourceCounts() -> String {
        withLock { state in
            "images=\(state.imageRegistry.count + state.cgImageRegistry.count) atlases=\(state.atlasRegistry.count) actions=\(state.actionRegistry.count) scenes=\(state.sceneRegistry.count) shaders=\(state.shaderRegistry.count) tilesets=\(state.tileSetRegistry.count) emitters=\(state.emitterRegistry.count)"
        }
    }

    // MARK: - Image Registration

    /// Registers image data for a given name.
    ///
    /// - Parameters:
    ///   - data: PNG or JPEG image data.
    ///   - name: The name to associate with the image.
    func registerImage(data: Data, forName name: String) {
        withLock { state in
            state.imageRegistry[name] = data
        }
    }

    /// Registers a CGImage for a given name.
    ///
    /// - Parameters:
    ///   - image: The CGImage to register.
    ///   - name: The name to associate with the image.
    func registerImage(_ image: CGImage, forName name: String) {
        guard let image = SKRegisteredImage(image) else {
            SKDiagnostics.logWarning("Unable to register image without owned pixel data: \(name)")
            return
        }
        withLock { state in
            state.cgImageRegistry[name] = image
        }
    }

    /// Retrieves a CGImage for a given name.
    ///
    /// - Parameter name: The name of the registered image.
    /// - Returns: The CGImage, or nil if not found.
    func image(forName name: String) -> CGImage? {
        let resource = withLock { state -> (SKRegisteredImage?, Data?) in
            if let image = state.cgImageRegistry[name] {
                return (image, nil)
            }
            if let data = state.imageRegistry[name] {
                return (nil, data)
            }
            for ext in ["png", "jpg", "jpeg"] {
                let nameWithExt = name.hasSuffix(".\(ext)") ? name : "\(name).\(ext)"
                if let data = state.imageRegistry[nameWithExt] {
                    return (nil, data)
                }
            }
            return (nil, nil)
        }
        if let image = resource.0 { return image.makeImage() }
        return resource.1.flatMap(decodeImage)
    }

    /// Decodes image data to CGImage.
    ///
    /// Supports PNG, JPEG, GIF, BMP, and TIFF formats via ImageIO/OpenImageIO.
    private func decodeImage(from data: Data) -> CGImage? {
        // CGImageSourceCreateWithData is available via OpenImageIO
        // Supports PNG, JPEG, GIF, BMP, and TIFF
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
    func registerAtlas(_ atlas: AtlasData, forName name: String) {
        guard let atlas = RegisteredAtlas(atlas) else {
            SKDiagnostics.logWarning("Unable to register atlas without owned pixel data: \(name)")
            return
        }
        withLock { state in
            state.atlasRegistry[name] = atlas
        }
    }

    /// Registers a texture atlas from image data and frame definitions.
    ///
    /// - Parameters:
    ///   - imageData: PNG or JPEG data for the atlas image.
    ///   - frames: Dictionary mapping frame names to their rects in normalized coordinates.
    ///   - name: The name to associate with the atlas.
    func registerAtlas(imageData: Data, frames: [String: CGRect], forName name: String) {
        if let image = decodeImage(from: imageData) {
            let atlas = AtlasData(image: image, frames: frames)
            registerAtlas(atlas, forName: name)
        }
    }

    /// Retrieves atlas data for a given name.
    ///
    /// - Parameter name: The name of the registered atlas.
    /// - Returns: The atlas data, or nil if not found.
    func atlas(forName name: String) -> AtlasData? {
        let atlas = withLock { state in
            state.atlasRegistry[name] ?? state.atlasRegistry["\(name).atlas"]
        }
        return atlas?.makeAtlasData()
    }

    // MARK: - Action Registration

    /// Registers action data for a given name.
    ///
    /// - Parameters:
    ///   - data: The action file data (property list format).
    ///   - name: The name to associate with the action.
    func registerAction(data: Data, forName name: String) {
        withLock { state in
            state.actionRegistry[name] = data
        }
    }

    /// Retrieves action data for a given name.
    func actionData(forName name: String) -> Data? {
        withLock { state in
            state.actionRegistry[name]
        }
    }

    // MARK: - Scene Registration

    /// Registers scene data for a given name.
    ///
    /// - Parameters:
    ///   - data: The scene file data (.sks format).
    ///   - name: The name to associate with the scene.
    func registerScene(data: Data, forName name: String) {
        withLock { state in
            state.sceneRegistry[name] = data
        }
    }

    /// Retrieves scene data for a given name.
    func sceneData(forName name: String) -> Data? {
        withLock { state in
            state.sceneRegistry[name] ?? state.sceneRegistry["\(name).sks"]
        }
    }

    // MARK: - Shader Registration

    /// Registers shader source code for a given name.
    ///
    /// - Parameters:
    ///   - source: The shader source code.
    ///   - name: The name to associate with the shader.
    func registerShader(source: String, forName name: String) {
        withLock { state in
            state.shaderRegistry[name] = source
        }
    }

    /// Retrieves shader source code for a given name.
    ///
    /// - Parameter name: The name of the registered shader.
    /// - Returns: The shader source code, or nil if not found.
    func shaderSource(forName name: String) -> String? {
        withLock { state in
            // Try exact name
            if let source = state.shaderRegistry[name] {
                return source
            }
            // Try with common extensions
            for ext in ["fsh", "frag", "glsl", "metal"] {
                let nameWithExt = "\(name).\(ext)"
                if let source = state.shaderRegistry[nameWithExt] {
                    return source
                }
            }
            return nil
        }
    }

    // MARK: - TileSet Registration

    /// Registers tile set data for a given name.
    ///
    /// - Parameters:
    ///   - data: The tile set file data (.sks format).
    ///   - name: The name to associate with the tile set.
    func registerTileSet(data: Data, forName name: String) {
        withLock { state in
            state.tileSetRegistry[name] = data
        }
    }

    /// Retrieves tile set data for a given name.
    ///
    /// - Parameter name: The name of the registered tile set.
    /// - Returns: The tile set data, or nil if not found.
    func tileSetData(forName name: String) -> Data? {
        withLock { state in
            state.tileSetRegistry[name] ?? state.tileSetRegistry["\(name).sks"]
        }
    }

    // MARK: - Emitter Registration

    /// Registers emitter data for a given name.
    ///
    /// - Parameters:
    ///   - data: The emitter file data (.sks format).
    ///   - name: The name to associate with the emitter.
    func registerEmitter(data: Data, forName name: String) {
        withLock { state in
            state.emitterRegistry[name] = data
        }
    }

    /// Retrieves emitter data for a given name.
    ///
    /// - Parameter name: The name of the registered emitter.
    /// - Returns: The emitter data, or nil if not found.
    func emitterData(forName name: String) -> Data? {
        withLock { state in
            state.emitterRegistry[name] ?? state.emitterRegistry["\(name).sks"]
        }
    }

    // MARK: - WASM URL Loading

    #if arch(wasm32)
    /// Loads an image from a URL asynchronously.
    ///
    /// - Parameters:
    ///   - url: The URL to load from.
    ///   - name: The name to register the loaded image under.
    /// - Returns: The loaded CGImage.
    func loadImage(from url: String, as name: String) async throws -> CGImage {
        let response = try await fetch(url: url)
        guard let image = decodeImage(from: response) else {
            throw SKResourceError.decodingFailed
        }
        guard let registeredImage = SKRegisteredImage(image) else {
            throw SKResourceError.decodingFailed
        }
        withLock { state in
            state.cgImageRegistry[name] = registeredImage
        }
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
enum SKResourceError: Error {
    case notFound
    case decodingFailed
    case networkFailed
    case invalidFormat
}
