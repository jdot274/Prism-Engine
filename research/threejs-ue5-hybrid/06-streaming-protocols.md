---
title: "Streaming Protocols & Plumbing (2026 State)"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§6"
---

# 6. Streaming Protocols & Plumbing (2026 State)

> _The transport layer between the UE5 simulation and the Three.js client. WebTransport just turned Baseline in March 2026 — that single change reshuffles every recommendation an older blog post would give you._

Related reading: [05-ue5-physics-only-architecture.md](05-ue5-physics-only-architecture.md) §5.4 for how to extract UE5 state into one of these transports; [08-recommended-architecture.md](08-recommended-architecture.md) for the recommended transport stack.

---

## 6.1 The four transports compared

| Transport | Latency | Ordering | Reliability | Browser support 2026 |
|---|---|---|---|---|
| **WebSocket** | TCP-bound; HOL blocking | Ordered | Reliable | Universal |
| **WebTransport (HTTP/3/QUIC)** | Multiplexed streams + datagrams; no HOL | Per-stream | Mixed (datagrams unreliable, streams reliable) | **Baseline Newly Available March 2026** (Chrome 97+, Edge 98+, Firefox 114+, **Safari 26.4+**, included in Interop 2026 per [caniuse](https://caniuse.com/webtransport), [MDN](https://developer.mozilla.org/en-US/docs/Web/API/WebTransport_API), [web-features explorer](https://web-platform-dx.github.io/web-features-explorer/features/webtransport/)) |
| **WebRTC DataChannel** | ~30–80 ms; STUN/TURN signaling | Optional | Optional | Universal but operationally heavy |
| **WebSockets over HTTP/3 (RFC 9220)** | – | – | – | Thin adoption; Jetty [issue #14294](https://github.com/jetty/jetty.project/issues/14294); skip |

**Verdict**: **WebTransport primary, WebSocket fallback.** That's the right answer for 2026 game traffic. WebRTC DataChannel only if you go peer-to-peer or need WebTransport-free reach in restricted networks.

## 6.2 UE5 WebTransport library

**No first-party UE5 WebTransport plugin** in 2026. Closest is the multi-transport [nprpc](https://github.com/nikitapn/nprpc) (March 2026). Run a sidecar — Node [`@fails-components/webtransport`](https://github.com/fails-components/webtransport), Rust [`wtransport`](https://github.com/BiagioFesta/wtransport), or Go `quic-go` — that proxies into UE5 via local UDP/loopback.

## 6.3 WebCodecs and MSE

- [WebCodecs](https://developer.mozilla.org/en-US/docs/Web/API/WebCodecs_API): Chrome/Edge 94+, Safari 26+, Firefox 130+ desktop (Firefox Android still missing — a real mobile-baseline blocker), Samsung 17+, iOS Safari 26+ ([caniuse](https://caniuse.com/webcodecs), [TestMu's writeup](https://www.testmuai.com/learning-hub/webcodecs-browser-support/)).
- **Use case**: Pixel-Streaming-style cloud-render fallback at sub-second latency ([Gustav Lotz fleet-app case study](https://www.gustavlotz.com/blog/live-video-streaming-fleet-app-sub-second-latency), [WebCodecs Fundamentals](https://webcodecsfundamentals.org/patterns/live-streaming/)).
- **MSE vs WebCodecs**: MSE = container-level, 2–4s latency, good for VOD. WebCodecs = containerless `EncodedVideoChunk`, sub-second. Use WebCodecs for anything interactive.

## 6.4 Media over QUIC (MoQ)

[draft-ietf-moq-transport-18](https://datatracker.ietf.org/doc/draft-ietf-moq-transport/) published May 12, 2026; WG milestone targets December 2026. 11 vendors demoed at NAB Show 2026 (Bitmovin, Cloudflare, AWS, CacheFly, Red5, Synamedia, Akamai, Ant Media, Norsk, Oracle, Nomad Media). Companion [LOC format draft](https://datatracker.ietf.org/doc/html/draft-ietf-moq-loc-02). [Forasoft's 2026 status](https://www.forasoft.com/blog/article/media-over-quic-moq-streaming-2026).

**Relevance**: MoQ is pub/sub on WebTransport with priorities — *perfect* fit for game state fan-out once tooling matures. **Too early in May 2026.** Bookmark for Q4 2026/2027.

## 6.5 Nanite-style geometry streaming on the web — *this is actually shipping*

- [Scthe/nanite-webgpu](https://github.com/Scthe/nanite-webgpu) — working WebGPU implementation, meshlet LOD hierarchies, software rasterization, 1.7B-triangle scenes.
- [meshoptimizer v1.1 (April 2026)](https://github.com/zeux/meshoptimizer/releases/tag/v1.1) — meshlet codec, 7–10 GB/s CPU / 150+ GB/s GPU decoders. [JS bindings PR #738](https://github.com/zeux/meshoptimizer/pull/738), [hierarchical clustered simplification PR #760](https://github.com/zeux/meshoptimizer/pull/760).
- [Three.js PR #33605 (May 2026)](https://github.com/mrdoob/three.js/pull/33605) — experimental GPU-driven software rasterizer.

**Status**: Production-tractable for WebGPU-only targets. WebGL2 can still meshlet-cull but loses the perf headroom.

## 6.6 Octree / chunk streaming for open worlds

- [Roblox-ts chunk demo](https://github.com/DestinEcarma/roblox-ts-demo), [procedural-worlds](https://github.com/Gzeu/roblox-procedural-worlds), [Roblox's April 2026 Hybrid Architecture announcement](https://about.roblox.com/te/newsroom/2026/04/roblox-reality-hybrid-architecture-democratizing-photorealistic-multiplayer-gaming), [Cinevva's open-world tech guide](https://app.cinevva.com/guides/browser-3d-open-world-tech).
- Standard pattern: server owns world chunks keyed by `(x,y,z)` integer coords; client subscribes to chunks within interest radius; LOD ring of full-detail → simplified mesh → billboard impostors.
- Maps cleanly to MoQ's pub/sub once that's mature.

## 6.7 State sync libraries

- **[Colyseus](https://colyseus.io/)** — Node + binary schema sync. Excellent small/medium. No UE5 native integration.
- **[Nakama](https://heroiclabs.com/nakama/)** v3.38.0 (March 2026) — OSS backend, supports UE5 + most engines. Heavyweight enterprise.
- **[Geckos.io](https://geckos.io/)** v3.1.0 (March 2026) — WebRTC DataChannel for UDP-over-browser, snapshot interpolation, typed buffer schema.
- **~~Hathora~~ — shut down May 5, 2026.** Migrate to [GameFabric by Nitrado](https://gamefabric.com/hathora/) or [Gameye](https://gameye.com/).
- **~~Lance.gg~~ — abandoned.** 2026 alternatives: [rollback-netcode](https://github.com/someusername6/rollback-netcode), [CarverJS](https://github.com/MoneyTales/carverjs), [p2play-js](https://github.com/aguiran/p2play-js).
- **[Yjs](https://yjs.dev/) / Automerge** — CRDT for eventually-consistent state (player loadouts, guild data, world editing). **Wrong tool** for 60 Hz action.
- **[SpacetimeDB](https://spacetimedb.com/docs/intro/what-is-spacetimedb)** v2.2.0 (May 2026) — logic-inside-the-DB in Rust/C#/TS/C++. Used by **BitCraft Online**. [TickForge](https://github.com/invertedmushroom/TickForge) is the reference fully-deterministic Rust + Rapier3D action MMO server on SpacetimeDB. **Most interesting non-UE alternative for 2026.**

---

**Up next:** [07 — Meta-scene tool design](07-meta-scene-tool-design.md). **Back to:** [README](README.md).
