# OpenSpriteKit Design Decisions

## Renderer-owned Core Image evaluation

### Ownership

Each `SKViewRenderer` and `SKRenderer` owns one `SKSceneImageProcessor`, which
owns one `SKImageRendering` implementation. The production implementation owns
one strong `CIContext` for the lifetime of that renderer.

```text
SKViewRenderer / SKRenderer
    -> SKSceneImageProcessor
        -> SKCoreImageRenderer
            -> CIContext
                -> CIContextRenderer
```

`SKEffectNode`, `SKTexture`, and `SKTransition` may construct immutable
`CIImage` recipes, but they do not create, cache, or globally share a
`CIContext`. This keeps WebGPU device affinity and compiled-resource caches at
the composition boundary and prevents a process-global context from crossing
independent canvases.

### Asynchronous WebGPU difference

Apple's SpriteKit `SKTexture.applying(_:)` copies filtered image data before it
returns. Browser WebGPU mapping and readback complete through JavaScript
promises and cannot be synchronously blocked by WebAssembly without preventing
the promise from making progress.

The portable implementation therefore preserves the operation name and
nonfailable result type but stores the immutable `CIImage` recipe in the new
texture. The renderer that first consumes the texture evaluates that recipe
before submitting the containing frame. `SKRenderer.renderAsync()` provides an
explicit completion and typed-error boundary for offscreen callers. The
standard synchronous `render()` schedules this preparation when required and
reports a failure through `lastRenderError`.

An evaluation failure never installs the source image as the filtered result.
`SKView.lastRenderError` or `SKRenderer.lastRenderError` reports the failure,
and effect-node children remain visible only as an explicitly failed effect
state.

### Mutable filters

`CIFilter` remains mutable and is accessed only on the renderer's main-actor
frame path. The resulting `CIImage` recipe is immutable before the asynchronous
context evaluation begins. A context is reusable, but a mutable filter is not
shared across executors.
