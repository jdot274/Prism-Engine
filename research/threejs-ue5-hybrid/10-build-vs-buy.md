---
title: "Custom-Build vs Off-the-Shelf Checklist"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§10"
---

# 10. Custom-Build vs Off-the-Shelf Checklist

> _Total custom-build budget: **~3–4 months of one engineer's focused work.** Everything else slots in from the open-source ecosystem._

Related reading: [08-recommended-architecture.md](08-recommended-architecture.md) for how the off-the-shelf pieces are wired together; [07-meta-scene-tool-design.md](07-meta-scene-tool-design.md) for the bespoke `scene.v1` tooling.

---

## 10.1 Off-the-shelf (use directly)

- WebTransport (Chromium + Safari 26.4); WebSocket fallback
- UE5 Dedicated Server + Lyra fork + Iris (Beta)
- Chaos Physics (server only)
- EOS Web API + EOS Anti-Cheat (server side)
- Rapier WASM (`@dimforge/rapier3d-deterministic`)
- Manifold (WASM + native C++)
- react-three-fiber v10 + drei v11 + react-three-uikit
- Spark (Gaussian splats web)
- Luma AI / Volinga / DazaiStudio SplatRenderer (Gaussian splats UE5)
- VRM via `@pixiv/three-vrm` + VRM4U
- Rive (web + UE5)
- meshoptimizer v1.1 (Meshopt + Draco + clusterizer)
- KTX2 + BasisU textures
- USD (OpenUSD WASM + Three.js USDLoader + UE5 Interchange OpenUSD)
- Pixel Streaming 2 + Selkies (FOSS alternative)
- Spout + SpoutBrowser + UE5_Spout2_DX12 (local zero-copy)
- NDI Unreal SDK v3.8 (network video)
- Nakama or SpacetimeDB (backend)
- Agones + Gameye/GameFabric (orchestration; **NOT Hathora**)
- LiveKit (voice)
- Cloudflare R2 + Workers (CDN + edge)
- Tint / Naga / SPIRV-Cross / DXC / Slang (shader translation)
- Spline → USDZ; PolyHaven assets; Unicorn Studio JSON

## 10.2 Custom-build (and how much work)

| Component | Effort estimate |
|---|---|
| **`UExporterSubsystem`** — UE5 → bit-packed delta over UDP | ~2 weeks |
| **Rust WebTransport gateway** bridging UDP ↔ WT sessions | ~2 weeks |
| **`scene.v1` DSL spec + JSON schema** | ~1 week + iteration |
| **SWC transform `.scene.tsx` → `scene.v1`** | ~1 week |
| **R3F `morphScene(prev, next)` reconciler + Zustand store** | ~2 weeks |
| **UE5 editor plugin** — Cortex-style WebSocket ↔ `UDataAsset` + `FScopedTransaction` | ~3 weeks (fork UnrealCortex/UnrealDataBridgeMCP) |
| **`mappings.json` registry** + Python emit-uasset | ~1 week |
| **Spline JSON → UE5 USDZ converter** (if you want Spline animations/events) | ~3 weeks |
| **WGSL leaf-shader library** + Tint pipeline → UE5 Custom HLSL nodes | ~1 week + ongoing |
| **PCG-noise + polynomial-transcendental shared math library** | ~1 week |
| **Manifold + Geometry Script parametric library** (shared shape grammars) | ~2 weeks per shape family |
| **Anti-cheat heuristics + obfuscation pipeline** | Ongoing |
| **Hot-reload protocol + dev orchestration** | ~1 week (chokidar + WS) |

**Total custom-build budget**: ~3–4 months of one engineer's focused work. Everything else slots in from the open-source ecosystem.

---

**Up next:** [Prior art & shipped projects](prior-art-and-shipped-projects.md) | [Closing notes](closing-notes.md). **Back to:** [README](README.md).
