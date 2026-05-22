---
title: "Executive Summary — The 5 Architectures You Should Actually Consider"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "Executive Summary"
---

# Executive Summary — The 5 Architectures You Should Actually Consider

Ranked by **feasibility-for-an-indie × visual-fidelity** as of May 2026. Each is technically achievable today; cost and risk vary wildly.

| # | Architecture | Fidelity ceiling | Indie risk | Status |
|---|---|---|---|---|
| **1** | **Gaussian Splat shared assets + Rust/UE5 server-state stream** | High (photoreal where authored) | Low–medium | Production for static splats; emerging for 4DGS |
| **2** | **UE5 Pixel Streaming 2 with Three.js as HTML/WebGL overlay** | Maxes out at UE5's native ceiling | Medium ($$ per stream-hour) | Production — what Epic actually ships |
| **3** | **USD as source-of-truth + dual-runtime DSL ("scene.v1") + UE5 server / WebTransport** | Stylized AAA achievable | Medium–high (build the tool) | Mostly production parts; the DSL is custom |
| **4** | **Drop UE5: Rust + Rapier-deterministic + SpacetimeDB-style backend, Three.js client only** | Stylized AAA achievable | Low–medium | Production parts; the architecture is now mainstream in 2026 |
| **5** | **Local Spout / SpoutBrowser zero-copy bridge** (for local kiosks, asymmetric VR, devkits) | Highest of any local hybrid | Low for one machine; doesn't help shipped multiplayer | Production for installations, not for retail |

The three "ignore for now but flag-it" categories: latent video diffusion world models (`Matrix-Game 3.0`, `LTX-Video`, `AlayaRenderer` — too expensive in 2026), MoQ (Media over QUIC — RFC not done), and NeRFs (officially displaced by Gaussians).

The single most important framing shift: **the question isn't "how do I export from Three.js to UE5" — it's "which artifacts are cheap to author once and consume in both runtimes?"** Geometry-as-Gaussians, materials-as-PBR+WGSL, animation-as-Rive, avatars-as-VRM, behavior-as-FSM-JSON. None of those are FBX or GLTF and all of them have first-class libraries on both sides.

---

## How the five rank — in context

1. **Gaussian splat shared assets** is the lowest-risk path to *photoreal* in both engines simultaneously. Authoring tools mature, both Three.js (Spark) and UE5 (Luma/Volinga/DazaiStudio) consume the same `.ply`/`.spz` bytes. The risk profile is "your art direction can/can't accept splats." See [§4.4](04-fake-rendering-tricks.md#44-gaussian-splatting--the-most-important-trick-in-this-report).
2. **Pixel Streaming 2 + Three.js overlay** is what Epic ships today. You pay GPU-hour cost per concurrent player (~1 user per 2 vCPUs on G4dn/NVadsA10; L40S does 4–6 1080p60 streams). Three.js layered over the video stream handles HUD/UI cheaply at 60 fps and offloads UI complexity from the GPU pool. See [§4.1](04-fake-rendering-tricks.md#41-ue5-pixel-streaming-2-the-most-fake-but-most-polished).
3. **`scene.v1` DSL + UE5 server + WebTransport gateway** is the path that gives you AAA-grade stylized fidelity with a single source of truth. It requires building the DSL/exporter pieces yourself — roughly 3–4 months of one engineer's work (see [§10](10-build-vs-buy.md)). The full design is in [§7](07-meta-scene-tool-design.md).
4. **Drop UE5 entirely** with Rust + `bevy_rapier` + a SpacetimeDB-style logic-in-DB backend, Three.js client. In 2026 this is mainstream — production parts everywhere, [TickForge](https://github.com/invertedmushroom/TickForge) is a reference deterministic Rapier3D action MMO server on SpacetimeDB. The trade-off: no Niagara/Chaos vehicles, no MetaHuman. See [§5.8](05-ue5-physics-only-architecture.md#58-server-authoritative-architectures) and [§6.7](06-streaming-protocols.md#67-state-sync-libraries).
5. **Spout / SpoutBrowser** is the sleeper choice for asymmetric local hardware setups — a forked Chromium publishes its WebGL/WebGPU framebuffer to UE5 via D3D12 shared handles at sub-frame latency, no encoder. Doesn't help shipped multiplayer. See [§4.7](04-fake-rendering-tricks.md#47-spout--ndi--syphon--local-zero-copy-bridges).

---

## 2026 currency notes that change the answer

The picture would look different even one quarter earlier. These are the changes that matter:

- **WebTransport reached Baseline (Newly Available) in March 2026** ([caniuse](https://caniuse.com/webtransport)) once Safari 26.4 shipped support — it is included in Interop 2026. Stop planning around WebSocket-only.
- **`glslang`'s HLSL frontend was deprecated in 16.3.0** ([issue #4210](https://github.com/KhronosGroup/glslang/issues/4210)). DXC and Slang own HLSL.
- **Hathora shut down May 5, 2026** — see [Gameye game-server shake-up post](https://gameye.com/blog/game-server-shake-up-2026/). [GameFabric (Nitrado)](https://gamefabric.com/hathora/) and [Gameye](https://gameye.com/) are the migration targets.
- **NeRF→Gaussian-splat displacement** ([Volinga official 3DGS migration](https://help.disguise.one/workflows/3dgs/volinga-3dgs)). UE4-NeRF never matured.
- **Lance.gg, Cannon-es** — stale/abandoned. See [§6.7](06-streaming-protocols.md#67-state-sync-libraries).

---

## Custom-build budget at a glance

Building the bespoke pieces on top of the off-the-shelf stack is approximately **3–4 months of one engineer's focused work**. The largest line items:

- **`UExporterSubsystem`** (UE5 → bit-packed delta over UDP): ~2 weeks
- **Rust WebTransport gateway** (UDP ↔ WT sessions): ~2 weeks
- **R3F `morphScene` reconciler + Zustand store**: ~2 weeks
- **UE5 editor hot-reload plugin** (forked from [UnrealCortex](https://github.com/etelyatn/UnrealCortex) / [UnrealDataBridgeMCP](https://github.com/etelyatn/UnrealDataBridgeMCP)): ~3 weeks
- **Spline JSON → UE5 USDZ converter** (if Spline animations are needed): ~3 weeks

The full effort table is in [10-build-vs-buy.md](10-build-vs-buy.md).

---

## Where to read next

- **The recommended pipeline (block diagram + tech table + 90-day plan):** [08-recommended-architecture.md](08-recommended-architecture.md).
- **Gaussian splats deep-dive (the single most important format in this report):** [04-fake-rendering-tricks.md §4.4](04-fake-rendering-tricks.md#44-gaussian-splatting--the-most-important-trick-in-this-report).
- **The `scene.v1` DSL JSON sketch:** [07-meta-scene-tool-design.md §7.2](07-meta-scene-tool-design.md).
- **Why anti-cheat in the browser is unsolvable, and what to do instead:** [05-ue5-physics-only-architecture.md §5.5](05-ue5-physics-only-architecture.md).
