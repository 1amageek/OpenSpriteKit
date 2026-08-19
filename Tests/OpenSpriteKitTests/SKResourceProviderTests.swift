@testable import OpenSpriteKit
import Testing

@Suite
struct SKResourceProviderTests {
    @Test
    func namedSceneFallsBackToInjectedProvider() {
        let expected = Data([1, 2, 3])
        let loader = SKResourceLoader(
            resourceProvider: StubSKResourceProvider(namedData: ["Scene": expected])
        )

        #expect(loader.sceneData(forName: "Scene") == expected)
    }

    @Test
    func registeredSceneOverridesPlatformProvider() {
        let packaged = Data([1])
        let registered = Data([2])
        let loader = SKResourceLoader(
            resourceProvider: StubSKResourceProvider(namedData: ["Scene": packaged])
        )
        loader.registerScene(data: registered, forName: "Scene")

        #expect(loader.sceneData(forName: "Scene") == registered)
    }

    @Test
    func missingNamedResourceRemainsAbsent() {
        let loader = SKResourceLoader(
            resourceProvider: StubSKResourceProvider(namedData: [:])
        )

        #expect(loader.sceneData(forName: "Missing") == nil)
    }

    @Test
    func missingNamedNodeDoesNotBecomeAnEmptySuccessValue() {
        #expect(SKNode(fileNamed: "__OpenSpriteKitMissingNodeFixture__") == nil)
    }
}

private struct StubSKResourceProvider: SKResourceProviding {
    let namedData: [String: Data]

    func data(named name: String, allowedExtensions: [String]) throws -> Data {
        guard let data = namedData[name] else {
            throw SKResourceError.notFound
        }
        return data
    }

    func data(contentsOf url: URL) throws -> Data {
        throw SKResourceError.notFound
    }

    func url(named name: String, allowedExtensions: [String]) -> URL? {
        nil
    }
}
