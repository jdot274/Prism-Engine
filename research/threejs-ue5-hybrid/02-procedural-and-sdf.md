---
title: "Procedural / Parametric / SDF Approaches"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§2"
---

# 2. Procedural / Parametric / SDF Approaches

> _Don't ship geometry — ship the recipe. Procedural and parametric content sidesteps the FBX/glTF problem entirely by recreating the same geometry on both sides from the same parameters._

Related reading: [01-scene-interchange-formats.md](01-scene-interchange-formats.md) for non-procedural alternatives; [03-shader-interop.md](03-shader-interop.md) for SDF shader sharing details; [07-meta-scene-tool-design.md](07-meta-scene-tool-design.md) for how procedural definitions are referenced from the DSL.

---

## 2.1 Signed Distance Fields shared between Three.js raymarcher and UE5 SDF material

- **Three.js side**: Custom `RawShaderMaterial` or TSL `compute()` raymarcher, using [IQ's SDF library](https://iquilezles.org/articles/distfunctions/) and [hg_sdf](https://mercury.sexy/hg_sdf/).
- **UE5 side**: Material Editor's Custom HLSL node with the same SDF functions; alternatively bake into UE5's [Mesh Distance Fields](https://dev.epicgames.com/documentation/en-us/unreal-engine/mesh-distance-fields-in-unreal-engine) (the Lumen + DFAO substrate).
- **Status**: Production for *post-process* SDF shaders (raymarched skyboxes, terrain). Production for game geometry only if you keep counts modest.
- **Shared artifact**: a single `float sceneSDF(vec3 p)` function authored in WGSL → emitted to HLSL via [Tint](https://dawn.googlesource.com/tint) or [Naga](https://github.com/gfx-rs/wgpu/tree/trunk/naga). See [§3](03-shader-interop.md).
- **Reference ports**: [Dimev/shadertoy-to-unreal-engine](https://github.com/Dimev/shadertoy-to-unreal-engine), [gam0022/RaymarchingInUE5](https://github.com/gam0022/RaymarchingInUE5), [Sharundaar's IQ-port series](https://sharundaar.com/porting-iq-2d-sdf-shadertoys-to-unreal-part-3.html).

## 2.2 Manifold + UE5 Geometry Script — *the underrated procedural bridge*

- **[Manifold](https://github.com/elalish/manifold)** (Apache-2): exact-arithmetic CSG kernel, compiles to **WASM** for browser and **C++** for native linking into UE5.
- **UE5 [Geometry Script](https://dev.epicgames.com/documentation/en-us/unreal-engine/geometry-script-users-guide-in-unreal-engine)**: official, Blueprint-callable, mesh-generation library; can be driven by a `UDataAsset` (typed JSON parameter pack).
- **The recipe**: Define a typed JSON parameter pack `{ shape: 'gear', radius: 1.2, teeth: 24, ... }`. Web client runs Manifold-WASM with these params. UE5 server/client runs Manifold native (linked into a Geometry Script library) with the same params. Same input → same triangles, deterministically.
- **Status**: Each piece is production. The integration is custom (≈ a week of glue per side).

## 2.3 Marching Cubes / Surface Nets / Dual Contouring

- **Three.js**: `examples/jsm/objects/MarchingCubes.js`; npm [isosurface](https://www.npmjs.com/package/isosurface) and [surface-nets](https://www.npmjs.com/package/surface-nets).
- **UE5**: [Voxel Plugin](https://voxelplugin.com/), [TransvoxelMC](https://github.com/Tuatara-Gamesworks/UE_Transvoxel), and Geometry Script's `AppendMarchingCubes` node (5.3+).
- **Determinism**: Yes if you (a) use integer grid sampling, (b) avoid floating-point edge cases (LERP threshold ties), (c) lock the same tie-breaking rule on both sides.
- **Status**: Production for voxel games (think *Astroneer*, *Hytale*). Most successful when paired with a *fixed* voxel grid you ship as a binary 3D texture.

## 2.4 L-systems, Wave Function Collapse, Perlin/Simplex noise

- **Deterministic across engines** if you (a) use integer math for the seed/state machine, (b) use [PCG hash](https://www.reedbeta.com/blog/hash-functions-for-gpu-rendering/) for sampling (HLSL/WGSL/GLSL bit-identical), (c) **avoid `sin`-based noise** (`fract(sin(dot(...))*43758.5453)` is not vendor-stable).
- **WFC**: [mxgmn/WaveFunctionCollapse](https://github.com/mxgmn/WaveFunctionCollapse) (C# original) has ports to JS, C++, Rust. Same input bitmap + same seed → same output.
- **L-systems**: trivial to port. Three.js examples and UE5 Geometry Script both support them.
- **Status**: Production. This is the cheapest way to get "same world on both clients" without shipping any geometry at all.

## 2.5 CSG / OpenSCAD / libfive / metaballs

- [three-csg-ts](https://github.com/samalexander/three-csg-ts), [manifold-3d](https://github.com/elalish/manifold) (best), [OpenSCAD](https://openscad.org/), [libfive](https://libfive.com/).
- Status: Use Manifold (§2.2) for everything CSG-related — it's the only one that's production-grade on both ends in 2026.

## 2.6 Best bets in this domain

1. **Manifold + UE5 Geometry Script** driven by typed JSON for parametric content.
2. **PCG-hash noise + WFC** for procedural world layout — both deterministic across engines.
3. **SDF shaders** as a shared *post-process* layer (skies, terrain, decals), authored once in WGSL.

---

**Up next:** [03 — Shader interop](03-shader-interop.md). **Back to:** [README](README.md).
