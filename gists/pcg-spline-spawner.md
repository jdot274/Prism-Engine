# PCG: spawn meshes along a spline

Graph that places lampposts every N meters along a `USplineComponent` actor.

## Nodes

```
Spline Sampler (Target Actor: SplineRef)
  Sample Mode: By Distance
  Distance Between Samples: 800 cm
  ↓
Transform Points
  Rotation.Yaw = align to spline tangent
  ↓
Static Mesh Spawner
  Mesh: Lamppost_Mesh
  Generate Mesh Instances Component: HISM
  Cull Distance: 15000
  ↓
Output
```

## Parameters

Expose as graph parameters:

- `Spacing` (float, default 800)
- `MeshSet` (array of `UStaticMesh`)
- `SidesOfSpline` (enum: Left / Right / Both)
- `CullDistance` (float, default 15000)

## Variant: alternating left/right

```
Spline Sampler → Subdivide Points (every other)
  Even points: Offset +200 cm in spline normal
  Odd points:  Offset -200 cm in spline normal
↓ Static Mesh Spawner
```

## Variant: random rotation jitter

```
Transform Points (after Spline Sampler)
  Rotation.Yaw += random(-10, 10)
  Scale *= random(0.95, 1.05)
```

## Usage in a level

1. Place a `BP_RoadSpline` actor with a `USplineComponent`
2. Place a `PCGVolume` covering the spline bounds
3. Assign the PCG Graph above
4. Set the **Spline Reference** parameter to your `BP_RoadSpline`
5. Generate

Re-runs whenever you tweak the spline.
