# Widget Component on a 3D mesh

Show UMG (with a Web Browser inside it) on any face of a mesh actor.

## Setup

In a custom Actor BP:

1. Add a `StaticMeshComponent` (the wall / screen / monitor)
2. Add a `WidgetComponent` as a child
3. Configure `WidgetComponent`:
   - **Widget Class** = your UMG (containing a `WebBrowser` widget pointed at three.js or any URL)
   - **Widget Space** = World
   - **Draw Size** = `2048 × 1024`
   - **Pivot** = `(0.5, 0.5)`
   - **Two Sided** = `true`
   - **Receive Hardware Input** = `true` (lets you click into the UMG/Browser)
4. In the BP construction script:
   ```
   WidgetComp->SetRelativeLocation(MeshComp->GetSocketLocation("ScreenFront"));
   WidgetComp->SetRelativeRotation(MeshComp->GetSocketRotation("ScreenFront"));
   ```

## Render-to-texture variant

Instead of letting the widget render in 3D directly, capture it to an RT and paint it on the mesh:

1. `WidgetComp->SetWidgetSpace(EWidgetSpace::World)`
2. Get its internal render target: `WidgetComp->GetRenderTarget()`
3. Set on a `MaterialInstanceDynamic`: `MID->SetTextureParameterValue("ScreenTex", RT)`
4. Assign `MID` to the mesh's material slot

This is what WebUI does under the hood.

## Pitfalls

- **Receive Hardware Input** + mouse cursor: enable `bShowMouseCursor` on the PlayerController.
- **Transparency**: WidgetComponent supports translucent / masked / opaque materials — pick based on whether you need overlays.
- **Performance**: a 2048×1024 widget redraws each tick. Use **Invalidation Box** inside the UMG for static portions.
