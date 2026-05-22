---
title: "Three.js ↔ UE5 Unconventional Interop — A 2026 Field Guide"
category: research
status: research
date: 2026-05-22
source: subagent research run (4 parallel specialist sub-workers + synthesis)
---

# Three.js ↔ UE5 Unconventional Interop — A 2026 Field Guide

*No FBX. No GLTF. Yes weird ideas.*

This folder is the full research drop on hybrid Three.js (web) ↔ Unreal Engine 5 architectures for the **Prism Engine** hybrid/web-native blueprint (see the repo [README](../../README.md)). It was produced by a 4-way parallel research sub-agent run on **2026-05-22** and is preserved here verbatim as the design substrate for the Fork A / Fork B decisions described in the top-level README.

> **Headline:** The question is not "how do I export from Three.js to UE5." The question is *"which artifacts are cheap to author once and consume in both runtimes?"* — geometry-as-Gaussians, materials-as-PBR+WGSL, animation-as-Rive, avatars-as-VRM, behavior-as-FSM-JSON. None of those are FBX or GLTF, and all of them have first-class libraries on both sides.

---

## Recommended architecture at a glance

For the engine's specific constraints (Figma + Spline + Unicorn-Studio authoring, AAA visual ambition, real-time multiplayer, no FBX/GLTF), the recommended pipeline is:

- **Photoreal geometry:** Gaussian splats (`.ply` / `.spz`) — rendered by [Spark](https://github.com/sparkjsdev/spark) on the web and [Luma](https://radiancefields.com/luma-gaussian-splatting-unreal-engine-plugin-unveiled) / [Volinga](https://web.volinga.ai/volinga-plugin-pro/) / [DazaiStudio SplatRenderer](https://github.com/DazaiStudio/SplatRenderer-UEPlugin) in UE5. **Same bytes, both engines.**
- **Authoritative simulation:** A forked Lyra UE5 dedicated server (Linux Shipping, `-nullrhi`) running Chaos + Iris + GAS + EOS.
- **Transport:** WebTransport over HTTP/3 primary, WebSocket fallback. Browser-side prediction runs `@dimforge/rapier3d-deterministic` WASM.
- **Bridge:** A Rust edge gateway ([wtransport](https://github.com/BiagioFesta/wtransport) + [tungstenite](https://github.com/snapview/tokio-tungstenite)) translates between WebTransport sessions and UE5 `NetConnection`s.
- **Build-once / render-in-both:** A `scene.v1` JSON DSL compiled from `.scene.tsx` (R3F flavoured) via SWC, with materials as PBR + KHR_* extensions, behaviors as FSMs, and asset references resolved through `mappings.json`.
- **Total custom-build budget:** roughly **3–4 months of one engineer** for the bespoke pieces (`UExporterSubsystem`, the gateway, the DSL, the SWC transform, the UE5 hot-reload plugin).

The full block diagram is in [`diagrams/recommended-architecture.txt`](diagrams/recommended-architecture.txt). The per-layer technology table and the first-90-day plan are in [`08-recommended-architecture.md`](08-recommended-architecture.md).

---

## Table of contents

1. [Executive summary](00-executive-summary.md) — the five architectures ranked by feasibility × fidelity.
2. [Scene-description interchange formats](01-scene-interchange-formats.md) — USD, VRM, custom binary, Houdini HDAs (§1 of the report).
3. [Procedural / parametric / SDF approaches](02-procedural-and-sdf.md) — Manifold, Geometry Script, marching cubes, deterministic noise, WFC (§2).
4. [Shader-level interop](03-shader-interop.md) — HLSL ↔ GLSL ↔ WGSL ↔ SPIR-V, the glslang deprecation, Three.js Node Material vs UE5 Material graph (§3).
5. [Fake-rendering / display-layer tricks](04-fake-rendering-tricks.md) — Pixel Streaming 2, RGBD, **Gaussian splatting deep-dive**, NeRF deprecation, octahedral impostors, Spout/NDI/Syphon, latent video diffusion (§4).
6. [UE5 for physics/networking only](05-ue5-physics-only-architecture.md) — headless UE Chaos, Rapier/Jolt/PhysX WASM determinism, rollback ownership, Iris extraction, EOS Anti-Cheat reality, Lyra as a fork base (§5).
7. [Streaming protocols & plumbing](06-streaming-protocols.md) — WebTransport vs WebSocket vs WebRTC, WebCodecs, MoQ, Nanite-style geometry streaming, state-sync libraries (§6).
8. [Meta-scene tool design](07-meta-scene-tool-design.md) — the `scene.v1` DSL JSON sketch, authoring stack, hot-reload across engines, build pipeline (§7).
9. [Recommended architecture for THIS project](08-recommended-architecture.md) — the big block diagram, per-layer tech table, first-90-day plan (§8).
10. [Experimental / research-grade tricks](09-experimental-tricks.md) — latent diffusion world models, MoQ, Vulkan zero-copy, Iris-over-WebTransport (§9).
11. [Custom-build vs off-the-shelf checklist](10-build-vs-buy.md) — effort estimates per bespoke component (§10).
12. [Prior art & shipped projects](prior-art-and-shipped-projects.md) — Krunker, Diep, Surviv, Venge, Decentraland, CipSoft MMO tech demo, and where UE5 ↔ browser hybrids exist publicly (gathered from §5.10 + scattered references).
13. [Closing notes](closing-notes.md) — opinions worth surfacing, currency calls, and "hygiene tax" list.

---

## 2026 currency calls — read before planning

These invalidate large amounts of older guidance found via web search. The numbering is the report's:

- **Hathora shut down May 5, 2026.** Migrate to [GameFabric](https://gamefabric.com/hathora/) or [Gameye](https://gameye.com/) for orchestration. (§4.1, §6.7)
- **WebTransport became Baseline March 2026** (Chrome 97+, Edge 98+, Firefox 114+, **Safari 26.4+** — included in Interop 2026 per [caniuse](https://caniuse.com/webtransport)). It is the right default for new projects; WebSocket is the fallback now. (§6.1)
- **`glslang`'s HLSL frontend was deprecated in 16.3.0** ([issue #4210](https://github.com/KhronosGroup/glslang/issues/4210), April 2026). Microsoft DXC and Slang own HLSL going forward. (§3)
- **NeRFs are displaced by Gaussian splatting.** Volinga deprecated their NeRF workflow in 2025; UE4-NeRF never matured. Use Gaussians. (§4.5)
- **Lance.gg is abandoned. Cannon-es is stale.** See §6.7 for 2026 alternatives.
- **No `Chaos` WASM build exists** and Epic has never indicated one is coming. Browser-side prediction must use a separate engine (Rapier recommended). (§5.2)

---

## Provenance & how this folder was assembled

This drop was produced on **2026-05-22** by filing a long-form synthesis report (≈66 KB of markdown) from the parent agent's transcript into well-organized topic files. The synthesis was itself the output of four parallel specialist sub-workers covering, respectively: scene formats + procedurals, shaders + display tricks, physics + streaming, and shipped projects + meta-format tooling.

- **Source of truth:** the synthesis report (verbatim) lives split across the topic files. URLs, library versions, the ASCII diagram, and currency notes are preserved exactly.
- **Section numbering** in this folder mirrors the report's §1–§10 plus the executive summary, prior art (gathered from §5.10), closing notes, and the recommended-architecture ASCII diagram.
- **Engine-specific bits** in the report (`x_unreal_*` / `x_three_*` extensions, Lyra hot-reload, etc.) line up directly with the **Fork A** and **Fork B** decision in the repo's top-level [README](../../README.md).

If a topic file feels thin against the executive summary, it is faithful to what the synthesis report contained — not a paraphrase. Sections that need expansion in future research passes are explicitly flagged inside each file.

---

## How to use this folder

- If you're deciding between **Fork A (UE5 + web hybrid)** and **Fork B (Rust + Rapier + SpacetimeDB)**: read [00-executive-summary.md](00-executive-summary.md), then [05-ue5-physics-only-architecture.md](05-ue5-physics-only-architecture.md), then [08-recommended-architecture.md](08-recommended-architecture.md).
- If you're designing the asset pipeline: read [04-fake-rendering-tricks.md](04-fake-rendering-tricks.md) (§4.4 Gaussian splats) and [01-scene-interchange-formats.md](01-scene-interchange-formats.md).
- If you're designing the runtime: read [06-streaming-protocols.md](06-streaming-protocols.md) and [07-meta-scene-tool-design.md](07-meta-scene-tool-design.md).
- If you're scoping engineering work: read [10-build-vs-buy.md](10-build-vs-buy.md).
- If you're explaining the project to a new collaborator: hand them [README.md](README.md) (this file) and [closing-notes.md](closing-notes.md).
