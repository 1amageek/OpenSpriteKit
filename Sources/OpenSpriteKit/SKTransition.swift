//
//  SKTransition.swift
//  OpenSpriteKit
//
//  Created by 1amageek on 2025/12/22.
//

import Foundation
import OpenCoreImage

// MARK: - SKTransition

/// An object used to perform an animated transition to a new scene.
///
/// An `SKTransition` object is used to animate a change from one scene to another.
open class SKTransition: @unchecked Sendable {

    // MARK: - Internal Types

    /// The type of transition to perform.
    internal enum TransitionType {
        case crossFade
        case fade(color: SKColor)
        case fadeIn
        case fadeOut
        case flip(direction: SKTransitionDirection)
        case reveal(direction: SKTransitionDirection)
        case moveIn(direction: SKTransitionDirection)
        case push(direction: SKTransitionDirection)
        case doorsOpen(horizontal: Bool)
        case doorsClose(horizontal: Bool)
        case doorway
        case ciFilter(filter: CIFilter)
        case none
    }

    // MARK: - Properties

    /// A Boolean value that indicates whether the transition should pause the incoming scene.
    open var pausesIncomingScene: Bool = true

    /// A Boolean value that indicates whether the transition should pause the outgoing scene.
    open var pausesOutgoingScene: Bool = true

    /// The duration of the transition in seconds.
    internal private(set) var duration: TimeInterval = 0

    /// The type of transition.
    internal private(set) var transitionType: TransitionType = .none

    // MARK: - Initializers

    /// Creates an empty transition.
    public init() {
    }

    /// Creates a transition with the specified type and duration.
    private init(type: TransitionType, duration: TimeInterval) {
        self.transitionType = type
        self.duration = duration
    }

    // MARK: - Factory Methods

    /// Creates a cross-fade transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A cross-fade transition.
    public class func crossFade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .crossFade, duration: duration)
    }

    /// Creates a fade transition.
    ///
    /// - Parameters:
    ///   - color: The color to fade through.
    ///   - duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(with color: SKColor, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fade(color: color), duration: duration)
    }

    /// Creates a transition that first fades to black and then fades to the new scene.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade transition.
    public class func fade(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fade(color: .black), duration: duration)
    }

    /// Creates a fade-in transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-in transition.
    public class func fadeIn(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fadeIn, duration: duration)
    }

    /// Creates a fade-out transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A fade-out transition.
    public class func fadeOut(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .fadeOut, duration: duration)
    }

    /// Creates a flip transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the flip.
    ///   - duration: The duration of the transition.
    /// - Returns: A flip transition.
    public class func flip(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: direction), duration: duration)
    }

    /// Creates a transition where the two scenes are flipped across a horizontal line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A horizontal flip transition.
    public class func flipHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: .up), duration: duration)
    }

    /// Creates a transition where the two scenes are flipped across a vertical line running through the center of the view.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A vertical flip transition.
    public class func flipVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .flip(direction: .right), duration: duration)
    }

    /// Creates a reveal transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the reveal.
    ///   - duration: The duration of the transition.
    /// - Returns: A reveal transition.
    public class func reveal(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .reveal(direction: direction), duration: duration)
    }

    /// Creates a move-in transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the move.
    ///   - duration: The duration of the transition.
    /// - Returns: A move-in transition.
    public class func moveIn(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .moveIn(direction: direction), duration: duration)
    }

    /// Creates a push transition.
    ///
    /// - Parameters:
    ///   - direction: The direction of the push.
    ///   - duration: The duration of the transition.
    /// - Returns: A push transition.
    public class func push(with direction: SKTransitionDirection, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .push(direction: direction), duration: duration)
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsOpen(horizontal: true), duration: duration)
    }

    /// Creates a doors-open transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-open transition.
    public class func doorsOpenVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsOpen(horizontal: false), duration: duration)
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseHorizontal(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsClose(horizontal: true), duration: duration)
    }

    /// Creates a doors-close transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doors-close transition.
    public class func doorsCloseVertical(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorsClose(horizontal: false), duration: duration)
    }

    /// Creates a doorway transition.
    ///
    /// - Parameter duration: The duration of the transition.
    /// - Returns: A doorway transition.
    public class func doorway(withDuration duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .doorway, duration: duration)
    }

    /// Creates a CIFilter-based transition.
    ///
    /// - Parameters:
    ///   - filter: The filter to use.
    ///   - duration: The duration of the transition.
    /// - Returns: A filter-based transition.
    public class func transition(with filter: CIFilter, duration: TimeInterval) -> SKTransition {
        return SKTransition(type: .ciFilter(filter: filter), duration: duration)
    }

    // MARK: - Copying

    /// Creates a copy of this transition.
    ///
    /// - Returns: A new transition with the same properties.
    open func copy() -> SKTransition {
        let transitionCopy = SKTransition(type: transitionType, duration: duration)
        transitionCopy.pausesIncomingScene = pausesIncomingScene
        transitionCopy.pausesOutgoingScene = pausesOutgoingScene
        return transitionCopy
    }
}

// MARK: - SKTransitionDirection

/// For some transitions, the direction in which the transition is performed.
public enum SKTransitionDirection: Int, Sendable, Hashable {
    case up = 0
    case down = 1
    case right = 2
    case left = 3
}

