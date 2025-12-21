// SKTransitionManager.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
import OpenCoreAnimation

/// Manages scene transitions and their animations.
@MainActor
internal final class SKTransitionManager {

    // MARK: - Singleton

    static let shared = SKTransitionManager()

    private init() {}

    // MARK: - Transition State

    private var isTransitioning: Bool = false
    private var startTime: TimeInterval = 0
    private var currentTransition: SKTransition?

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

        // Set initial state for the incoming scene
        setupInitialState(for: transition, toScene: toScene)
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
        let progress = min(Float(elapsed / transition.duration), 1.0)

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

    private func setupInitialState(for transition: SKTransition, toScene: SKScene) {
        let type = transition.transitionType

        switch type {
        case .crossFade:
            toScene.alpha = 0

        case .fade, .fadeIn:
            toScene.alpha = 0

        case .fadeOut:
            // Fade out shows black, then incoming scene
            toScene.alpha = 0

        case .moveIn(let direction):
            let offset = offsetForDirection(direction, size: toScene.size)
            toScene.position = offset

        case .push(let direction):
            let offset = offsetForDirection(direction, size: toScene.size)
            toScene.position = offset

        case .reveal(let direction):
            // Outgoing scene moves to reveal incoming scene underneath
            toScene.zPosition = -1

        case .flip(let direction):
            // 3D flip would require more complex animation
            toScene.alpha = 0

        case .doorsOpen(let horizontal):
            toScene.alpha = 0

        case .doorsClose(let horizontal):
            toScene.alpha = 0

        case .doorway:
            toScene.alpha = 0

        case .ciFilter:
            // Filter-based transitions would use CIImage
            toScene.alpha = 0

        case .none:
            break
        }
    }

    private func updateTransition(_ transition: SKTransition, fromScene: SKScene, toScene: SKScene, progress: Float) {
        let type = transition.transitionType
        let p = CGFloat(progress)

        switch type {
        case .crossFade:
            fromScene.alpha = 1 - p
            toScene.alpha = p

        case .fade(let color):
            // First half: fade out to color
            // Second half: fade in from color
            if progress < 0.5 {
                let fadeOut = CGFloat(progress * 2)
                fromScene.alpha = 1 - fadeOut
                toScene.alpha = 0
            } else {
                let fadeIn = CGFloat((progress - 0.5) * 2)
                fromScene.alpha = 0
                toScene.alpha = fadeIn
            }

        case .fadeIn:
            toScene.alpha = p

        case .fadeOut:
            fromScene.alpha = 1 - p
            if progress >= 0.5 {
                toScene.alpha = 1
            }

        case .moveIn(let direction):
            let fullOffset = offsetForDirection(direction, size: toScene.size)
            toScene.position = CGPoint(
                x: fullOffset.x * (1 - p),
                y: fullOffset.y * (1 - p)
            )

        case .push(let direction):
            let fullOffset = offsetForDirection(direction, size: toScene.size)
            toScene.position = CGPoint(
                x: fullOffset.x * (1 - p),
                y: fullOffset.y * (1 - p)
            )
            let outOffset = offsetForDirection(oppositeDirection(direction), size: fromScene.size)
            fromScene.position = CGPoint(
                x: outOffset.x * p,
                y: outOffset.y * p
            )

        case .reveal(let direction):
            let outOffset = offsetForDirection(direction, size: fromScene.size)
            fromScene.position = CGPoint(
                x: outOffset.x * p,
                y: outOffset.y * p
            )

        case .flip(let direction):
            // Simplified flip - just crossfade
            fromScene.alpha = 1 - p
            toScene.alpha = p

        case .doorsOpen(let horizontal):
            if progress < 0.5 {
                // Doors opening
                fromScene.alpha = 1
                toScene.alpha = 0
            } else {
                fromScene.alpha = 0
                toScene.alpha = 1
            }

        case .doorsClose(let horizontal):
            if progress < 0.5 {
                toScene.alpha = 0
            } else {
                toScene.alpha = CGFloat((progress - 0.5) * 2)
            }

        case .doorway:
            // Crossfade for doorway
            fromScene.alpha = 1 - p
            toScene.alpha = p

        case .ciFilter:
            // Filter transitions would need custom rendering
            fromScene.alpha = 1 - p
            toScene.alpha = p

        case .none:
            toScene.alpha = 1
        }
    }

    private func completeTransition(view: SKView, fromScene: SKScene, toScene: SKScene, transition: SKTransition) {
        // Clean up outgoing scene
        fromScene.willMove(from: view)
        fromScene._view = nil
        fromScene.position = .zero
        fromScene.alpha = 1

        // Reset physics state for outgoing scene
        SKPhysicsEngine.shared.reset(for: fromScene)

        // Restore incoming scene state
        toScene.position = .zero
        toScene.alpha = 1
        toScene.zPosition = 0

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
}
