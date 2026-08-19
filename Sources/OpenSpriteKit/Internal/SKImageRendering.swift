// SKImageRendering.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

/// The renderer-owned Core Image boundary used by SpriteKit image consumers.
///
/// A context retains command queues, compiled pipelines, and intermediate
/// resources. Keeping it at the renderer boundary gives each view or offscreen
/// renderer one reusable evaluation context without introducing process-global
/// device affinity.
@MainActor
internal protocol SKImageRendering: AnyObject {
    func render(_ image: CIImage, from rect: CGRect) async throws -> CGImage
    func clearCaches()
    func reclaimResources()
}

/// The production Core Image rendering service.
///
/// `SKViewRenderer` and `SKRenderer` each own one instance. Nodes and textures
/// retain only image recipes and never create or share a context themselves.
@MainActor
internal final class SKCoreImageRenderer: SKImageRendering {
    private let context: CIContext

    init(options: [CIContextOption: Any]? = nil) {
        self.context = CIContext(options: options)
    }

    func render(_ image: CIImage, from rect: CGRect) async throws -> CGImage {
        guard rect.origin.x.isFinite,
              rect.origin.y.isFinite,
              rect.width.isFinite,
              rect.height.isFinite,
              rect.width > 0,
              rect.height > 0 else {
            throw SKRendererError.imageProcessingFailed("Core Image output extent must be finite and non-empty")
        }
        return try await context.createCGImageAsync(image, from: rect)
    }

    func clearCaches() {
        context.clearCaches()
    }

    func reclaimResources() {
        context.reclaimResources()
    }
}
