---
title: "The UE5 for Physics/Networking Only Architecture"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§5"
---

# 5. The "UE5 for Physics/Networking Only" Architecture

> _What if the only thing UE5 does is serve as the authoritative simulation? No rendering, no UMG, no Niagara on the player side — just Chaos, Iris, GAS, and EOS. This section is the deep-dive on that path._

Related reading: [06-streaming-protocols.md](06-streaming-protocols.md) for the transports underlying the state-extraction patterns described in §5.4 and §5.7; [08-recommended-architecture.md](08-recommended-architecture.md) for how this slots into the recommended pipeline; [prior-art-and-shipped-projects.md](prior-art-and-shipped-projects.md) for the shipped browser-game references in §5.10.

---

## 5.1 UE5 Dedicated Server (headless)

- **Flags**: `-server -log -nosound -nullrhi -unattended -port=7777` ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-dedicated-servers-in-unreal-engine), [Nodecraft guide](https://nodecraft.studio/docs/game-server-launch-guide/executable/game-engines/unreal-engine/), [Gameye Docker container guide](https://gameye.com/blog/unreal-engine-5-dedicated-server-docker-container/), [Unreal Containers reference](https://unrealcontainers.com/docs/use-cases/dedicated-servers)).
- **Build**: `*Server.Target.cs` with `Type = TargetType.Server`. Linux Shipping is the deployment target — never test only on Windows.
- **Gotchas**: Blueprint-heavy projects must ship assets server-side too; wrap rendering with `#if !UE_SERVER`; Niagara/FMOD still allocate. Profile cold-start RSS before scaling.

## 5.2 Chaos Physics on the dedicated server

- **Networked Physics** docs aligned in 5.7 ([networked physics](https://dev.epicgames.com/documentation/en-us/unreal-engine/networked-physics), [Chaos overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/overview-of-the-chaos-physics-system-in-unreal-engine)). [StraySpark Chaos Vehicles 2026 masterclass](https://www.strayspark.studio/blog/chaos-vehicles-masterclass-shipping-racing-game-2026) covers 150ms/2% loss tuning.
- **Determinism**: **Same-binary deterministic** (enable async fixed-step + physics prediction + history capture). **NOT** cross-platform deterministic — different CPU vendors and SIMD will drift over thousands of ticks. **No Chaos WASM build exists.**
- **Implication**: Server is the truth; you cannot deterministically resim Chaos in the browser. Predict on the client with a *different* engine (Rapier).

## 5.3 Iris replication (5.5+, Beta in 5.7)

- [Iris docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/introduction-to-iris-in-unreal-engine), [components](https://dev.epicgames.com/documentation/en-us/unreal-engine/components-of-iris-in-unreal-engine), [prioritization](https://dev.epicgames.com/documentation/en-us/unreal-engine/iris-prioritization-in-unreal-engine), [Vorixo's serializer deep-dive](https://vorixo.github.io/devtricks/iris-netserializers/) and [filter deep-dive](https://vorixo.github.io/devtricks/iris-replication-filter/).
- **Real-world**: [CipSoft MMO tech demo on 5.6](https://forums.unrealengine.com/t/our-experience-building-an-mmo-tech-demo-with-unreal-engine-5-6/2703197) hit ~450 CCU, ~250 stable.
- **Web client question**: Iris produces UE's proprietary binary frames over `UNetDriver` UDP. **A browser cannot speak this.** There is no Iris-over-WebTransport from Epic and no public plan in 2026. Use Iris's quantized state as an *intermediate cache* and export your own delta protocol.

## 5.4 Extracting state to a non-UE client — four patterns

1. **Custom `UGameInstanceSubsystem` → WebTransport/WebSocket → binary frames** (recommended).
   - Plugins: experimental [`WebSocketMessaging`](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/PluginIndex/WebSocketMessaging) ships with 5.7. Community: [BlueprintWebSocket](https://github.com/Pandoa/BlueprintWebSocket), [ue-websockets-helper](https://github.com/prwc/ue-websockets-helper), Marketplace [Internet Protocol Client](https://www.unrealengine.com/marketplace/en-US/product/internet-protocol-client-websocket-http-and-json).
2. **Custom `UNetDriver`** masquerading as a UE client — see [Photon NetDriver](https://github.com/oculus-samples/Unreal-SharedSpaces/blob/main-5.x/Plugins/PhotonNetDriver/Documentation/PhotonNetDriver.md), [Redwood NetDriver](https://redwoodmmo.com/docs/miscellaneous/netdriver-docs). Powerful, expensive.
3. **Replication Graph / Iris-bridge proxy** walking quantized state into your wire format.
4. **Pixel Streaming 2** — see [§4.1](04-fake-rendering-tricks.md#41-ue5-pixel-streaming-2-the-most-fake-but-most-polished).

**No off-the-shelf "UE5 → Three.js" plugin exists in 2026.** Starter code: [Embody](https://github.com/snorkelingcode/Embody-Unreal-Engine-Source), [UE5_Remote](https://github.com/tgraupmann/UE5_Remote).

**Wire format**: FlatBuffers wins for hot reads (decode ~18ns/op vs Protobuf ~1180ns in [Go benchmarks](https://github.com/kcchu/buffer-benchmarks)), Protobuf wins for schema evolution. For per-tick deltas: **bit-packed custom (Glenn Fiedler bitstream)**. For spawn/RPC: FlatBuffers.

## 5.5 Anti-cheat — *the hard truth*

- [EOS Anti-Cheat](https://dev.epicgames.com/docs/epic-online-services/trust-and-safety/anti-cheat-interfaces/anti-cheat-interfaces) **Server Interface** supports Linux x86_64, virtualized fine.
- **Client Interface does not work in a browser**, ever. It needs OS-level kernel/user-mode drivers. EAC, BattlEye, EasyAntiCheat — **none** can run in a JS sandbox.
- **Reality**: Krunker.io ships obfuscated inline-`<script>` JS with homebrew tamper detectors and still gets cheated ([jakob.space writeup](https://jakob.space/blog/browser-games-aren-t-an-easy-target.html)). Your defense is **server-side validation only** + heuristic anti-bot + heavy JS obfuscation + reCAPTCHA Enterprise on join.

## 5.6 EOS from web

- [EOS Web API](https://dev.epicgames.com/docs/web-api-ref) (REST) + [Sessions](https://dev.epicgames.com/docs/game-services/lobbies-and-sessions/sessions). **No first-party JS SDK** in 2026 (latest native SDK 1.19.0.3, Feb 10 2026 — [What's New](https://dev.epicgames.com/docs/epic-online-services/whats-new)).
- **Pattern**: Run EOS on your backend; expose your own REST/WS facade to the browser. OAuth web flow for Sign-in-with-Epic. **Voice**: use LiveKit or Daily — EOS RTC has no browser path.

## 5.7 Browser-side physics for client prediction

| Engine | Determinism | Verdict |
|---|---|---|
| **[Rapier](https://github.com/dimforge/rapier.js/)** (`@dimforge/rapier3d-deterministic`) | **Cross-platform IEEE-754, including WASM** ([docs](https://rapier.rs/docs/user_guides/javascript/determinism)) | **Default choice.** Strongest determinism guarantee any popular browser physics engine offers. |
| [Jolt Physics WASM](https://www.npmjs.com/package/jolt-physics) v1.0.0 (Dec 2025) | Same-platform deterministic; cross-platform not guaranteed | Choose only for specific features (Horizon Forbidden West-grade) |
| [PhysX 5 WASM](https://github.com/fabmax/physx-js-webidl) v2.7.3 (April 2026) | Not cross-platform deterministic | Avoid unless sharing assets with native PhysX client |
| Ammo.js / Cannon-es | Stale (2022–2024) | Prototype only |

## 5.8 Server-authoritative architectures

- **Rollback netcode**: [GGPO](https://github.com/pond3r/ggpo), Backroll, [Photon Quantum 3.0.11 (April 2026)](https://www.photonengine.com/quantum) (Unity-only, 100% deterministic ECS, up to 128 players). For ≤16-player twitch only.
- **Server-authoritative + client prediction** — the right model for 95% of 2026 web games. Reference: Gabriel Gambetta's [Client-Side Prediction](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html), [Entity Interpolation](https://gabrielgambetta.com/entity-interpolation.html), [Lag Compensation](https://www.gabrielgambetta.com/lag-compensation.html); Glenn Fiedler's [Snapshot Interpolation](https://new.gafferongames.com/post/snapshot_interpolation/).

**The hard question — Rapier on client + Chaos on server, who owns truth?** Three real strategies:

1. **UE5 (Chaos) final authority; client predicts simple kinematic motion in Rapier; snap on divergence.** Tolerable for non-physics gameplay; ugly when Chaos and Rapier vehicle models disagree.
2. **Rapier on both ends** — Rust server (`bevy_rapier` or standalone), Rapier-WASM client, deterministic across IEEE-754. Then **UE5 disappears**.
3. **Hybrid (recommended)**: UE5 Chaos for *heavy* physics (vehicles, destruction); Rapier WASM client-side as *decorative* (particles, cloth, ragdoll hit-reactions, never authoritative) plus simple kinematic prediction for player movement. Server snapshots heavy stuff at 20–30 Hz; client interpolates. This is the [Counter-Strike/Source playbook](https://developer.valvesoftware.com/wiki/Lag_compensation) adapted for the web.

## 5.9 Lyra as a reference fork

- [Lyra docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-sample-game-in-unreal-engine), [X157's overview](https://x157.github.io/UE5/LyraStarterGame/), [Matt's Experiences deep dive](https://unrealist.org/lyra-part-2/), [EOS-with-Lyra tutorial](https://dev.epicgames.com/community/learning/tutorials/375e/unreal-engine-using-epic-online-services-with-lyra-starter-game).
- **Strategy**: Fork Lyra, gut rendering/HUD/MetaHuman, keep Experiences + GAS + EOS scaffolding, plug in your custom WebTransport subsystem. Saves weeks.

## 5.10 Reference implementations of UE-server + web-client at scale

**None public** at AAA scale as of May 2026. The closest are Pixel Streaming deployments (which stream video, not state). **You'd be pioneering.**

Shipped browser-game references (without UE5) are gathered separately in [prior-art-and-shipped-projects.md](prior-art-and-shipped-projects.md):

- Krunker.io, Venge.io, Diep.io, Surviv.io, Decentraland — full architecture notes there.

---

**Up next:** [06 — Streaming protocols](06-streaming-protocols.md). **Back to:** [README](README.md).
