# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CRITICAL: Reading Apple Documentation

**ALWAYS use the `remark` command for Apple Developer documentation.**

```bash
remark "https://developer.apple.com/documentation/spritekit/sknode"
```

**DO NOT use WebFetch, WebSearch, or other tools for Apple documentation URLs.** Apple's documentation pages require JavaScript rendering, and only the `remark` command can properly extract content from them.

This applies to ALL Apple Developer documentation URLs:
- `https://developer.apple.com/documentation/*`
- `https://developer.apple.com/library/*`

---

## Project Overview

OpenSpriteKit is a Swift library that provides **full API compatibility with Apple's SpriteKit framework** for WebAssembly (WASM) environments.

### Core Principle: Full Compatibility

**The API must be 100% compatible with SpriteKit.** This means:
- Identical type names, method signatures, and property names
- Same behavior and semantics as SpriteKit
- Code written for SpriteKit should compile and work without modification when using OpenSpriteKit

### How `canImport` Works

Users of this library will write code like:

```swift
#if canImport(SpriteKit)
import SpriteKit
#else
import OpenSpriteKit
#endif

// This code works in both environments
let scene = SKScene(size: CGSize(width: 800, height: 600))
let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
sprite.position = CGPoint(x: 400, y: 300)
scene.addChild(sprite)
```

- **When SpriteKit is available** (iOS, macOS, etc.): Users import SpriteKit directly
- **When SpriteKit is NOT available** (WASM): Users import OpenSpriteKit, which provides identical APIs

This library exists so that cross-platform Swift code can use SpriteKit APIs even in WASM environments where Apple's SpriteKit is not available.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter <TestName>

# Build for WASM (requires SwiftWasm toolchain)
swift build --triple wasm32-unknown-wasi
```

## Architecture

### Implementation Approach

This library provides standalone implementations of SpriteKit types for WASM environments. Each type must exactly mirror the SpriteKit API:

```swift
// Example: SKNode must match SpriteKit.SKNode exactly
open class SKNode: NSResponder, Sendable {
    public var position: CGPoint
    public var zPosition: CGFloat
    public var xScale: CGFloat
    public var yScale: CGFloat
    public var zRotation: CGFloat
    public var alpha: CGFloat
    public var isHidden: Bool
    public var parent: SKNode?
    public var children: [SKNode]
    public var scene: SKScene?
    public var frame: CGRect { get }

    public func addChild(_ node: SKNode)
    public func removeFromParent()
    public func run(_ action: SKAction)
    // ... all other SpriteKit.SKNode APIs
}
```

**Important**: Always refer to Apple's official SpriteKit documentation to ensure API signatures match exactly.

## Dependencies

This library depends on:
- **OpenCoreGraphics** for types like:
  - `CGRect`, `CGPoint`, `CGSize`, `CGFloat`
  - `CGImage`, `CGColor`, `CGColorSpace`
  - `CGAffineTransform`, `CGPath`, `CGContext`
- **OpenCoreImage** for types like:
  - `CIImage`, `CIFilter`, `CIContext`
  - Filter effects and image processing

### Conditional Imports for Dependencies

**IMPORTANT**: Dependencies are re-exported from `OpenSpriteKit.swift` using `@_exported import`. This means:

1. **In `OpenSpriteKit.swift` only**:
```swift
#if canImport(CoreGraphics)
@_exported import CoreGraphics
#else
@_exported import OpenCoreGraphics
#endif

#if canImport(CoreImage)
@_exported import CoreImage
#else
@_exported import OpenCoreImage
#endif

@_exported import Foundation
```

2. **In all other source files**: No imports needed! CG*, CI*, and Foundation types are automatically available.

3. **In test files**: Only `@testable import OpenSpriteKit` is needed - all CG* types are available through the re-export.

This pattern ensures:
- **During tests** (`swift test`): Native CoreGraphics/CoreImage are used (Apple platforms)
- **For WASM builds** (`swift build --triple wasm32-unknown-wasi`): OpenCoreGraphics/OpenCoreImage are used
- Clean source files without repetitive import statements

## Types to Implement

### Core Node Types

| Type | Description |
|------|-------------|
| `SKNode` | The base class of all SpriteKit nodes |
| `SKScene` | The root node for all Sprite Kit objects displayed in a view |
| `SKView` | A view that renders SpriteKit content |

### Sprite and Shape Nodes

| Type | Description |
|------|-------------|
| `SKSpriteNode` | A node that draws a rectangular texture, image, or colored square |
| `SKShapeNode` | A node that renders a shape from a Core Graphics path |
| `SKLabelNode` | A node that displays a text label |
| `SKVideoNode` | A node that displays video content |
| `SKCropNode` | A node that masks child content with a shape |
| `SKEffectNode` | A node that applies Core Image filters to its children |
| `SKEmitterNode` | A node that creates and renders particles |
| `SKLightNode` | A node that provides lighting for sprite nodes |
| `SK3DNode` | A node that renders a SceneKit scene as a 2D image |

### Camera and Reference Nodes

| Type | Description |
|------|-------------|
| `SKCameraNode` | A node that determines the portion of the scene visible in the view |
| `SKReferenceNode` | A node that creates its children from an archived collection of nodes |

### Textures

| Type | Description |
|------|-------------|
| `SKTexture` | An image used to render nodes |
| `SKTextureAtlas` | A collection of textures |
| `SKMutableTexture` | A texture that can be dynamically modified |

### Actions

| Type | Description |
|------|-------------|
| `SKAction` | An object that performs changes to nodes over time |
| `SKAction` (move) | `moveTo`, `moveBy`, `move(to:duration:)` |
| `SKAction` (scale) | `scaleTo`, `scaleBy`, `scale(to:duration:)` |
| `SKAction` (rotate) | `rotateTo`, `rotateBy`, `rotate(toAngle:duration:)` |
| `SKAction` (fade) | `fadeIn`, `fadeOut`, `fadeAlpha(to:duration:)` |
| `SKAction` (sequence) | `sequence`, `group`, `repeat`, `repeatForever` |
| `SKAction` (timing) | `wait(forDuration:)`, `run(_:)`, `customAction` |

### Physics

| Type | Description |
|------|-------------|
| `SKPhysicsWorld` | The driver of the physics engine in a scene |
| `SKPhysicsBody` | An object that adds physics simulation to a node |
| `SKPhysicsContact` | A description of the contact between two physics bodies |
| `SKPhysicsJoint` | The base class for joints that connect physics bodies |
| `SKPhysicsJointPin` | A joint that pins two bodies together |
| `SKPhysicsJointSpring` | A joint that simulates a spring |
| `SKPhysicsJointFixed` | A joint that fuses two bodies together |
| `SKPhysicsJointSliding` | A joint that allows bodies to slide along an axis |
| `SKPhysicsJointLimit` | A joint that limits the distance between two bodies |
| `SKFieldNode` | A node that applies forces to physics bodies |

### Constraints

| Type | Description |
|------|-------------|
| `SKConstraint` | A specification for constraining a node's position or rotation |
| `SKReachConstraints` | A specification for reach constraints used in inverse kinematics |

### Tile Maps

| Type | Description |
|------|-------------|
| `SKTileMapNode` | A node that renders a 2D tile map |
| `SKTileSet` | A container for tile definitions |
| `SKTileGroup` | A set of related tile definitions |
| `SKTileGroupRule` | Rules for automatically placing tiles |
| `SKTileDefinition` | A single tile definition |

### Audio

| Type | Description |
|------|-------------|
| `SKAudioNode` | A node that plays audio |

### Warping

| Type | Description |
|------|-------------|
| `SKWarpGeometry` | Geometry for warping sprites and effect nodes |
| `SKWarpGeometryGrid` | A warp geometry based on a grid of source and destination positions |

### Delegates and Protocols

| Type | Description |
|------|-------------|
| `SKSceneDelegate` | A protocol to respond to scene life cycle events |
| `SKPhysicsContactDelegate` | A protocol for responding to physics contact events |
| `SKViewDelegate` | A protocol for controlling the view's render loop |

## WebGPU Rendering Backend

### Overview

OpenSpriteKit is a **WASM/Web-only library** that uses **WebGPU** as its GPU rendering backend via OpenCoreGraphics and OpenCoreImage. This provides hardware-accelerated 2D rendering comparable to Metal on Apple platforms.

**Key point**: This library does NOT run on native platforms (iOS, macOS). On native platforms, users import Apple's SpriteKit directly. OpenSpriteKit exists solely to provide SpriteKit API compatibility in WASM environments where Apple's SpriteKit is unavailable.

### Architecture

```
+-------------------------------------------------------------+
|                    OpenSpriteKit API                         |
|  (SKNode, SKScene, SKSpriteNode, SKAction - SpriteKit API)   |
+-------------------------------------------------------------+
|                    Rendering Layer                           |
|  +-------------------+  +--------------------+               |
|  | SceneRenderer     |  | ActionScheduler    |               |
|  | (Frame rendering) |  | (Animation timing) |               |
|  +-------------------+  +--------------------+               |
|  +-------------------+  +--------------------+               |
|  | TextureManager    |  | PhysicsEngine      |               |
|  | (GPU textures)    |  | (Collision/Forces) |               |
|  +-------------------+  +--------------------+               |
+-------------------------------------------------------------+
|                    OpenCoreImage                             |
|         (CIFilter effects for SKEffectNode)                  |
+-------------------------------------------------------------+
|                    OpenCoreGraphics                          |
|  (CGContext, CGPath, CGImage, CGAffineTransform)             |
+-------------------------------------------------------------+
|                     swift-webgpu                             |
|          (SwiftWebGPU - Type-safe WebGPU bindings)           |
+-------------------------------------------------------------+
|                     JavaScriptKit                            |
|               (Swift-to-JavaScript bridge)                   |
+-------------------------------------------------------------+
|                    Browser WebGPU API                        |
|                     (navigator.gpu)                          |
+-------------------------------------------------------------+
```

### Core Components

#### 1. SceneRenderer

Manages the render loop and frame composition:

```swift
internal actor SceneRenderer {
    private var device: GPUDevice?
    private var renderPipeline: GPURenderPipeline?

    func render(scene: SKScene, to view: SKView) async {
        // 1. Update node tree (positions, rotations, scales)
        // 2. Process actions
        // 3. Run physics simulation
        // 4. Render nodes front-to-back by zPosition
        // 5. Present to canvas
    }
}
```

#### 2. TextureManager

Handles GPU texture creation and caching:

```swift
internal actor TextureManager {
    private var textureCache: [String: GPUTexture] = [:]

    func texture(for skTexture: SKTexture) async -> GPUTexture {
        // Load or retrieve cached GPU texture
    }
}
```

#### 3. ActionScheduler

Manages SKAction execution timing:

```swift
internal class ActionScheduler {
    func update(deltaTime: TimeInterval) {
        // Update all running actions
        // Remove completed actions
        // Handle completion blocks
    }
}
```

### Rendering Strategy

#### Sprite Batching

Sprites with the same texture are batched into single draw calls:

```swift
internal struct SpriteBatch {
    let texture: GPUTexture
    var instances: [SpriteInstance]

    struct SpriteInstance {
        var transform: matrix_float4x4
        var textureRect: CGRect
        var color: CGColor
        var alpha: Float
    }
}
```

#### Z-Order Rendering

Nodes are sorted by `zPosition` for correct layering:

```swift
func sortedNodes(in scene: SKScene) -> [SKNode] {
    scene.children
        .flatMap { $0.allDescendants() }
        .sorted { $0.zPosition < $1.zPosition }
}
```

### Physics Implementation

Physics simulation using a 2D physics engine:

```swift
public class SKPhysicsWorld {
    internal var bodies: [SKPhysicsBody] = []
    internal var joints: [SKPhysicsJoint] = []

    public var gravity: CGVector = CGVector(dx: 0, dy: -9.8)
    public var speed: CGFloat = 1.0

    internal func simulate(deltaTime: TimeInterval) {
        // Apply gravity
        // Integrate velocities
        // Detect collisions
        // Resolve contacts
        // Update node positions
    }
}
```

### Platform Strategy

OpenSpriteKit is **exclusively for WASM/Web environments**. No conditional compilation is needed within this library.

Users select between SpriteKit and OpenSpriteKit at the import level:

```swift
// User's application code
#if canImport(SpriteKit)
import SpriteKit  // Native platforms (iOS, macOS, etc.)
#else
import OpenSpriteKit  // WASM/Web - uses WebGPU internally
#endif

// Same API works in both environments
let scene = SKScene(size: CGSize(width: 800, height: 600))
let sprite = SKSpriteNode(imageNamed: "player")
scene.addChild(sprite)
```

### Performance Considerations

1. **Sprite batching**: Combine sprites with same texture into single draw calls
2. **Texture atlases**: Pack multiple textures to reduce GPU state changes
3. **Action optimization**: Pre-calculate action curves, avoid per-frame allocations
4. **Physics spatial partitioning**: Use quadtree for broad-phase collision detection
5. **Node culling**: Skip rendering nodes outside visible area
6. **Dirty flag tracking**: Only update transforms when nodes actually change

## Protocol Conformances

- `SKNode`, `SKScene`: Should conform to `NSCopying`, `NSSecureCoding` (where applicable)
- Value types should conform to: `Sendable`, `Hashable`, `Equatable`, `Codable`
- Node classes should properly support `Sendable` for concurrent access

## Implementation Policy

- **Do NOT implement deprecated APIs** - Only implement current, non-deprecated SpriteKit APIs
- Focus on APIs that are meaningful for WASM environments
- Rendering should produce visually correct results matching SpriteKit behavior
- GameplayKit integration is lower priority for initial implementation

## Coding Rules

### DO NOT use platform-specific C library imports

**NEVER use this pattern:**
```swift
// ❌ DO NOT DO THIS
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif
```

Math functions like `sin()`, `cos()`, etc. are already available through Foundation, which is re-exported from `OpenSpriteKit.swift`. Just use them directly without any module prefix.

```swift
// ✅ CORRECT - Foundation provides math functions
let angle = sin(Double(zRotation))
let cosAngle = cos(Double(zRotation))
```

```swift
// ❌ WRONG - Don't use Darwin prefix
let angle = Darwin.sin(zRotation)
```

## Reading Apple Documentation

When reading Apple's official documentation, **always use the `remark` command**:

```bash
remark "https://developer.apple.com/documentation/spritekit/sknode"
```

This ensures proper parsing and extraction of API specifications from Apple's documentation pages. Do NOT use WebFetch or other tools for Apple documentation URLs.

## Testing

Uses Swift Testing framework (not XCTest). Test syntax:

```swift
import Testing
@testable import OpenSpriteKit

@Test func testSKNodeHierarchy() {
    let parent = SKNode()
    let child = SKNode()
    parent.addChild(child)

    #expect(child.parent === parent)
    #expect(parent.children.contains { $0 === child })
}

@Test func testSKSpriteNodeCreation() {
    let sprite = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
    #expect(sprite.size.width == 100)
    #expect(sprite.size.height == 100)
}

@Test func testSKActionSequence() async {
    let node = SKNode()
    let action = SKAction.sequence([
        SKAction.moveBy(x: 100, y: 0, duration: 1.0),
        SKAction.fadeOut(withDuration: 0.5)
    ])
    node.run(action)
    // Verify action execution
}
```

## SpriteKit Behavior Reference

This section summarizes key SpriteKit behaviors that must be matched exactly in OpenSpriteKit.

### Coordinate System

- **Origin**: Bottom-left corner of the scene (0, 0)
- **Positive X**: Rightward
- **Positive Y**: Upward
- **Rotation**: Radians, counterclockwise positive (0 = right, π/2 = up, π = left, 3π/2 = down)
- **Scene coordinates**: The scene's coordinate space is the reference for all nodes
- **Node coordinates**: Each node defines its own local coordinate space

### Node Tree Structure

- Nodes form a tree hierarchy with `SKScene` as root
- Parent-child relationships: `parent`, `children`, `addChild(_:)`, `removeFromParent()`
- A node can only have one parent at a time
- Adding a node that already has a parent removes it from its current parent first
- `scene` property returns the root SKScene (nil if not in a scene)

### Property Propagation

These properties propagate down the node tree (accumulated/inherited by descendants):

| Property | Propagation |
|----------|-------------|
| `xScale`, `yScale` | Multiplied down the tree |
| `zPosition` | Added to parent's accumulated zPosition |
| `zRotation` | Added to parent's accumulated rotation |
| `alpha` | Multiplied down the tree |
| `isHidden` | If parent is hidden, all descendants are hidden |
| `speed` | Multiplied down the tree (affects action speed) |

**Non-propagating properties**: `position`, `name`, `isPaused`

### Node Tree Search Syntax

The `subscript(_:)` and `enumerateChildNodes(withName:using:)` methods support pattern syntax:

| Pattern | Meaning |
|---------|---------|
| `name` | Direct children with exact name match |
| `/name` | Direct children with name |
| `//name` | Recursive search for all descendants with name |
| `.` | Current node |
| `..` | Parent node |
| `*` | Wildcard (matches any characters) |
| `//node/child` | All "child" nodes that are children of any "node" |
| `../sibling` | Sibling of current node |

### Coordinate Conversion

```swift
// Convert point FROM another node's coordinate space TO this node's space
func convert(_ point: CGPoint, from node: SKNode) -> CGPoint

// Convert point FROM this node's coordinate space TO another node's space
func convert(_ point: CGPoint, to node: SKNode) -> CGPoint
```

Conversion goes through scene coordinates as the common reference.

### Hit-Testing

- **Order**: Reverse of drawing order (topmost drawn node is tested first)
- **Method**: Based on `frame` (bounding box), not actual content shape
- **Affected by**: `isUserInteractionEnabled`, `isHidden`, `alpha` (if 0)
- `containsPoint(_:)` checks if point is within node's accumulated frame

### Physics Bodies

Three types of physics bodies:

| Type | Dynamic | Has Volume | Use Case |
|------|---------|------------|----------|
| **Dynamic Volume** | Yes | Yes | Moving objects (balls, characters) |
| **Static Volume** | No | Yes | Immovable obstacles |
| **Edge** | No | No | Boundaries, platforms |

**Edge bodies**:
- Created with `edgeLoopFrom(rect:)`, `edgeFrom(_:to:)`, etc.
- Always `isDynamic = false`
- Zero area (no volume)
- Cannot collide with other edge bodies

**Physics properties**:
- `mass`: Weight of the body
- `density`: Mass per unit area
- `friction`: Surface friction (0.0-1.0)
- `restitution`: Bounciness (0.0-1.0)
- `linearDamping`, `angularDamping`: Motion resistance

**Bit masks** (UInt32, default 0xFFFFFFFF):
- `categoryBitMask`: What this body is
- `collisionBitMask`: What this body bounces off
- `contactTestBitMask`: What triggers contact callbacks

### Camera (SKCameraNode)

- Camera is a node that can be positioned/scaled/rotated
- Set `scene.camera = cameraNode` to use
- Visible area is determined by camera position and view size
- Camera transforms are applied inversely to rendering
- Nodes added as children of camera stay fixed in view (HUD elements)

### Performance Optimization

1. **Texture Atlases**: Pack textures to reduce draw calls
2. **Sprite Batching**: Same texture sprites batched automatically
3. **Node Culling**: Nodes outside visible area should be culled
4. **Minimize Draw Calls**: Use fewer unique textures/shaders
5. **Avoid Overdraw**: Minimize overlapping transparent nodes
6. **Use Static Bodies**: For immovable physics objects
7. **Dirty Flag Tracking**: Only update transforms when changed

### Drawing Order

1. Parent nodes drawn before children
2. Among siblings, lower `zPosition` drawn first
3. Equal `zPosition`: order in `children` array
4. Children inherit parent's accumulated position/rotation/scale

### Warp Geometry (SKWarpGeometryGrid)

- **Source/Destination arrays**: Normalized vertex positions (0.0-1.0), row-major order
- **Columns/Rows**: Number of divisions (vertices = columns + 1, rows + 1)
- **Origin**: Bottom-left of grid
- **Animation**:
  - `warpGeometry` property: Apply immediately
  - `SKAction.warp(to:duration:)`: Animated morphing
  - `SKAction.animate(withWarps:times:)`: Chain multiple warps
- **Non-SKWarpable nodes**: Add as children of SKEffectNode to warp

### Custom Fragment Shaders

**SpriteKit-provided symbols:**

| Symbol | Type | Description |
|--------|------|-------------|
| `sampler2D u_texture` | Uniform | Texture sampler |
| `float u_time` | Uniform | Elapsed simulation time |
| `float u_path_length` | Uniform | Path length (strokeShader only) |
| `vec2 v_tex_coord` | Varying | Normalized texture coordinates |
| `vec4 v_color_mix` | Varying | Premultiplied node color |
| `float v_path_distance` | Varying | Distance along path (strokeShader only) |
| `SKDefaultShading()` | Function | Default SpriteKit shading |

**Data passing:**
- **SKUniform**: Per-frame data (same for all nodes using shader)
- **SKAttribute**: Per-primitive data (different for each node)

**SKAttributeType values:**
- `none`, `float`, `halfFloat`
- `vectorFloat2`, `vectorFloat3`, `vectorFloat4`
- `vectorHalfFloat2`, `vectorHalfFloat3`, `vectorHalfFloat4`

**Shader output**: Set `gl_FragColor` (premultiplied alpha)

### Tile Maps (SKTileMapNode)

**SKTileSetType:**
- `.grid`: Standard square grid
- `.hexagonalFlat`: Hexagonal with flat tops
- `.hexagonalPointy`: Hexagonal with pointy tops
- `.isometric`: Isometric (diamond) grid

**SKTileAdjacencyMask**: Defines auto-tiling rules for adjacent tiles
- Cardinal: `adjacencyUp`, `adjacencyDown`, `adjacencyLeft`, `adjacencyRight`
- Diagonal: `adjacencyUpperLeft`, `adjacencyUpperRight`, `adjacencyLowerLeft`, `adjacencyLowerRight`
- Edges/Corners: Various edge and corner masks
- Hex variants: `hexFlat*`, `hexPointy*` prefixed masks

### Physics Joints

**Creating joints:**
1. Create physics bodies and attach to nodes
2. Create joint with scene coordinates (convert if needed)
3. Add to physics world: `scene.physicsWorld.add(joint)`

**Joint types:**
- **SKPhysicsJointPin**: Allows independent rotation around anchor
- **SKPhysicsJointFixed**: Fuses bodies together rigidly
- **SKPhysicsJointSpring**: Elastic connection between bodies
- **SKPhysicsJointSliding**: Bodies slide along an axis
- **SKPhysicsJointLimit**: Maximum distance constraint (like rope)

**Removing joints:** `scene.physicsWorld.remove(joint)`

**Coordinate conversion for joints:**
```swift
let scenePosition = parentNode.convert(childNode.position, to: scene)
let joint = SKPhysicsJointPin.joint(withBodyA: bodyA, bodyB: bodyB, anchor: scenePosition)
```

### Inverse Kinematics

- **End effector**: The node that reaches toward target
- **Root node**: Fixed anchor point of chain
- **SKAction.reach(to:rootNode:duration:)**: Solves IK chain
- **SKConstraint**: Used to limit joint rotations and positions
- Non-physics based: Uses node hierarchy, not physics joints

## Reference

- [SpriteKit Documentation](https://developer.apple.com/documentation/spritekit)
- [SpriteKit Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/Introduction/Introduction.html)
- [SKNode Class Reference](https://developer.apple.com/documentation/spritekit/sknode)
- [SKAction Class Reference](https://developer.apple.com/documentation/spritekit/skaction)
