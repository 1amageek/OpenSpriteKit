// SKTexture.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// An object that manages the data for a texture used in SpriteKit rendering.
///
/// An `SKTexture` object is a container for texture data. Textures hold image data
/// and can be applied to sprites or other nodes that need to render images.
open class SKTexture: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Properties

    /// The size of the texture in points.
    open var size: CGSize {
        return _size
    }
    internal var _size: CGSize = .zero

    /// The rectangle within the texture that defines the visible region.
    open var textureRect: CGRect {
        return _textureRect
    }
    private var _textureRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// The filtering mode used when the texture is drawn in a size other than its native size.
    open var filteringMode: SKTextureFilteringMode = .linear

    /// A Boolean value that indicates whether mipmaps are generated for the texture.
    open var usesMipmaps: Bool = false

    /// The underlying CGImage if available.
    open private(set) var cgImage: CGImage?

    // MARK: - Initializers

    /// Creates an empty texture.
    public override init() {
        super.init()
    }

    /// Creates a texture from an image file.
    ///
    /// - Parameter name: The name of the image file in the app bundle.
    ///
    /// On WASM platforms, the image must be pre-registered with `SKResourceLoader`:
    /// ```swift
    /// SKResourceLoader.shared.registerImage(data: pngData, forName: "player")
    /// let texture = SKTexture(imageNamed: "player")
    /// ```
    public init(imageNamed name: String) {
        super.init()
        if let image = SKResourceLoader.shared.image(forName: name) {
            self.cgImage = image
            self._size = CGSize(width: image.width, height: image.height)
        }
    }

    /// Creates a texture from a CGImage.
    ///
    /// - Parameter cgImage: The Core Graphics image to use as the texture source.
    public init(cgImage: CGImage) {
        self.cgImage = cgImage
        self._size = CGSize(width: cgImage.width, height: cgImage.height)
        super.init()
    }

    /// Creates a texture from raw RGBA image data.
    ///
    /// - Parameters:
    ///   - data: Raw RGBA pixel data (4 bytes per pixel).
    ///   - size: The size of the texture in pixels.
    public init(data: Data, size: CGSize) {
        self._size = size
        super.init()
        self.cgImage = Self.createCGImage(from: data, size: size, flipped: false)
    }

    /// Creates a texture from raw RGBA image data with optional vertical flip.
    ///
    /// - Parameters:
    ///   - data: Raw RGBA pixel data (4 bytes per pixel).
    ///   - size: The size of the texture in pixels.
    ///   - flipped: Whether the image should be flipped vertically.
    public init(data: Data, size: CGSize, flipped: Bool) {
        self._size = size
        super.init()
        self.cgImage = Self.createCGImage(from: data, size: size, flipped: flipped)
    }

    /// Creates a texture from raw image data with a specific row alignment.
    ///
    /// - Parameters:
    ///   - data: Raw pixel data.
    ///   - size: The size of the texture in pixels.
    ///   - rowLength: The number of pixels in a row (may include padding).
    ///   - alignment: The byte alignment of each row.
    public init(data: Data, size: CGSize, rowLength: UInt32, alignment: UInt32) {
        self._size = size
        super.init()
        self.cgImage = Self.createCGImage(from: data, size: size, rowLength: Int(rowLength), alignment: Int(alignment))
    }

    /// Creates a CGImage from raw RGBA data.
    private static func createCGImage(from data: Data, size: CGSize, flipped: Bool) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixelData = data
        if flipped {
            pixelData = flipImageVertically(data: data, width: width, height: height, bytesPerRow: bytesPerRow)
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: pixelData as CFData)!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Creates a CGImage from raw data with custom row length and alignment.
    private static func createCGImage(from data: Data, size: CGSize, rowLength: Int, alignment: Int) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4

        // Calculate aligned bytes per row
        let unalignedBytesPerRow = rowLength * bytesPerPixel
        let alignedBytesPerRow = ((unalignedBytesPerRow + alignment - 1) / alignment) * alignment

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: alignedBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: data as CFData)!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Flips image data vertically.
    private static func flipImageVertically(data: Data, width: Int, height: Int, bytesPerRow: Int) -> Data {
        var flipped = Data(count: data.count)
        data.withUnsafeBytes { src in
            flipped.withUnsafeMutableBytes { dst in
                for y in 0..<height {
                    let srcOffset = y * bytesPerRow
                    let dstOffset = (height - 1 - y) * bytesPerRow
                    memcpy(dst.baseAddress! + dstOffset, src.baseAddress! + srcOffset, bytesPerRow)
                }
            }
        }
        return flipped
    }

    /// Creates a texture that represents a rectangular portion of another texture.
    ///
    /// - Parameters:
    ///   - rect: A rectangle in unit coordinate space specifying the portion of the texture.
    ///   - texture: The source texture.
    public init(rect: CGRect, in texture: SKTexture) {
        self._textureRect = rect
        self._size = CGSize(
            width: texture.size.width * rect.width,
            height: texture.size.height * rect.height
        )
        super.init()
    }

    /// Creates a texture from a CIImage.
    ///
    /// - Parameter image: The Core Image image to use as the texture source.
    public init(image: CIImage) {
        self._size = image.extent.size
        super.init()
        // Render CIImage to CGImage
        let context = CIContext()
        if let cgImage = context.createCGImage(image, from: image.extent) {
            self.cgImage = cgImage
        }
    }

    /// Creates a texture with a noise pattern.
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the noise (0.0 = rough, 1.0 = smooth).
    ///   - size: The size of the texture.
    ///   - grayscale: Whether the noise should be grayscale.
    /// - Returns: A texture containing procedurally generated noise.
    public class func noiseTexture(withSmoothness smoothness: CGFloat, size: CGSize, grayscale: Bool) -> SKTexture {
        let texture = SKTexture()
        texture._size = size

        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        var pixelData = Data(count: width * height * bytesPerPixel)

        // Generate Perlin-like noise
        let scale = max(0.01, 1.0 - Double(smoothness)) * 8.0  // Higher smoothness = larger scale = smoother
        let octaves = Int(1 + (1.0 - Double(smoothness)) * 4)  // More octaves for rougher noise

        pixelData.withUnsafeMutableBytes { buffer in
            let pixels = buffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * bytesPerPixel

                    if grayscale {
                        let noise = perlinNoise(x: Double(x) * scale / Double(width),
                                               y: Double(y) * scale / Double(height),
                                               octaves: octaves)
                        let value = UInt8(max(0, min(255, Int((noise + 1.0) * 127.5))))
                        pixels[offset] = value      // R
                        pixels[offset + 1] = value  // G
                        pixels[offset + 2] = value  // B
                        pixels[offset + 3] = 255    // A
                    } else {
                        let r = perlinNoise(x: Double(x) * scale / Double(width),
                                           y: Double(y) * scale / Double(height),
                                           octaves: octaves, seed: 0)
                        let g = perlinNoise(x: Double(x) * scale / Double(width),
                                           y: Double(y) * scale / Double(height),
                                           octaves: octaves, seed: 1000)
                        let b = perlinNoise(x: Double(x) * scale / Double(width),
                                           y: Double(y) * scale / Double(height),
                                           octaves: octaves, seed: 2000)
                        pixels[offset] = UInt8(max(0, min(255, Int((r + 1.0) * 127.5))))
                        pixels[offset + 1] = UInt8(max(0, min(255, Int((g + 1.0) * 127.5))))
                        pixels[offset + 2] = UInt8(max(0, min(255, Int((b + 1.0) * 127.5))))
                        pixels[offset + 3] = 255
                    }
                }
            }
        }

        texture.cgImage = createCGImage(from: pixelData, size: size, flipped: false)
        return texture
    }

    /// Creates a texture with a vector noise pattern (for normal maps).
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the noise (0.0 = rough, 1.0 = smooth).
    ///   - size: The size of the texture.
    /// - Returns: A texture containing vector noise suitable for normal mapping.
    public class func vectorNoiseTexture(withSmoothness smoothness: CGFloat, size: CGSize) -> SKTexture {
        let texture = SKTexture()
        texture._size = size

        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        var pixelData = Data(count: width * height * bytesPerPixel)

        let scale = max(0.01, 1.0 - Double(smoothness)) * 8.0
        let octaves = Int(1 + (1.0 - Double(smoothness)) * 4)

        pixelData.withUnsafeMutableBytes { buffer in
            let pixels = buffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * bytesPerPixel

                    // Generate 3D noise for vector components
                    let nx = perlinNoise(x: Double(x) * scale / Double(width),
                                        y: Double(y) * scale / Double(height),
                                        octaves: octaves, seed: 0)
                    let ny = perlinNoise(x: Double(x) * scale / Double(width),
                                        y: Double(y) * scale / Double(height),
                                        octaves: octaves, seed: 1000)
                    let nz = perlinNoise(x: Double(x) * scale / Double(width),
                                        y: Double(y) * scale / Double(height),
                                        octaves: octaves, seed: 2000)

                    // Normalize and encode as RGB (normal map format)
                    let length = Foundation.sqrt(nx * nx + ny * ny + nz * nz)
                    let normalizedX = length > 0 ? nx / length : 0
                    let normalizedY = length > 0 ? ny / length : 0
                    let normalizedZ = length > 0 ? nz / length : 1

                    pixels[offset] = UInt8((normalizedX + 1.0) * 127.5)      // R = X
                    pixels[offset + 1] = UInt8((normalizedY + 1.0) * 127.5)  // G = Y
                    pixels[offset + 2] = UInt8((normalizedZ + 1.0) * 127.5)  // B = Z
                    pixels[offset + 3] = 255                                  // A
                }
            }
        }

        texture.cgImage = createCGImage(from: pixelData, size: size, flipped: false)
        return texture
    }

    // MARK: - Perlin Noise Implementation

    /// Generates Perlin noise at a given position.
    private class func perlinNoise(x: Double, y: Double, octaves: Int, seed: Int = 0) -> Double {
        var result = 0.0
        var amplitude = 1.0
        var frequency = 1.0
        var maxValue = 0.0

        for _ in 0..<octaves {
            result += noise2D(x: x * frequency + Double(seed), y: y * frequency) * amplitude
            maxValue += amplitude
            amplitude *= 0.5
            frequency *= 2.0
        }

        return result / maxValue
    }

    /// 2D noise function using value noise approximation.
    private class func noise2D(x: Double, y: Double) -> Double {
        let xi = Int(Foundation.floor(x))
        let yi = Int(Foundation.floor(y))
        let xf = x - Foundation.floor(x)
        let yf = y - Foundation.floor(y)

        // Smoothstep interpolation
        let u = xf * xf * (3.0 - 2.0 * xf)
        let v = yf * yf * (3.0 - 2.0 * yf)

        // Hash corners
        let aa = hash2D(x: xi, y: yi)
        let ab = hash2D(x: xi, y: yi + 1)
        let ba = hash2D(x: xi + 1, y: yi)
        let bb = hash2D(x: xi + 1, y: yi + 1)

        // Bilinear interpolation
        let x1 = lerp(a: aa, b: ba, t: u)
        let x2 = lerp(a: ab, b: bb, t: u)
        return lerp(a: x1, b: x2, t: v)
    }

    /// Hash function for noise generation.
    private class func hash2D(x: Int, y: Int) -> Double {
        var n = x + y * 57
        n = (n << 13) ^ n
        let m = (n &* (n &* n &* 15731 &+ 789221) &+ 1376312589) & 0x7fffffff
        return Double(m) / Double(0x7fffffff) * 2.0 - 1.0
    }

    /// Linear interpolation.
    private class func lerp(a: Double, b: Double, t: Double) -> Double {
        return a + t * (b - a)
    }

    public required init?(coder: NSCoder) {
        _size = CGSize(
            width: CGFloat(coder.decodeDouble(forKey: "size.width")),
            height: CGFloat(coder.decodeDouble(forKey: "size.height"))
        )
        _textureRect = CGRect(
            x: CGFloat(coder.decodeDouble(forKey: "textureRect.x")),
            y: CGFloat(coder.decodeDouble(forKey: "textureRect.y")),
            width: CGFloat(coder.decodeDouble(forKey: "textureRect.width")),
            height: CGFloat(coder.decodeDouble(forKey: "textureRect.height"))
        )
        filteringMode = SKTextureFilteringMode(rawValue: coder.decodeInteger(forKey: "filteringMode")) ?? .linear
        usesMipmaps = coder.decodeBool(forKey: "usesMipmaps")
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(Double(_size.width), forKey: "size.width")
        coder.encode(Double(_size.height), forKey: "size.height")
        coder.encode(Double(_textureRect.origin.x), forKey: "textureRect.x")
        coder.encode(Double(_textureRect.origin.y), forKey: "textureRect.y")
        coder.encode(Double(_textureRect.size.width), forKey: "textureRect.width")
        coder.encode(Double(_textureRect.size.height), forKey: "textureRect.height")
        coder.encode(filteringMode.rawValue, forKey: "filteringMode")
        coder.encode(usesMipmaps, forKey: "usesMipmaps")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKTexture()
        copy._size = _size
        copy._textureRect = _textureRect
        copy.filteringMode = filteringMode
        copy.usesMipmaps = usesMipmaps
        copy.cgImage = cgImage
        return copy
    }

    // MARK: - Texture Operations

    /// Preloads texture data into memory.
    ///
    /// This ensures the texture's CGImage is decoded and ready for rendering.
    ///
    /// - Parameter completionHandler: A block called when preloading is complete.
    open func preload(completionHandler: @escaping () -> Void) {
        // Force decode the CGImage if present
        if let cgImage = self.cgImage {
            // Access pixel data to force decoding
            _ = cgImage.width
            _ = cgImage.height
        }
        completionHandler()
    }

    /// Preloads multiple textures into memory.
    ///
    /// - Parameters:
    ///   - textures: The textures to preload.
    ///   - completionHandler: A block called when preloading is complete.
    public class func preload(_ textures: [SKTexture], withCompletionHandler completionHandler: @escaping () -> Void) {
        // Preload all textures
        let group = DispatchGroup()
        for texture in textures {
            group.enter()
            texture.preload {
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completionHandler()
        }
    }

    /// Returns a new texture by applying a Core Image filter.
    ///
    /// - Parameter filter: The filter to apply.
    /// - Returns: A new texture with the filter applied.
    open func applying(_ filter: CIFilter) -> SKTexture {
        guard let cgImage = self.cgImage else {
            return self.copy() as! SKTexture
        }

        // Create CIImage from CGImage
        let inputImage = CIImage(cgImage: cgImage)

        // Apply filter
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else {
            return self.copy() as! SKTexture
        }

        // Render filtered image to CGImage
        let context = CIContext()
        guard let filteredCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return self.copy() as! SKTexture
        }

        // Create new texture with filtered image
        let newTexture = SKTexture(cgImage: filteredCGImage)
        newTexture.filteringMode = self.filteringMode
        newTexture.usesMipmaps = self.usesMipmaps
        return newTexture
    }

    /// Returns the CGImage representation of this texture.
    ///
    /// - Returns: A CGImage, or nil if the texture cannot be converted.
    open func getCGImage() -> CGImage? {
        return cgImage
    }
}

// MARK: - SKTextureFilteringMode

/// Texture filtering modes to use when the texture is drawn in a size other than its native size.
public enum SKTextureFilteringMode: Int, Sendable, Hashable {
    /// Each pixel is drawn using the nearest point in the texture.
    /// This mode is faster but results in blocky textures when enlarged.
    case nearest = 0

    /// Each pixel is drawn using a linear interpolation of the surrounding pixels.
    /// This mode produces smoother results but is more computationally expensive.
    case linear = 1
}

// MARK: - SKTextureAtlas

/// A collection of related textures stored together for efficient access.
///
/// An `SKTextureAtlas` object lets you store multiple textures together as a single
/// resource. Using a texture atlas can improve rendering performance.
open class SKTextureAtlas: NSObject, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Properties

    /// The names of all textures in the atlas.
    open var textureNames: [String] = []

    private var textures: [String: SKTexture] = [:]

    // MARK: - Initializers

    /// Creates an empty texture atlas.
    public override init() {
        super.init()
    }

    /// Creates a texture atlas from a dictionary of textures.
    ///
    /// - Parameter dictionary: A dictionary mapping texture names to CGImages or SKTextures.
    public init(dictionary: [String: Any]) {
        super.init()
        for (name, value) in dictionary {
            if let texture = value as? SKTexture {
                textures[name] = texture
                textureNames.append(name)
            } else if CFGetTypeID(value as CFTypeRef) == CGImage.typeID {
                // Handle CGImage (CoreFoundation type)
                let cgImage = value as! CGImage
                let texture = SKTexture(cgImage: cgImage)
                textures[name] = texture
                textureNames.append(name)
            } else if let data = value as? Data {
                if let image = SKResourceLoader.shared.image(forName: name) {
                    let texture = SKTexture(cgImage: image)
                    textures[name] = texture
                    textureNames.append(name)
                }
            }
        }
    }

    /// Creates a texture atlas from a named atlas in the app bundle.
    ///
    /// On WASM platforms, the atlas must be pre-registered with `SKResourceLoader`:
    /// ```swift
    /// let atlasData = SKResourceLoader.AtlasData(
    ///     image: cgImage,
    ///     frames: ["frame1": CGRect(x: 0, y: 0, width: 0.5, height: 0.5), ...]
    /// )
    /// SKResourceLoader.shared.registerAtlas(atlasData, forName: "myAtlas")
    /// let atlas = SKTextureAtlas(named: "myAtlas")
    /// ```
    ///
    /// - Parameter name: The name of the texture atlas.
    public init(named name: String) {
        super.init()
        if let atlasData = SKResourceLoader.shared.atlas(forName: name) {
            loadFromAtlasData(atlasData)
        }
    }

    /// Loads textures from atlas data.
    private func loadFromAtlasData(_ data: SKResourceLoader.AtlasData) {
        let atlasTexture = SKTexture(cgImage: data.image)
        let atlasSize = atlasTexture.size

        for (frameName, normalizedRect) in data.frames {
            // Create sub-texture using normalized coordinates
            let subTexture = SKTexture(rect: normalizedRect, in: atlasTexture)
            textures[frameName] = subTexture
            textureNames.append(frameName)
        }
    }

    public required init?(coder: NSCoder) {
        textureNames = coder.decodeObject(forKey: "textureNames") as? [String] ?? []
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(textureNames, forKey: "textureNames")
    }

    // MARK: - Texture Access

    /// Returns a texture with the specified name.
    ///
    /// - Parameter name: The name of the texture.
    /// - Returns: The texture, or a placeholder if not found.
    open func textureNamed(_ name: String) -> SKTexture {
        if let texture = textures[name] {
            return texture
        }
        // Return a placeholder texture
        return SKTexture()
    }

    // MARK: - Preloading

    /// Preloads the texture atlas into memory.
    ///
    /// - Parameter completionHandler: A block called when preloading is complete.
    open func preload(completionHandler: @escaping () -> Void) {
        // Preload all textures in the atlas
        let allTextures = textures.values.map { $0 }
        SKTexture.preload(allTextures, withCompletionHandler: completionHandler)
    }

    /// Preloads multiple texture atlases into memory.
    ///
    /// - Parameters:
    ///   - atlases: The atlases to preload.
    ///   - completionHandler: A block called when preloading is complete.
    public class func preloadTextureAtlases(_ atlases: [SKTextureAtlas], withCompletionHandler completionHandler: @escaping () -> Void) {
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
    }

    /// Preloads multiple named texture atlases into memory.
    ///
    /// - Parameters:
    ///   - atlasNames: The names of the atlases to preload.
    ///   - completionHandler: A block called with the loaded atlases.
    public class func preloadTextureAtlasesNamed(_ atlasNames: [String], withCompletionHandler completionHandler: @escaping (Error?, [SKTextureAtlas]) -> Void) {
        var atlases: [SKTextureAtlas] = []
        var loadError: Error? = nil

        for name in atlasNames {
            let atlas = SKTextureAtlas(named: name)
            if atlas.textureNames.isEmpty {
                loadError = SKResourceError.notFound
            }
            atlases.append(atlas)
        }

        // Preload all atlases
        preloadTextureAtlases(atlases) {
            completionHandler(loadError, atlases)
        }
    }
}
