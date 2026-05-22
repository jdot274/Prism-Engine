---
title: "Shader-Level Interop (HLSL ↔ GLSL ↔ SPIR-V ↔ WGSL ↔ MSL)"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§3"
---

# 3. Shader-Level Interop (HLSL ↔ GLSL ↔ SPIR-V ↔ WGSL ↔ MSL)

> _The 2026 picture, in one line: **SPIR-V is the offline IR, WGSL is the practical authoring language, and `glslang`'s HLSL frontend was deprecated in April 2026** ([issue #4210](https://github.com/KhronosGroup/glslang/issues/4210), shipped in [16.3.0](https://github.com/KhronosGroup/glslang/releases/tag/16.3.0)). Microsoft DXC and Slang own HLSL now._

Related reading: [02-procedural-and-sdf.md](02-procedural-and-sdf.md) §2.1 for the SDF-shader use case; [04-fake-rendering-tricks.md](04-fake-rendering-tricks.md) §4.4 for Gaussian splat shaders.

---

## 3.1 The tools

| Tool | Direction | Maturity 2026 | Repo |
|---|---|---|---|
| **[SPIRV-Cross](https://github.com/KhronosGroup/SPIRV-Cross)** | SPIR-V → {GLSL, HLSL, MSL} | Production; tess HLSL landed Feb 2026 ([PR #2604](https://github.com/KhronosGroup/SPIRV-Cross/pull/2604)) | KhronosGroup/SPIRV-Cross |
| **[Naga](https://github.com/gfx-rs/wgpu/tree/trunk/naga)** | WGSL/SPIR-V/GLSL ↔ {WGSL, SPIR-V, HLSL, MSL, GLSL} | Production for WGSL backends; HLSL backend is SM5.0/5.1/6.0 only | gfx-rs/wgpu |
| **[DXC](https://github.com/microsoft/DirectXShaderCompiler)** | HLSL → DXIL, SPIR-V | Production; SM6.10 preview shipping April 2026 | microsoft/DirectXShaderCompiler |
| **[Tint](https://dawn.googlesource.com/tint)** | WGSL → {HLSL, MSL, SPIR-V, GLSL, WGSL} | Production (in Chromium); bindless HLSL Jan 2026 | dawn.googlesource.com/tint |
| **[Slang](https://github.com/shader-slang/slang)** | Slang → SPIR-V/HLSL/CUDA/Metal | Production v2026.5.2; the spiritual successor to HLSL | shader-slang/slang |
| **[glslang](https://github.com/KhronosGroup/glslang)** | GLSL → SPIR-V | Production for GLSL; HLSL frontend deprecated | KhronosGroup/glslang |

## 3.2 The 2026 translation matrix (frontend → backend)

The path you'll actually use: **WGSL → (Tint or Naga) → HLSL** for UE5; **WGSL → (TSL pipeline) → GLSL/WGSL** for Three.js. Or author in **Slang** if you want a richer language than WGSL with the same translation menu.

## 3.3 Three.js Node Material (TSL)

- [TSL spec](https://threejs.org/docs/TSL.html); [GLSL→TSL transpiler](https://threejsroadmap.com/blog/how-to-convert-glsl-shaders-to-tsl) (~90% accurate). r170 added `geometryNode`, `compute()` for compute-in-material ([PR #30768](https://github.com/mrdoob/three.js/pull/30768)).
- **Verdict**: Excellent for *web-only* shading. **No** auto-translation to UE5 Material Editor — the IRs are incompatible. Treat TSL as your web-side authoring; share only the *leaf math functions* with UE5 via WGSL → HLSL.

## 3.4 UE5 Custom HLSL nodes

- [Custom expressions](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-custom-material-expressions-in-unreal-engine) accept inline HLSL; for larger blocks use `AddShaderSourceDirectoryMapping` and `.usf` includes ([CT Blog walkthrough](https://tianc377.github.io/posts/UseHLSLinUE5byCPPPlugin/)).
- **~30% of WGSL/HLSL copy-pastes for free** — only the *pure-math* leaf functions (noise, BRDFs, SDFs, post-effects). Anything touching `View.WorldCameraOrigin`, `Parameters.TexCoords`, `MaterialFloat` requires porting.

## 3.5 Deterministic GPU math — the foundation for "same pixel both sides"

The canonical bit-identical hash is the **PCG hash (RXS-M-XS)**:

```glsl
uint pcg_hash(uint x) {
    uint state = x * 747796405u + 2891336453u;
    uint word  = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}
```

This compiles identically in HLSL, GLSL 330+, and WGSL (use `u32`). Multi-D variants: `pcg3d`/`pcg4d` per [Nathan Reed's reference](https://www.reedbeta.com/blog/hash-functions-for-gpu-rendering/).

**FP caveats**: `+`/`-`/`*` are deterministic across HLSL/GLSL when `precise` / `-Od`; **but** `pow`, `exp`, `log`, `sin`, `cos` differ by vendor (NVIDIA/AMD/Intel/Apple). Use minimax-polynomial approximations of transcendentals where you need pixel-locked output.

## 3.6 Compute shader portability

WebGPU compute → HLSL compute for procedural mesh gen *works* for pure-integer/bitwise paths (PCG noise, hash grids, voxel chunking). Floating-point heavy compute (cloth, fluid, GPU-driven culling) will drift; only use it when the result feeds *back* into the same engine (i.e., generate-once-per-engine, no cross-engine round-trip).

## 3.7 Shadertoy-style raymarched scenes — pixel-identical ports

Achievable if you (a) match gamma (Shadertoy assumes linear→sRGB ~2.2; UE5 does sRGB writeout — don't double-encode), (b) match UV orientation (UE5 flips Y in some paths), (c) avoid driver-defined transcendentals. Verified by repos in [§2.1](02-procedural-and-sdf.md#21-signed-distance-fields-shared-between-threejs-raymarcher-and-ue5-sdf-material).

**The shareable artifact**: a single function `vec3 sceneColor(vec2 uv, float t)` — render via Three.js fullscreen quad and a UE5 Material Domain "Post Process" or unlit quad with Custom node body.

## 3.8 Best bets in this domain

1. **Author shared shader math in WGSL** → emit HLSL via Tint/Naga for UE5 Custom nodes.
2. **Anchor determinism with PCG hash + polynomial-approximated transcendentals.**
3. **Slang as the upgrade path** if Khronos+Microsoft converge.

---

**Up next:** [04 — Fake-rendering tricks (incl. Gaussian splats)](04-fake-rendering-tricks.md). **Back to:** [README](README.md).
