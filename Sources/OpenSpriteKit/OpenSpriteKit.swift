// OpenSpriteKit.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

// Re-export CoreGraphics/OpenCoreGraphics so all files in this module can use CG types
#if canImport(CoreGraphics)
@_exported import CoreGraphics
#else
@_exported import OpenCoreGraphics
#endif

// Re-export CoreImage/OpenCoreImage for filter effects
#if canImport(CoreImage)
@_exported import CoreImage
#else
@_exported import OpenCoreImage
#endif

@_exported import Foundation

// Re-export SIMD types from SIMDSupport module
@_exported import SIMDSupport
