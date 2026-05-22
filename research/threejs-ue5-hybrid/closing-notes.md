---
title: "Closing Notes — Opinions, Currency Calls, Hygiene Tax"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "Closing notes"
---

# Closing Notes

> _A few opinions worth surfacing explicitly, plus the "hygiene tax" — the 2026 changes that invalidate large amounts of older blog-post guidance you'll find via web search._

---

## Opinions worth stating

- **Gaussian Splatting is the single most under-appreciated answer to "no FBX/GLTF."** It's the only format where the exact same bytes render in Three.js (Spark) and UE5 (Luma, Volinga, DazaiStudio) in 2026. If your art direction can accommodate it, design around `.ply`/`.spz` as the primary photoreal asset. Deep-dive: [04-fake-rendering-tricks.md §4.4](04-fake-rendering-tricks.md#44-gaussian-splatting--the-most-important-trick-in-this-report).
- **WebTransport just turned Baseline.** Stop planning around WebSocket-only for new projects. WS is the fallback, not the default. Deep-dive: [06-streaming-protocols.md §6.1](06-streaming-protocols.md#61-the-four-transports-compared).
- **The "UE5 for physics only" framing is right in principle but oversells UE5's role.** If your game doesn't need Chaos's vehicle/destruction/Niagara features, drop UE5 and run **Rust + Rapier + SpacetimeDB**. You get bit-identical client/server prediction, one language, and no headless-UE deployment pain. Deep-dive: [05-ue5-physics-only-architecture.md §5.8](05-ue5-physics-only-architecture.md#58-server-authoritative-architectures), [06-streaming-protocols.md §6.7](06-streaming-protocols.md#67-state-sync-libraries).
- **Anti-cheat in the browser is fundamentally unsolvable.** Server-side validation is your entire defense. Bake this into the gameplay design — no client-authoritative anything. Deep-dive: [05-ue5-physics-only-architecture.md §5.5](05-ue5-physics-only-architecture.md#55-anti-cheat--the-hard-truth).
- **The meta-scene-format tool is buildable for ~3–4 months of one engineer.** That's roughly the same effort as porting a non-trivial Unity codebase to UE5. Worth it if you actually plan to author once and render in both. Effort breakdown: [10-build-vs-buy.md §10.2](10-build-vs-buy.md#102-custom-build-and-how-much-work).

## Hygiene tax — re-check anything from a 2024 blog post

These changes are *all* recent enough that older guidance will be wrong:

- **Hathora is dead** (shut down May 5, 2026). Migrate to GameFabric or Gameye.
- **Lance.gg is dead** / abandoned. See [06-streaming-protocols.md §6.7](06-streaming-protocols.md#67-state-sync-libraries) for 2026 alternatives.
- **Cannon-es is stale.** Use Rapier or Jolt.
- **Khronos's `glslang` HLSL frontend is deprecated** (16.3.0, April 2026). DXC and Slang own HLSL going forward.
- **NeRFs are displaced** by Gaussian splats; Volinga deprecated NeRF in 2025.
- **`Chaos` WASM does not exist**, and Epic has never indicated one is coming.
- **No first-party EOS JS SDK** in 2026 — run EOS on your backend, expose your own REST/WS facade.
- **WebTransport is now Baseline** (Safari 26.4+) — included in Interop 2026.

---

**Back to:** [README](README.md).
