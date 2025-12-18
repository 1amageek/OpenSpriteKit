// SKAction.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation
#if canImport(Dispatch)
import Dispatch
#endif

/// The signature for the custom timing block.
public typealias SKActionTimingFunction = (Float) -> Float

/// The modes that an action can use to adjust the apparent timing of the action.
public enum SKActionTimingMode: Int, Sendable, Hashable {
    /// Linear timing means that the action executes at a constant rate throughout its duration.
    case linear = 0

    /// Ease-in timing means that the action begins slowly and then speeds up as it progresses.
    case easeIn = 1

    /// Ease-out timing means that the action begins at the normal rate and then slows down as it completes.
    case easeOut = 2

    /// Ease-in/ease-out timing means that the action begins slowly, accelerates through the middle
    /// of its duration, and then slows down again as it completes.
    case easeInEaseOut = 3
}

/// An object that is run by a node to change its structure or content.
///
/// Actions are used to change a node in some way over time. For example, you can use actions
/// to move a node, scale it, rotate it, or fade its transparency. You can also use actions
/// to play sounds or run custom code.
open class SKAction: NSObject, NSCopying, NSSecureCoding {

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    // MARK: - Timing Properties

    /// The duration required to complete an action.
    open var duration: TimeInterval = 0.0

    /// A setting that controls the speed curve of an animation.
    open var timingMode: SKActionTimingMode = .linear

    /// A block used to customize the timing function.
    open var timingFunction: SKActionTimingFunction = { $0 }

    /// A speed factor that modifies how fast an action runs.
    open var speed: CGFloat = 1.0

    // MARK: - Action Type

    /// The internal type of this action.
    internal enum ActionType {
        case moveBy(dx: CGFloat, dy: CGFloat)
        case moveTo(x: CGFloat?, y: CGFloat?)
        case followPath(path: CGPath, asOffset: Bool, orientToPath: Bool)
        case rotateBy(angle: CGFloat)
        case rotateTo(angle: CGFloat, shortestUnitArc: Bool)
        case scaleBy(xScale: CGFloat, yScale: CGFloat)
        case scaleTo(xScale: CGFloat?, yScale: CGFloat?)
        case scaleToSize(size: CGSize)
        case speedBy(delta: CGFloat)
        case speedTo(speed: CGFloat)
        case fadeAlphaBy(delta: CGFloat)
        case fadeAlphaTo(alpha: CGFloat)
        case hide
        case unhide
        case setTexture(texture: SKTexture, resize: Bool)
        case animateTextures(textures: [SKTexture], timePerFrame: TimeInterval, resize: Bool, restore: Bool)
        case setNormalTexture(texture: SKTexture, resize: Bool)
        case animateNormalTextures(textures: [SKTexture], timePerFrame: TimeInterval, resize: Bool, restore: Bool)
        case resizeBy(width: CGFloat, height: CGFloat)
        case resizeTo(width: CGFloat?, height: CGFloat?)
        case colorize(color: SKColor, blendFactor: CGFloat)
        case colorizeWithBlendFactor(blendFactor: CGFloat)
        case playSoundFile(filename: String, waitForCompletion: Bool)
        case play
        case pause
        case stop
        case changeVolume(to: Float?, by: Float?)
        case changePlaybackRate(to: Float?, by: Float?)
        case removeFromParent
        case runOnChild(action: SKAction, name: String)
        case group(actions: [SKAction])
        case sequence(actions: [SKAction])
        case repeatAction(action: SKAction, count: Int)
        case repeatForever(action: SKAction)
        case wait(duration: TimeInterval, range: TimeInterval)
        case runBlock(block: () -> Void)
        #if canImport(Dispatch)
        case runBlockOnQueue(block: () -> Void, queue: DispatchQueue)
        #endif
        case customAction(block: (SKNode, CGFloat) -> Void)
        #if canImport(ObjectiveC)
        case performSelector(selector: Selector, target: AnyObject)
        #endif
        case applyForce(force: CGVector, point: CGPoint?)
        case applyTorque(torque: CGFloat)
        case applyImpulse(impulse: CGVector, point: CGPoint?)
        case applyAngularImpulse(impulse: CGFloat)
        case changeCharge(to: Float?, by: Float?)
        case changeMass(to: Float?, by: Float?)
        case strength(to: Float?, by: Float?)
        case falloff(to: Float?, by: Float?)
        case reach(target: CGPoint, rootNode: SKNode, velocity: CGFloat?)
        case reachToNode(target: SKNode, rootNode: SKNode, velocity: CGFloat?)
        case warp(geometry: SKWarpGeometry)
        case animateWarps(geometries: [SKWarpGeometry], times: [NSNumber], restore: Bool)
        case stereopan(to: Float?, by: Float?)
        case changeObstruction(to: Float?, by: Float?)
        case changeOcclusion(to: Float?, by: Float?)
        case changeReverb(to: Float?, by: Float?)
    }

    internal var actionType: ActionType = .wait(duration: 0, range: 0)

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        duration = coder.decodeDouble(forKey: "duration")
        timingMode = SKActionTimingMode(rawValue: coder.decodeInteger(forKey: "timingMode")) ?? .linear
        speed = CGFloat(coder.decodeDouble(forKey: "speed"))
        super.init()
    }

    // MARK: - NSCoding

    public func encode(with coder: NSCoder) {
        coder.encode(duration, forKey: "duration")
        coder.encode(timingMode.rawValue, forKey: "timingMode")
        coder.encode(Double(speed), forKey: "speed")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKAction()
        copy.duration = duration
        copy.timingMode = timingMode
        copy.timingFunction = timingFunction
        copy.speed = speed
        copy.actionType = actionType
        return copy
    }

    // MARK: - Reversing an Animation

    /// Creates an action that reverses the behavior of another action.
    open func reversed() -> SKAction {
        let reversed = SKAction()
        reversed.duration = duration
        reversed.timingMode = timingMode
        reversed.speed = speed

        switch actionType {
        case .moveBy(let dx, let dy):
            reversed.actionType = .moveBy(dx: -dx, dy: -dy)
        case .rotateBy(let angle):
            reversed.actionType = .rotateBy(angle: -angle)
        case .scaleBy(let xScale, let yScale):
            reversed.actionType = .scaleBy(xScale: -xScale, yScale: -yScale)
        case .fadeAlphaBy(let delta):
            reversed.actionType = .fadeAlphaBy(delta: -delta)
        case .sequence(let actions):
            reversed.actionType = .sequence(actions: actions.reversed().map { $0.reversed() })
        case .group(let actions):
            reversed.actionType = .group(actions: actions.map { $0.reversed() })
        default:
            reversed.actionType = actionType
        }

        return reversed
    }

    // MARK: - Named Action Initializers

    /// Creates an action of the given name from an action file.
    public convenience init?(named name: String) {
        self.init()
        // TODO: Load from action file
    }

    /// Creates an action of the given name from an action file with a new duration.
    public convenience init?(named name: String, duration: TimeInterval) {
        self.init(named: name)
        self.duration = duration
    }

    /// Creates an action of the given name from an action file.
    public convenience init?(named name: String, fromURL url: URL) {
        self.init()
        // TODO: Load from action file at URL
    }

    /// Creates an action of the given name from an action file with a new duration.
    public convenience init?(named name: String, fromURL url: URL, duration: TimeInterval) {
        self.init(named: name, fromURL: url)
        self.duration = duration
    }

    // MARK: - Move Actions

    /// Creates an action that moves a node relative to its current position.
    public class func moveBy(x deltaX: CGFloat, y deltaY: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .moveBy(dx: deltaX, dy: deltaY)
        return action
    }

    /// Creates an action that moves a node relative to its current position.
    public class func move(by delta: CGVector, duration: TimeInterval) -> SKAction {
        return moveBy(x: delta.dx, y: delta.dy, duration: duration)
    }

    /// Creates an action that moves a node to a new position.
    public class func move(to location: CGPoint, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .moveTo(x: location.x, y: location.y)
        return action
    }

    /// Creates an action that moves a node horizontally.
    public class func moveTo(x: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .moveTo(x: x, y: nil)
        return action
    }

    /// Creates an action that moves a node vertically.
    public class func moveTo(y: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .moveTo(x: nil, y: y)
        return action
    }

    // MARK: - Path Actions

    /// Creates an action that moves the node along a relative path, orienting the node to the path.
    public class func follow(_ path: CGPath, duration: TimeInterval) -> SKAction {
        return follow(path, asOffset: true, orientToPath: true, duration: duration)
    }

    /// Creates an action that moves the node along a relative path at a specified speed, orienting the node to the path.
    public class func follow(_ path: CGPath, speed: CGFloat) -> SKAction {
        return follow(path, asOffset: true, orientToPath: true, speed: speed)
    }

    /// Creates an action that moves the node along a path.
    public class func follow(_ path: CGPath, asOffset offset: Bool, orientToPath orient: Bool, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .followPath(path: path, asOffset: offset, orientToPath: orient)
        return action
    }

    /// Creates an action that moves the node at a specified speed along a path.
    public class func follow(_ path: CGPath, asOffset offset: Bool, orientToPath orient: Bool, speed: CGFloat) -> SKAction {
        // Calculate duration based on path length and speed
        // For now, use a default duration
        let action = SKAction()
        action.duration = 1.0 // TODO: Calculate from path length
        action.actionType = .followPath(path: path, asOffset: offset, orientToPath: orient)
        return action
    }

    // MARK: - Rotation Actions

    /// Creates an action that rotates the node by a relative value.
    public class func rotate(byAngle radians: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .rotateBy(angle: radians)
        return action
    }

    /// Creates an action that rotates the node counterclockwise to an absolute angle.
    public class func rotate(toAngle radians: CGFloat, duration: TimeInterval) -> SKAction {
        return rotate(toAngle: radians, duration: duration, shortestUnitArc: false)
    }

    /// Creates an action that rotates the node to an absolute value.
    public class func rotate(toAngle radians: CGFloat, duration: TimeInterval, shortestUnitArc: Bool) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .rotateTo(angle: radians, shortestUnitArc: shortestUnitArc)
        return action
    }

    // MARK: - Speed Actions

    /// Creates an action that changes how fast the node executes actions by a relative value.
    public class func speed(by delta: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .speedBy(delta: delta)
        return action
    }

    /// Creates an action that changes how fast the node executes actions.
    public class func speed(to speed: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .speedTo(speed: speed)
        return action
    }

    // MARK: - Scale Actions

    /// Creates an action that changes the x and y scale values of a node by a relative value.
    public class func scale(by scale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleBy(xScale: scale, yScale: scale)
        return action
    }

    /// Creates an action that changes the x and y scale values of a node to achieve a specific size.
    public class func scale(to size: CGSize, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleToSize(size: size)
        return action
    }

    /// Creates an action that changes the x and y scale values of a node.
    public class func scale(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleTo(xScale: scale, yScale: scale)
        return action
    }

    /// Creates an action that adds relative values to the x and y scale values of a node.
    public class func scaleX(by xScale: CGFloat, y yScale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleBy(xScale: xScale, yScale: yScale)
        return action
    }

    /// Creates an action that changes the x and y scale values of a node.
    public class func scaleX(to xScale: CGFloat, y yScale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleTo(xScale: xScale, yScale: yScale)
        return action
    }

    /// Creates an action that changes the x scale value of a node to a new value.
    public class func scaleX(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleTo(xScale: scale, yScale: nil)
        return action
    }

    /// Creates an action that changes the y scale value of a node to a new value.
    public class func scaleY(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .scaleTo(xScale: nil, yScale: scale)
        return action
    }

    // MARK: - Fade Actions

    /// Creates an action that changes the alpha value of the node to 1.0.
    public class func fadeIn(withDuration duration: TimeInterval) -> SKAction {
        return fadeAlpha(to: 1.0, duration: duration)
    }

    /// Creates an action that changes the alpha value of the node to 0.0.
    public class func fadeOut(withDuration duration: TimeInterval) -> SKAction {
        return fadeAlpha(to: 0.0, duration: duration)
    }

    /// Creates an action that adjusts the alpha value of a node by a relative value.
    public class func fadeAlpha(by delta: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .fadeAlphaBy(delta: delta)
        return action
    }

    /// Creates an action that adjusts the alpha value of a node to a new value.
    public class func fadeAlpha(to alpha: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .fadeAlphaTo(alpha: alpha)
        return action
    }

    // MARK: - Visibility Actions

    /// Creates an action that makes a node visible.
    public class func unhide() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .unhide
        return action
    }

    /// Creates an action that hides a node.
    public class func hide() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .hide
        return action
    }

    // MARK: - Texture Actions

    /// Creates an action that changes a sprite's texture.
    public class func setTexture(_ texture: SKTexture) -> SKAction {
        return setTexture(texture, resize: false)
    }

    /// Creates an action that changes a sprite's texture, possibly resizing the sprite.
    public class func setTexture(_ texture: SKTexture, resize: Bool) -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .setTexture(texture: texture, resize: resize)
        return action
    }

    /// Creates an action that animates changes to a sprite's texture.
    public class func animate(with textures: [SKTexture], timePerFrame sec: TimeInterval) -> SKAction {
        return animate(with: textures, timePerFrame: sec, resize: false, restore: true)
    }

    /// Creates an action that animates changes to a sprite's texture, possibly resizing the sprite.
    public class func animate(with textures: [SKTexture], timePerFrame sec: TimeInterval, resize: Bool, restore: Bool) -> SKAction {
        let action = SKAction()
        action.duration = sec * TimeInterval(textures.count)
        action.actionType = .animateTextures(textures: textures, timePerFrame: sec, resize: resize, restore: restore)
        return action
    }

    /// Creates an action that changes a sprite's normal texture.
    public class func setNormalTexture(_ texture: SKTexture) -> SKAction {
        return setNormalTexture(texture, resize: false)
    }

    /// Creates an action that changes a sprite's normal texture, possibly resizing the sprite.
    public class func setNormalTexture(_ texture: SKTexture, resize: Bool) -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .setNormalTexture(texture: texture, resize: resize)
        return action
    }

    /// Creates an action that animates changes to a sprite's normal texture.
    public class func animate(withNormalTextures textures: [SKTexture], timePerFrame sec: TimeInterval) -> SKAction {
        return animate(withNormalTextures: textures, timePerFrame: sec, resize: false, restore: true)
    }

    /// Creates an action that animates changes to a sprite's texture.
    public class func animate(withNormalTextures textures: [SKTexture], timePerFrame sec: TimeInterval, resize: Bool, restore: Bool) -> SKAction {
        let action = SKAction()
        action.duration = sec * TimeInterval(textures.count)
        action.actionType = .animateNormalTextures(textures: textures, timePerFrame: sec, resize: resize, restore: restore)
        return action
    }

    // MARK: - Resize Actions

    /// Creates an action that adjusts the size of a sprite.
    public class func resize(byWidth width: CGFloat, height: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .resizeBy(width: width, height: height)
        return action
    }

    /// Creates an action that changes the height of a sprite to a new absolute value.
    public class func resize(toHeight height: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .resizeTo(width: nil, height: height)
        return action
    }

    /// Creates an action that changes the width of a sprite to a new absolute value.
    public class func resize(toWidth width: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .resizeTo(width: width, height: nil)
        return action
    }

    /// Creates an action that changes the width and height of a sprite to a new absolute value.
    public class func resize(toWidth width: CGFloat, height: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .resizeTo(width: width, height: height)
        return action
    }

    // MARK: - Colorize Actions

    /// Creates an animation that animates a sprite's color and blend factor.
    public class func colorize(with color: SKColor, colorBlendFactor: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .colorize(color: color, blendFactor: colorBlendFactor)
        return action
    }

    /// Creates an action that animates a sprite's blend factor.
    public class func colorize(withColorBlendFactor colorBlendFactor: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .colorizeWithBlendFactor(blendFactor: colorBlendFactor)
        return action
    }

    // MARK: - Audio Actions

    /// Creates an action that plays a sound.
    public class func playSoundFileNamed(_ soundFile: String, waitForCompletion wait: Bool) -> SKAction {
        let action = SKAction()
        action.duration = wait ? 1.0 : 0 // TODO: Get actual sound duration
        action.actionType = .playSoundFile(filename: soundFile, waitForCompletion: wait)
        return action
    }

    /// Creates an action that tells an audio node to start playback.
    public class func play() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .play
        return action
    }

    /// Creates an action that tells an audio node to pause playback.
    public class func pause() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .pause
        return action
    }

    /// Creates an action that tells an audio node to stop playback.
    public class func stop() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .stop
        return action
    }

    /// Creates an action that changes an audio node's volume to a new value.
    public class func changeVolume(to volume: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeVolume(to: volume, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's volume by a relative value.
    public class func changeVolume(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeVolume(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes an audio node's playback rate to a new value.
    public class func changePlaybackRate(to rate: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changePlaybackRate(to: rate, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's playback rate by a relative amount.
    public class func changePlaybackRate(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changePlaybackRate(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes an audio node's stereo panning to a new value.
    public class func stereoPan(to pan: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .stereopan(to: pan, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's stereo panning by a relative value.
    public class func stereoPan(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .stereopan(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes an audio node's obstruction to a new value.
    public class func changeObstruction(to obstruction: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeObstruction(to: obstruction, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's obstruction by a relative value.
    public class func changeObstruction(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeObstruction(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes an audio node's occlusion to a new value.
    public class func changeOcclusion(to occlusion: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeOcclusion(to: occlusion, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's occlusion by a relative value.
    public class func changeOcclusion(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeOcclusion(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes an audio node's reverb to a new value.
    public class func changeReverb(to reverb: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeReverb(to: reverb, by: nil)
        return action
    }

    /// Creates an action that changes an audio node's reverb by a relative value.
    public class func changeReverb(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeReverb(to: nil, by: delta)
        return action
    }

    // MARK: - Physics Actions

    /// Creates an action that applies a force to the center of gravity of a node's physics body.
    public class func applyForce(_ force: CGVector, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyForce(force: force, point: nil)
        return action
    }

    /// Creates an action that applies a force to a specific point on a node's physics body.
    public class func applyForce(_ force: CGVector, at point: CGPoint, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyForce(force: force, point: point)
        return action
    }

    /// Creates an action that applies a torque to a node's physics body.
    public class func applyTorque(_ torque: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyTorque(torque: torque)
        return action
    }

    /// Creates an action that applies an impulse to the center of gravity of a physics body.
    public class func applyImpulse(_ impulse: CGVector, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyImpulse(impulse: impulse, point: nil)
        return action
    }

    /// Creates an action that applies an impulse to a specific point of a node's physics body.
    public class func applyImpulse(_ impulse: CGVector, at point: CGPoint, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyImpulse(impulse: impulse, point: point)
        return action
    }

    /// Creates an action that applies an angular impulse to a node's physics body.
    public class func applyAngularImpulse(_ impulse: CGFloat, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .applyAngularImpulse(impulse: impulse)
        return action
    }

    /// Creates an action that changes the charge of a node's physics body to a new value.
    public class func changeCharge(to charge: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeCharge(to: charge, by: nil)
        return action
    }

    /// Creates an action that changes the charge of a node's physics body by a relative value.
    public class func changeCharge(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeCharge(to: nil, by: delta)
        return action
    }

    /// Creates an action that changes the mass of a node's physics body to a new value.
    public class func changeMass(to mass: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeMass(to: mass, by: nil)
        return action
    }

    /// Creates an action that changes the mass of a node's physics body by a relative value.
    public class func changeMass(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .changeMass(to: nil, by: delta)
        return action
    }

    /// Creates an action that animates a change of a physics field's strength.
    public class func strength(to strength: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .strength(to: strength, by: nil)
        return action
    }

    /// Creates an action that animates a change of a physics field's strength to a value relative to the existing value.
    public class func strength(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .strength(to: nil, by: delta)
        return action
    }

    /// Creates an action that animates a change of a physics field's falloff.
    public class func falloff(to falloff: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .falloff(to: falloff, by: nil)
        return action
    }

    /// Creates an action that animates a change of a physics field's falloff to a value relative to the existing value.
    public class func falloff(by delta: Float, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .falloff(to: nil, by: delta)
        return action
    }

    // MARK: - Removal Actions

    /// Creates an action that removes the node from its parent.
    public class func removeFromParent() -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .removeFromParent
        return action
    }

    // MARK: - Child Actions

    /// Creates an action that runs an action on a named child object.
    public class func run(_ action: SKAction, onChildWithName name: String) -> SKAction {
        let runAction = SKAction()
        runAction.duration = action.duration
        runAction.actionType = .runOnChild(action: action, name: name)
        return runAction
    }

    // MARK: - Chaining Actions

    /// Creates an action that runs a collection of actions in parallel.
    public class func group(_ actions: [SKAction]) -> SKAction {
        let action = SKAction()
        action.duration = actions.map { $0.duration }.max() ?? 0
        action.actionType = .group(actions: actions)
        return action
    }

    /// Creates an action that runs a collection of actions sequentially.
    public class func sequence(_ actions: [SKAction]) -> SKAction {
        let action = SKAction()
        action.duration = actions.reduce(0) { $0 + $1.duration }
        action.actionType = .sequence(actions: actions)
        return action
    }

    /// Creates an action that repeats another action a specified number of times.
    public class func `repeat`(_ action: SKAction, count: Int) -> SKAction {
        let repeatAction = SKAction()
        repeatAction.duration = action.duration * TimeInterval(count)
        repeatAction.actionType = .repeatAction(action: action, count: count)
        return repeatAction
    }

    /// Creates an action that repeats another action forever.
    public class func repeatForever(_ action: SKAction) -> SKAction {
        let repeatAction = SKAction()
        repeatAction.duration = TimeInterval.infinity
        repeatAction.actionType = .repeatForever(action: action)
        return repeatAction
    }

    // MARK: - Delay Actions

    /// Creates an action that idles for a specified period of time.
    public class func wait(forDuration duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .wait(duration: duration, range: 0)
        return action
    }

    /// Creates an action that idles for a randomized period of time.
    public class func wait(forDuration duration: TimeInterval, withRange durationRange: TimeInterval) -> SKAction {
        let action = SKAction()
        // Calculate random duration within range
        let randomOffset = (Double.random(in: 0...1) - 0.5) * durationRange
        action.duration = duration + randomOffset
        action.actionType = .wait(duration: duration, range: durationRange)
        return action
    }

    // MARK: - Custom Actions

    /// Creates an action that executes a block over a duration.
    public class func customAction(withDuration duration: TimeInterval, actionBlock block: @escaping (SKNode, CGFloat) -> Void) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .customAction(block: block)
        return action
    }

    #if canImport(ObjectiveC)
    /// Creates an action that calls a method on an object.
    public class func perform(_ selector: Selector, onTarget target: Any) -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .performSelector(selector: selector, target: target as AnyObject)
        return action
    }
    #endif

    /// Creates an action that executes a block.
    public class func run(_ block: @escaping () -> Void) -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .runBlock(block: block)
        return action
    }

    #if canImport(Dispatch)
    /// Creates an action that executes a block on a specific dispatch queue.
    public class func run(_ block: @escaping () -> Void, queue: DispatchQueue) -> SKAction {
        let action = SKAction()
        action.duration = 0
        action.actionType = .runBlockOnQueue(block: block, queue: queue)
        return action
    }
    #endif

    // MARK: - Inverse Kinematics Actions

    /// Creates an action that performs an inverse kinematic reach.
    public class func reach(to position: CGPoint, rootNode root: SKNode, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .reach(target: position, rootNode: root, velocity: nil)
        return action
    }

    /// Creates an action that performs an inverse kinematic reach.
    public class func reach(to position: CGPoint, rootNode root: SKNode, velocity: CGFloat) -> SKAction {
        let action = SKAction()
        action.duration = 1.0 // TODO: Calculate from distance and velocity
        action.actionType = .reach(target: position, rootNode: root, velocity: velocity)
        return action
    }

    /// Creates an action that performs an inverse kinematic reach.
    public class func reach(to node: SKNode, rootNode root: SKNode, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.duration = duration
        action.actionType = .reachToNode(target: node, rootNode: root, velocity: nil)
        return action
    }

    /// Creates an action that performs an inverse kinematic reach.
    public class func reach(to node: SKNode, rootNode root: SKNode, velocity: CGFloat) -> SKAction {
        let action = SKAction()
        action.duration = 1.0 // TODO: Calculate from distance and velocity
        action.actionType = .reachToNode(target: node, rootNode: root, velocity: velocity)
        return action
    }

    // MARK: - Warp Actions

    /// Creates an action to distort a node based using an SKWarpGeometry object.
    public class func warp(to warp: SKWarpGeometry, duration: TimeInterval) -> SKAction? {
        let action = SKAction()
        action.duration = duration
        action.actionType = .warp(geometry: warp)
        return action
    }

    /// Creates an action to distort a node through a sequence of SKWarpGeometry objects.
    public class func animate(withWarps warps: [SKWarpGeometry], times: [NSNumber]) -> SKAction? {
        return animate(withWarps: warps, times: times, restore: false)
    }

    /// Creates an action to distort a node through a sequence of SKWarpGeometry objects.
    public class func animate(withWarps warps: [SKWarpGeometry], times: [NSNumber], restore: Bool) -> SKAction? {
        guard warps.count == times.count else { return nil }
        let action = SKAction()
        action.duration = times.last?.doubleValue ?? 0
        action.actionType = .animateWarps(geometries: warps, times: times, restore: restore)
        return action
    }
}
