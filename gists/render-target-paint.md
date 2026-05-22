# GPU paint with two render targets

Ping-pong two RTs to accumulate per-pixel paint each frame, sampled by the previous frame's state.

## Assets

- `RT_PaintA` and `RT_PaintB` — `UTextureRenderTarget2D`, RGBA8, 1024×1024
- `M_PaintBrush` — material that:
  - Samples a `Texture2D` parameter `PrevState`
  - Reads `BrushPosition` and `BrushRadius` parameters
  - Outputs the new state into Emissive

## Material

```hlsl
// M_PaintBrush emissive logic
float2 uv = TexCoord(0);
float4 prev = Texture2DSample(PrevState, uv);
float d = distance(uv, BrushPosition);
float brushMask = saturate(1.0 - d / BrushRadius);
float3 newColor = lerp(prev.rgb, BrushColor, brushMask);
return float4(newColor, 1);
```

## Blueprint / C++ tick

```cpp
void APaintSurface::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    bool bUseA = (FrameCount++ & 1) == 0;
    UTextureRenderTarget2D* Source = bUseA ? RT_PaintB : RT_PaintA;
    UTextureRenderTarget2D* Target = bUseA ? RT_PaintA : RT_PaintB;

    BrushMID->SetTextureParameterValue(TEXT("PrevState"), Source);
    BrushMID->SetVectorParameterValue(TEXT("BrushPosition"),
        FLinearColor(BrushUV.X, BrushUV.Y, 0, 0));
    BrushMID->SetScalarParameterValue(TEXT("BrushRadius"), BrushRadiusUV);
    BrushMID->SetVectorParameterValue(TEXT("BrushColor"), FLinearColor::Red);

    UKismetRenderingLibrary::DrawMaterialToRenderTarget(this, Target, BrushMID);

    SurfaceMaterial->SetTextureParameterValue(TEXT("BaseColor"), Target);
}
```

## Use cases

- Terrain painting (blood, mud, snow trails)
- Procedural decals at runtime
- Whiteboard / drawing surfaces
- Fluid sim ping-pong
