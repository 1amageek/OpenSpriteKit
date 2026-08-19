// SKSceneImageProcessor.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

@_spi(OpenSpriteKit) import OpenCoreImage

/// Prepares all Core Image-backed resources before a scene layer tree is
/// submitted to its drawing backend.
///
/// The processor is owned one-to-one by an `SKViewRenderer` or `SKRenderer` and
/// strongly owns that renderer's Core Image service. Mutable filters remain on
/// the main actor; only immutable `CIImage` recipes cross an async suspension.
@MainActor
internal final class SKSceneImageProcessor {
    private let imageRenderer: any SKImageRendering

    init(imageRenderer: any SKImageRendering) {
        self.imageRenderer = imageRenderer
    }

    /// Returns whether rendering this tree requires asynchronous image work.
    func requiresPreparation(in node: SKNode) -> Bool {
        if textures(attachedTo: node).contains(where: { $0.requiresImagePreparation }) {
            return true
        }
        if let effectNode = node as? SKEffectNode,
           effectNode.shouldEnableEffects,
           effectNode.filter != nil,
           (!effectNode.shouldRasterize || effectNode._needsFilterUpdate) {
            return true
        }
        return node.children.contains { requiresPreparation(in: $0) }
    }

    /// Resolves texture recipes and effect-node framebuffers for one frame.
    ///
    /// Independent failures are all handled so one broken node cannot leave a
    /// sibling's stale framebuffer active. The first failure is returned to the
    /// public renderer error channel.
    func prepareFrameImages(in scene: SKScene) async -> SKRendererError? {
        var firstError = await prepareTextureImages(in: scene)
        let effectError = await prepareEffectImages(in: scene)
        if firstError == nil {
            firstError = effectError
        }
        return firstError
    }

    func prepareTextureImages(in scene: SKScene) async -> SKRendererError? {
        await prepareTextures(in: scene)
    }

    func prepareEffectImages(in scene: SKScene) async -> SKRendererError? {
        await prepareEffects(in: scene)
    }

    func clearCaches() {
        imageRenderer.clearCaches()
    }

    func reclaimResources() {
        imageRenderer.reclaimResources()
    }

    // MARK: - Texture Preparation

    private func prepareTextures(in root: SKNode) async -> SKRendererError? {
        var textureMap: [ObjectIdentifier: SKTexture] = [:]
        collectTextures(from: root, into: &textureMap)

        var firstError: SKRendererError?
        for texture in textureMap.values where texture.requiresImagePreparation {
            do {
                try await texture.prepareImage(using: imageRenderer)
            } catch {
                if firstError == nil {
                    firstError = rendererError(from: error)
                }
            }
        }

        refreshTextureLayers(in: root)
        return firstError
    }

    private func collectTextures(
        from node: SKNode,
        into textures: inout [ObjectIdentifier: SKTexture]
    ) {
        for texture in self.textures(attachedTo: node) {
            textures[ObjectIdentifier(texture)] = texture
        }
        for child in node.children {
            collectTextures(from: child, into: &textures)
        }
    }

    private func textures(attachedTo node: SKNode) -> [SKTexture] {
        var textures: [SKTexture] = []
        var shaders: [SKShader] = []

        if let sprite = node as? SKSpriteNode {
            if let texture = sprite.texture { textures.append(texture) }
            if let normalTexture = sprite.normalTexture { textures.append(normalTexture) }
            if let shader = sprite.shader { shaders.append(shader) }
        }
        if let shape = node as? SKShapeNode {
            if let fillTexture = shape.fillTexture { textures.append(fillTexture) }
            if let strokeTexture = shape.strokeTexture { textures.append(strokeTexture) }
            if let fillShader = shape.fillShader { shaders.append(fillShader) }
            if let strokeShader = shape.strokeShader { shaders.append(strokeShader) }
        }
        if let emitter = node as? SKEmitterNode,
           let particleTexture = emitter.particleTexture {
            textures.append(particleTexture)
        }
        if let field = node as? SKFieldNode,
           let fieldTexture = field.texture {
            textures.append(fieldTexture)
        }
        if let effect = node as? SKEffectNode,
           let shader = effect.shader {
            shaders.append(shader)
        }

        for shader in shaders {
            for uniform in shader.uniforms {
                if let texture = uniform.textureValue {
                    textures.append(texture)
                }
            }
        }
        return textures
    }

    private func refreshTextureLayers(in node: SKNode) {
        if let sprite = node as? SKSpriteNode {
            sprite.updateLayerContents()
        }
        if let shape = node as? SKShapeNode {
            shape.updateTextureLayers()
        }
        if let emitter = node as? SKEmitterNode {
            emitter.updateEmitterTexture()
        }
        for child in node.children {
            refreshTextureLayers(in: child)
        }
    }

    // MARK: - Effect Preparation

    private func prepareEffects(in node: SKNode) async -> SKRendererError? {
        var firstError: SKRendererError?

        // Children are prepared first so a parent effect captures the final
        // composited result of any nested effect node.
        for child in node.children {
            let childError = await prepareEffects(in: child)
            if firstError == nil {
                firstError = childError
            }
        }

        if let effectNode = node as? SKEffectNode {
            do {
                try await prepare(effectNode)
            } catch {
                restoreUnfilteredChildren(of: effectNode)
                if firstError == nil {
                    firstError = rendererError(from: error)
                }
            }
        }
        return firstError
    }

    private func prepare(_ effectNode: SKEffectNode) async throws {
        guard effectNode.shouldEnableEffects else {
            restoreUnfilteredChildren(of: effectNode)
            return
        }
        guard let filter = effectNode.filter else {
            throw SKRendererError.imageProcessingFailed("SKEffectNode has effects enabled but no filter")
        }

        if effectNode.shouldRasterize,
           !effectNode._needsFilterUpdate,
           effectNode._renderedFilterConfigurationRevision == filter._configurationRevision,
           let cachedImage = effectNode._cachedFilteredImage {
            effectNode.layer.contents = cachedImage
            setChildLayersHidden(true, for: effectNode)
            return
        }

        let frame = effectNode.filterContentFrame
        guard !frame.isNull, !frame.isEmpty else {
            throw SKRendererError.imageProcessingFailed("SKEffectNode cannot filter an empty child frame")
        }
        guard let childImage = effectNode.renderChildrenToImage(in: frame) else {
            throw SKRendererError.imageProcessingFailed("SKEffectNode could not render its child tree into an image")
        }

        let revision = effectNode._filterRevision
        let recipe = try effectNode.filteredImageRecipe(for: childImage)
        let filterRevision = filter._configurationRevision
        let outputRect = CGRect(origin: .zero, size: frame.size)
        let filteredImage: CGImage
        do {
            filteredImage = try await imageRenderer.render(recipe, from: outputRect)
        } catch let error as SKRendererError {
            throw error
        } catch {
            throw SKRendererError.imageProcessingFailed(String(describing: error))
        }

        // The mutable filter or node configuration may have changed while the
        // WebGPU promise was suspended. Never commit pixels from an older
        // recipe into the new configuration.
        guard effectNode._filterRevision == revision,
              effectNode.filter === filter,
              filter._configurationRevision == filterRevision else { return }

        effectNode.storeFilteredImage(filteredImage, filterRevision: filterRevision)
        effectNode.layer.contents = filteredImage
        effectNode.layer.bounds = frame
        setChildLayersHidden(true, for: effectNode)
    }

    private func restoreUnfilteredChildren(of effectNode: SKEffectNode) {
        effectNode.layer.contents = nil
        effectNode._cachedFilteredImage = nil
        effectNode._needsFilterUpdate = true
        setChildLayersHidden(false, for: effectNode)
    }

    private func setChildLayersHidden(_ hidden: Bool, for node: SKNode) {
        for child in node.children {
            child.layer.isHidden = hidden || child.isHidden
        }
    }

    private func rendererError(from error: Error) -> SKRendererError {
        if let rendererError = error as? SKRendererError {
            return rendererError
        }
        return .imageProcessingFailed(String(describing: error))
    }
}
