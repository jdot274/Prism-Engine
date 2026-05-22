---
title: "The Build Once, Render in Both Tool — A Concrete Design"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§7"
---

# 7. The "Build Once, Render in Both" Tool — A Concrete Design

> _This is the design problem the user asked to solve. Below is a workable specification — the `scene.v1` DSL, its authoring stack, hot-reload story, and build pipeline._

Related reading: [01-scene-interchange-formats.md](01-scene-interchange-formats.md) for the format primitives this DSL composes; [02-procedural-and-sdf.md](02-procedural-and-sdf.md) for the parametric / procedural definitions referenced from `scene.v1`; [08-recommended-architecture.md](08-recommended-architecture.md) for how this tool integrates with the runtime stack.

---

## 7.1 Existing precedents

| Format | Why it's a model |
|---|---|
| **USD / OpenUSD** | Layering + composition arcs survive 30-year pipelines |
| **VRM** | Spec pins coords, units, skeleton → same file renders identically in Three.js + UE5 + Unity. Copy this discipline. |
| **R3F scene graph** | Declarative React tree as source of truth; custom reconciler can target UE actors (see [`@theatre/r3f`](https://www.theatrejs.com/), [`@json-render/react-three-fiber`](https://registry.npmjs.org/@json-render/react-three-fiber) April 2026, [`react-three-start`](https://github.com/pmndrs/react-three-start) May 2026) |
| **dotLottie v2.0** | One JSON, runtimes everywhere — the *principle* applies even though the data model is 2D |
| **Decentraland CRDT stream** | Most-shipped real-world "one DSL, two renderers" |

## 7.2 The `scene.v1` DSL — concrete sketch

```json
{
  "schema": "scene.v1",
  "axis": { "up": "Z", "forward": "Y", "units": "m" },
  "buffers": [
    { "id": "buf0", "uri": "scene.bin", "byteLength": 1048576 }
  ],
  "materials": [
    {
      "id": "mat.brick",
      "model": "pbrMetallicRoughness",
      "baseColor": [0.8, 0.3, 0.2, 1.0],
      "metallic": 0.0, "roughness": 0.7,
      "baseColorTexture": { "uri": "tex/brick_basecolor.ktx2" },
      "normalTexture":    { "uri": "tex/brick_normal.ktx2" },
      "extensions": {
        "KHR_materials_clearcoat": { "clearcoatFactor": 0.1 },
        "x_unreal_master":  "M_Brick_Master",
        "x_three_overrides": { "envMapIntensity": 1.2 }
      }
    }
  ],
  "meshes": [
    { "id": "mesh.cube",
      "primitives": [{
        "bufferView": "buf0/0/24576",
        "indices":    "buf0/24576/4096",
        "material":   "mat.brick",
        "attributes": { "POSITION": "vec3", "NORMAL": "vec3", "TEXCOORD_0": "vec2" }
      }]
    }
  ],
  "nodes": [
    { "id": "tower",        "type": "transform", "transform": {...}, "children": [...] },
    { "id": "tower.body",   "type": "mesh", "mesh": "mesh.cube", "physics": "phys.tower",
                            "tags": ["destructible", "interactable"] },
    { "id": "tower.light",  "type": "light",
                            "props": { "kind": "point", "intensityLumens": 800, "colorK": 3200,
                                       "castShadows": true, "x_unreal_mobility": "Movable" } },
    { "id": "tower.spawn",  "type": "spawner",
                            "props": { "prototype": "@enemies/grunt", "interval": 5.0,
                                       "max": 6, "radius": 4.0 } },
    { "id": "tower.trigger","type": "trigger",
                            "props": { "shape": "phys.triggerSphere",
                                       "emits": "onPlayerEnter:tower.alarm" } }
  ],
  "physics": [
    { "id": "phys.tower", "shape": "box", "extents": [1,1,2], "mass": 0, "channel": "world" },
    { "id": "phys.triggerSphere", "shape": "sphere", "radius": 3, "mass": null, "channel": "trigger" }
  ],
  "behaviors": [
    { "id": "tower.alarm",
      "kind": "fsm",
      "initial": "idle",
      "states": {
        "idle":  { "on":    { "onPlayerEnter": "alert" } },
        "alert": { "enter": ["@actions/spawnerBurst:tower.spawn:3"],
                   "after": { "10s": "idle" } }
      }
    }
  ],
  "anim": [
    { "id": "tower.flicker", "target": "tower.light",
      "property": "props.intensityLumens",
      "track": [{ "t":0,"v":800 }, { "t":0.1,"v":300 }, { "t":0.2,"v":800 }],
      "loop": true }
  ]
}
```

Key design choices:

- **Physical units (lumens, Kelvin)** so both renderers convert identically.
- **Materials = PBR baseline + KHR_* extensions** (glTF extensions are universal even though the *container* is excluded). Engine-specific bits go under `x_unreal_*` / `x_three_*`, ignored cross-engine.
- **Behaviors are FSMs invoking named actions** (`@actions/<name>:<args>`) that each runtime resolves to its native scripting (TS on web, GAS/Blueprint on UE5). **Avoid embedding Lua snippets** — you'd ship two VMs and synchronize their globals.
- **Physics shapes referenced by id** — Bullet/PhysX/Jolt primitive names — channel routes to UE collision profiles or Rapier groups.
- **Asset registry** (`mappings.json`) resolves `@enemies/grunt` to its native asset path in each runtime, generated at build.

## 7.3 Authoring stack

- **Figma plugin → 2D UI layout** ([F2R3](https://github.com/patrickkeenan/f2r3), [FigmaThird](https://github.com/ahkohd/FigmaThird), [3d.to.design](https://divriots.com/blog/introducing-3d-to-design)) → `figma.json` → consumed by [react-three-uikit](https://github.com/pmndrs/uikit) on web + UE5 CommonUI. **Don't try to model 3D in Figma.**
- **Spline → hero set-pieces only** → export `code` (web) + USDZ (UE5). Re-author animations in the DSL.
- **Unicorn Studio → web-only background/material layers** (the JSON is web-only since [scene-level publishing landed in their 2026 changelog](https://www.unicorn.studio/docs/changelog/)).
- **Custom R3F-flavoured `.scene.tsx`** files as the engineer-facing source-of-truth. SWC transform lowers JSX → `scene.v1` JSON at build.
- **VS Code preview pane**: empty R3F shell that hot-swaps scenes via Vite HMR.
- **PolyHaven** ([CC0 + strict tech standards](https://docs.polyhaven.com/en/technical-standards/textures) + [REST API](https://polyhaven.com/our-api)) for PBR materials.
- **VRM via `@pixiv/three-vrm`** + **[VRM4U](https://github.com/ruyo/VRM4U)** for characters.

## 7.4 Hot reload across both engines

- **Web**: `chokidar` → push JSON to a Zustand store → R3F components subscribe via selectors and `morphScene(prev, next)` diffs the tree (only re-create nodes with new `id` or changed `type`; mutate transforms/props on the rest).
- **UE5**: C++ editor module + Python utility opens WebSocket on `localhost:9011`; parses JSON into a `UDataAsset`; broadcasts `OnSceneReloaded`. Existing prior art with compatible internals: [UnrealCortex](https://github.com/etelyatn/UnrealCortex) and [UnrealDataBridgeMCP](https://github.com/etelyatn/UnrealDataBridgeMCP) (both 2026) — they wrap mutations in `FScopedTransaction` so undo works.
- **Shipped game**: cooked `UDataAsset` (UE5) and CDN-static `scene.json` + `scene.bin` (web). Patching is a CDN cache bust on web; a `.pak` push + `LoadPackageAsync` on UE5.

## 7.5 Animation pipeline

- **3D skeletal/rigid**: Embed glTF-style joint-matrix-over-time buffers under the hood (the binary format, not the container).
- **Property tracks**: Inline keyframes in the DSL (as `tower.flicker` above).
- **2D UI motion**: **[Rive](https://rive.app/runtimes)** — [Rive's Unreal runtime v0.4.22 (Feb 2026)](https://github.com/rive-app/rive-unreal) supports UE 5.7+; same `.riv` file plays in [rive-wasm](https://github.com/rive-app/rive-wasm) on the web. **The only cross-runtime animation format with full state-machine parity in 2026.**
- **Lottie / dotLottie**: marketing surfaces, onboarding (no UE5 native runtime).

## 7.6 Build pipeline

```
authoring/
  scenes/*.scene.tsx          ← R3F-flavoured DSL (source of truth)
  ui/*.figma.json             ← exported Figma frames
  hero/*.spline               ← Spline hero scenes
  bg/*.unicorn.json           ← Unicorn Studio shader layers (web-only)

tools/
  compile-dsl                 ← SWC transform: .scene.tsx → scene.v1 JSON + scene.bin
  pack-assets                 ← KTX2 textures, Draco/Meshopt meshes
  emit-mappings               ← writes web ⇄ UE asset path map
  emit-three                  ← optional codegen: scene.v1 → tree-shaken R3F .tsx
  emit-uasset                 ← Python in UE5: scene.v1 → cooked UDataAsset
                                (preferred default: runtime-load the JSON;
                                 codegen only for ship-critical scenes)

runtime-web/ — R3F reads scene.v1 via @json-render-style reconciler
runtime-ue5/ — C++ plugin reads cooked UDataAsset or live JSON in dev
```

**Prefer runtime-loaded data assets** over codegen — preserves hot reload on a shipped game, avoids rebuilds for content patches, matches how Decentraland, Roblox, Fortnite Creative all work in production.

---

**Up next:** [08 — Recommended architecture (block diagram + tech table + 90-day plan)](08-recommended-architecture.md). **Back to:** [README](README.md).
