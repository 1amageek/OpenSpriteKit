// SKTextureAtlas.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A collection of textures optimized for storage and drawing performance.
///
/// An `SKTextureAtlas` is a collection of textures that were either created from an `.atlas`
/// folder in the app bundle, or created at runtime. Texture atlases improve memory usage and
/// rendering performance by reducing draw calls. Whenever you have textures that are always
/// used together, store them in an atlas for best results.
///
/// ## Example
/// ```swift
/// // Create atlas from a dictionary of images
/// let atlas = SKTextureAtlas(dictionary: [
///     "player_idle": playerIdleImage,
///     "player_run": playerRunImage,
///     "player_jump": playerJumpImage
/// ])
///
/// // Get a texture from the atlas
/// let idleTexture = atlas.textureNamed("player_idle")
/// ```
open class SKTextureAtlas: @unchecked Sendable {

    // MARK: - Properties

    /// The names of the texture images stored in the atlas.
    open private(set) var textureNames: [String] = []

    /// Internal storage for textures by name.
    private var textures: [String: SKTexture] = [:]

    /// The source texture that contains all atlas images (if using a packed atlas).
    private var sourceTexture: SKTexture?

    /// Atlas metadata for named atlases.
    private var atlasName: String?

    /// Whether the atlas has been preloaded.
    private var isPreloaded: Bool = false

    // MARK: - Initializers

    /// Creates an empty texture atlas.
    public init() {
    }

    /// Creates a texture atlas from data stored in the app bundle.
    ///
    /// This initializer looks for an `.atlas` folder or asset catalog sprite atlas
    /// with the specified name in the app bundle.
    ///
    /// - Parameter name: The name of the texture atlas in the app bundle.
    public convenience init(named name: String) {
        self.init()
        self.atlasName = name
        // In WASM environment, atlas loading is handled differently
        // The actual texture data would be loaded via resource loader
    }

    /// Creates a texture atlas from a set of image files.
    ///
    /// Use this initializer to create a texture atlas at runtime from a dictionary
    /// of images. The keys are the texture names and the values are the source images.
    ///
    /// - Parameter dictionary: A dictionary where keys are texture names and values
    ///   are either `CGImage` objects, `SKTexture` objects, or image data.
    public convenience init(dictionary: [String: Any]) {
        self.init()

        for (name, value) in dictionary {
            if let texture = value as? SKTexture {
                textures[name] = texture
                textureNames.append(name)
            } else if let cgImage = value as? CGImage {
                let texture = SKTexture(cgImage: cgImage)
                textures[name] = texture
                textureNames.append(name)
            } else if let data = value as? Data {
                // Use imageData initializer which decodes image format and determines size
                if let texture = SKTexture(imageData: data) {
                    textures[name] = texture
                    textureNames.append(name)
                }
            }
        }

        textureNames.sort()
    }

    /// Creates a texture atlas from a sprite sheet with frame definitions.
    ///
    /// - Parameters:
    ///   - texture: The source sprite sheet texture.
    ///   - frames: A dictionary mapping texture names to their normalized rectangles (0-1 coordinates).
    public convenience init(texture: SKTexture, frames: [String: CGRect]) {
        self.init()
        self.sourceTexture = texture

        for (name, rect) in frames {
            let subTexture = SKTexture(rect: rect, in: texture)
            textures[name] = subTexture
            textureNames.append(name)
        }

        textureNames.sort()
    }

    // MARK: - Accessing Textures

    /// Creates a texture from data stored in the texture atlas.
    ///
    /// - Parameter name: The name of the texture to retrieve.
    /// - Returns: The texture with the specified name. If no texture exists with that name,
    ///   returns a placeholder texture.
    open func textureNamed(_ name: String) -> SKTexture {
        // Return cached texture if available
        if let texture = textures[name] {
            return texture
        }

        // For named atlases, try to load the texture
        if let atlasName = atlasName {
            // Construct the full resource name
            let resourceName = "\(atlasName)/\(name)"

            // Try to load from resources
            // In WASM environment, this would use SKResourceLoader
            let texture = SKTexture(imageNamed: resourceName)
            textures[name] = texture
            if !textureNames.contains(name) {
                textureNames.append(name)
                textureNames.sort()
            }
            return texture
        }

        // Return a placeholder texture if not found
        // Create a small colored texture as placeholder
        let placeholderTexture = SKTexture()
        textures[name] = placeholderTexture
        return placeholderTexture
    }

    // MARK: - Preloading

    /// Loads an atlas object's textures into memory, calling a completion handler after the task completes.
    ///
    /// Preloading textures can improve performance by ensuring all textures are decoded
    /// and ready before they're needed for rendering.
    ///
    /// - Parameter completionHandler: A block called when preloading completes.
    open func preload(completionHandler: @escaping @Sendable () -> Void) {
        guard !isPreloaded else {
            completionHandler()
            return
        }

        // Preload all textures
        let allTextures = Array(textures.values)

        if allTextures.isEmpty {
            isPreloaded = true
            completionHandler()
            return
        }

        SKTexture.preload(allTextures) { [weak self] in
            self?.isPreloaded = true
            completionHandler()
        }
    }

    /// Loads the textures of multiple atlas objects into memory, calling a completion handler after the task completes.
    ///
    /// - Parameters:
    ///   - atlases: An array of texture atlases to preload.
    ///   - completionHandler: A block called when all atlases have been preloaded.
    public class func preloadTextureAtlases(_ atlases: [SKTextureAtlas], withCompletionHandler completionHandler: @escaping @Sendable () -> Void) {
        guard !atlases.isEmpty else {
            completionHandler()
            return
        }

        #if arch(wasm32)
        // WASM: Simple counter-based implementation (no GCD available)
        final class Counter: @unchecked Sendable {
            var count: Int
            let total: Int
            let completion: @Sendable () -> Void

            init(total: Int, completion: @escaping @Sendable () -> Void) {
                self.count = 0
                self.total = total
                self.completion = completion
            }

            func increment() {
                count += 1
                if count >= total {
                    completion()
                }
            }
        }

        let counter = Counter(total: atlases.count, completion: completionHandler)

        for atlas in atlases {
            atlas.preload {
                counter.increment()
            }
        }
        #else
        // Native: Use DispatchGroup for thread-safe coordination
        let group = DispatchGroup()

        for atlas in atlases {
            group.enter()
            atlas.preload {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completionHandler()
        }
        #endif
    }

    /// Loads the textures of multiple atlases into memory, calling a completion handler after the task completes.
    ///
    /// - Parameters:
    ///   - atlasNames: An array of atlas names to load and preload.
    ///   - completionHandler: A block called when all atlases have been loaded and preloaded.
    ///     The block receives an optional error and the loaded atlases.
    public class func preloadTextureAtlasesNamed(_ atlasNames: [String], withCompletionHandler completionHandler: @escaping @Sendable ((any Error)?, [SKTextureAtlas]) -> Void) {
        guard !atlasNames.isEmpty else {
            completionHandler(nil, [])
            return
        }

        let loadedAtlases: [SKTextureAtlas] = atlasNames.map { SKTextureAtlas(named: $0) }

        preloadTextureAtlases(loadedAtlases) {
            completionHandler(nil, loadedAtlases)
        }
    }

    // MARK: - Atlas Management

    /// Adds a texture to the atlas with the specified name.
    ///
    /// - Parameters:
    ///   - texture: The texture to add.
    ///   - name: The name to associate with the texture.
    open func addTexture(_ texture: SKTexture, named name: String) {
        textures[name] = texture
        if !textureNames.contains(name) {
            textureNames.append(name)
            textureNames.sort()
        }
    }

    /// Removes a texture from the atlas.
    ///
    /// - Parameter name: The name of the texture to remove.
    open func removeTexture(named name: String) {
        textures.removeValue(forKey: name)
        textureNames.removeAll { $0 == name }
    }

    /// Returns whether the atlas contains a texture with the specified name.
    ///
    /// - Parameter name: The name to check.
    /// - Returns: `true` if the atlas contains a texture with that name.
    open func containsTexture(named name: String) -> Bool {
        return textures[name] != nil
    }

    /// The number of textures in the atlas.
    open var count: Int {
        return textures.count
    }

    // MARK: - Convenience Methods

    /// Creates an array of textures from the atlas for animation.
    ///
    /// - Parameter names: The names of the textures to retrieve, in order.
    /// - Returns: An array of textures in the specified order.
    open func textures(named names: [String]) -> [SKTexture] {
        return names.compactMap { textures[$0] }
    }

    /// Creates an array of all textures in the atlas, sorted by name.
    ///
    /// - Returns: An array of all textures in the atlas.
    open func allTextures() -> [SKTexture] {
        return textureNames.compactMap { textures[$0] }
    }
}

// MARK: - SKTextureAtlas Loading from JSON

extension SKTextureAtlas {

    /// Creates a texture atlas from an Aseprite-style JSON definition.
    ///
    /// - Parameters:
    ///   - jsonData: The JSON data defining frame rectangles.
    ///   - texture: The source sprite sheet texture.
    /// - Returns: A configured texture atlas, or nil if parsing fails.
    public static func atlas(fromJSON jsonData: Data, texture: SKTexture) -> SKTextureAtlas? {
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let framesData = json["frames"] as? [[String: Any]] else {
            return nil
        }

        let textureSize = texture.size()
        var frames: [String: CGRect] = [:]

        for frameData in framesData {
            guard let filename = frameData["filename"] as? String,
                  let frameInfo = frameData["frame"] as? [String: Int],
                  let x = frameInfo["x"],
                  let y = frameInfo["y"],
                  let w = frameInfo["w"],
                  let h = frameInfo["h"] else {
                continue
            }

            // Convert to normalized coordinates (0-1)
            let normalizedRect = CGRect(
                x: CGFloat(x) / textureSize.width,
                y: CGFloat(y) / textureSize.height,
                width: CGFloat(w) / textureSize.width,
                height: CGFloat(h) / textureSize.height
            )

            // Remove file extension from filename for texture name
            let name = (filename as NSString).deletingPathExtension
            frames[name] = normalizedRect
        }

        return SKTextureAtlas(texture: texture, frames: frames)
    }

    /// Creates a texture atlas from a grid-based sprite sheet.
    ///
    /// - Parameters:
    ///   - texture: The source sprite sheet texture.
    ///   - columns: Number of columns in the grid.
    ///   - rows: Number of rows in the grid.
    ///   - names: Optional names for each frame. If nil, uses "frame_0", "frame_1", etc.
    /// - Returns: A configured texture atlas.
    public static func atlas(fromGridTexture texture: SKTexture, columns: Int, rows: Int, names: [String]? = nil) -> SKTextureAtlas {
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)

        var frames: [String: CGRect] = [:]
        var index = 0

        for row in 0..<rows {
            for col in 0..<columns {
                let rect = CGRect(
                    x: CGFloat(col) * frameWidth,
                    y: CGFloat(row) * frameHeight,
                    width: frameWidth,
                    height: frameHeight
                )

                let name: String
                if let names = names, index < names.count {
                    name = names[index]
                } else {
                    name = "frame_\(index)"
                }

                frames[name] = rect
                index += 1
            }
        }

        return SKTextureAtlas(texture: texture, frames: frames)
    }
}
