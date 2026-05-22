---
title: "Prior Art & Shipped Projects"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§5.10 + scattered references"
---

# Prior Art & Shipped Projects

> _The hybrid UE5-server + browser-client architecture this report recommends has **no public AAA-scale reference implementation** as of May 2026 (§5.10). The closest production deployments are Pixel Streaming installations — which stream video, not state. The references below are either (a) shipped browser-only games whose networking patterns we should copy, or (b) UE5 production deployments that show the server-side ceiling, or (c) tooling we can fork._

This file gathers content from §5.10 of the report plus scattered references throughout. See the corresponding source sections for the full surrounding context.

Related reading: [05-ue5-physics-only-architecture.md](05-ue5-physics-only-architecture.md) for the architectural framing; [08-recommended-architecture.md](08-recommended-architecture.md) for which of these projects most influenced the recommended design.

---

## Shipped browser games — reference networking architectures

These are the *production* deployments of browser-only multiplayer games whose networking patterns the recommended hybrid architecture is modeled on. None of them are UE5 hybrids — they are pure web stacks — but every one of them has been battle-tested at scale.

- **Krunker.io** — Three.js + custom Node + [KrunkScript](https://docs.krunker.io/) (typed client/server-split scripting). Architecture analysis: [jakob.space — *browser games aren't an easy target*](https://jakob.space/blog/browser-games-aren-t-an-easy-target.html). The KrunkScript pattern (one typed language with `client { ... }` / `server { ... }` blocks) is a direct precedent for "share the same DSL across runtimes." Krunker's anti-cheat history is the canonical case study in why browser-side anti-cheat is unsolvable — see [§5.5](05-ue5-physics-only-architecture.md#55-anti-cheat--the-hard-truth).
- **Venge.io** — PlayCanvas-based. Demonstrates that a web engine can ship a polished competitive FPS without UE5.
- **Diep.io** — 2D Canvas + WebAssembly + binary [WebSocket protocol](https://github.com/abcxff/diepindepth). The binary-WebSocket-protocol writeup is a great primer for bit-packed deltas (cf. the recommended wire format in [§5.4](05-ue5-physics-only-architecture.md#54-extracting-state-to-a-non-ue-client--four-patterns)).
- **Surviv.io** — PixiJS + WebSocket + SAT.js + [server reconciliation + interpolation](https://github.com/tromagon/Survivio-Network-Proto). The `Survivio-Network-Proto` repo is one of the clearest open implementations of the Glenn Fiedler / Gabriel Gambetta reconciliation pattern. Direct reference for the web-side prediction loop ([§5.8](05-ue5-physics-only-architecture.md#58-server-authoritative-architectures)).
- **Decentraland** — Two parallel clients (Unity WebGL + Godot 4 fork) consuming the same CRDT scene stream over [LiveKit/WebRTC](https://github.com/decentraland/docs/blob/main/creator/sdk7/interactivity/player-physics.md). **The most relevant prior art** for "one DSL, two renderers": Decentraland's CRDT scene stream is *the* shipped real-world precedent for the `scene.v1` design in [§7](07-meta-scene-tool-design.md).

## UE5 dedicated-server scale references

- **CipSoft MMO tech demo on UE 5.6** — [forum writeup](https://forums.unrealengine.com/t/our-experience-building-an-mmo-tech-demo-with-unreal-engine-5-6/2703197) reports ~450 concurrent users peak, ~250 stable. The most concrete public data point on Iris + Lyra + Chaos at scale (referenced in [§5.3](05-ue5-physics-only-architecture.md#53-iris-replication-55-beta-in-57)).
- **StraySpark Chaos Vehicles 2026 masterclass** — [shipping racing game writeup](https://www.strayspark.studio/blog/chaos-vehicles-masterclass-shipping-racing-game-2026) covers 150 ms / 2% loss tuning. Reference for the Chaos-server-side authority strategy in [§5.8](05-ue5-physics-only-architecture.md#58-server-authoritative-architectures).
- **Magnopus Niagara Gaussian splat viewer** — [engineering blog](https://www.magnopus.com/blog/how-we-wrote-a-gpu-based-gaussian-splats-viewer-in-unreal-with-niagara). The clearest behind-the-scenes account of shipping splat rendering inside UE5 production tooling.
- **StraySpark Gaussian splat capture-to-game pipeline** — [walkthrough](https://www.strayspark.studio/blog/gaussian-splatting-unreal-engine-5-capture-to-game-pipeline). The single best end-to-end pipeline doc for the splat workflow recommended in [§4.4](04-fake-rendering-tricks.md#44-gaussian-splatting--the-most-important-trick-in-this-report).

## UE5-server + web-client at scale

**None public** at AAA scale as of May 2026 (§5.10). The closest are Pixel Streaming deployments (which stream video, not state). **You'd be pioneering.**

## Tooling we can fork

- **[UnrealCortex](https://github.com/etelyatn/UnrealCortex) + [UnrealDataBridgeMCP](https://github.com/etelyatn/UnrealDataBridgeMCP)** — Cortex-style WebSocket ↔ `UDataAsset` mutators wrapped in `FScopedTransaction` (so undo works). Direct fork base for the dev-only hot-reload plugin in [§7.4](07-meta-scene-tool-design.md#74-hot-reload-across-both-engines).
- **[Embody](https://github.com/snorkelingcode/Embody-Unreal-Engine-Source) + [UE5_Remote](https://github.com/tgraupmann/UE5_Remote)** — starter code for the "extract UE5 state into a non-UE wire format" problem in [§5.4](05-ue5-physics-only-architecture.md#54-extracting-state-to-a-non-ue-client--four-patterns).
- **[Photon NetDriver](https://github.com/oculus-samples/Unreal-SharedSpaces/blob/main-5.x/Plugins/PhotonNetDriver/Documentation/PhotonNetDriver.md), [Redwood NetDriver](https://redwoodmmo.com/docs/miscellaneous/netdriver-docs)** — reference implementations of the "custom UNetDriver masquerading as a UE client" pattern.
- **[TickForge](https://github.com/invertedmushroom/TickForge)** — reference fully-deterministic Rust + Rapier3D action MMO server on SpacetimeDB. The most interesting non-UE alternative for 2026 ([§6.7](06-streaming-protocols.md#67-state-sync-libraries)).
- **[Lyra](https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-sample-game-in-unreal-engine)** — Experiences + GAS + EOS scaffolding. Fork base for the authoritative server in [§5.9](05-ue5-physics-only-architecture.md#59-lyra-as-a-reference-fork) and the recommended architecture in [§8](08-recommended-architecture.md).

## Roblox's hybrid architecture (April 2026)

- [Roblox Reality Hybrid Architecture announcement](https://about.roblox.com/te/newsroom/2026/04/roblox-reality-hybrid-architecture-democratizing-photorealistic-multiplayer-gaming) — Roblox's own move toward a hybrid photoreal stack is the closest a major platform has come to publicly endorsing the framing of this report.

---

> _Note: this file is a curated index of prior art mentioned across the report. If a project here is critical to your evaluation, follow the link to its source section for the full surrounding context._

**Back to:** [README](README.md) | [Closing notes](closing-notes.md).
