// SKCameraNode.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

/// A node that determines which portion of the scene is visible in the view.
///
/// An `SKCameraNode` object defines the viewport of a scene. When a camera is assigned to a scene's
/// `camera` property, the scene is rendered from the camera's point of view.
///
/// The camera's position in the scene's coordinate system determines which portion of the scene is visible.
/// You can also rotate and scale the camera to change the view.
open class SKCameraNode: SKNode, @unchecked Sendable {

    // MARK: - Initializers

    public override init() {
        super.init()
    }

    // MARK: - Visibility Methods

    /// Determines whether a node is visible when viewed from this camera.
    ///
    /// - Parameters:
    ///   - node: The node to test.
    ///   - view: The view in which the scene is rendered.
    /// - Returns: `true` if the node is visible; otherwise, `false`.
    open func contains(_ node: SKNode, in view: SKView) -> Bool {
        // Hidden nodes are never visible
        guard !node.isHidden && node.alpha > 0 else { return false }

        // Calculate visible rect in scene coordinates
        let visibleRect = calculateVisibleRect(in: view)

        // Get the node's frame in scene coordinates
        guard let scene = self.scene, let nodeScene = node.scene, scene === nodeScene else {
            return false
        }

        let nodeFrame = node.calculateAccumulatedFrame()

        // Check if the node's frame intersects with the visible rect
        return visibleRect.intersects(nodeFrame)
    }

    /// Returns all nodes that are visible when viewed from this camera.
    ///
    /// - Parameter view: The view in which the scene is rendered.
    /// - Returns: An array of all visible nodes.
    open func containedNodeSet(in view: SKView) -> [SKNode] {
        guard let scene = self.scene else { return [] }

        var visibleNodes: [SKNode] = []
        let visibleRect = calculateVisibleRect(in: view)

        // Recursively check all nodes
        collectVisibleNodes(from: scene, visibleRect: visibleRect, into: &visibleNodes)

        return visibleNodes
    }

    /// Calculates the visible rectangle in scene coordinates based on camera transform.
    ///
    /// - Parameter view: The view displaying the scene.
    /// - Returns: The rectangle representing the visible area in scene coordinates.
    public func calculateVisibleRect(in view: SKView) -> CGRect {
        let viewSize = view.viewSize

        // Base visible size (accounting for camera scale)
        let effectiveScale = CGPoint(x: xScale, y: yScale)
        let scaledWidth = viewSize.width / (effectiveScale.x != 0 ? effectiveScale.x : 1)
        let scaledHeight = viewSize.height / (effectiveScale.y != 0 ? effectiveScale.y : 1)

        // Center on camera position
        var rect = CGRect(
            x: position.x - scaledWidth / 2,
            y: position.y - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )

        // If camera is rotated, we need to calculate the bounding box of the rotated rectangle
        if zRotation != 0 {
            let cos = Foundation.cos(Double(zRotation))
            let sin = Foundation.sin(Double(zRotation))

            // Calculate corners of the unrotated rectangle relative to camera position
            let corners = [
                CGPoint(x: -scaledWidth / 2, y: -scaledHeight / 2),
                CGPoint(x: scaledWidth / 2, y: -scaledHeight / 2),
                CGPoint(x: scaledWidth / 2, y: scaledHeight / 2),
                CGPoint(x: -scaledWidth / 2, y: scaledHeight / 2)
            ]

            // Rotate corners and find bounding box
            var minX = CGFloat.infinity
            var maxX = -CGFloat.infinity
            var minY = CGFloat.infinity
            var maxY = -CGFloat.infinity

            for corner in corners {
                let rotatedX = CGFloat(Double(corner.x) * cos - Double(corner.y) * sin)
                let rotatedY = CGFloat(Double(corner.x) * sin + Double(corner.y) * cos)
                minX = min(minX, rotatedX)
                maxX = max(maxX, rotatedX)
                minY = min(minY, rotatedY)
                maxY = max(maxY, rotatedY)
            }

            rect = CGRect(
                x: position.x + minX,
                y: position.y + minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }

        return rect
    }

    /// Recursively collects visible nodes.
    private func collectVisibleNodes(from node: SKNode, visibleRect: CGRect, into result: inout [SKNode]) {
        // Skip hidden nodes and their children
        guard !node.isHidden && node.alpha > 0 else { return }

        // Check if this node is visible
        let nodeFrame = node.calculateAccumulatedFrame()
        if visibleRect.intersects(nodeFrame) {
            result.append(node)
        }

        // Check children
        for child in node.children {
            collectVisibleNodes(from: child, visibleRect: visibleRect, into: &result)
        }
    }
}
