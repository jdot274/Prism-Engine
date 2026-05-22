---
title: "Scene-Description Interchange Formats That Aren't FBX/GLTF"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§1"
---

# 1. Scene-Description Interchange Formats That Aren't FBX/GLTF

> _The hard constraint of this study: no FBX, no glTF. What's left that's actually usable in both Three.js and UE5 in 2026?_

Related reading: [02-procedural-and-sdf.md](02-procedural-and-sdf.md) for parametric/procedural alternatives; [04-fake-rendering-tricks.md](04-fake-rendering-tricks.md) §4.4 for Gaussian splats (the *photoreal-geometry* counterpart to this section's *scene-structure* formats); [07-meta-scene-tool-design.md](07-meta-scene-tool-design.md) for how all of these get wrapped in a single DSL.

---

## 1.1 OpenUSD / USD / USDZ — *the only real production-grade bidirectional pipe*

- **UE5 side**: Native [Interchange OpenUSD](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/PluginIndex/InterchangeOpenUSD) in 5.7; USD Stage Editor; full layer-composition arcs; runtime + editor.
- **Three.js side**: `examples/jsm/loaders/USDLoader.js` ([docs](https://threejs.org/docs/pages/USDLoader.html)) gained USDC support in [PR #32704](https://github.com/mrdoob/three.js/pull/32704) (Jan 2026). Pure-TS [`@cinevva/usdjs`](https://github.com/cinevva-engine/usdjs) (Jan 2026) parses USDA/USDC/USDZ without WASM.
- **WASM**: [OpenUSD v26.03](https://aousd.org/blog/openusd-v26-03/) ships official `wasm32`/`wasm64` builds plus `wasmFetchResolver` for HTTP layer loading. NVIDIA's [Omniverse Embedded Web Viewer](https://docs.omniverse.nvidia.com/embedded-web-viewer/latest/create/overview.html) is the cloud-streamed version.
- **Spline**: Already exports USDZ. So does Apple's `usdz_converter`, Houdini, Maya, Blender (via [BlenderUSDZ](https://github.com/robmcrosby/BlenderUSDZ) or 4.2+ native).
- **Status**: **Production**. This is the closest thing to a "no-FBX, no-glTF" lingua franca in 2026.
- **Gotchas**: USDZ on the web is mostly read-only — no widely-deployed *exporter* in browser. UE5's USD importer is opinionated about coordinates (Y-up vs Z-up flips) and has reproducible quirks with Material assignment when layered composition gets deep. Avoid USDA in production (slower parse); ship USDC.

## 1.2 Three.js native `Object3D.toJSON()`

- The JSON schema is well-defined ([docs](https://threejs.org/docs/#api/en/core/Object3D.toJSON)), but **there is no off-the-shelf UE5 importer**. You'd write a Python editor utility that walks the JSON tree and maps `Mesh`/`Group`/`Light`/`Camera`/`PerspectiveCamera`/`Material` → UE5 `StaticMeshActor`/`SceneComponent`/`PointLight`/`CameraActor`/`UMaterialInstanceDynamic`.
- **Status**: Custom build. Roughly 1–2 weeks of editor scripting for an MVP. Useful only if you're already source-of-truth in Three.js *and* don't want USD.

## 1.3 VRM 1.0 + VRMA — *the model your scene format should copy*

- **Status**: Production on both sides.
- **Web**: [`@pixiv/three-vrm`](https://github.com/pixiv/three-vrm) (MIT).
- **UE5**: [VRM4U](https://github.com/ruyo/VRM4U) (MIT, UE 5.0–5.7).
- **Why it matters**: VRM is the *one* asset class where the same file produces visually-identical results in Three.js and UE5 because the spec pins coords, units, skeleton, and material model. **Steal this pattern for your scene format.** See [§7](07-meta-scene-tool-design.md).
- Use VRM for any humanoid avatar without thinking about it.

## 1.4 Alembic, OpenVDB / NanoVDB

- **Alembic** (`.abc`): UE5 has a mature Alembic importer for baked geometry caches; web is sparse — no maintained Three.js loader, you'd transcode to a custom binary or to USDZ.
- **OpenVDB / NanoVDB**: UE5 supports VDB via Heterogeneous Volumes (5.3+); web has [openvdb.js](https://github.com/openvdb/openvdb-wasm) and [`@vrcmteam/vdb-loader-three`](https://www.npmjs.com/package/@vrcmteam/vdb-loader-three) but performance is hostile. Use VDB only for volumetric clouds/smoke baked once at build, then convert to point-cloud or splat for the web tier.
- **Status**: Experimental for hybrid; production for native-only.

## 1.5 PMX/PMD, .vox (MagicaVoxel), VRMA, PLY/STL/OFF/3MF

- **PMX/PMD** (MMD): Niche but well-supported in Three.js via [MMDLoader](https://threejs.org/docs/?q=mmd) and via [UE4PMXImporter](https://github.com/bm9bm9/UE4PmxImporter)-style community plugins. Mention only if your art comes from anime/avatar communities.
- **.vox**: [MagicaVoxel](https://ephtracy.github.io/) format is trivial to parse; readers exist for both. Use if your aesthetic is voxel.
- **PLY**: The substrate for Gaussian splats (see [§4.4](04-fake-rendering-tricks.md#44-gaussian-splatting--the-most-important-trick-in-this-report)). Both runtimes parse it natively.

## 1.6 Custom binary formats — what real studios do

CD Projekt's REDengine, id Tech, Frostbite, Decima all roll their own. For indie use, the realistic recipe is:

- **Meshes**: glTF binary buffers wrapped in your own header (positions/normals/UVs + Draco or Meshopt compression).
- **Textures**: KTX2 + BasisU universal supercompression — works in WebGL2/WebGPU and via [UE5 KTX2 plugin](https://dev.epicgames.com/marketplace/en-US/product/ktx-2-image-encode-decode-2-utilities). Both engines consume the same bytes.
- **Sentinel**: A tiny JSON sidecar with version, axis, units, and asset registry.

Repos to study for compression: [zeux/meshoptimizer v1.1 (April 2026)](https://github.com/zeux/meshoptimizer/releases/tag/v1.1) — CPU decoders at 7–10 GB/s, GPU at 150+ GB/s, plus [JS bindings PR #738](https://github.com/zeux/meshoptimizer/pull/738) and [hierarchical clustered simplification PR #760](https://github.com/zeux/meshoptimizer/pull/760).

## 1.7 Houdini Engine / HDAs as portable procedural definitions

- **UE5**: [Houdini Engine for UE](https://www.sidefx.com/products/houdini-engine/) is mature, replays `.hda` files at runtime via SideFX's licensed Engine library.
- **Web**: [Houdini Engine for the Web](https://www.sidefx.com/docs/houdini/web/engine.html) exists as a SideFX-hosted service ("Houdini Engine in the Cloud"). Free tier is limited; commercial deals at scale. **Not deterministic** between web replay and UE replay (different builds) but close.
- **Status**: Production for AAA studios; tractable for indie if you stay within free-tier quotas.

## 1.8 Lottie / dotLottie — not 3D but worth the pattern

- [dotLottie v2.0 spec](https://dotlottie.io/spec/2.0/) ships state machines, theming, and a runtime that's identical on web/iOS/Android/Flutter/RN/UE5 ([rive-app/rive-unreal](https://github.com/rive-app/rive-unreal) covers Rive, the modern dotLottie alternative). Use for HUD/UI vector motion — see [§7](07-meta-scene-tool-design.md).

## 1.9 Best bets in this domain

1. **USD/USDZ** as the *scene structure* format.
2. **Gaussian Splats** as the *photoreal geometry* format (see [§4](04-fake-rendering-tricks.md)).
3. **VRM 1.0** as the *avatar* format.
4. **glTF binary buffers** (yes, technically inside our DSL) as the *under-the-hood mesh storage* — you said no glTF the format, but its `.bin` layout is the universal sub-component everyone copies anyway.

---

**Up next:** [02 — Procedural & SDF approaches](02-procedural-and-sdf.md). **Back to:** [README](README.md).
