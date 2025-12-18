// SKSceneDelegate.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// Methods that, when implemented, allow any class to participate in the SpriteKit render loop callbacks.
///
/// The `SKSceneDelegate` protocol is used to implement a delegate to be called whenever the scene is being animated.
/// Typically, you supply a delegate when you want to use a scene without requiring the scene to be subclassed.
/// The methods in this protocol all correspond to methods implemented by the `SKScene` class.
/// If the delegate implements a particular method, that method is called instead of the corresponding method on the scene object.
public protocol SKSceneDelegate: NSObjectProtocol {

    /// Tells you to perform any app specific logic to update your scene.
    ///
    /// - Parameters:
    ///   - currentTime: The current system time.
    ///   - scene: The scene that is being updated.
    func update(_ currentTime: TimeInterval, for scene: SKScene)

    /// Tells you to perform any necessary logic after scene actions are evaluated.
    ///
    /// - Parameter scene: The scene whose actions have been evaluated.
    func didEvaluateActions(for scene: SKScene)

    /// Tells you to perform any necessary logic after physics simulations are performed.
    ///
    /// - Parameter scene: The scene whose physics have been simulated.
    func didSimulatePhysics(for scene: SKScene)

    /// Tells you to perform any necessary logic after constraints are applied.
    ///
    /// - Parameter scene: The scene whose constraints have been applied.
    func didApplyConstraints(for scene: SKScene)

    /// Tells you to perform any necessary logic after the scene has finished all of the steps required to process animations.
    ///
    /// - Parameter scene: The scene that has finished updating.
    func didFinishUpdate(for scene: SKScene)
}

// MARK: - Default Implementations

public extension SKSceneDelegate {
    func update(_ currentTime: TimeInterval, for scene: SKScene) {}
    func didEvaluateActions(for scene: SKScene) {}
    func didSimulatePhysics(for scene: SKScene) {}
    func didApplyConstraints(for scene: SKScene) {}
    func didFinishUpdate(for scene: SKScene) {}
}
