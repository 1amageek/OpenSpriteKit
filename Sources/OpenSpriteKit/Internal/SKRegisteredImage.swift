import Foundation

internal struct SKRegisteredImage: Sendable {
    let width: Int
    let height: Int
    let bitsPerComponent: Int
    let bitsPerPixel: Int
    let bytesPerRow: Int
    let colorSpace: CGColorSpace
    let bitmapInfo: CGBitmapInfo
    let decode: [CGFloat]?
    let shouldInterpolate: Bool
    let renderingIntent: CGColorRenderingIntent
    let data: Data

    init?(_ image: CGImage) {
        guard let data = image.data ?? image.dataProvider?.data else { return nil }
        let colorSpace = image.colorSpace ?? .deviceRGB
        let decodeCount = colorSpace.numberOfComponents * 2
        let decode = image.decode.map {
            Array(UnsafeBufferPointer(start: $0, count: decodeCount))
        }
        self.width = image.width
        self.height = image.height
        self.bitsPerComponent = image.bitsPerComponent
        self.bitsPerPixel = image.bitsPerPixel
        self.bytesPerRow = image.bytesPerRow
        self.colorSpace = colorSpace
        self.bitmapInfo = image.bitmapInfo
        self.decode = decode
        self.shouldInterpolate = image.shouldInterpolate
        self.renderingIntent = image.renderingIntent
        self.data = data
    }

    func makeImage() -> CGImage? {
        let provider = CGDataProvider(data: data)
        if let decode {
            return decode.withUnsafeBufferPointer { buffer in
                makeImage(provider: provider, decode: buffer.baseAddress)
            }
        }
        return makeImage(provider: provider, decode: nil)
    }

    private func makeImage(
        provider: CGDataProvider,
        decode: UnsafePointer<CGFloat>?
    ) -> CGImage? {
        CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: decode,
            shouldInterpolate: shouldInterpolate,
            intent: renderingIntent
        )
    }
}
