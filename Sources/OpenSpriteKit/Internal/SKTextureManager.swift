// SKTextureManager.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenCoreAnimation

#if arch(wasm32)
import JavaScriptKit
import SwiftWebGPU
#endif

/// Manages GPU texture resources for SpriteKit.
///
/// This class handles the conversion of CGImage data to GPU textures
/// and provides caching to avoid redundant texture uploads.
internal final class SKTextureManager {

    // MARK: - Singleton

    /// The shared texture manager instance.
    nonisolated(unsafe) static let shared = SKTextureManager()

    // MARK: - Properties

    #if arch(wasm32)
    /// Cache of GPU textures keyed by CGImage identity.
    private var textureCache: [ObjectIdentifier: GPUTexture] = [:]

    /// Cache of texture metadata.
    private var metadataCache: [ObjectIdentifier: TextureMetadata] = [:]
    #endif

    /// Metadata about a cached texture.
    struct TextureMetadata {
        let width: Int
        let height: Int
        let hasAlpha: Bool
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Texture Creation

    #if arch(wasm32)
    /// Creates or retrieves a cached GPU texture from a CGImage.
    ///
    /// - Parameters:
    ///   - cgImage: The source image.
    ///   - device: The GPU device to create the texture on.
    /// - Returns: A GPU texture, or nil if creation failed.
    func texture(from cgImage: CGImage, device: GPUDevice) -> GPUTexture? {
        let key = ObjectIdentifier(cgImage)

        // Check cache
        if let cached = textureCache[key] {
            return cached
        }

        // Create new texture
        guard let texture = createTexture(from: cgImage, device: device) else {
            return nil
        }

        // Cache it
        textureCache[key] = texture
        metadataCache[key] = TextureMetadata(
            width: cgImage.width,
            height: cgImage.height,
            hasAlpha: cgImage.alphaInfo != .none
        )

        return texture
    }

    /// Creates a GPU texture from CGImage data.
    ///
    /// - Parameters:
    ///   - cgImage: The source image.
    ///   - device: The GPU device.
    /// - Returns: A GPU texture, or nil if creation failed.
    private func createTexture(from cgImage: CGImage, device: GPUDevice) -> GPUTexture? {
        let width = cgImage.width
        let height = cgImage.height

        guard width > 0 && height > 0 else { return nil }

        // Get RGBA data from CGImage
        guard let rgbaData = getRGBAData(from: cgImage) else {
            return nil
        }

        // Create texture descriptor
        let textureDescriptor = GPUTextureDescriptor(
            size: GPUExtent3D(width: UInt32(width), height: UInt32(height)),
            format: .rgba8unorm,
            usage: [.textureBinding, .copyDst, .renderAttachment]
        )

        let texture = device.createTexture(descriptor: textureDescriptor)

        // Upload data to texture
        let jsArray = createJSUint8Array(from: rgbaData)

        device.queue.writeTexture(
            destination: GPUImageCopyTexture(texture: texture),
            data: jsArray,
            dataLayout: GPUImageDataLayout(
                offset: 0,
                bytesPerRow: UInt32(width * 4),
                rowsPerImage: UInt32(height)
            ),
            size: GPUExtent3D(width: UInt32(width), height: UInt32(height))
        )

        return texture
    }

    /// Converts a CGImage to RGBA8 data.
    ///
    /// - Parameter cgImage: The source image.
    /// - Returns: Raw RGBA data, or nil if conversion failed.
    private func getRGBAData(from cgImage: CGImage) -> Data? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = bytesPerRow * height

        // If the image already has compatible RGBA data, use it directly
        if let data = cgImage.data,
           cgImage.bitsPerPixel == 32,
           cgImage.bitsPerComponent == 8,
           cgImage.bytesPerRow == bytesPerRow {
            // Check if it's already RGBA format
            let isRGBA = cgImage.bitmapInfo.pixelFormat == .packed &&
                        (cgImage.alphaInfo == .premultipliedLast ||
                         cgImage.alphaInfo == .last ||
                         cgImage.alphaInfo == .noneSkipLast)
            if isRGBA {
                return data
            }
        }

        // Otherwise, we need to convert the image data
        // For now, use the raw data if available and convert format
        guard let sourceData = cgImage.data else {
            return nil
        }

        return convertToRGBA(
            sourceData: sourceData,
            width: width,
            height: height,
            sourceBitsPerPixel: cgImage.bitsPerPixel,
            sourceBytesPerRow: cgImage.bytesPerRow,
            alphaInfo: cgImage.alphaInfo,
            byteOrder: cgImage.byteOrderInfo
        )
    }

    /// Converts image data to RGBA8 format.
    private func convertToRGBA(
        sourceData: Data,
        width: Int,
        height: Int,
        sourceBitsPerPixel: Int,
        sourceBytesPerRow: Int,
        alphaInfo: CGImageAlphaInfo,
        byteOrder: CGImageByteOrderInfo
    ) -> Data? {
        let destBytesPerRow = width * 4
        var destData = Data(count: destBytesPerRow * height)

        // Handle common formats
        switch sourceBitsPerPixel {
        case 32:
            // 32-bit formats (RGBA, BGRA, ARGB, etc.)
            return convert32BitToRGBA(
                sourceData: sourceData,
                destData: &destData,
                width: width,
                height: height,
                sourceBytesPerRow: sourceBytesPerRow,
                alphaInfo: alphaInfo,
                byteOrder: byteOrder
            )

        case 24:
            // 24-bit RGB (no alpha)
            return convert24BitToRGBA(
                sourceData: sourceData,
                destData: &destData,
                width: width,
                height: height,
                sourceBytesPerRow: sourceBytesPerRow
            )

        case 8:
            // 8-bit grayscale
            return convert8BitGrayscaleToRGBA(
                sourceData: sourceData,
                destData: &destData,
                width: width,
                height: height,
                sourceBytesPerRow: sourceBytesPerRow
            )

        default:
            // Unsupported format
            return nil
        }
    }

    /// Converts 32-bit image data to RGBA.
    private func convert32BitToRGBA(
        sourceData: Data,
        destData: inout Data,
        width: Int,
        height: Int,
        sourceBytesPerRow: Int,
        alphaInfo: CGImageAlphaInfo,
        byteOrder: CGImageByteOrderInfo
    ) -> Data? {
        let destBytesPerRow = width * 4

        sourceData.withUnsafeBytes { sourceBuffer in
            destData.withUnsafeMutableBytes { destBuffer in
                guard let sourceBase = sourceBuffer.baseAddress,
                      let destBase = destBuffer.baseAddress else { return }

                for y in 0..<height {
                    for x in 0..<width {
                        let sourceOffset = y * sourceBytesPerRow + x * 4
                        let destOffset = y * destBytesPerRow + x * 4

                        let s = sourceBase.advanced(by: sourceOffset).assumingMemoryBound(to: UInt8.self)
                        let d = destBase.advanced(by: destOffset).assumingMemoryBound(to: UInt8.self)

                        // Handle different byte orders and alpha positions
                        switch (byteOrder, alphaInfo) {
                        case (_, .premultipliedFirst), (_, .first):
                            // ARGB -> RGBA
                            d[0] = s[1]  // R
                            d[1] = s[2]  // G
                            d[2] = s[3]  // B
                            d[3] = s[0]  // A

                        case (_, .premultipliedLast), (_, .last):
                            // RGBA -> RGBA (copy as-is)
                            d[0] = s[0]  // R
                            d[1] = s[1]  // G
                            d[2] = s[2]  // B
                            d[3] = s[3]  // A

                        case (_, .noneSkipFirst):
                            // xRGB -> RGBA
                            d[0] = s[1]  // R
                            d[1] = s[2]  // G
                            d[2] = s[3]  // B
                            d[3] = 255   // A

                        case (_, .noneSkipLast):
                            // RGBx -> RGBA
                            d[0] = s[0]  // R
                            d[1] = s[1]  // G
                            d[2] = s[2]  // B
                            d[3] = 255   // A

                        case (.order32Big, _):
                            // Big-endian BGRA -> RGBA
                            d[0] = s[2]  // R
                            d[1] = s[1]  // G
                            d[2] = s[0]  // B
                            d[3] = s[3]  // A

                        default:
                            // Assume RGBA
                            d[0] = s[0]
                            d[1] = s[1]
                            d[2] = s[2]
                            d[3] = s[3]
                        }
                    }
                }
            }
        }

        return destData
    }

    /// Converts 24-bit RGB data to RGBA.
    private func convert24BitToRGBA(
        sourceData: Data,
        destData: inout Data,
        width: Int,
        height: Int,
        sourceBytesPerRow: Int
    ) -> Data? {
        let destBytesPerRow = width * 4

        sourceData.withUnsafeBytes { sourceBuffer in
            destData.withUnsafeMutableBytes { destBuffer in
                guard let sourceBase = sourceBuffer.baseAddress,
                      let destBase = destBuffer.baseAddress else { return }

                for y in 0..<height {
                    for x in 0..<width {
                        let sourceOffset = y * sourceBytesPerRow + x * 3
                        let destOffset = y * destBytesPerRow + x * 4

                        let s = sourceBase.advanced(by: sourceOffset).assumingMemoryBound(to: UInt8.self)
                        let d = destBase.advanced(by: destOffset).assumingMemoryBound(to: UInt8.self)

                        d[0] = s[0]  // R
                        d[1] = s[1]  // G
                        d[2] = s[2]  // B
                        d[3] = 255   // A (opaque)
                    }
                }
            }
        }

        return destData
    }

    /// Converts 8-bit grayscale to RGBA.
    private func convert8BitGrayscaleToRGBA(
        sourceData: Data,
        destData: inout Data,
        width: Int,
        height: Int,
        sourceBytesPerRow: Int
    ) -> Data? {
        let destBytesPerRow = width * 4

        sourceData.withUnsafeBytes { sourceBuffer in
            destData.withUnsafeMutableBytes { destBuffer in
                guard let sourceBase = sourceBuffer.baseAddress,
                      let destBase = destBuffer.baseAddress else { return }

                for y in 0..<height {
                    for x in 0..<width {
                        let sourceOffset = y * sourceBytesPerRow + x
                        let destOffset = y * destBytesPerRow + x * 4

                        let gray = sourceBase.advanced(by: sourceOffset).assumingMemoryBound(to: UInt8.self)[0]
                        let d = destBase.advanced(by: destOffset).assumingMemoryBound(to: UInt8.self)

                        d[0] = gray  // R
                        d[1] = gray  // G
                        d[2] = gray  // B
                        d[3] = 255   // A
                    }
                }
            }
        }

        return destData
    }

    /// Creates a JavaScript Uint8Array from Data.
    private func createJSUint8Array(from data: Data) -> JSObject {
        let uint8Array = JSObject.global.Uint8Array.function!.new(data.count)
        data.withUnsafeBytes { bytes in
            for i in 0..<data.count {
                uint8Array[i] = .number(Double(bytes.load(fromByteOffset: i, as: UInt8.self)))
            }
        }
        return uint8Array
    }

    // MARK: - Cache Management

    /// Removes a specific texture from the cache.
    ///
    /// - Parameter cgImage: The CGImage whose texture should be removed.
    func removeTexture(for cgImage: CGImage) {
        let key = ObjectIdentifier(cgImage)
        textureCache.removeValue(forKey: key)
        metadataCache.removeValue(forKey: key)
    }

    /// Clears all cached textures.
    func clearCache() {
        textureCache.removeAll()
        metadataCache.removeAll()
    }

    /// Returns metadata for a cached texture.
    ///
    /// - Parameter cgImage: The CGImage to get metadata for.
    /// - Returns: Texture metadata, or nil if not cached.
    func metadata(for cgImage: CGImage) -> TextureMetadata? {
        let key = ObjectIdentifier(cgImage)
        return metadataCache[key]
    }

    #else

    // MARK: - Native Platform Stubs

    /// On native platforms, texture management is handled by the system.
    func clearCache() {
        // No-op on native platforms
    }

    #endif
}
