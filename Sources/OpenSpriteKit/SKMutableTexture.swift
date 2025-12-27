// SKMutableTexture.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A texture whose contents can be dynamically updated.
///
/// An `SKMutableTexture` object is a texture that can be dynamically updated. You create a mutable
/// texture object, then use its `modifyPixelData` method to update the texture's contents.
///
/// ## Example
/// ```swift
/// let texture = SKMutableTexture(size: CGSize(width: 256, height: 256))
///
/// // Update the texture with a gradient
/// texture.modifyPixelData { data, bytesPerRow in
///     guard let pixels = data?.assumingMemoryBound(to: UInt8.self) else { return }
///     let width = 256
///     let height = 256
///
///     for y in 0..<height {
///         for x in 0..<width {
///             let offset = y * bytesPerRow + x * 4
///             pixels[offset] = UInt8(x)       // Red
///             pixels[offset + 1] = UInt8(y)   // Green
///             pixels[offset + 2] = 128        // Blue
///             pixels[offset + 3] = 255        // Alpha
///         }
///     }
/// }
///
/// let sprite = SKSpriteNode(texture: texture)
/// ```
open class SKMutableTexture: SKTexture, @unchecked Sendable {

    // MARK: - Properties

    /// The pixel format used for the texture data.
    private var pixelFormat: Int32 = 0

    /// Internal pixel data storage.
    private var pixelData: Data?

    /// Bytes per row for the pixel data.
    private var bytesPerRow: Int = 0

    /// Flag indicating whether the texture needs to be uploaded to the GPU.
    private var needsGPUUpdate: Bool = false

    // MARK: - Initializers

    /// Creates a new mutable texture.
    ///
    /// - Parameter size: The size of the texture in points.
    public init(size: CGSize) {
        super.init()
        _size = size
        setupPixelData()
    }

    /// Creates a mutable texture with a specific pixel format.
    ///
    /// - Parameters:
    ///   - size: The size of the texture in points.
    ///   - pixelFormat: The pixel format of the texture data.
    public init(size: CGSize, pixelFormat format: Int32) {
        self.pixelFormat = format
        super.init()
        _size = size
        setupPixelData()
    }

    // MARK: - Private Setup

    private func setupPixelData() {
        let textureSize = size()
        let width = Int(textureSize.width)
        let height = Int(textureSize.height)
        let bytesPerPixel = 4 // RGBA8
        bytesPerRow = width * bytesPerPixel
        let dataSize = bytesPerRow * height
        pixelData = Data(count: dataSize)

        // Create initial CGImage
        updateCGImage()
    }

    // MARK: - Pixel Modification

    /// Modifies the texture's pixel data.
    ///
    /// Use this method to update the texture's contents. The block receives a pointer to the
    /// texture's pixel data and the number of bytes per row. You can modify the pixel data
    /// directly through this pointer.
    ///
    /// After the block executes, the texture is automatically updated to reflect the changes.
    /// This includes updating the internal CGImage used for rendering.
    ///
    /// - Parameter block: A block that receives a pointer to the pixel data and the row length.
    ///   The pixel data is in RGBA format with 8 bits per component.
    open func modifyPixelData(_ block: (UnsafeMutableRawPointer?, Int) -> Void) {
        guard var data = pixelData else {
            block(nil, 0)
            return
        }

        data.withUnsafeMutableBytes { buffer in
            block(buffer.baseAddress, bytesPerRow)
        }

        // Store the modified data back
        pixelData = data

        // Update the CGImage to reflect changes
        updateCGImage()

        // Mark as needing GPU update
        needsGPUUpdate = true
    }

    /// Updates the internal CGImage from the pixel data.
    private func updateCGImage() {
        guard let data = pixelData else { return }

        let textureSize = size()
        let width = Int(textureSize.width)
        let height = Int(textureSize.height)
        guard width > 0 && height > 0 else { return }

        // Create a CGImage from the pixel data
        let colorSpace = CGColorSpace.deviceRGB

        let provider = CGDataProvider(data: data)

        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )

        // Update the base class cgImage storage
        self._cgImage = image
    }

    /// Returns the current CGImage, updating it first if necessary.
    public override func cgImage() -> CGImage? {
        if _cgImage == nil || needsGPUUpdate {
            updateCGImage()
            needsGPUUpdate = false
        }
        return _cgImage
    }

    // MARK: - Convenience Methods

    /// Fills the texture with a solid color.
    ///
    /// - Parameter color: The color to fill the texture with.
    open func fill(with color: SKColor) {
        modifyPixelData { data, bytesPerRow in
            guard let pixels = data?.assumingMemoryBound(to: UInt8.self) else { return }

            let textureSize = self.size()
            let width = Int(textureSize.width)
            let height = Int(textureSize.height)

            // Extract color components
            let (r, g, b, a) = extractColorComponents(from: color)

            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * bytesPerRow + x * 4
                    pixels[offset] = r
                    pixels[offset + 1] = g
                    pixels[offset + 2] = b
                    pixels[offset + 3] = a
                }
            }
        }
    }

    /// Sets a pixel at the specified location.
    ///
    /// - Parameters:
    ///   - x: The x coordinate of the pixel.
    ///   - y: The y coordinate of the pixel.
    ///   - color: The color to set.
    open func setPixel(at x: Int, y: Int, color: SKColor) {
        let textureSize = size()
        guard x >= 0 && x < Int(textureSize.width) && y >= 0 && y < Int(textureSize.height) else { return }

        modifyPixelData { data, bytesPerRow in
            guard let pixels = data?.assumingMemoryBound(to: UInt8.self) else { return }

            let offset = y * bytesPerRow + x * 4
            let (r, g, b, a) = extractColorComponents(from: color)

            pixels[offset] = r
            pixels[offset + 1] = g
            pixels[offset + 2] = b
            pixels[offset + 3] = a
        }
    }

    /// Clears the texture to transparent black.
    open func clear() {
        modifyPixelData { data, bytesPerRow in
            guard let pixels = data else { return }
            let totalBytes = bytesPerRow * Int(self.size().height)
            memset(pixels, 0, totalBytes)
        }
    }

    // MARK: - Private Helpers

    private func extractColorComponents(from color: SKColor) -> (UInt8, UInt8, UInt8, UInt8) {
        return (
            UInt8(min(255, max(0, color.red * 255))),
            UInt8(min(255, max(0, color.green * 255))),
            UInt8(min(255, max(0, color.blue * 255))),
            UInt8(min(255, max(0, color.alpha * 255)))
        )
    }
}
