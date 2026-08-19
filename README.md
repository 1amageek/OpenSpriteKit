# OpenSpriteKit

A Swift library implementing SpriteKit-compatible APIs for WebAssembly (WASM) environments on top of the OpenCore* stack and WebGPU.

## Overview

OpenSpriteKit enables cross-platform Swift applications to use SpriteKit APIs in WASM/Web environments where Apple's native SpriteKit is unavailable. The library uses WebGPU as its rendering backend for hardware-accelerated 2D graphics.

## Requirements

- Swift 6.4 development snapshot or newer
- For native platforms: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+
- For WASM: SwiftWasm toolchain

## Installation

### Swift Package Manager

Add OpenSpriteKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenSpriteKit.git", from: "1.0.0")
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

// Shared code can use the common, implemented API surface.
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
- **WASM/Web**: Use OpenSpriteKit for the implemented compatibility surface

## Implementation Status

The presence of a public type does not imply behavioral parity with every
SpriteKit feature. The current verified baseline is:

| Evidence | Result |
|---|---|
| Native package | 460 tests passed |
| Swift 6.4 WASM build | `OpenSpriteKit` target compiled successfully |
| Package browser smoke | Scene, action, rendering, and pixel assertions passed |
| `megaman` release-WASM E2E | 33 automated scenarios passed; 1 capture-only scenario is intentionally skipped |

The node tree, CALayer-backed 2D rendering, single-pass scene transition
composition, actions, reparenting, common
physics/input paths, texture-backed velocity fields, browser/native audio
control, and game-scene execution are active. The software CGImage path renders
sprites, shapes, and deterministic bitmap labels. Known gaps include a
SceneKit-compatible 3D runtime, full typographic shaping in the software path,
unsupported archive classes, and filter behavior inherited from lower layers.
Core Image evaluation is owned per `SKViewRenderer`/`SKRenderer`; effect nodes
and filtered textures submit immutable image recipes to that owner and surface
typed failures instead of silently substituting unfiltered pixels. See
[`DESIGN.md`](DESIGN.md) for the browser-async compatibility contract.
`SK3DNode`, perspective flip transitions, split-scene door transitions, and
dual-scene Core Image transitions are explicitly unavailable instead of being
reported as successful cross-fades or empty renders.

## Public Types

### Nodes

| Type | Status |
|------|--------|
| `SKNode` | Partial: secure archive allowed-class enforcement remains incomplete |
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
| `SK3DNode` | Explicitly unavailable until a SceneKit-compatible runtime and offscreen renderer exist |
| `SKTransformNode` | Implemented |
| `SKAudioNode` | Implemented |
| `SKFieldNode` | Implemented, including normal-texture velocity sampling |
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

# Run focused native tests with a 30-second process timeout
perl -e 'alarm 30; exec @ARGV' -- \
  xcodebuild test -scheme OpenSpriteKit -destination 'platform=macOS' \
  -only-testing:OpenSpriteKitTests

# Build for WASM with the pinned Swift 6.4 toolchain and matching SDK
TOOLCHAINS=org.swift.64202607171a xcrun swift build \
  --swift-sdk swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm
```

## End-to-End Tests

OpenSpriteKit has a stand-alone browser smoke suite and a game-level suite.
Together they exercise the SpriteKit → `OpenCoreAnimation` →
`OpenCoreGraphics` → WebGPU path in real Chromium.

- Package smoke: `Tests/e2e/`
- Game source: `../megaman/` (primary live E2E for OpenSpriteKit)
- Game specs: `../megaman/tests/e2e/specs/`

```bash
cd Tests/e2e && npm test
cd ../../../megaman/tests/e2e && npm test
```

These passing scenarios establish the exercised runtime paths; they are not a
claim of complete SpriteKit behavioral or rendering parity.

## Dependencies

- [OpenCoreGraphics](https://github.com/aspect-team/OpenCoreGraphics) - Core Graphics types for WASM
- [OpenCoreImage](https://github.com/aspect-team/OpenCoreImage) - Core Image filters for WASM
- [OpenCoreAnimation](https://github.com/aspect-team/OpenCoreAnimation) - Core Animation for WASM
- OpenFoundation - shared Foundation-compatible values and full-Swift toolchain identity

Named resources and URL reads pass through `SKResourceProviding`; `.sks`, action,
emitter, and tile property lists pass through `SKPropertyListDecoding`. This keeps
`Bundle`, file I/O, and `PropertyListSerialization` inside full-Swift adapters instead
of spreading platform capabilities through SpriteKit domain types. Failable named
initializers preserve missing or invalid resources as `nil`; they do not fabricate an
empty node as a successful load.

## License

MIT License
