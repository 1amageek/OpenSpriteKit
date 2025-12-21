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

        /// Duration calculated at runtime for velocity-based actions.
        /// If nil, uses action.duration.
        var calculatedDuration: TimeInterval?

        /// Effective duration considering both action.duration and calculatedDuration.
        var effectiveDuration: TimeInterval {
            calculatedDuration ?? action.duration
        }
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
        var color: SKColor?   // For SKSpriteNode colorize
        var colorBlendFactor: CGFloat?  // For SKSpriteNode colorize
        var strength: Float?  // For SKFieldNode
        var falloff: Float?   // For SKFieldNode
        var warpGeometry: SKWarpGeometry?  // For SKWarpable nodes
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

        // Calculate duration for velocity-based reach actions
        runningAction.calculatedDuration = calculateVelocityBasedDuration(for: action, from: node)

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
        // Use effectiveDuration which may be calculated at runtime for velocity-based actions
        let duration = runningAction.effectiveDuration
        var progress: Float

        if duration <= 0 || duration == .infinity {
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
        case .scaleTo, .scaleBy, .scaleXYBy, .scaleToSize:
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
        case .colorize, .colorizeWithBlendFactor:
            if let sprite = node as? SKSpriteNode {
                state.color = sprite.color
                state.colorBlendFactor = sprite.colorBlendFactor
            }
        case .strength, .falloff:
            if let field = node as? SKFieldNode {
                state.strength = field.strength
                state.falloff = field.falloff
            }
        case .warp, .animateWarps:
            if let warpable = node as? SKWarpable {
                state.warpGeometry = warpable.warpGeometry
            }
        default:
            break
        }

        return state
    }

    /// Calculates duration for velocity-based actions.
    ///
    /// For reach actions with velocity, the duration is calculated as distance / velocity.
    /// Returns nil for actions that don't need velocity-based duration calculation.
    private func calculateVelocityBasedDuration(for action: SKAction, from node: SKNode) -> TimeInterval? {
        switch action.actionType {
        case .reach(let target, _, let velocity):
            guard let velocity = velocity, velocity > 0 else { return nil }
            let dx = target.x - node.position.x
            let dy = target.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)
            return TimeInterval(distance / velocity)

        case .reachToNode(let targetNode, _, let velocity):
            guard let velocity = velocity, velocity > 0 else { return nil }
            // Convert target node position to common coordinate space
            guard let scene = node.scene, targetNode.scene === scene else { return nil }
            let worldTarget = targetNode.convert(.zero, to: scene)
            let dx = worldTarget.x - node.position.x
            let dy = worldTarget.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)
            return TimeInterval(distance / velocity)

        default:
            return nil
        }
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

        case .followPath(let path, let asOffset, let orientToPath):
            if let initialPos = initialState.position {
                // Get point along path at progress
                let point = pointOnPath(path, at: CGFloat(progress))
                if asOffset {
                    node.position = CGPoint(x: initialPos.x + point.x, y: initialPos.y + point.y)
                } else {
                    node.position = point
                }

                // Orient to path: rotate node to match tangent direction
                if orientToPath {
                    let tangentAngle = tangentOnPath(path, at: CGFloat(progress))
                    node.zRotation = tangentAngle
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
                // scaleBy multiplies: interpolate the multiplier from 1 to target
                // At progress=0: initialX * 1 = initialX
                // At progress=1: initialX * xScale
                node.xScale = initialX * (1 + (xScale - 1) * CGFloat(progress))
                node.yScale = initialY * (1 + (yScale - 1) * CGFloat(progress))
            }

        case .scaleXYBy(let dx, let dy):
            if let initialX = initialState.xScale, let initialY = initialState.yScale {
                // scaleXYBy adds: simply add the delta scaled by progress
                // At progress=0: initialX + 0 = initialX
                // At progress=1: initialX + dx
                node.xScale = initialX + dx * CGFloat(progress)
                node.yScale = initialY + dy * CGFloat(progress)
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
                    runningAction.elapsedTime = runningAction.effectiveDuration
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
                runningAction.elapsedTime = runningAction.effectiveDuration
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
                        runningAction.elapsedTime = runningAction.effectiveDuration
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
            block(node, CGFloat(progress) * CGFloat(runningAction.effectiveDuration))

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
        case .colorize(let targetColor, let targetBlendFactor):
            if let sprite = node as? SKSpriteNode {
                let initialBlend = initialState.colorBlendFactor ?? sprite.colorBlendFactor
                // Interpolate color if we have initial color
                if let initialColor = initialState.color {
                    // Interpolate RGBA components
                    let p = CGFloat(progress)
                    var initialR: CGFloat = 0, initialG: CGFloat = 0, initialB: CGFloat = 0, initialA: CGFloat = 0
                    var targetR: CGFloat = 0, targetG: CGFloat = 0, targetB: CGFloat = 0, targetA: CGFloat = 0

                    initialColor.getRed(&initialR, green: &initialG, blue: &initialB, alpha: &initialA)
                    targetColor.getRed(&targetR, green: &targetG, blue: &targetB, alpha: &targetA)

                    sprite.color = SKColor(
                        red: initialR + (targetR - initialR) * p,
                        green: initialG + (targetG - initialG) * p,
                        blue: initialB + (targetB - initialB) * p,
                        alpha: initialA + (targetA - initialA) * p
                    )
                } else {
                    sprite.color = targetColor
                }
                // Interpolate blend factor from initial to target
                sprite.colorBlendFactor = initialBlend + (targetBlendFactor - initialBlend) * CGFloat(progress)
            }

        case .colorizeWithBlendFactor(let targetBlendFactor):
            if let sprite = node as? SKSpriteNode {
                let initialBlend = initialState.colorBlendFactor ?? sprite.colorBlendFactor
                sprite.colorBlendFactor = initialBlend + (targetBlendFactor - initialBlend) * CGFloat(progress)
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
                let initialStrength = initialState.strength ?? field.strength
                if let targetStrength = to {
                    field.strength = initialStrength + (targetStrength - initialStrength) * Float(progress)
                } else if let delta = by {
                    // For relative change, apply delta based on initial value
                    field.strength = initialStrength + delta * Float(progress)
                }
            }

        case .falloff(let to, let by):
            if let field = node as? SKFieldNode {
                let initialFalloff = initialState.falloff ?? field.falloff
                if let targetFalloff = to {
                    field.falloff = initialFalloff + (targetFalloff - initialFalloff) * Float(progress)
                } else if let delta = by {
                    // For relative change, apply delta based on initial value
                    field.falloff = initialFalloff + delta * Float(progress)
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
        case .warp(let targetGeometry):
            if var warpable = node as? SKWarpable {
                // If we have both initial and target geometries, interpolate
                if let initialGeometry = initialState.warpGeometry as? SKWarpGeometryGrid,
                   let targetGrid = targetGeometry as? SKWarpGeometryGrid,
                   initialGeometry.numberOfColumns == targetGrid.numberOfColumns,
                   initialGeometry.numberOfRows == targetGrid.numberOfRows {
                    // Interpolate destination positions
                    let interpolatedGeometry = interpolateWarpGeometry(
                        from: initialGeometry,
                        to: targetGrid,
                        progress: Float(progress)
                    )
                    warpable.warpGeometry = interpolatedGeometry
                } else {
                    // If geometries are incompatible, just set the target at completion
                    if progress >= 1.0 {
                        warpable.warpGeometry = targetGeometry
                    }
                }
            }

        case .animateWarps(let geometries, let times, _):
            guard !geometries.isEmpty, !times.isEmpty else { break }
            if var warpable = node as? SKWarpable {
                let totalDuration = times.last ?? 1.0
                let currentTime = Double(progress) * totalDuration

                // Find the appropriate warp geometry for current time
                var warpIndex = 0
                for (index, time) in times.enumerated() {
                    if currentTime >= time {
                        warpIndex = index
                    } else {
                        break
                    }
                }

                if warpIndex < geometries.count {
                    // If we can interpolate to next geometry, do so
                    if warpIndex + 1 < geometries.count,
                       let currentGrid = geometries[warpIndex] as? SKWarpGeometryGrid,
                       let nextGrid = geometries[warpIndex + 1] as? SKWarpGeometryGrid,
                       currentGrid.numberOfColumns == nextGrid.numberOfColumns,
                       currentGrid.numberOfRows == nextGrid.numberOfRows {
                        let startTime = times[warpIndex]
                        let endTime = times[warpIndex + 1]
                        let segmentProgress = Float((currentTime - startTime) / (endTime - startTime))
                        let clampedProgress = max(0, min(1, segmentProgress))
                        warpable.warpGeometry = interpolateWarpGeometry(
                            from: currentGrid,
                            to: nextGrid,
                            progress: clampedProgress
                        )
                    } else {
                        warpable.warpGeometry = geometries[warpIndex]
                    }
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

    /// Calculates the tangent angle on a path at a given progress.
    ///
    /// - Parameters:
    ///   - path: The path to calculate the tangent on.
    ///   - progress: Progress along the path (0.0 to 1.0).
    /// - Returns: The tangent angle in radians.
    private func tangentOnPath(_ path: CGPath, at progress: CGFloat) -> CGFloat {
        // Get two points slightly apart to calculate tangent
        let epsilon: CGFloat = 0.001
        let p1 = pointOnPath(path, at: max(0, progress - epsilon))
        let p2 = pointOnPath(path, at: min(1, progress + epsilon))

        let dx = p2.x - p1.x
        let dy = p2.y - p1.y

        // atan2 returns angle in radians, where 0 = right, π/2 = up
        return atan2(dy, dx)
    }

    // MARK: - Warp Geometry Interpolation

    /// Interpolates between two warp geometries.
    ///
    /// - Parameters:
    ///   - from: The source warp geometry.
    ///   - to: The destination warp geometry.
    ///   - progress: The interpolation progress (0.0 to 1.0).
    /// - Returns: An interpolated warp geometry.
    private func interpolateWarpGeometry(from: SKWarpGeometryGrid, to: SKWarpGeometryGrid, progress: Float) -> SKWarpGeometryGrid {
        // Interpolate destination positions
        var interpolatedDestinations: [SIMD2<Float>] = []
        let count = min(from.destinationPositions.count, to.destinationPositions.count)

        for i in 0..<count {
            let fromPos = from.destinationPositions[i]
            let toPos = to.destinationPositions[i]
            let interpolated = SIMD2<Float>(
                fromPos.x + (toPos.x - fromPos.x) * progress,
                fromPos.y + (toPos.y - fromPos.y) * progress
            )
            interpolatedDestinations.append(interpolated)
        }

        // Use the source positions from the 'from' geometry (they should be the same)
        return SKWarpGeometryGrid(
            columns: from.numberOfColumns,
            rows: from.numberOfRows,
            sourcePositions: from.sourcePositions,
            destinationPositions: interpolatedDestinations
        )
    }
}
