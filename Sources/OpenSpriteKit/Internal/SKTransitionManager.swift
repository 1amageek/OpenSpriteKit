// SKTransitionManager.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import OpenFoundation

/// Manages scene transitions and their animations.
@MainActor
internal final class SKTransitionManager {

    // MARK: - Singleton

    static let shared = SKTransitionManager()

    internal init() {}

    // MARK: - Transition State

    private var isTransitioning: Bool = false
    private var startTime: TimeInterval = 0
    private var currentTransition: SKTransition?
    private var compositionLayer: CALayer?
    private var fadeLayer: CALayer?
    private var fromSceneState: SceneState?
    private var toSceneState: SceneState?

    var renderLayer: CALayer? { compositionLayer }

    /// The scene being transitioned from (accessible during transitions).
    private(set) var fromScene: SKScene?

    /// The scene being transitioned to (accessible during transitions).
    private(set) var toScene: SKScene?

    private weak var view: SKView?

    // MARK: - Transition Execution

    /// Performs a transition from one scene to another.
    ///
    /// - Parameters:
    ///   - transition: The transition to perform.
    ///   - fromScene: The scene being transitioned from.
    ///   - toScene: The scene being transitioned to.
    ///   - view: The view displaying the scenes.
    func performTransition(_ transition: SKTransition, from fromScene: SKScene, to toScene: SKScene, in view: SKView) {
        guard !isTransitioning else { return }

        self.isTransitioning = true
        self.currentTransition = transition
        self.fromScene = fromScene
        self.toScene = toScene
        self.view = view
        self.startTime = CACurrentMediaTime()
        self.fromSceneState = SceneState(scene: fromScene)
        self.toSceneState = SceneState(scene: toScene)

        // Pause scenes according to transition settings
        if transition.pausesOutgoingScene {
            fromScene.isPaused = true
        }
        if transition.pausesIncomingScene {
            toScene.isPaused = true
        }

        // Initialize the incoming scene
        toScene._view = view

        // Call sceneDidLoad() once when the scene is first presented
        if !toScene._didCallSceneDidLoad {
            toScene._didCallSceneDidLoad = true
            toScene.sceneDidLoad()
        }

        toScene.didMove(to: view)

        configureCompositionLayer(
            for: transition,
            fromScene: fromScene,
            toScene: toScene
        )
        setupInitialState(for: transition, fromScene: fromScene, toScene: toScene)
    }

    /// Called each frame during a transition.
    ///
    /// - Parameter currentTime: The current time.
    /// - Returns: `true` if the transition is still in progress.
    func update(currentTime: TimeInterval) -> Bool {
        guard isTransitioning,
              let transition = currentTransition,
              let fromScene = fromScene,
              let toScene = toScene,
              let view = view else {
            return false
        }

        let elapsed = currentTime - startTime
        let progress: Float
        if transition.duration <= 0 {
            progress = 1
        } else {
            progress = min(max(Float(elapsed / transition.duration), 0), 1)
        }

        // Apply timing function
        let easedProgress = applyEasing(progress)

        // Update transition animation
        updateTransition(transition, fromScene: fromScene, toScene: toScene, progress: easedProgress)

        // Check if transition is complete
        if progress >= 1.0 {
            completeTransition(view: view, fromScene: fromScene, toScene: toScene, transition: transition)
            return false
        }

        return true
    }

    // MARK: - Transition Helpers

    private func setupInitialState(
        for transition: SKTransition,
        fromScene: SKScene,
        toScene: SKScene
    ) {
        let type = transition.transitionType
        guard let fromState = fromSceneState, let toState = toSceneState else { return }

        switch type {
        case .crossFade:
            toScene.alpha = 0

        case .fade:
            fromScene.alpha = fromState.alpha
            toScene.alpha = 0
            fadeLayer?.opacity = 0

        case .fadeIn:
            toScene.alpha = 0

        case .fadeOut:
            // Fade out shows black, then incoming scene
            toScene.alpha = 0

        case .moveIn(let direction):
            let offset = offsetForDirection(direction, size: toScene.size)
            toScene.position = toState.position + offset

        case .push(let direction):
            let offset = offsetForDirection(direction, size: toScene.size)
            toScene.position = toState.position + offset

        case .reveal(_):
            // Outgoing scene moves to reveal incoming scene underneath
            toScene.zPosition = min(fromState.zPosition, toState.zPosition) - 1

        case .flip(_):
            preconditionFailure("Unavailable flip transition reached the renderer")

        case .doorsOpen(_):
            preconditionFailure("Unavailable doors-open transition reached the renderer")

        case .doorsClose(_):
            preconditionFailure("Unavailable doors-close transition reached the renderer")

        case .doorway:
            preconditionFailure("Unavailable doorway transition reached the renderer")

        case .ciFilter:
            preconditionFailure("Unavailable Core Image transition reached the renderer")

        case .none:
            break
        }
    }

    private func updateTransition(_ transition: SKTransition, fromScene: SKScene, toScene: SKScene, progress: Float) {
        let type = transition.transitionType
        let p = CGFloat(progress)
        guard let fromState = fromSceneState, let toState = toSceneState else { return }

        switch type {
        case .crossFade:
            fromScene.alpha = fromState.alpha * (1 - p)
            toScene.alpha = toState.alpha * p

        case .fade:
            if progress < 0.5 {
                let fadeOut = CGFloat(progress * 2)
                fromScene.alpha = fromState.alpha
                toScene.alpha = 0
                fadeLayer?.opacity = Float(fadeOut)
            } else {
                let fadeIn = CGFloat((progress - 0.5) * 2)
                fromScene.alpha = 0
                toScene.alpha = toState.alpha
                fadeLayer?.opacity = Float(1 - fadeIn)
            }

        case .fadeIn:
            toScene.alpha = toState.alpha * p

        case .fadeOut:
            fromScene.alpha = fromState.alpha * (1 - p)
            if progress >= 0.5 {
                toScene.alpha = toState.alpha
            }

        case .moveIn(let direction):
            let fullOffset = offsetForDirection(direction, size: toScene.size)
            toScene.position = CGPoint(
                x: toState.position.x + fullOffset.x * (1 - p),
                y: toState.position.y + fullOffset.y * (1 - p)
            )

        case .push(let direction):
            let fullOffset = offsetForDirection(direction, size: toScene.size)
            toScene.position = CGPoint(
                x: toState.position.x + fullOffset.x * (1 - p),
                y: toState.position.y + fullOffset.y * (1 - p)
            )
            let outOffset = offsetForDirection(oppositeDirection(direction), size: fromScene.size)
            fromScene.position = CGPoint(
                x: fromState.position.x + outOffset.x * p,
                y: fromState.position.y + outOffset.y * p
            )

        case .reveal(let direction):
            let outOffset = offsetForDirection(direction, size: fromScene.size)
            fromScene.position = CGPoint(
                x: fromState.position.x + outOffset.x * p,
                y: fromState.position.y + outOffset.y * p
            )

        case .flip(_):
            preconditionFailure("Unavailable flip transition reached the renderer")

        case .doorsOpen(_):
            preconditionFailure("Unavailable doors-open transition reached the renderer")

        case .doorsClose(_):
            preconditionFailure("Unavailable doors-close transition reached the renderer")

        case .doorway:
            preconditionFailure("Unavailable doorway transition reached the renderer")

        case .ciFilter:
            preconditionFailure("Unavailable Core Image transition reached the renderer")

        case .none:
            toScene.alpha = toState.alpha
        }
    }

    private func completeTransition(view: SKView, fromScene: SKScene, toScene: SKScene, transition: SKTransition) {
        // Clean up outgoing scene
        fromScene.willMove(from: view)
        fromScene._removeAllActionsRecursivelyForCleanup()
        fromScene._view = nil
        fromScene.layer.removeFromSuperlayer()
        toScene.layer.removeFromSuperlayer()
        fadeLayer?.removeFromSuperlayer()
        fromSceneState?.restore(scene: fromScene)

        // Reset physics state for outgoing scene
        SKPhysicsEngine.shared.reset(for: fromScene)

        // Restore incoming scene state
        toSceneState?.restore(scene: toScene)

        // Reset physics state for incoming scene (clear any stale contact data)
        SKPhysicsEngine.shared.reset(for: toScene)

        // Unpause scenes
        fromScene.isPaused = false
        toScene.isPaused = false

        // Update view's scene reference
        view._setScene(toScene)

        // Reset state
        isTransitioning = false
        currentTransition = nil
        compositionLayer = nil
        fadeLayer = nil
        fromSceneState = nil
        toSceneState = nil
        self.fromScene = nil
        self.toScene = nil
        self.view = nil
    }

    // MARK: - Helper Functions

    private func offsetForDirection(_ direction: SKTransitionDirection, size: CGSize) -> CGPoint {
        switch direction {
        case .up:
            return CGPoint(x: 0, y: -size.height)
        case .down:
            return CGPoint(x: 0, y: size.height)
        case .left:
            return CGPoint(x: size.width, y: 0)
        case .right:
            return CGPoint(x: -size.width, y: 0)
        }
    }

    private func oppositeDirection(_ direction: SKTransitionDirection) -> SKTransitionDirection {
        switch direction {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    private func applyEasing(_ t: Float) -> Float {
        // Ease in/out cubic
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let f = (2 * t - 2)
            return 0.5 * f * f * f + 1
        }
    }

    private func configureCompositionLayer(
        for transition: SKTransition,
        fromScene: SKScene,
        toScene: SKScene
    ) {
        let size = CGSize(
            width: max(fromScene.size.width, toScene.size.width),
            height: max(fromScene.size.height, toScene.size.height)
        )
        let composition = CALayer()
        composition.anchorPoint = .zero
        composition.bounds = CGRect(origin: .zero, size: size)

        switch transition.transitionType {
        case .reveal, .doorsOpen, .doorway:
            composition.addSublayer(toScene.layer)
            composition.addSublayer(fromScene.layer)
        default:
            composition.addSublayer(fromScene.layer)
            composition.addSublayer(toScene.layer)
        }

        if case let .fade(color) = transition.transitionType {
            let overlay = CALayer()
            overlay.anchorPoint = .zero
            overlay.bounds = composition.bounds
            overlay.backgroundColor = color.cgColor
            overlay.opacity = 0
            composition.addSublayer(overlay)
            fadeLayer = overlay
        }
        compositionLayer = composition
    }

    private struct SceneState {
        let position: CGPoint
        let alpha: CGFloat
        let zPosition: CGFloat
        let xScale: CGFloat
        let yScale: CGFloat

        init(scene: SKScene) {
            position = scene.position
            alpha = scene.alpha
            zPosition = scene.zPosition
            xScale = scene.xScale
            yScale = scene.yScale
        }

        func restore(scene: SKScene) {
            scene.position = position
            scene.alpha = alpha
            scene.zPosition = zPosition
            scene.xScale = xScale
            scene.yScale = yScale
        }
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
