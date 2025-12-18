// SKActionRunner.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// Manages the execution of SKActions on nodes.
///
/// SKActionRunner is responsible for:
/// - Tracking running actions and their elapsed time
/// - Capturing initial state for "to" actions
/// - Applying timing functions
/// - Executing completion callbacks
/// - Supporting compound actions (sequence, group, repeat)
///
/// - Note: This class is accessed from the main thread only (display link callbacks and SKNode methods).
internal final class SKActionRunner {

    // MARK: - Singleton

    /// Shared instance of the action runner.
    /// Using nonisolated(unsafe) since access is always from main thread.
    nonisolated(unsafe) static let shared = SKActionRunner()

    private init() {}

    /// Resets all running actions (for testing purposes).
    func reset() {
        runningActions.removeAll()
        anonymousActions.removeAll()
    }

    // MARK: - Running Action State

    /// Stores the state of a running action.
    struct RunningAction {
        let action: SKAction
        var elapsedTime: TimeInterval
        var initialState: InitialState
        var completion: (() -> Void)?
        var isCompleted: Bool = false

        // For compound actions
        var currentIndex: Int = 0  // For sequence
        var childStates: [RunningAction]?  // For group/sequence
        var repeatCount: Int = 0  // For repeat
    }

    /// Captures the initial state of a node for interpolation.
    struct InitialState {
        var position: CGPoint?
        var zRotation: CGFloat?
        var xScale: CGFloat?
        var yScale: CGFloat?
        var alpha: CGFloat?
        var size: CGSize?  // For SKSpriteNode
    }

    // MARK: - Properties

    /// Maps node identifiers to their running actions.
    private var runningActions: [ObjectIdentifier: [String: RunningAction]] = [:]

    /// Anonymous actions (actions without keys).
    private var anonymousActions: [ObjectIdentifier: [RunningAction]] = [:]

    // MARK: - Action Management

    /// Registers an action to run on a node.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - node: The node to run the action on.
    ///   - key: Optional key to identify the action.
    ///   - completion: Optional completion block.
    func runAction(_ action: SKAction, on node: SKNode, withKey key: String? = nil, completion: (() -> Void)? = nil) {
        let nodeId = ObjectIdentifier(node)
        let initialState = captureInitialState(for: action, from: node)

        var runningAction = RunningAction(
            action: action,
            elapsedTime: 0,
            initialState: initialState,
            completion: completion
        )

        // Initialize child states for compound actions
        if case .group(let actions) = action.actionType {
            runningAction.childStates = actions.map { childAction in
                RunningAction(
                    action: childAction,
                    elapsedTime: 0,
                    initialState: captureInitialState(for: childAction, from: node),
                    completion: nil
                )
            }
        } else if case .sequence(let actions) = action.actionType, !actions.isEmpty {
            let firstAction = actions[0]
            runningAction.childStates = [RunningAction(
                action: firstAction,
                elapsedTime: 0,
                initialState: captureInitialState(for: firstAction, from: node),
                completion: nil
            )]
            runningAction.currentIndex = 0
        }

        if let key = key {
            // Remove existing action with same key
            runningActions[nodeId]?[key] = nil
            if runningActions[nodeId] == nil {
                runningActions[nodeId] = [:]
            }
            runningActions[nodeId]?[key] = runningAction
        } else {
            if anonymousActions[nodeId] == nil {
                anonymousActions[nodeId] = []
            }
            anonymousActions[nodeId]?.append(runningAction)
        }
    }

    /// Removes all actions from a node.
    func removeAllActions(from node: SKNode) {
        let nodeId = ObjectIdentifier(node)
        runningActions[nodeId] = nil
        anonymousActions[nodeId] = nil
    }

    /// Removes an action with a specific key from a node.
    func removeAction(forKey key: String, from node: SKNode) {
        let nodeId = ObjectIdentifier(node)
        runningActions[nodeId]?[key] = nil
    }

    // MARK: - Update Loop

    /// Updates all running actions.
    ///
    /// - Parameters:
    ///   - scene: The scene containing the nodes.
    ///   - deltaTime: The time elapsed since the last update.
    func update(scene: SKScene, deltaTime: TimeInterval) {
        updateActionsRecursively(node: scene, deltaTime: deltaTime)
    }

    private func updateActionsRecursively(node: SKNode, deltaTime: TimeInterval) {
        // Skip if paused
        guard !node.isPaused else { return }

        // Calculate effective delta time based on node's speed
        let effectiveDelta = deltaTime * Double(node.speed)

        // Update keyed actions
        let nodeId = ObjectIdentifier(node)
        if var keyedActions = runningActions[nodeId] {
            var keysToRemove: [String] = []

            for (key, var runningAction) in keyedActions {
                if updateRunningAction(&runningAction, on: node, deltaTime: effectiveDelta) {
                    // Action completed
                    runningAction.completion?()
                    keysToRemove.append(key)
                } else {
                    keyedActions[key] = runningAction
                }
            }

            for key in keysToRemove {
                keyedActions[key] = nil
            }
            runningActions[nodeId] = keyedActions.isEmpty ? nil : keyedActions
        }

        // Update anonymous actions
        if var anons = anonymousActions[nodeId] {
            var indicesToRemove: [Int] = []

            for i in anons.indices {
                if updateRunningAction(&anons[i], on: node, deltaTime: effectiveDelta) {
                    // Action completed
                    anons[i].completion?()
                    indicesToRemove.append(i)
                }
            }

            // Remove completed actions in reverse order
            for i in indicesToRemove.reversed() {
                anons.remove(at: i)
            }
            anonymousActions[nodeId] = anons.isEmpty ? nil : anons
        }

        // Recurse to children
        for child in node.children {
            updateActionsRecursively(node: child, deltaTime: effectiveDelta)
        }
    }

    // MARK: - Action Execution

    /// Updates a single running action.
    ///
    /// - Returns: `true` if the action is completed.
    private func updateRunningAction(_ runningAction: inout RunningAction, on node: SKNode, deltaTime: TimeInterval) -> Bool {
        let action = runningAction.action
        let effectiveDelta = deltaTime * Double(action.speed)

        runningAction.elapsedTime += effectiveDelta

        // Calculate progress (0.0 to 1.0)
        let duration = action.duration
        var progress: Float

        if duration <= 0 {
            progress = 1.0
        } else {
            progress = Float(min(runningAction.elapsedTime / duration, 1.0))
        }

        // Apply timing mode
        progress = applyTimingMode(progress, mode: action.timingMode)

        // Apply custom timing function
        progress = action.timingFunction(progress)

        // Execute the action based on its type
        executeAction(action, on: node, progress: progress, initialState: runningAction.initialState, runningAction: &runningAction, deltaTime: effectiveDelta)

        // Check if completed
        if duration <= 0 {
            return true
        }
        return runningAction.elapsedTime >= duration
    }

    // MARK: - Timing Functions

    private func applyTimingMode(_ t: Float, mode: SKActionTimingMode) -> Float {
        switch mode {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return t * (2 - t)
        case .easeInEaseOut:
            if t < 0.5 {
                return 2 * t * t
            } else {
                return -1 + (4 - 2 * t) * t
            }
        }
    }

    // MARK: - Initial State Capture

    private func captureInitialState(for action: SKAction, from node: SKNode) -> InitialState {
        var state = InitialState()

        switch action.actionType {
        case .moveTo, .moveBy, .followPath:
            state.position = node.position
        case .rotateTo, .rotateBy:
            state.zRotation = node.zRotation
        case .scaleTo, .scaleBy, .scaleToSize:
            state.xScale = node.xScale
            state.yScale = node.yScale
        case .fadeAlphaTo, .fadeAlphaBy:
            state.alpha = node.alpha
        case .resizeTo, .resizeBy:
            if let sprite = node as? SKSpriteNode {
                state.size = sprite.size
            }
        default:
            break
        }

        return state
    }

    // MARK: - Action Execution

    private func executeAction(_ action: SKAction, on node: SKNode, progress: Float, initialState: InitialState, runningAction: inout RunningAction, deltaTime: TimeInterval) {
        switch action.actionType {

        // MARK: Movement Actions
        case .moveBy(let dx, let dy):
            if let initialPos = initialState.position {
                node.position = CGPoint(
                    x: initialPos.x + dx * CGFloat(progress),
                    y: initialPos.y + dy * CGFloat(progress)
                )
            }

        case .moveTo(let x, let y):
            if let initialPos = initialState.position {
                let targetX = x ?? initialPos.x
                let targetY = y ?? initialPos.y
                node.position = CGPoint(
                    x: initialPos.x + (targetX - initialPos.x) * CGFloat(progress),
                    y: initialPos.y + (targetY - initialPos.y) * CGFloat(progress)
                )
            }

        case .followPath(let path, let asOffset, _):
            if let initialPos = initialState.position {
                // Get point along path at progress
                let point = pointOnPath(path, at: CGFloat(progress))
                if asOffset {
                    node.position = CGPoint(x: initialPos.x + point.x, y: initialPos.y + point.y)
                } else {
                    node.position = point
                }
            }

        // MARK: Rotation Actions
        case .rotateBy(let angle):
            if let initialRotation = initialState.zRotation {
                node.zRotation = initialRotation + angle * CGFloat(progress)
            }

        case .rotateTo(let angle, let shortestUnitArc):
            if let initialRotation = initialState.zRotation {
                var targetAngle = angle
                if shortestUnitArc {
                    // Calculate shortest arc
                    let diff = angle - initialRotation
                    let twoPi = CGFloat.pi * 2
                    let normalized = diff - twoPi * floor((diff + .pi) / twoPi)
                    targetAngle = initialRotation + normalized
                }
                node.zRotation = initialRotation + (targetAngle - initialRotation) * CGFloat(progress)
            }

        // MARK: Scale Actions
        case .scaleBy(let xScale, let yScale):
            if let initialX = initialState.xScale, let initialY = initialState.yScale {
                // scaleBy multiplies, so we interpolate the multiplier
                node.xScale = initialX * (1 + (xScale - 1) * CGFloat(progress))
                node.yScale = initialY * (1 + (yScale - 1) * CGFloat(progress))
            }

        case .scaleTo(let xScale, let yScale):
            if let initialX = initialState.xScale, let initialY = initialState.yScale {
                let targetX = xScale ?? initialX
                let targetY = yScale ?? initialY
                node.xScale = initialX + (targetX - initialX) * CGFloat(progress)
                node.yScale = initialY + (targetY - initialY) * CGFloat(progress)
            }

        case .scaleToSize(let size):
            if let sprite = node as? SKSpriteNode, let initialSize = initialState.size {
                let newWidth = initialSize.width + (size.width - initialSize.width) * CGFloat(progress)
                let newHeight = initialSize.height + (size.height - initialSize.height) * CGFloat(progress)
                sprite.size = CGSize(width: newWidth, height: newHeight)
            }

        // MARK: Alpha Actions
        case .fadeAlphaBy(let delta):
            if let initialAlpha = initialState.alpha {
                node.alpha = initialAlpha + delta * CGFloat(progress)
            }

        case .fadeAlphaTo(let alpha):
            if let initialAlpha = initialState.alpha {
                node.alpha = initialAlpha + (alpha - initialAlpha) * CGFloat(progress)
            }

        case .hide:
            if progress >= 1.0 {
                node.isHidden = true
            }

        case .unhide:
            if progress >= 1.0 {
                node.isHidden = false
            }

        // MARK: Texture Actions
        case .setTexture(let texture, let resize):
            if progress >= 1.0, let sprite = node as? SKSpriteNode {
                sprite.texture = texture
                if resize {
                    sprite.size = texture.size
                }
            }

        case .animateTextures(let textures, _, let resize, _):
            guard let sprite = node as? SKSpriteNode, !textures.isEmpty else { break }
            let totalFrames = textures.count
            let frameIndex = min(Int(Float(totalFrames) * progress), totalFrames - 1)
            let texture = textures[frameIndex]
            sprite.texture = texture
            if resize {
                sprite.size = texture.size
            }

        // MARK: Resize Actions
        case .resizeBy(let width, let height):
            if let sprite = node as? SKSpriteNode, let initialSize = initialState.size {
                sprite.size = CGSize(
                    width: initialSize.width + width * CGFloat(progress),
                    height: initialSize.height + height * CGFloat(progress)
                )
            }

        case .resizeTo(let width, let height):
            if let sprite = node as? SKSpriteNode, let initialSize = initialState.size {
                let targetWidth = width ?? initialSize.width
                let targetHeight = height ?? initialSize.height
                sprite.size = CGSize(
                    width: initialSize.width + (targetWidth - initialSize.width) * CGFloat(progress),
                    height: initialSize.height + (targetHeight - initialSize.height) * CGFloat(progress)
                )
            }

        // MARK: Compound Actions
        case .group(_):
            // Execute all child actions in parallel
            if var childStates = runningAction.childStates {
                var allCompleted = true
                for i in childStates.indices {
                    if !childStates[i].isCompleted {
                        let completed = updateRunningAction(&childStates[i], on: node, deltaTime: deltaTime)
                        if completed {
                            childStates[i].isCompleted = true
                        } else {
                            allCompleted = false
                        }
                    }
                }
                runningAction.childStates = childStates
                if allCompleted {
                    runningAction.elapsedTime = action.duration
                }
            }

        case .sequence(let actions):
            // Execute actions one at a time
            guard !actions.isEmpty else { break }
            if runningAction.childStates == nil {
                runningAction.childStates = []
                runningAction.currentIndex = 0
            }

            while runningAction.currentIndex < actions.count {
                let currentAction = actions[runningAction.currentIndex]

                // Initialize child state if needed
                if runningAction.childStates?.isEmpty ?? true {
                    runningAction.childStates = [RunningAction(
                        action: currentAction,
                        elapsedTime: 0,
                        initialState: captureInitialState(for: currentAction, from: node),
                        completion: nil
                    )]
                }

                // Update current action
                if var childState = runningAction.childStates?.first {
                    let completed = updateRunningAction(&childState, on: node, deltaTime: deltaTime)
                    if completed {
                        runningAction.currentIndex += 1
                        runningAction.childStates = []
                        // Continue to next action in same frame if time permits
                        continue
                    } else {
                        runningAction.childStates = [childState]
                        break
                    }
                }
                break
            }

            if runningAction.currentIndex >= actions.count {
                runningAction.elapsedTime = action.duration
            }

        case .repeatAction(let repeatedAction, let count):
            // Handle repeat with count
            if runningAction.childStates == nil {
                runningAction.childStates = [RunningAction(
                    action: repeatedAction,
                    elapsedTime: 0,
                    initialState: captureInitialState(for: repeatedAction, from: node),
                    completion: nil
                )]
                runningAction.repeatCount = 0
            }

            if var childState = runningAction.childStates?.first {
                let completed = updateRunningAction(&childState, on: node, deltaTime: deltaTime)
                if completed {
                    runningAction.repeatCount += 1
                    if runningAction.repeatCount < count {
                        // Reset for next iteration
                        runningAction.childStates = [RunningAction(
                            action: repeatedAction,
                            elapsedTime: 0,
                            initialState: captureInitialState(for: repeatedAction, from: node),
                            completion: nil
                        )]
                    } else {
                        runningAction.elapsedTime = action.duration
                    }
                } else {
                    runningAction.childStates = [childState]
                }
            }

        case .repeatForever(let repeatedAction):
            // Handle repeat forever
            if runningAction.childStates == nil {
                runningAction.childStates = [RunningAction(
                    action: repeatedAction,
                    elapsedTime: 0,
                    initialState: captureInitialState(for: repeatedAction, from: node),
                    completion: nil
                )]
            }

            if var childState = runningAction.childStates?.first {
                let completed = updateRunningAction(&childState, on: node, deltaTime: deltaTime)
                if completed {
                    // Reset for next iteration
                    runningAction.childStates = [RunningAction(
                        action: repeatedAction,
                        elapsedTime: 0,
                        initialState: captureInitialState(for: repeatedAction, from: node),
                        completion: nil
                    )]
                } else {
                    runningAction.childStates = [childState]
                }
            }
            // repeatForever never completes

        case .wait:
            // Just wait, nothing to do
            break

        case .runBlock(let block):
            if progress >= 1.0 {
                block()
            }

        #if canImport(Dispatch)
        case .runBlockOnQueue(let block, let queue):
            if progress >= 1.0 {
                queue.async { block() }
            }
        #endif

        case .customAction(let block):
            block(node, CGFloat(progress) * CGFloat(action.duration))

        case .removeFromParent:
            if progress >= 1.0 {
                node.removeFromParent()
            }

        case .runOnChild(let childAction, let name):
            if progress >= 1.0 {
                if let child = node.childNode(withName: name) {
                    child.run(childAction)
                }
            }

        // MARK: Speed Actions
        case .speedBy(let delta):
            // This affects the node's speed property
            node.speed = 1.0 + delta * CGFloat(progress)

        case .speedTo(let targetSpeed):
            node.speed = 1.0 + (targetSpeed - 1.0) * CGFloat(progress)

        // MARK: Other Actions (placeholder implementations)
        default:
            // TODO: Implement remaining action types
            break
        }
    }

    // MARK: - Path Helpers

    private func pointOnPath(_ path: CGPath, at progress: CGFloat) -> CGPoint {
        // Approximate point on path at given progress
        // This is a simplified implementation
        var points: [CGPoint] = []

        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                points.append(element.pointee.points[0])
            case .addQuadCurveToPoint:
                points.append(element.pointee.points[1])
            case .addCurveToPoint:
                points.append(element.pointee.points[2])
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }

        guard points.count > 1 else {
            return points.first ?? .zero
        }

        // Calculate total path length
        var totalLength: CGFloat = 0
        for i in 1..<points.count {
            let dx = points[i].x - points[i-1].x
            let dy = points[i].y - points[i-1].y
            totalLength += sqrt(dx*dx + dy*dy)
        }

        // Find point at progress
        let targetLength = totalLength * progress
        var currentLength: CGFloat = 0

        for i in 1..<points.count {
            let dx = points[i].x - points[i-1].x
            let dy = points[i].y - points[i-1].y
            let segmentLength = sqrt(dx*dx + dy*dy)

            if currentLength + segmentLength >= targetLength {
                let t = (targetLength - currentLength) / segmentLength
                return CGPoint(
                    x: points[i-1].x + dx * t,
                    y: points[i-1].y + dy * t
                )
            }
            currentLength += segmentLength
        }

        return points.last ?? .zero
    }
}
