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
    public init(imageNamed name: String) {
        super.init()
        // TODO: Load image from bundle
    }

    /// Creates a texture from a CGImage.
    ///
    /// - Parameter cgImage: The Core Graphics image to use as the texture source.
    public init(cgImage: CGImage) {
        self.cgImage = cgImage
        self._size = CGSize(width: cgImage.width, height: cgImage.height)
        super.init()
    }

    /// Creates a texture from raw image data.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - size: The size of the texture.
    public init(data: Data, size: CGSize) {
        self._size = size
        super.init()
        // TODO: Create texture from data
    }

    /// Creates a texture from raw image data with additional options.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - size: The size of the texture.
    ///   - flipped: Whether the image should be flipped vertically.
    public init(data: Data, size: CGSize, flipped: Bool) {
        self._size = size
        super.init()
        // TODO: Create texture from data
    }

    /// Creates a texture from raw image data with a specific row alignment.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - size: The size of the texture.
    ///   - rowLength: The number of pixels in a row.
    ///   - alignment: The byte alignment of the data.
    public init(data: Data, size: CGSize, rowLength: UInt32, alignment: UInt32) {
        self._size = size
        super.init()
        // TODO: Create texture from data
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
        // TODO: Create texture from CIImage
    }

    /// Creates a texture with a noise pattern.
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the noise.
    ///   - size: The size of the texture.
    ///   - grayscale: Whether the noise should be grayscale.
    /// - Returns: A texture containing noise.
    public class func noiseTexture(withSmoothness smoothness: CGFloat, size: CGSize, grayscale: Bool) -> SKTexture {
        let texture = SKTexture()
        texture._size = size
        return texture
    }

    /// Creates a texture with a vector noise pattern.
    ///
    /// - Parameters:
    ///   - smoothness: The smoothness of the noise.
    ///   - size: The size of the texture.
    /// - Returns: A texture containing vector noise.
    public class func vectorNoiseTexture(withSmoothness smoothness: CGFloat, size: CGSize) -> SKTexture {
        let texture = SKTexture()
        texture._size = size
        return texture
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
    /// - Parameter completionHandler: A block called when preloading is complete.
    open func preload(completionHandler: @escaping () -> Void) {
        // TODO: Implement preloading
        completionHandler()
    }

    /// Preloads multiple textures into memory.
    ///
    /// - Parameters:
    ///   - textures: The textures to preload.
    ///   - completionHandler: A block called when preloading is complete.
    public class func preload(_ textures: [SKTexture], withCompletionHandler completionHandler: @escaping () -> Void) {
        // TODO: Implement batch preloading
        completionHandler()
    }

    /// Returns a new texture by applying a Core Image filter.
    ///
    /// - Parameter filter: The filter to apply.
    /// - Returns: A new texture with the filter applied.
    open func applying(_ filter: CIFilter) -> SKTexture {
        // TODO: Implement filter application
        return self.copy() as! SKTexture
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
    /// - Parameter dictionary: A dictionary mapping texture names to CGImages.
    public init(dictionary: [String: Any]) {
        super.init()
        // TODO: Create textures from dictionary
    }

    /// Creates a texture atlas from a named atlas in the app bundle.
    ///
    /// - Parameter name: The name of the texture atlas.
    public init(named name: String) {
        super.init()
        // TODO: Load atlas from bundle
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
        // TODO: Implement preloading
        completionHandler()
    }

    /// Preloads multiple texture atlases into memory.
    ///
    /// - Parameters:
    ///   - atlases: The atlases to preload.
    ///   - completionHandler: A block called when preloading is complete.
    public class func preloadTextureAtlases(_ atlases: [SKTextureAtlas], withCompletionHandler completionHandler: @escaping () -> Void) {
        // TODO: Implement batch preloading
        completionHandler()
    }

    /// Preloads multiple named texture atlases into memory.
    ///
    /// - Parameters:
    ///   - atlasNames: The names of the atlases to preload.
    ///   - completionHandler: A block called with the loaded atlases.
    public class func preloadTextureAtlasesNamed(_ atlasNames: [String], withCompletionHandler completionHandler: @escaping (Error?, [SKTextureAtlas]) -> Void) {
        // TODO: Implement named atlas preloading
        let atlases = atlasNames.map { SKTextureAtlas(named: $0) }
        completionHandler(nil, atlases)
    }
}
