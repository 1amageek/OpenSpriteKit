// OpenSpriteKit WASM browser tests, authored as Swift Testing `@Test`
// functions that run inside headless Chromium via BrowserTestRunner.
//
// Boot flow (reactor-ABI):
//   1. `setup()` is exported to JS via `@_cdecl` + `--export=setup`.
//   2. `WasmTestingReactor.boot` installs the JavaScriptKit executor and
//      touches module-scope globals to avoid the reactor-ABI global-init
//      race (see MEMORY + ReactorBoot.swift for background).
//   3. `performSetup()` creates a <canvas>, initialises an `SKRenderer`,
//      attaches a scene with three sprites, and starts the rAF loop.
//   4. `BrowserTestRunner.run()` spawns the Swift Testing ABI v0 entry
//      point. Each `@Test` function below references module-scope state
//      and asserts against it. Completion is signalled to the browser
//      side through `window.__wasm_tests`.
//
// D1 regression is exercised directly inside `dynamicSpawnCompoundActionRuns`:
// a node is attached post-boot and runs a nested sequence(group(...),
// .removeFromParent()). If the outer sequence fails to advance past the
// group, the spawn stays parented — the assertion catches that directly.

import Foundation
import Testing
import WasmTesting
import OpenSpriteKit

nonisolated(unsafe) var setupError: String?
nonisolated(unsafe) var canvasWidth: Int = 0
nonisolated(unsafe) var canvasHeight: Int = 0
nonisolated(unsafe) var frameCount: Int = 0
nonisolated(unsafe) var sceneRef: SKScene?
nonisolated(unsafe) var rendererRef: SKRenderer?
nonisolated(unsafe) var spawnedNode: SKSpriteNode?

@_cdecl("setup")
public func setup() {
    WasmTestingReactor.boot(
        touchGlobals: {
            setupError = nil
            canvasWidth = 0
            canvasHeight = 0
            frameCount = 0
            sceneRef = nil
            rendererRef = nil
            spawnedNode = nil
        },
        then: {
            await performSetup()
            BrowserTestRunner.run()
        }
    )
}

@MainActor
func performSetup() async {
    let document = JSObject.global.document
    let canvas = document.createElement("canvas")
    canvas.id = "osk-canvas"
    canvas.width = .number(400)
    canvas.height = .number(300)
    canvas.style.border = "1px solid #333"
    _ = document.body.appendChild(canvas)

    canvasWidth = 400
    canvasHeight = 300

    guard let canvasObject = canvas.object else {
        setupError = "canvas has no JSObject"
        return
    }

    let renderer = SKRenderer(canvas: canvasObject)
    do {
        try await renderer.initialize()
    } catch {
        setupError = "renderer.initialize failed: \(error)"
        return
    }

    let scene = SKScene(size: CGSize(width: 400, height: 300))
    scene.backgroundColor = .init(red: 0.10, green: 0.10, blue: 0.15, alpha: 1.0)

    let red = SKSpriteNode(color: .init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
                           size: CGSize(width: 60, height: 60))
    red.position = CGPoint(x: 80, y: 150)
    scene.addChild(red)

    let green = SKSpriteNode(color: .init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
                             size: CGSize(width: 60, height: 60))
    green.position = CGPoint(x: 200, y: 150)
    scene.addChild(green)

    let blue = SKSpriteNode(color: .init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0),
                            size: CGSize(width: 60, height: 60))
    blue.position = CGPoint(x: 320, y: 150)
    scene.addChild(blue)

    sceneRef = scene
    rendererRef = renderer
    renderer.scene = scene

    RenderLoop.start { seconds in
        rendererRef?.update(atTime: seconds)
        rendererRef?.render()
        frameCount += 1
    }
}

@MainActor
func spawnDynamic() {
    guard let scene = sceneRef else { return }

    let node = SKSpriteNode(color: .init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
                            size: CGSize(width: 40, height: 40))
    node.position = CGPoint(x: 200, y: 220)
    node.alpha = 0.0
    node.xScale = 0.2
    node.yScale = 0.2

    let scaleUp = SKAction.scale(to: 1.5, duration: 0.8)
    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
    let moveBy = SKAction.moveBy(x: 0, y: -40, duration: 0.8)
    let group = SKAction.group([scaleUp, fadeIn, moveBy])
    let sequence = SKAction.sequence([group, SKAction.removeFromParent()])

    scene.addChild(node)
    spawnedNode = node
    node.run(sequence)
}

// MARK: - Tests
//
// These tests share module-scope scene state (the scene built in `performSetup`
// is mutated by `dynamicSpawnCompoundActionRuns`). Swift Testing runs tests in
// parallel by default, so they must be gathered into a `.serialized` suite —
// otherwise the boot test's `children.count == 3` races against the dynamic
// spawn's `addChild`.

@Suite(.serialized)
struct SmokeTests {

@Test func bootInitialisesCanvasAndScene() throws {
    try #require(setupError == nil, "performSetup failed: \(setupError ?? "")")
    #expect(canvasWidth == 400)
    #expect(canvasHeight == 300)
    try #require(sceneRef != nil)
    #expect(sceneRef!.children.count == 3)
    #expect(rendererRef != nil)
}

@Test func renderLoopAdvancesFrameCount() async throws {
    try #require(setupError == nil, "performSetup failed: \(setupError ?? "")")
    let before = frameCount
    try await Task.sleep(nanoseconds: 500_000_000)
    let after = frameCount
    #expect(
        after - before >= 15,
        "frame count should advance under rAF (before=\(before), after=\(after))"
    )
}

// D1 regression: a node added AFTER the scene is running must execute a
// nested compound action (.sequence([.group([scaleBy, fade, moveBy]),
// .removeFromParent()])). Pre-fix this silently no-op'd — spawn stayed at
// alpha=0, xScale=0.2 and never got removed.
@Test @MainActor func dynamicSpawnCompoundActionRuns() async throws {
    try #require(setupError == nil, "performSetup failed: \(setupError ?? "")")

    spawnDynamic()
    try #require(spawnedNode != nil, "spawnDynamic produced no node")
    try #require(spawnedNode!.parent != nil, "spawn not attached to scene")

    // Mid-action: 500 ms into the 0.8 s group. The 0.4 s fade has already
    // finished (alpha should be 1.0) and the scale should be past the
    // halfway point of 0.2 → 1.5.
    try await Task.sleep(nanoseconds: 500_000_000)
    let midAlpha = spawnedNode?.alpha ?? -1
    let midScale = spawnedNode?.xScale ?? -1
    let midParentAttached = spawnedNode?.parent != nil
    #expect(midParentAttached, "spawn detached before group completed")
    #expect(
        midAlpha >= 0.5,
        "alpha did not animate past 0.5 (got \(midAlpha)); compound actions silently no-op?"
    )
    #expect(
        midScale >= 0.6,
        "xScale did not animate past 0.6 (got \(midScale)); compound actions silently no-op?"
    )

    // End-of-chain: by 1.2 s the sequence must have reached
    // .removeFromParent(). If parent is still set, the outer sequence
    // failed to advance past the group.
    try await Task.sleep(nanoseconds: 700_000_000)
    let endParentAttached = spawnedNode?.parent != nil
    #expect(
        !endParentAttached,
        "spawn was not removed from parent — outer .sequence did not advance to .removeFromParent"
    )
}

// Re-parenting (addChild on an already-parented node, and move(toParent:))
// must preserve running actions. Pre-fix, SKNode.addChild internally called
// removeFromParent which recursively wiped action state — so any reparent
// silently stopped mid-flight actions.
@Test @MainActor func reparentPreservesRunningActions() async throws {
    try #require(setupError == nil, "performSetup failed: \(setupError ?? "")")
    try #require(sceneRef != nil)

    let firstParent = SKNode()
    sceneRef!.addChild(firstParent)
    let secondParent = SKNode()
    sceneRef!.addChild(secondParent)

    let mover = SKSpriteNode(color: .init(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0),
                             size: CGSize(width: 20, height: 20))
    mover.position = CGPoint(x: 0, y: 250)
    firstParent.addChild(mover)

    mover.run(SKAction.moveBy(x: 200, y: 0, duration: 1.0))

    try await Task.sleep(nanoseconds: 150_000_000)
    let xBeforeReparent = mover.position.x
    #expect(xBeforeReparent > 10,
            "action not progressing before reparent (x=\(xBeforeReparent))")

    secondParent.addChild(mover)
    try #require(mover.parent === secondParent, "reparent failed")

    try await Task.sleep(nanoseconds: 400_000_000)
    let xAfterReparent = mover.position.x
    #expect(
        xAfterReparent > xBeforeReparent + 30,
        "addChild-reparent wiped the running action (before=\(xBeforeReparent), after=\(xAfterReparent))"
    )

    // move(toParent:) path
    let thirdParent = SKNode()
    sceneRef!.addChild(thirdParent)
    mover.move(toParent: thirdParent)
    try #require(mover.parent === thirdParent, "move(toParent:) failed")

    try await Task.sleep(nanoseconds: 300_000_000)
    let xAfterMove = mover.position.x
    #expect(
        xAfterMove > xAfterReparent + 20,
        "move(toParent:) wiped the running action (afterReparent=\(xAfterReparent), afterMove=\(xAfterMove))"
    )

    mover.removeFromParent()
    firstParent.removeFromParent()
    secondParent.removeFromParent()
    thirdParent.removeFromParent()
}

} // end SmokeTests
