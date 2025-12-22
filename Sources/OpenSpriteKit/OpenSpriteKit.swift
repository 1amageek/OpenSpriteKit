// OpenSpriteKit.swift
// OpenSpriteKit
//
// Copyright (c) 2024 OpenSpriteKit contributors
// Licensed under MIT License

// Re-export dependencies so all files in this module can use CG/CI types
// Note: OpenImageIO already re-exports OpenCoreGraphics, so we don't import it directly
// to avoid "ambiguous type lookup" errors (CGImage would be visible from both modules)
//@_exported import OpenImageIO
//@_exported import OpenCoreImage
//@_exported import OpenCoreAnimation
//@_exported import Foundation

// Re-export SIMD types from SIMDSupport module
@_exported import SIMDSupport
