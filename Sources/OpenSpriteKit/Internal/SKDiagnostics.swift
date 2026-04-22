// SKDiagnostics.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

import Foundation

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

    private func logStats(scene: SKScene) {
        let nodeStats = collectNodeStats(from: scene)
        let actionCount = SKActionRunner.shared.totalRunningActionsCount()
        let textureCount = SKTextureCache.shared.cachedCount()
        let resourceCounts = SKResourceLoader.shared.resourceCounts()
        #if arch(wasm32)
        let gpuTextureCount = SKTextureManager.shared.cachedTextureCount()
        #else
        let gpuTextureCount = 0
        #endif

        print("""
        [SKDiagnostics] nodes=\(nodeStats.nodeCount) emitters=\(nodeStats.emitterCount) particles=\(nodeStats.particleCount) actions=\(actionCount) textures=\(textureCount) gpuTextures=\(gpuTextureCount) resources=\(resourceCounts)
        """)
    }

    private func collectNodeStats(from root: SKNode) -> (nodeCount: Int, emitterCount: Int, particleCount: Int) {
        var nodeCount = 0
        var emitterCount = 0
        var particleCount = 0

        var stack: [SKNode] = [root]
        while let node = stack.popLast() {
            nodeCount += 1
            if let emitter = node as? SKEmitterNode {
                emitterCount += 1
                particleCount += emitter.activeParticleCount
            }
            stack.append(contentsOf: node.children)
        }

        return (nodeCount, emitterCount, particleCount)
    }
}
