# OpenSpriteKit

A Swift library providing **full API compatibility with Apple's SpriteKit** for WebAssembly (WASM) environments.

## Overview

OpenSpriteKit enables cross-platform Swift applications to use SpriteKit APIs in WASM/Web environments where Apple's native SpriteKit is unavailable. The library uses WebGPU as its rendering backend for hardware-accelerated 2D graphics.

## Requirements

- Swift 6.2+
- For native platforms: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+
- For WASM: SwiftWasm toolchain

## Installation

### Swift Package Manager

Add OpenSpriteKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aspect-team/OpenSpriteKit.git", from: "1.0.0")
]
```

## Usage

OpenSpriteKit is designed for seamless cross-platform development using `canImport`:

```swift
#if canImport(SpriteKit)
import SpriteKit
#else
import OpenSpriteKit
#endif

// Your SpriteKit code works in both environments
let scene = SKScene(size: CGSize(width: 800, height: 600))

let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
sprite.position = CGPoint(x: 400, y: 300)
scene.addChild(sprite)

let action = SKAction.repeatForever(
    SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
)
sprite.run(action)
```

- **Native platforms** (iOS, macOS, etc.): Use Apple's SpriteKit directly
- **WASM/Web**: Use OpenSpriteKit with identical APIs

## Implemented Types

### Nodes

| Type | Status |
|------|--------|
| `SKNode` | Implemented |
| `SKScene` | Implemented |
| `SKSpriteNode` | Implemented |
| `SKShapeNode` | Implemented |
| `SKLabelNode` | Implemented |
| `SKEffectNode` | Implemented |
| `SKCropNode` | Implemented |
| `SKCameraNode` | Implemented |
| `SKEmitterNode` | Implemented |
| `SKLightNode` | Implemented |
| `SKVideoNode` | Implemented |
| `SKReferenceNode` | Implemented |
| `SK3DNode` | Implemented |
| `SKTransformNode` | Implemented |
| `SKAudioNode` | Implemented |
| `SKFieldNode` | Implemented |
| `SKTileMapNode` | Implemented |

### Rendering

| Type | Status |
|------|--------|
| `SKView` | Implemented |
| `SKRenderer` | Implemented |
| `SKTexture` | Implemented |
| `SKMutableTexture` | Implemented |
| `SKShader` | Implemented |

### Actions

| Type | Status |
|------|--------|
| `SKAction` | Implemented |

### Physics

| Type | Status |
|------|--------|
| `SKPhysicsWorld` | Implemented |
| `SKPhysicsBody` | Implemented |
| `SKPhysicsJoint` | Implemented |

### Constraints & Geometry

| Type | Status |
|------|--------|
| `SKConstraint` | Implemented |
| `SKReachConstraints` | Implemented |
| `SKRange` | Implemented |
| `SKRegion` | Implemented |
| `SKWarpGeometry` | Implemented |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  OpenSpriteKit API                      │
│    (SKNode, SKScene, SKSpriteNode, SKAction, etc.)      │
├─────────────────────────────────────────────────────────┤
│                  Rendering Layer                        │
│   SceneRenderer │ ActionScheduler │ TextureManager      │
├─────────────────────────────────────────────────────────┤
│                  OpenCoreImage                          │
│           (CIFilter effects for SKEffectNode)           │
├─────────────────────────────────────────────────────────┤
│                  OpenCoreGraphics                       │
│     (CGContext, CGPath, CGImage, CGAffineTransform)     │
├─────────────────────────────────────────────────────────┤
│                    WebGPU                               │
│              (Hardware-accelerated rendering)           │
└─────────────────────────────────────────────────────────┘
```

## Building

```bash
# Build for native platforms
swift build

# Run tests
swift test

# Build for WASM (requires SwiftWasm toolchain)
swift build --triple wasm32-unknown-wasi
```

## Dependencies

- [OpenCoreGraphics](https://github.com/aspect-team/OpenCoreGraphics) - Core Graphics types for WASM
- [OpenCoreImage](https://github.com/aspect-team/OpenCoreImage) - Core Image filters for WASM
- [OpenCoreAnimation](https://github.com/aspect-team/OpenCoreAnimation) - Core Animation for WASM

## License

MIT License
