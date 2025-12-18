// SKMutableTexture.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// A texture whose contents can be dynamically updated.
///
/// An `SKMutableTexture` object is a texture that can be dynamically updated. You create a mutable
/// texture object, then use its `modifyPixelData` method to update the texture's contents.
open class SKMutableTexture: SKTexture {

    // MARK: - Properties

    /// The pixel format used for the texture data.
    private var pixelFormat: Int32 = 0

    /// Internal pixel data storage.
    private var pixelData: Data?

    /// Bytes per row for the pixel data.
    private var bytesPerRow: Int = 0

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

    public required init?(coder: NSCoder) {
        pixelFormat = coder.decodeInt32(forKey: "pixelFormat")
        pixelData = coder.decodeObject(forKey: "pixelData") as? Data
        bytesPerRow = coder.decodeInteger(forKey: "bytesPerRow")
        super.init(coder: coder)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(pixelFormat, forKey: "pixelFormat")
        coder.encode(pixelData, forKey: "pixelData")
        coder.encode(bytesPerRow, forKey: "bytesPerRow")
    }

    // MARK: - Private Setup

    private func setupPixelData() {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4 // RGBA8
        bytesPerRow = width * bytesPerPixel
        let dataSize = bytesPerRow * height
        pixelData = Data(count: dataSize)
    }

    // MARK: - Pixel Modification

    /// Modifies the texture's pixel data.
    ///
    /// Use this method to update the texture's contents. The block receives a pointer to the
    /// texture's pixel data and the number of bytes per row. You can modify the pixel data
    /// directly through this pointer.
    ///
    /// - Parameter block: A block that receives a pointer to the pixel data and the row length.
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

        // TODO: Upload modified pixel data to GPU texture
    }
}
