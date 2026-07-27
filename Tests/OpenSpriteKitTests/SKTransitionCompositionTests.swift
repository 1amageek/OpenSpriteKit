@testable import OpenSpriteKit
import Testing

@Suite("Scene transition composition")
struct SKTransitionCompositionTests {
    @MainActor
    @Test("Cross-fade renders both scenes through one composition layer")
    func crossFadeUsesSingleCompositionLayer() throws {
        let manager = SKTransitionManager()
        let view = SKView()
        let fromScene = SKScene(size: CGSize(width: 320, height: 180))
        let toScene = SKScene(size: CGSize(width: 320, height: 180))
        fromScene.position = CGPoint(x: 7, y: 11)
        fromScene.alpha = 0.75
        toScene.position = CGPoint(x: 13, y: 17)
        toScene.alpha = 0.5
        view._setScene(fromScene)

        manager.performTransition(
            SKTransition.crossFade(withDuration: 1),
            from: fromScene,
            to: toScene,
            in: view
        )

        let composition = try #require(manager.renderLayer)
        let layers = try #require(composition.sublayers)
        #expect(layers.count == 2)
        #expect(layers[0] === fromScene.layer)
        #expect(layers[1] === toScene.layer)

        #expect(manager.update(currentTime: .greatestFiniteMagnitude) == false)
        #expect(manager.renderLayer == nil)
        #expect(view.scene === toScene)
        #expect(fromScene.layer.superlayer == nil)
        #expect(toScene.layer.superlayer == nil)
        #expect(fromScene.position == CGPoint(x: 7, y: 11))
        #expect(fromScene.alpha == 0.75)
        #expect(toScene.position == CGPoint(x: 13, y: 17))
        #expect(toScene.alpha == 0.5)
    }

    @MainActor
    @Test("Color fade includes an overlay in the same composition")
    func colorFadeUsesCompositionOverlay() throws {
        let manager = SKTransitionManager()
        let view = SKView()
        let fromScene = SKScene(size: CGSize(width: 64, height: 64))
        let toScene = SKScene(size: CGSize(width: 64, height: 64))
        view._setScene(fromScene)

        manager.performTransition(
            SKTransition.fade(with: .red, duration: 1),
            from: fromScene,
            to: toScene,
            in: view
        )

        let composition = try #require(manager.renderLayer)
        let layers = try #require(composition.sublayers)
        #expect(layers.count == 3)
        #expect(layers[0] === fromScene.layer)
        #expect(layers[1] === toScene.layer)
        #expect(layers[2].backgroundColor == SKColor.red.cgColor)

        _ = manager.update(currentTime: .greatestFiniteMagnitude)
    }

    @MainActor
    @Test("Zero-duration transition completes without invalid progress")
    func zeroDurationCompletesImmediatelyOnUpdate() {
        let manager = SKTransitionManager()
        let view = SKView()
        let fromScene = SKScene(size: CGSize(width: 32, height: 32))
        let toScene = SKScene(size: CGSize(width: 32, height: 32))
        view._setScene(fromScene)

        manager.performTransition(
            SKTransition.crossFade(withDuration: 0),
            from: fromScene,
            to: toScene,
            in: view
        )

        #expect(manager.update(currentTime: CACurrentMediaTime()) == false)
        #expect(view.scene === toScene)
        #expect(manager.renderLayer == nil)
    }

    @MainActor
    @Test("Move-in transition offsets from the incoming scene's existing position")
    func moveInPreservesPositionBasis() {
        let manager = SKTransitionManager()
        let view = SKView()
        let fromScene = SKScene(size: CGSize(width: 320, height: 180))
        let toScene = SKScene(size: CGSize(width: 320, height: 180))
        toScene.position = CGPoint(x: 25, y: 40)
        view._setScene(fromScene)

        manager.performTransition(
            SKTransition.moveIn(with: .left, duration: 1),
            from: fromScene,
            to: toScene,
            in: view
        )

        #expect(toScene.position == CGPoint(x: 345, y: 40))
        _ = manager.update(currentTime: .greatestFiniteMagnitude)
        #expect(toScene.position == CGPoint(x: 25, y: 40))
    }
}
