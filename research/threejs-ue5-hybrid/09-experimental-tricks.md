---
title: "Experimental / Research-Grade Tricks (Know About, Don't Ship)"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§9"
---

# 9. Experimental / Research-Grade Tricks (Know About, Don't Ship)

> _The grab-bag of techniques that are technically real but economically or operationally absurd for indie use in 2026. Keep them on your radar — most of them will be tractable within 12–24 months._

Related reading: [04-fake-rendering-tricks.md §4.10](04-fake-rendering-tricks.md#410-latent-video-diffusion-world-models--the-speculative-wildcard) for the latent-diffusion deep-dive; [06-streaming-protocols.md §6.4](06-streaming-protocols.md#64-media-over-quic-moq) for MoQ; [05-ue5-physics-only-architecture.md §5.2](05-ue5-physics-only-architecture.md#52-chaos-physics-on-the-dedicated-server) for why a Chaos WASM is the dream.

---

| Trick | Why it's interesting | Why not in 2026 |
|---|---|---|
| **Latent-diffusion world models** (Matrix-Game 3.0, LTX-Video, GameNGen, HY-WorldPlay, AlayaRenderer) | Could "re-render" a UE5 G-buffer in any art style in real time | ~1 H100 per player; absurd indie economics |
| **NeRFs in UE5** (Volinga's old NeRF mode, instant-NGP UE ports) | Photoreal scene capture | Displaced by Gaussian Splatting in 2025 |
| **Vulkan/D3D12 zero-copy texture share from sandboxed Chromium** | The dream: Three.js → UE5 with zero serialization | Requires custom Chromium build; sandbox forbids it stock |
| **MoQ (Media over QUIC) for game state pub/sub** | Native game-server fan-out via priorities | IETF WG draft May 2026; tooling not ready |
| **Iris-over-WebTransport** | Would let browsers be first-class UE NetConnections | No Epic spec, no public plan |
| **Houdini Engine in the Cloud** for deterministic procedural geometry | Same `.hda` runs in both engines | SideFX-hosted; commercial pricing kills indie use |
| **MV-HEVC encode in WebCodecs** | Stereo/depth peel from Three.js → UE5 in one stream | Chrome has decode only; encode 12–18 months out |
| **WebSockets over HTTP/3 (RFC 9220)** | The "WebSocket but multiplexed" upgrade | Browsers chose WebTransport instead; adoption thin |
| **Chaos Physics WASM** | Bit-identical browser physics matching the UE5 server | Doesn't exist; Epic has never indicated it will |
| **Native PhysX 5 WASM from NVIDIA** | Same as above but PhysX | Only community ports; no NVIDIA build |
| **Cross-process Vulkan external memory with sandboxed Chromium** | Pure performance | Requires custom browser fork |
| **Tencent HY-WorldPlay-style streaming video models** | "Stream the game as a generative video" | Centralized GPU cost prohibitive |

---

**Up next:** [10 — Build vs buy](10-build-vs-buy.md). **Back to:** [README](README.md).
