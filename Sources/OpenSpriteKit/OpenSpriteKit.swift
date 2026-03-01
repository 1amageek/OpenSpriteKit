// OpenSpriteKit.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

@_exported import Foundation

// Re-export SIMD types from SIMDSupport module
@_exported import SIMDSupport

// OpenSpriteKit is a WASM-only library that uses OpenCoreGraphics/OpenCoreAnimation
@_exported import OpenCoreGraphics
@_exported import OpenCoreAnimation

/// Cache management utilities for OpenSpriteKit resources.
public enum OpenSpriteKitCache {
    /// Clears all known caches (textures, resources, and GPU textures on WASM).
    public static func clearAll() {
        SKTextureCache.shared.clearCache()
        SKResourceLoader.shared.clearAll()
        #if arch(wasm32)
        SKTextureManager.shared.clearCache()
        #endif
    }

    /// Clears only texture caches.
    public static func clearTextures() {
        SKTextureCache.shared.clearCache()
        #if arch(wasm32)
        SKTextureManager.shared.clearCache()
        #endif
    }

    /// Clears resource registries (images, atlases, scenes, shaders, etc.).
    public static func clearResources() {
        SKResourceLoader.shared.clearAll()
    }
}
