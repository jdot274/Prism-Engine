# Mirror via SceneCapture2D + Render Target

Make a real mirror surface in UE — actor reflects the scene as it would in a real mirror.

## Assets

- `RT_Mirror_1024` — `UTextureRenderTarget2D`, RGBA8, 1024 × 1024, sRGB on
- `M_Mirror` — material that:
  - Samples `RT_Mirror_1024`
  - UV = `ScreenPosition.xy / ScreenPosition.w * float2(0.5, -0.5) + 0.5`
  - Output → Emissive (Unlit shading model)

## Actor

`BP_Mirror` Blueprint:

1. `StaticMeshComponent` — flat plane mesh, assigned `M_Mirror`
2. `SceneCaptureComponent2D` named `MirrorCapture`
   - **Texture Target** = `RT_Mirror_1024`
   - **Capture Source** = `SCS_FinalColorLDR`
   - **Projection Type** = `Perspective`
   - **FOV** = matches the player camera (typically 90)
   - **Capture Every Frame** = `true`

## Tick logic

Each frame, position the capture as a mirror reflection of the player camera:

```cpp
void ABP_Mirror::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);
    APlayerCameraManager* Cam = UGameplayStatics::GetPlayerCameraManager(this, 0);
    FVector  CamLoc = Cam->GetCameraLocation();
    FRotator CamRot = Cam->GetCameraRotation();

    FVector  MirrorLoc = MirrorMesh->GetComponentLocation();
    FVector  MirrorN   = MirrorMesh->GetForwardVector();
    FVector  ToCam     = CamLoc - MirrorLoc;
    float    Dist      = FVector::DotProduct(ToCam, MirrorN);
    FVector  ReflLoc   = CamLoc - 2.0f * Dist * MirrorN;

    FVector ReflFwd = FMath::GetReflectionVector(Cam->GetActorForwardVector(), MirrorN);
    FVector ReflUp  = FMath::GetReflectionVector(Cam->GetActorUpVector(),      MirrorN);
    FRotator ReflRot = FRotationMatrix::MakeFromXZ(ReflFwd, ReflUp).Rotator();

    MirrorCapture->SetWorldLocationAndRotation(ReflLoc, ReflRot);
    MirrorCapture->FOVAngle = Cam->GetFOVAngle();
}
```

## Performance

- One mirror ≈ one extra render pass. Two mirrors facing each other recurse — disable recursion via `ShowOnlyActors` or limit `MirrorCapture->MaxViewDistanceOverride`.
- Reduce RT size for distant or non-focal mirrors.
- Disable Bloom / DOF in the capture's `Post Process Settings → Show Flags`.

## Bonus: portal

Same recipe, but place the SceneCapture at the **destination** portal facing the right way. Use `CustomNearClippingPlane = MirrorPlane` to clip everything behind the portal surface.
