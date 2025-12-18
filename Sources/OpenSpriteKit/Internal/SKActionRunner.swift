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
        var speed: CGFloat?
        var charge: CGFloat?  // For physics body charge
        var mass: CGFloat?    // For physics body mass
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
        case .speedBy, .speedTo:
            state.speed = node.speed
        case .changeCharge:
            if let body = node.physicsBody {
                state.charge = body.charge
            }
        case .changeMass:
            if let body = node.physicsBody {
                state.mass = body.mass
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
            // This affects the node's speed property, starting from initial speed
            let initialSpeed = initialState.speed ?? node.speed
            node.speed = initialSpeed + delta * CGFloat(progress)

        case .speedTo(let targetSpeed):
            // Interpolate from initial speed to target speed
            let initialSpeed = initialState.speed ?? node.speed
            node.speed = initialSpeed + (targetSpeed - initialSpeed) * CGFloat(progress)

        // MARK: Normal Texture Actions
        case .setNormalTexture(let texture, let resize):
            if progress >= 1.0, let sprite = node as? SKSpriteNode {
                sprite.normalTexture = texture
                if resize {
                    sprite.size = texture.size
                }
            }

        case .animateNormalTextures(let textures, _, let resize, _):
            guard let sprite = node as? SKSpriteNode, !textures.isEmpty else { break }
            let totalFrames = textures.count
            let frameIndex = min(Int(Float(totalFrames) * progress), totalFrames - 1)
            let texture = textures[frameIndex]
            sprite.normalTexture = texture
            if resize {
                sprite.size = texture.size
            }

        // MARK: Colorize Actions
        case .colorize(let color, let blendFactor):
            if let sprite = node as? SKSpriteNode {
                sprite.color = color
                sprite.colorBlendFactor = CGFloat(progress) * blendFactor
            }

        case .colorizeWithBlendFactor(let blendFactor):
            if let sprite = node as? SKSpriteNode {
                sprite.colorBlendFactor = CGFloat(progress) * blendFactor
            }

        // MARK: Sound Actions
        case .playSoundFile(let filename, _):
            // Sound playback would require Web Audio API integration for WASM
            // This is a placeholder that logs the intent
            if progress >= 1.0 {
                #if DEBUG
                print("[SKAction] playSoundFile: \(filename)")
                #endif
            }

        case .play:
            if progress >= 1.0, let audioNode = node as? SKAudioNode {
                audioNode.isPositional = true  // Mark as playing
            }

        case .pause:
            if progress >= 1.0, let audioNode = node as? SKAudioNode {
                audioNode.isPositional = false  // Mark as paused
            }

        case .stop:
            if progress >= 1.0, let _ = node as? SKAudioNode {
                // Stop playback
            }

        case .changeVolume(let to, let by):
            // Audio volume changes would require integration with audio system
            _ = to
            _ = by

        case .changePlaybackRate(let to, let by):
            // Playback rate changes would require integration with audio system
            _ = to
            _ = by

        case .stereopan(let to, let by):
            // Stereo panning would require integration with audio system
            _ = to
            _ = by

        case .changeObstruction(let to, let by):
            _ = to
            _ = by

        case .changeOcclusion(let to, let by):
            _ = to
            _ = by

        case .changeReverb(let to, let by):
            _ = to
            _ = by

        // MARK: Physics Actions
        case .applyForce(let force, let point):
            if let body = node.physicsBody {
                if let point = point {
                    body.applyForce(force, at: point)
                } else {
                    body.applyForce(force)
                }
            }

        case .applyTorque(let torque):
            if let body = node.physicsBody {
                body.applyTorque(torque)
            }

        case .applyImpulse(let impulse, let point):
            if progress >= 1.0, let body = node.physicsBody {
                if let point = point {
                    body.applyImpulse(impulse, at: point)
                } else {
                    body.applyImpulse(impulse)
                }
            }

        case .applyAngularImpulse(let impulse):
            if progress >= 1.0, let body = node.physicsBody {
                body.applyAngularImpulse(impulse)
            }

        case .changeCharge(let to, let by):
            if let body = node.physicsBody {
                if let targetCharge = to {
                    // Use stored initial charge from InitialState
                    let initialCharge = initialState.charge ?? body.charge
                    body.charge = initialCharge + (CGFloat(targetCharge) - initialCharge) * CGFloat(progress)
                } else if let delta = by {
                    // For relative change, apply delta incrementally
                    let initialCharge = initialState.charge ?? body.charge
                    body.charge = initialCharge + CGFloat(delta) * CGFloat(progress)
                }
            }

        case .changeMass(let to, let by):
            if let body = node.physicsBody {
                if let targetMass = to {
                    // Use stored initial mass from InitialState
                    let initialMass = initialState.mass ?? body.mass
                    body.mass = initialMass + (CGFloat(targetMass) - initialMass) * CGFloat(progress)
                } else if let delta = by {
                    // For relative change, apply delta incrementally
                    let initialMass = initialState.mass ?? body.mass
                    body.mass = initialMass + CGFloat(delta) * CGFloat(progress)
                }
            }

        // MARK: Field Actions
        case .strength(let to, let by):
            if let field = node as? SKFieldNode {
                if let targetStrength = to {
                    let initialStrength = field.strength
                    field.strength = initialStrength + (targetStrength - initialStrength) * Float(progress)
                } else if let delta = by {
                    field.strength += delta * Float(progress) * Float(deltaTime)
                }
            }

        case .falloff(let to, let by):
            if let field = node as? SKFieldNode {
                if let targetFalloff = to {
                    let initialFalloff = field.falloff
                    field.falloff = initialFalloff + (targetFalloff - initialFalloff) * Float(progress)
                } else if let delta = by {
                    field.falloff += delta * Float(progress) * Float(deltaTime)
                }
            }

        // MARK: Inverse Kinematics Actions
        case .reach(let target, let rootNode, _):
            // Simplified IK implementation
            // Real IK would require iterative solving through the joint chain
            if progress >= 1.0 {
                solveIK(endEffector: node, target: target, rootNode: rootNode)
            } else {
                // Interpolate towards target
                let currentPos = node.position
                let interpolatedTarget = CGPoint(
                    x: currentPos.x + (target.x - currentPos.x) * CGFloat(progress),
                    y: currentPos.y + (target.y - currentPos.y) * CGFloat(progress)
                )
                solveIK(endEffector: node, target: interpolatedTarget, rootNode: rootNode)
            }

        case .reachToNode(let targetNode, let rootNode, _):
            let target = targetNode.position
            if let targetScene = targetNode.scene, let nodeScene = node.scene {
                if targetScene === nodeScene {
                    let worldTarget = targetNode.convert(.zero, to: nodeScene)
                    if progress >= 1.0 {
                        solveIK(endEffector: node, target: worldTarget, rootNode: rootNode)
                    } else {
                        let currentPos = node.position
                        let interpolatedTarget = CGPoint(
                            x: currentPos.x + (worldTarget.x - currentPos.x) * CGFloat(progress),
                            y: currentPos.y + (worldTarget.y - currentPos.y) * CGFloat(progress)
                        )
                        solveIK(endEffector: node, target: interpolatedTarget, rootNode: rootNode)
                    }
                }
            }

        // MARK: Warp Actions
        case .warp(let geometry):
            if var warpable = node as? SKWarpable {
                warpable.warpGeometry = geometry
            }

        case .animateWarps(let geometries, let times, _):
            guard !geometries.isEmpty, !times.isEmpty else { break }
            if var warpable = node as? SKWarpable {
                let totalDuration = times.last?.doubleValue ?? 1.0
                let currentTime = Double(progress) * totalDuration

                // Find the appropriate warp geometry for current time
                var warpIndex = 0
                for (index, time) in times.enumerated() {
                    if currentTime >= time.doubleValue {
                        warpIndex = index
                    } else {
                        break
                    }
                }

                if warpIndex < geometries.count {
                    warpable.warpGeometry = geometries[warpIndex]
                }
            }

        #if canImport(ObjectiveC)
        case .performSelector(let selector, let target):
            if progress >= 1.0 {
                _ = target.perform(selector)
            }
        #endif
        }
    }

    // MARK: - Inverse Kinematics Solver

    /// Simple two-bone IK solver using FABRIK algorithm.
    private func solveIK(endEffector: SKNode, target: CGPoint, rootNode: SKNode) {
        // Build the chain from end effector to root
        var chain: [SKNode] = []
        var current: SKNode? = endEffector

        while let node = current {
            chain.append(node)
            if node === rootNode {
                break
            }
            current = node.parent
        }

        guard chain.count >= 2 else { return }

        // FABRIK algorithm iterations
        let iterations = 10
        let tolerance: CGFloat = 0.001

        // Get joint positions in world space
        var positions = chain.map { node -> CGPoint in
            if let scene = node.scene {
                return node.convert(.zero, to: scene)
            }
            return node.position
        }

        // Calculate bone lengths
        var lengths: [CGFloat] = []
        for i in 0..<(positions.count - 1) {
            let dx = positions[i + 1].x - positions[i].x
            let dy = positions[i + 1].y - positions[i].y
            lengths.append(sqrt(dx * dx + dy * dy))
        }

        let rootPosition = positions.last!

        for _ in 0..<iterations {
            // Forward reaching (from end effector to root)
            positions[0] = target

            for i in 1..<positions.count {
                let direction = normalize(subtractPoints(positions[i], positions[i - 1]))
                positions[i] = addPoints(positions[i - 1], multiplyPoint(direction, lengths[i - 1]))
            }

            // Backward reaching (from root to end effector)
            positions[positions.count - 1] = rootPosition

            for i in stride(from: positions.count - 2, through: 0, by: -1) {
                let direction = normalize(subtractPoints(positions[i], positions[i + 1]))
                positions[i] = addPoints(positions[i + 1], multiplyPoint(direction, lengths[i]))
            }

            // Check if close enough to target
            let dx = positions[0].x - target.x
            let dy = positions[0].y - target.y
            if sqrt(dx * dx + dy * dy) < tolerance {
                break
            }
        }

        // Apply rotations to joints
        for i in 0..<(chain.count - 1) {
            let node = chain[i]
            let parent = chain[i + 1]

            let dx = positions[i].x - positions[i + 1].x
            let dy = positions[i].y - positions[i + 1].y
            let angle = atan2(dy, dx)

            // Apply constraints if any
            var constrainedAngle = angle
            if let constraints = node.constraints {
                for constraint in constraints {
                    if let rotationConstraint = constraint.constraintType {
                        if case .zRotation(let range) = rotationConstraint {
                            constrainedAngle = max(range.lowerLimit, min(range.upperLimit, constrainedAngle))
                        }
                    }
                }
            }

            node.zRotation = constrainedAngle
        }
    }

    /// Normalizes a vector.
    private func normalize(_ point: CGPoint) -> CGPoint {
        let length = sqrt(point.x * point.x + point.y * point.y)
        guard length > 0 else { return CGPoint(x: 1, y: 0) }
        return CGPoint(x: point.x / length, y: point.y / length)
    }

    /// Subtracts two points.
    private func subtractPoints(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// Adds two points.
    private func addPoints(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    /// Multiplies a point by a scalar.
    private func multiplyPoint(_ point: CGPoint, _ scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
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
