// SKDiagnostics.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

public struct SKDiagnosticsSnapshot: Sendable {
    public let nodeCount: Int
    public let emitterCount: Int
    public let particleCount: Int
    public let runningActionCount: Int
    public let actionNodeBucketCount: Int
    public let orphanedActionNodeBucketCount: Int
    public let textureCount: Int
    public let gpuTextureCount: Int
    public let resourceCounts: String
}

/// Lightweight diagnostics for tracking growth over time (WASM-friendly).
@MainActor
public final class SKDiagnostics {
    public static let shared = SKDiagnostics()

    /// Logs a warning for non-fatal issues (failed file loads, parse errors, etc.).
    /// Callable from any isolation context.
    nonisolated static func logWarning(_ message: String, file: String = #fileID, line: Int = #line) {
        print("[OpenSpriteKit WARNING] \(file):\(line) - \(message)")
    }

    private init() {}

    private var isEnabled: Bool = false
    private var interval: TimeInterval = 1.0
    private var lastLogTime: TimeInterval = 0

    public func setEnabled(_ enabled: Bool, interval: TimeInterval = 1.0) {
        isEnabled = enabled
        self.interval = max(0.25, interval)
    }

    public func tick(scene: SKScene) {
        guard isEnabled else { return }

        let now = Date().timeIntervalSinceReferenceDate
        if lastLogTime == 0 || now - lastLogTime >= interval {
            lastLogTime = now
            logStats(scene: scene)
        }
    }

    public func snapshot(scene: SKScene) -> SKDiagnosticsSnapshot {
        let nodeStats = collectNodeStats(from: scene)
        let actionNodeIDs = SKActionRunner.shared.runningActionNodeIDs()
        let textureCount = SKTextureCache.shared.cachedCount()
        let resourceCounts = SKResourceLoader.shared.resourceCounts()
        #if arch(wasm32)
        let gpuTextureCount = SKTextureManager.shared.cachedTextureCount()
        #else
        let gpuTextureCount = 0
        #endif

        return SKDiagnosticsSnapshot(
            nodeCount: nodeStats.nodeCount,
            emitterCount: nodeStats.emitterCount,
            particleCount: nodeStats.particleCount,
            runningActionCount: SKActionRunner.shared.totalRunningActionsCount(),
            actionNodeBucketCount: actionNodeIDs.count,
            orphanedActionNodeBucketCount: actionNodeIDs.subtracting(nodeStats.nodeIDs).count,
            textureCount: textureCount,
            gpuTextureCount: gpuTextureCount,
            resourceCounts: resourceCounts
        )
    }

    private func logStats(scene: SKScene) {
        let stats = snapshot(scene: scene)

        print("""
        [SKDiagnostics] nodes=\(stats.nodeCount) emitters=\(stats.emitterCount) particles=\(stats.particleCount) actions=\(stats.runningActionCount) actionBuckets=\(stats.actionNodeBucketCount) orphanedActionBuckets=\(stats.orphanedActionNodeBucketCount) textures=\(stats.textureCount) gpuTextures=\(stats.gpuTextureCount) resources=\(stats.resourceCounts)
        """)
    }

    private func collectNodeStats(from root: SKNode) -> (nodeCount: Int, emitterCount: Int, particleCount: Int, nodeIDs: Set<ObjectIdentifier>) {
        var nodeCount = 0
        var emitterCount = 0
        var particleCount = 0
        var nodeIDs: Set<ObjectIdentifier> = []

        var stack: [SKNode] = [root]
        while let node = stack.popLast() {
            nodeCount += 1
            nodeIDs.insert(ObjectIdentifier(node))
            if let emitter = node as? SKEmitterNode {
                emitterCount += 1
                particleCount += emitter.activeParticleCount
            }
            stack.append(contentsOf: node.children)
        }

        return (nodeCount, emitterCount, particleCount, nodeIDs)
    }
}
