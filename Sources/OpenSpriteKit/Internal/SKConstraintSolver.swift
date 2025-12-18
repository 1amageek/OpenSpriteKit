// SKConstraintSolver.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// Evaluates and applies SKConstraints to nodes.
///
/// This solver is called during the frame cycle after physics simulation
/// and before rendering.
internal final class SKConstraintSolver {

    // MARK: - Singleton

    nonisolated(unsafe) static let shared = SKConstraintSolver()

    private init() {}

    // MARK: - Constraint Evaluation

    /// Applies all constraints for nodes in the given scene.
    ///
    /// - Parameter scene: The scene whose nodes should have constraints applied.
    func applyConstraints(for scene: SKScene) {
        applyConstraintsRecursively(node: scene)
    }

    /// Recursively applies constraints to a node and its children.
    private func applyConstraintsRecursively(node: SKNode) {
        // Apply constraints to this node
        if let constraints = node.constraints, !constraints.isEmpty {
            for constraint in constraints {
                if constraint.enabled {
                    applyConstraint(constraint, to: node)
                }
            }
        }

        // Recurse to children
        for child in node.children {
            applyConstraintsRecursively(node: child)
        }
    }

    /// Applies a single constraint to a node.
    private func applyConstraint(_ constraint: SKConstraint, to node: SKNode) {
        guard let type = constraint.constraintType else { return }

        switch type {
        case .positionX(let range):
            node.position.x = clamp(node.position.x, range: range)

        case .positionY(let range):
            node.position.y = clamp(node.position.y, range: range)

        case .positionXY(let xRange, let yRange):
            node.position.x = clamp(node.position.x, range: xRange)
            node.position.y = clamp(node.position.y, range: yRange)

        case .zRotation(let range):
            node.zRotation = clamp(node.zRotation, range: range)

        case .orientToNode(let targetNode, let offset):
            orientNode(node, to: targetNode.position, offset: offset, referenceNode: constraint.referenceNode)

        case .orientToPoint(let point, let offset):
            orientNode(node, to: point, offset: offset, referenceNode: constraint.referenceNode)

        case .orientToPointInNode(let point, let targetNode, let offset):
            // Convert point from target node's coordinate space to scene coordinates
            if let scene = node.scene {
                let worldPoint = targetNode.convert(point, to: scene)
                orientNode(node, to: worldPoint, offset: offset, referenceNode: constraint.referenceNode)
            }

        case .distanceToNode(let range, let targetNode):
            constrainDistance(of: node, to: targetNode.position, range: range, referenceNode: constraint.referenceNode)

        case .distanceToPoint(let range, let point):
            constrainDistance(of: node, to: point, range: range, referenceNode: constraint.referenceNode)

        case .distanceToPointInNode(let range, let point, let targetNode):
            // Convert point from target node's coordinate space
            if let scene = node.scene {
                let worldPoint = targetNode.convert(point, to: scene)
                constrainDistance(of: node, to: worldPoint, range: range, referenceNode: constraint.referenceNode)
            }
        }
    }

    // MARK: - Constraint Helpers

    /// Clamps a value to a range.
    private func clamp(_ value: CGFloat, range: SKRange) -> CGFloat {
        return max(range.lowerLimit, min(range.upperLimit, value))
    }

    /// Orients a node to face a target point.
    private func orientNode(_ node: SKNode, to target: CGPoint, offset: SKRange, referenceNode: SKNode?) {
        var targetPoint = target

        // If there's a reference node, convert coordinates
        if let ref = referenceNode, let scene = node.scene {
            // Convert target to reference node's coordinate space, then back
            targetPoint = scene.convert(target, from: ref)
        }

        // Calculate angle from node to target
        let dx = targetPoint.x - node.position.x
        let dy = targetPoint.y - node.position.y
        var angle = atan2(dy, dx)

        // Apply offset constraint
        angle = clamp(angle, range: offset)

        node.zRotation = angle
    }

    /// Constrains the distance between a node and a target point.
    private func constrainDistance(of node: SKNode, to target: CGPoint, range: SKRange, referenceNode: SKNode?) {
        var targetPoint = target

        // If there's a reference node, convert coordinates
        if let ref = referenceNode, let scene = node.scene {
            targetPoint = scene.convert(target, from: ref)
        }

        let dx = targetPoint.x - node.position.x
        let dy = targetPoint.y - node.position.y
        let distance = sqrt(dx * dx + dy * dy)

        // Check if distance is within range
        if distance < range.lowerLimit {
            // Too close - push node away
            if distance > 0 {
                let scale = range.lowerLimit / distance
                node.position = CGPoint(
                    x: targetPoint.x - dx * scale,
                    y: targetPoint.y - dy * scale
                )
            }
        } else if distance > range.upperLimit {
            // Too far - pull node closer
            if distance > 0 {
                let scale = range.upperLimit / distance
                node.position = CGPoint(
                    x: targetPoint.x - dx * scale,
                    y: targetPoint.y - dy * scale
                )
            }
        }
    }
}

// MARK: - SKRange Extension

extension SKRange {
    /// Returns the value clamped to this range.
    func clamp(_ value: CGFloat) -> CGFloat {
        return max(lowerLimit, min(upperLimit, value))
    }
}
