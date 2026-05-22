---
title: "Recommended Architecture for THIS User (Block Diagram + Tech Table + 90-Day Plan)"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§8"
---

# 8. Recommended Architecture for THIS User

> _Given the constraints (Figma + Spline + Unicorn assets, AAA ambition, real-time multiplayer, no FBX/GLTF), this is the concrete pipeline I'd build._

The block diagram below is also preserved as a standalone file at [`diagrams/recommended-architecture.txt`](diagrams/recommended-architecture.txt) for easy embedding in slide decks / FigJam boards.

Related reading: every other file in this folder feeds into this one. The shortest path: [00-executive-summary.md](00-executive-summary.md) → here → [10-build-vs-buy.md](10-build-vs-buy.md).

---

## 8.0 The pipeline (block diagram)

```
                      ┌─────────────────────────────────────────┐
                      │             AUTHORING LAYER             │
                      │  Figma   Spline   Unicorn   PolyHaven   │
                      │  (UI)    (hero)   (bg fx)   (PBR)       │
                      │            VRM avatars (Pixiv → VRM4U)  │
                      │            Gaussian Splats (.ply/.spz)  │
                      │            Rive (HUD/UI motion)         │
                      └────────────────────┬────────────────────┘
                                           │
                              .scene.tsx, .figma.json, *.spline, *.riv, *.ply
                                           │
                                           ▼
                  ┌────────────────────────────────────────────┐
                  │             COMPILER  /  PACKER            │
                  │  SWC → scene.v1 JSON + scene.bin           │
                  │  KTX2 / Draco / Meshopt v1.1 / .spz        │
                  │  mappings.json  (web ⇄ UE asset paths)     │
                  └──────────────┬─────────────────┬───────────┘
                                 │                 │
                          scene.v1 (CDN)     scene.v1 (cooked UDataAsset)
                                 │                 │
              ┌──────────────────▼──┐         ┌────▼──────────────────┐
              │     WEB CLIENT      │         │  UE5 DEDICATED SERVER │
              │  Vite + R3F v10     │         │  (Linux, -nullrhi)    │
              │  drei v11 / webgpu  │         │  Forked Lyra:         │
              │  three-uikit (UI)   │         │  Experiences + GAS +  │
              │  Spark (Gaussians)  │         │  EOS + Iris + Chaos   │
              │  Rapier-determin.   │         │                       │
              │   (client predict)  │         │  UExporterSubsystem:  │
              │  Rive (HUD)         │         │  walks Iris quantized │
              │  Manifold-WASM      │         │  state → bit-packed   │
              │   (parametric geo)  │         │  delta → gateway      │
              └─────────┬───────────┘         └───────────┬───────────┘
                        │                                 │
                        │       WebTransport (QUIC)       │
                        │       binary deltas @ 30Hz      │
                        └────────────────┬────────────────┘
                                         ▼
                  ┌────────────────────────────────────────────┐
                  │      RUST EDGE GATEWAY (per region)        │
                  │  wtransport / quinn + tungstenite (WS fb)  │
                  │  Maps WT sessions <-> UE5 NetConnections   │
                  │  Auth via EOS Web API + your JWT           │
                  │  Lag-comp ring buffer, rate limits         │
                  └─────┬─────────────────────┬────────────────┘
                        │                     │
                        │ Local UDP/loopback  │
                        │                     │
                        ▼                     ▼
              ┌────────────────────┐  ┌──────────────────────────┐
              │ Backend services   │  │   Optional companion     │
              │ Nakama / Go / Node │  │  PIXEL STREAMING 2 edge  │
              │ Match orch (Agones)│  │  AV1 on RTX 40/L40S      │
              │ Postgres + Redis   │  │  for trailers, AAA-tier  │
              │ CF R2 CDN (assets) │  │  showcase zones,         │
              │ LiveKit SFU (voice)│  │  asymmetric VR pairing   │
              │ ClickHouse (telem) │  └──────────────────────────┘
              └────────────────────┘

                  ┌────────────────────────────────────────────┐
                  │            DEV-ONLY HOT RELOAD             │
                  │  chokidar → ws://localhost:9011            │
                  │   ├── R3F: diff store, morphScene()        │
                  │   └── UE5: Cortex-style plugin →           │
                  │            UDataAsset + FScopedTransaction │
                  └────────────────────────────────────────────┘
```

## 8.1 Specific tech at each layer

| Layer | Choice | Reason |
|---|---|---|
| Web renderer | **react-three-fiber v10 + drei v11 webgpu** | WebGPU primary, WebGL2 fallback; mature ecosystem |
| Web UI | **react-three-uikit + Rive** | UI Toolkit-style flexbox in 3D; Rive for motion |
| Web physics | **`@dimforge/rapier3d-deterministic`** | Only cross-platform-deterministic WASM physics in 2026 |
| Web parametric geo | **Manifold-WASM** | Exact CSG kernel, same binary as UE5-side native link |
| Web photoreal geo | **[Spark](https://github.com/sparkjsdev/spark)** for Gaussian Splats | Production renderer with LOD streaming |
| Web characters | **[`@pixiv/three-vrm`](https://github.com/pixiv/three-vrm)** | Identical avatar to UE5 via VRM4U |
| Transport (primary) | **WebTransport (QUIC) via [wtransport](https://github.com/BiagioFesta/wtransport) sidecar** | Datagrams for state, streams for RPC |
| Transport (fallback) | **WebSocket via [tungstenite](https://github.com/snapview/tokio-tungstenite)** | Hostile-network reach |
| Wire format | **Bit-packed deltas (custom) + FlatBuffers for cold spawn/RPC** | Hot reads cheap, schema evolution clean |
| Edge gateway | **Rust + axum + wtransport** | One process per region; bridges WT ↔ UE5 NetConnections |
| Authoritative server | **UE5 Linux Shipping (-nullrhi), forked Lyra** | Chaos for vehicles/destruction; Iris (5.7 Beta) for internal state; GAS for abilities; EOS for sessions/anti-cheat |
| Game-state extraction | **`UExporterSubsystem`** ticks 20–30 Hz, walks Iris quantized state, emits to local UDP | No off-the-shelf; ~2 weeks to build |
| Anti-cheat | **EOS AC server-side only + server-side input sanity + obfuscation + reCAPTCHA** | EAC client doesn't run in browser, ever |
| Voice | **[LiveKit](https://livekit.io/) SFU** | Browser-first WebRTC; EOS RTC has no web SDK |
| Asset CDN | **Cloudflare R2 + glTF-binary-under-the-hood (KTX2, Meshopt v1.1, Draco)** | Cheap egress, universal browser support |
| Photoreal scenes | **`.ply`/`.spz` Gaussian Splats** | Spark on web, Luma/Volinga/DazaiStudio in UE5 — same bytes |
| Hero scenes | **Spline → USDZ + Spline code export** | One asset, both runtimes |
| 2D motion | **Rive (`.riv`)** | Identical state machines on both sides |
| Avatars | **VRM 1.0 + VRMA** | One file, three runtimes |
| Authoring source-of-truth | **`.scene.tsx` SWC-compiled to `scene.v1` JSON** | Engineer-friendly + machine-parseable |
| Backend platform | **[Nakama](https://heroiclabs.com/nakama/) or SpacetimeDB** | Matchmaking, persistence, leaderboards |
| Orchestration | **Agones on Kubernetes + Gameye/GameFabric** | NOT Hathora (dead) |

## 8.2 First-90-day plan

1. Fork Lyra; build Linux Shipping server target; Dockerize per [Gameye guide](https://gameye.com/blog/unreal-engine-5-dedicated-server-docker-container/).
2. Strip rendering content; enable Iris (`bUseIris = true` in `*.Target.cs`); enable Chaos prediction + history.
3. Write the `UExporterSubsystem` — walks Iris quantized state per tick, emits bit-packed deltas to local UDP.
4. Stand up Rust `wtransport` gateway bridging UDP ↔ WebTransport sessions; bolt on WSS fallback via `tungstenite`.
5. Three.js + R3F + Vite client; `@dimforge/rapier3d-deterministic` for prediction; snapshot interpolation buffer ≈ 100ms.
6. EOS Web API for Sign-in-with-Epic; EOS Sessions proxied through backend; voice via LiveKit.
7. Asset pipeline: KTX2 + meshopt v1.1; Gaussian splat scenes via Spark + Luma; VRM avatars via three-vrm + VRM4U.

---

**Up next:** [09 — Experimental tricks (know-don't-ship)](09-experimental-tricks.md). **Back to:** [README](README.md).
