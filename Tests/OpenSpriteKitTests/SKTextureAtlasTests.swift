import Foundation
import Testing
@testable import OpenSpriteKit

private enum SKTextureAtlasTestError: Error {
    case failedToCreateContext
    case failedToCreateImage
}

private func makeAtlasImage(width: Int = 4, height: Int = 2) throws -> CGImage {
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: .deviceRGB,
        bitmapInfo: bitmapInfo
    ) else {
        throw SKTextureAtlasTestError.failedToCreateContext
    }

    context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
    context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
    context.fill(CGRect(x: width / 2, y: 0, width: width / 2, height: height))

    guard let image = context.makeImage() else {
        throw SKTextureAtlasTestError.failedToCreateImage
    }
    return image
}

@Suite("SKTextureAtlas", .serialized)
struct SKTextureAtlasTests {

    private func registerTestAtlas(named name: String = "heroes") throws {
        let image = try makeAtlasImage()
        let frames: [String: CGRect] = [
            "idle": CGRect(x: 0, y: 0, width: 0.5, height: 1.0),
            "run": CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
        ]
        SKResourceLoader.shared.registerAtlas(.init(image: image, frames: frames), forName: name)
    }

    @Test("Named atlas exposes registered frame metadata immediately")
    func testNamedAtlasLoadsRegisteredMetadata() throws {
        SKResourceLoader.shared.clearAtlases()
        defer { SKResourceLoader.shared.clearAtlases() }

        try registerTestAtlas()
        let atlas = SKTextureAtlas(named: "heroes")

        #expect(atlas.textureNames == ["idle", "run"])
        #expect(atlas.count == 2)
        #expect(atlas.containsTexture(named: "idle"))
        #expect(atlas.containsTexture(named: "run"))
    }

    @Test("Preloading named atlases materializes registered textures")
    func testPreloadTextureAtlasesNamedLoadsRegisteredFrames() throws {
        SKResourceLoader.shared.clearAtlases()
        defer { SKResourceLoader.shared.clearAtlases() }

        try registerTestAtlas()

        var result: ((any Error)?, [SKTextureAtlas])?
        SKTextureAtlas.preloadTextureAtlasesNamed(["heroes"]) { error, atlases in
            result = (error, atlases)
        }
        let resolvedResult = try #require(result)

        #expect(resolvedResult.0 == nil)
        #expect(resolvedResult.1.count == 1)

        guard let atlas = resolvedResult.1.first else {
            Issue.record("Expected preloaded atlas")
            return
        }

        #expect(atlas.textureNames == ["idle", "run"])
        #expect(atlas.count == 2)

        let textures = atlas.allTextures()
        #expect(textures.count == 2)
        #expect(textures.allSatisfy { $0.isPreloaded })
        #expect(textures.allSatisfy { $0.cgImage() != nil })
    }

    @Test("Atlas metadata can be observed after late registration")
    func testLateAtlasRegistrationRefreshesMetadata() throws {
        SKResourceLoader.shared.clearAtlases()
        defer { SKResourceLoader.shared.clearAtlases() }

        let atlas = SKTextureAtlas(named: "late")
        #expect(atlas.textureNames.isEmpty)

        try registerTestAtlas(named: "late")

        #expect(atlas.textureNames == ["idle", "run"])
        #expect(atlas.count == 2)
        #expect(atlas.containsTexture(named: "idle"))
    }

    @Test("Missing texture lookup does not pollute atlas metadata")
    func testMissingTextureLookupStaysOutOfMetadata() {
        SKResourceLoader.shared.clearAtlases()
        defer { SKResourceLoader.shared.clearAtlases() }

        let atlas = SKTextureAtlas(named: "missing")
        let texture = atlas.textureNamed("ghost")

        #expect(texture.cgImage() == nil)
        #expect(atlas.textureNames.isEmpty)
        #expect(atlas.count == 0)
        #expect(!atlas.containsTexture(named: "ghost"))
        #expect(atlas.allTextures().isEmpty)
    }
}
