import Testing
@testable import OpenSpriteKit

@MainActor
@Suite("Renderer-owned Core Image evaluation")
struct SKImageRenderingOwnershipTests {
    @Test("Filtered textures stay lazy until the owning renderer evaluates them")
    func filteredTextureUsesOwningRenderer() async throws {
        let source = SKTexture(cgImage: try makeImage(red: 255, green: 0, blue: 0))
        let filter = try #require(CIFilter(name: "CIColorInvert"))
        let filtered = source.applying(filter)
        let renderer = RecordingImageRenderer(output: try makeImage(red: 0, green: 255, blue: 0))

        #expect(filtered.cgImage() == nil)
        #expect(filtered.requiresImagePreparation)
        #expect(renderer.renderCount == 0)

        try await filtered.prepareImage(using: renderer)

        #expect(renderer.renderCount == 1)
        #expect(filtered.cgImage() != nil)
        #expect(!filtered.requiresImagePreparation)
    }

    @Test("Texture evaluation failure never substitutes the unfiltered source")
    func filteredTextureFailureIsExplicit() async throws {
        let sourceImage = try makeImage(red: 255, green: 0, blue: 0)
        let source = SKTexture(cgImage: sourceImage)
        let filter = try #require(CIFilter(name: "CIColorInvert"))
        let filtered = source.applying(filter)
        let renderer = RecordingImageRenderer(
            output: try makeImage(red: 0, green: 255, blue: 0),
            failure: TestImageError.rejected
        )

        do {
            try await filtered.prepareImage(using: renderer)
            Issue.record("Filtered texture evaluation unexpectedly succeeded")
        } catch let error as SKRendererError {
            guard case .imageProcessingFailed = error else {
                Issue.record("Unexpected renderer error: \(error)")
                return
            }
        }

        #expect(filtered.cgImage() == nil)
        #expect(filtered.requiresImagePreparation)
        #expect(source.cgImage() === sourceImage)
    }

    @Test("Effect nodes use the renderer-owned service and reuse rasterized output")
    func effectNodeUsesRendererOwnedService() async throws {
        let renderer = RecordingImageRenderer(output: try makeImage(red: 0, green: 0, blue: 255))
        let processor = SKSceneImageProcessor(imageRenderer: renderer)
        let scene = SKScene(size: CGSize(width: 2, height: 2))
        let effect = SKEffectNode()
        let filter = try #require(CIFilter(name: "CIColorInvert"))
        effect.shouldEnableEffects = true
        effect.shouldRasterize = true
        effect.filter = filter
        let child = SKSpriteNode(
            texture: SKTexture(cgImage: try makeImage(red: 255, green: 0, blue: 0)),
            size: CGSize(width: 2, height: 2)
        )
        effect.addChild(child)
        scene.addChild(effect)

        let firstError = await processor.prepareFrameImages(in: scene)
        #expect(firstError == nil)
        #expect(renderer.renderCount == 1)
        #expect(effect._cachedFilteredImage != nil)
        #expect(effect.children.first?.layer.isHidden == true)

        let secondError = await processor.prepareFrameImages(in: scene)
        #expect(secondError == nil)
        #expect(renderer.renderCount == 1)

        effect.shouldCenterFilter.toggle()
        let thirdError = await processor.prepareFrameImages(in: scene)
        #expect(thirdError == nil)
        #expect(renderer.renderCount == 2)

        child.position.x = 1
        let fourthError = await processor.prepareFrameImages(in: scene)
        #expect(fourthError == nil)
        #expect(renderer.renderCount == 3)

        filter.setValue(0.5, forKey: kCIInputIntensityKey)
        let fifthError = await processor.prepareFrameImages(in: scene)
        #expect(fifthError == nil)
        #expect(renderer.renderCount == 4)
    }

    @Test("Disabled scene effects preserve explicitly hidden child layers")
    func disabledSceneEffectDoesNotUnhideNodes() async throws {
        let renderer = RecordingImageRenderer(output: try makeImage(red: 0, green: 0, blue: 255))
        let processor = SKSceneImageProcessor(imageRenderer: renderer)
        let scene = SKScene(size: CGSize(width: 2, height: 2))
        let child = SKSpriteNode(
            texture: SKTexture(cgImage: try makeImage(red: 255, green: 0, blue: 0)),
            size: CGSize(width: 2, height: 2)
        )
        child.isHidden = true
        scene.addChild(child)

        let error = await processor.prepareFrameImages(in: scene)

        #expect(error == nil)
        #expect(child.layer.isHidden)
        #expect(renderer.renderCount == 0)
    }

    @Test("Effect failure restores children and reaches the renderer error channel")
    func effectFailureIsExplicit() async throws {
        let renderer = RecordingImageRenderer(
            output: try makeImage(red: 0, green: 0, blue: 255),
            failure: TestImageError.rejected
        )
        let processor = SKSceneImageProcessor(imageRenderer: renderer)
        let scene = SKScene(size: CGSize(width: 2, height: 2))
        let effect = SKEffectNode()
        effect.shouldEnableEffects = true
        let filter = try #require(CIFilter(name: "CIColorInvert"))
        effect.filter = filter
        effect.addChild(SKSpriteNode(
            texture: SKTexture(cgImage: try makeImage(red: 255, green: 0, blue: 0)),
            size: CGSize(width: 2, height: 2)
        ))
        scene.addChild(effect)

        let error = await processor.prepareFrameImages(in: scene)

        guard let error, case .imageProcessingFailed = error else {
            Issue.record("Expected an explicit image-processing failure, got \(String(describing: error))")
            return
        }
        #expect(effect._cachedFilteredImage == nil)
        #expect(effect.layer.contents == nil)
        #expect(effect.children.first?.layer.isHidden == false)
    }

    private func makeImage(red: UInt8, green: UInt8, blue: UInt8) throws -> CGImage {
        let data = Data([red, green, blue, 255])
        return try #require(CGImage(
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: .deviceRGB,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: data),
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
    }
}

@MainActor
private final class RecordingImageRenderer: SKImageRendering {
    private let output: CGImage
    private let failure: Error?
    private(set) var renderCount = 0

    init(output: CGImage, failure: Error? = nil) {
        self.output = output
        self.failure = failure
    }

    func render(_ image: CIImage, from rect: CGRect) async throws -> CGImage {
        _ = (image, rect)
        renderCount += 1
        if let failure {
            throw failure
        }
        return output
    }

    func clearCaches() {}
    func reclaimResources() {}
}

private enum TestImageError: Error {
    case rejected
}
