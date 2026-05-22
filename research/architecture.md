# Prism — Architecture Decision Document

**Status:** Proposed (v0.1)
**Author:** Technical Director
**Date:** 2026-05-21
**Horizon:** First 6 months of engineering (PoC → Beta)

---

## 0. Executive Summary

Prism is a suite of 50–100 focused micro-app "tools" that wraps UE5 and eliminates the tool-switching tax. The architecture must satisfy three non-negotiable properties:

1. **Aesthetic fidelity.** The dark canvas, luminous 3D-rendered icons, gradient sliders, blur/bloom, and 60fps card animations are the product's calling card. Native UE5 widget systems cannot achieve this without unsustainable engineering cost.
2. **Live scene coupling.** Tools must read/write UE5 state with sub-frame perceived latency. A user dragging a hue slider must see the material update in the viewport with no perceptible lag (target: <16 ms round-trip from drag event to viewport repaint).
3. **Upgrade survivability.** UE5 ships ~2 major versions per year. Prism's surface area against the engine must be small and stable, or maintenance will consume the team.

**The headline decisions are:**

- **Hybrid integration model.** A thin UE5 editor plugin acts as a "scene bridge"; the rich UI lives in a separate companion process.
- **Companion process is a native Rust application** rendering with **wgpu** + a custom retained UI layer (with Skia for vector/text). Not Electron. Not Slate.
- **Transport is shared memory + a local websocket control channel** (not REST, not named pipe alone).
- **Phase 1 (4 weeks):** prove a single tool — a material color picker — round-trips a parameter to a saved material asset.

The remainder of this document defends these choices and lays out the consequences.

---

## 1. Integration Model Decision

### Option A — UE5 Editor Plugin (in-process, C++/Python)

**What it means.** Prism ships as a UE5 plugin (`Prism.uplugin`). All tool UIs are built with Slate/UMG. All scene access is direct in-process C++. Distribution is via Fab or a manual `.zip` install into the project's `Plugins/` folder.

**Pros**
- Zero IPC latency. Direct pointer access to `UObject` graph.
- No process lifecycle to manage — when UE5 starts, Prism starts.
- Single language stack (C++), single build (UBT).
- Crash boundary is shared with the editor (also a con — see below).

**Cons**
- **Aesthetic ceiling.** Slate is not designed for the visual language described (luminous 3D icons, animated gradients, bloom). Achievable, but every effect is a multi-week custom-widget engineering project. UMG is worse.
- **UE5 version churn.** Every major UE5 release breaks plugin APIs in non-trivial ways (Slate, Editor module, asset registry signatures have all changed across 4.x → 5.0 → 5.3 → 5.5). A pure plugin means a re-port every release.
- **Crash blast radius.** A bug in a Prism tool crashes the user's editor session and loses unsaved scene state.
- **Iteration speed.** Hot-reloading C++ in UE5 is fragile. Iteration cycle for a UI tweak is ~30s minimum.
- **Distribution.** Plugins are versioned per-engine. We would ship N binaries for N supported UE5 versions.

**Verdict.** Rejected as the primary model. Latency is its only true advantage, and a hybrid recovers most of that advantage.

### Option B — Companion Electron/Tauri App (out-of-process, REST/WS)

**What it means.** Prism is a standalone desktop app. It talks to UE5 via the Remote Control API (HTTP/WebSocket) shipped with the engine.

**Pros**
- Zero coupling to UE5 build system. Ship one Prism binary, supports many UE5 versions.
- Crash isolation — Prism crashing never takes the editor with it.
- Maximum UI freedom (web stack or native).
- Iteration speed of a web/native app, not a UE5 plugin.

**Cons**
- **Remote Control API is not enough.** It exposes a curated set of UObject properties via HTTP. It does not give you UV data, mesh paint, decal placement, or color sampling of the rendered viewport. Many Prism tools require deeper access than Remote Control provides.
- **Latency.** A pure HTTP/WS bridge adds 2–8 ms per round-trip on localhost — survivable, but stacks up for interactive sliders.
- **Discovery.** A companion app must locate the UE5 editor process, handshake, and recover from editor restarts.
- **Electron specifically:** ~150 MB baseline, 200+ MB memory at idle, Chromium update treadmill, and the visual quality of Electron apps is bounded by web rendering (which is fine for layout but not for the 3D-rendered glow aesthetic without significant GPU work).

**Verdict.** Rejected as a pure solution because Remote Control's surface area is too thin for our tool catalogue. The companion-process *idea* is right; the *bridge* needs to be richer.

### Option C — Hybrid (RECOMMENDED)

**What it means.** Two components:

1. **`PrismBridge`** — a thin UE5 editor plugin (~5–10k LoC C++). Its only job is to expose a structured, versioned API over a local transport. It owns no UI. It exposes scene reads, scene writes, asset-save operations, viewport sampling, and a tick-driven event stream.
2. **`PrismApp`** — a standalone native companion process. Owns 100% of the UI, the tool runtime, the AI command palette, and the node-graph wiring engine.

**Pros**
- **Best of both.** The bridge gives us the deep UE5 access that Remote Control lacks. The companion gives us full aesthetic freedom and a single binary across UE5 versions.
- **Surface area is small.** The bridge plugin is the *only* code that must be ported across UE5 versions. The bridge IDL is versioned, so the companion app supports multiple bridge versions concurrently.
- **Crash isolation.** A buggy tool crashes `PrismApp`, not UE5.
- **Iteration speed.** Tool authors work entirely in `PrismApp` (native code, hot-reload-friendly) and never recompile the plugin during normal feature work.
- **Distribution.** Ship one `PrismApp` installer; ship one small `PrismBridge` plugin per supported UE5 version (much cheaper than porting the whole app).

**Cons**
- Two binaries to ship and version.
- IPC overhead, addressed below.
- A handshake/discovery layer must exist.

**Latency analysis for the hybrid.** Three transport options were considered:

| Transport | Read latency (1KB) | Write latency | Throughput | Notes |
|---|---|---|---|---|
| HTTP (Remote Control style) | 1.5–4 ms | 2–5 ms | Low | Per-request overhead kills sliders |
| Named Pipe (raw) | 0.1–0.3 ms | 0.1–0.3 ms | High | Win-friendly, no framing |
| Local Websocket | 0.3–0.8 ms | 0.3–0.8 ms | Medium | Good for events, has framing |
| **Shared memory + WS control** | **<50 μs** | **<50 μs** | **Very high** | Use SHM for high-rate data (viewport pixels, parameter streams); WS for commands and events |

**Decision:** Shared memory ring buffers for hot paths (color sampling, slider streams, viewport thumbnails) + a local Websocket on `127.0.0.1` for command/event traffic and discovery. This matches how OBS, Substance Painter's live link, and modern DCC bridges work.

### Recommendation

**Adopt Option C (Hybrid).** This is the only model that simultaneously satisfies aesthetic, latency, and upgrade-survivability requirements. The cost (two binaries, an IPC surface) is real but bounded; the alternative costs (aesthetic compromise *or* per-release re-port) are unbounded.

---

## 2. UI Rendering Stack

The visual brief — luminous 3D icons, animated gradients, dark canvas with blur/bloom, 60fps card animations — pushes us decisively away from "UI toolkits" and toward "GPU-rendered surfaces."

### Candidates evaluated

**Slate / UMG.** Rejected. Achievable in theory; in practice every glow/bloom/3D-icon effect is bespoke engineering against an immediate-mode-ish API not built for this. Also locks UI to in-process plugin model. Incompatible with the hybrid decision above.

**Embedded web renderer (CEF / WebView2).** Tempting because designers can mock in HTML/CSS quickly. Rejected for three reasons:
1. CEF brings ~120 MB of distribution weight and the Chromium update treadmill.
2. The "3D-rendered glow" aesthetic requires either shipping pre-rendered assets (bloats install) or running WebGL/WebGPU shaders inside the browser — at which point we're paying CEF's overhead to do what wgpu does directly.
3. Compositing 50+ floating cards each running their own DOM is expensive.

**Dear ImGui.** Rejected for product UI. ImGui is the right tool for developer-facing tooling with utilitarian aesthetics. It is the wrong tool when the UI *is* the product's differentiator. (We will use ImGui internally for the debug overlay only.)

**Custom Skia/Lottie renderer in a companion process.** Closer. Skia handles vector + text beautifully. Lottie handles animated assets. But Skia alone won't carry the 3D-rendered icon and bloom requirements at 60fps for many cards.

### Recommended stack

**`PrismApp` UI = native Rust + `wgpu` (GPU) + `Skia` (vector/text fallback) + a thin retained-mode UI layer.**

Specifically:
- **Window/event loop:** `winit`.
- **GPU surface:** `wgpu` (Vulkan on Windows, Metal on macOS, DX12 fallback). Every card is a textured quad; the canvas composites them with bloom in a single post-process pass.
- **3D-rendered icons:** authored in Blender, baked to a small glTF + PBR maps, rendered in-app with a tiny PBR shader. *Not* video, *not* pre-rendered sprites — live shading lets icons react to hover, theme, and tool state.
- **Vector/text/curves:** `tiny-skia` for 2D primitives, `cosmic-text` for text shaping. Skia (`skia-safe`) for any case `tiny-skia` can't handle (gradient meshes, complex blending).
- **Animation:** custom spring/tween system with a `Lottie` importer for designer-authored micro-animations.
- **Retained UI layer:** custom, small (~3k LoC). We do NOT adopt `egui` (immediate mode, wrong fit for highly animated UI), `iced` (mature but constrains rendering control), or `Slint` (licensing + aesthetic ceiling). The retained tree is necessary because we need stable widget identity across frames for animation interpolation.

### Which tool types use which approach

| Tool category | Rendering approach |
|---|---|
| Color wheel, gradient designers, palette pullers | wgpu shader-based (HSV wheels, gradient meshes are native to GPU) |
| Curve editor, node graph, wire connections | tiny-skia for paths + wgpu for compositing |
| Mesh paint / decal brushes | Bridge-driven; UI renders previews via wgpu but the painting itself happens server-side in UE5 |
| AI command palette (Ctrl+K) | cosmic-text + tiny-skia |
| Launcher rail, card chrome, blur/bloom | wgpu post-process pipeline |

### Performance budget

- **Per-frame budget:** 16.6 ms at 60fps.
- **Allocation budget:** zero allocations per frame in steady-state UI code (allocations only on tool open/close).
- **GPU budget:** <2 ms GPU time for the entire canvas at 4K with 20 cards visible.

---

## 3. Scene State Bridge

This is the load-bearing technical risk of the project. Get this wrong and Prism becomes a slideshow.

### UE5 APIs that matter

| Capability | Primary API | Notes |
|---|---|---|
| Read selected actor / properties | `GEditor->GetSelectedActors()`, `FProperty` reflection | C++ editor module only; not exposed via Python without bridging |
| Material parameter read/write | `UMaterialInstance::SetScalarParameterValueEditorOnly` / `K2_GetScalarParameterValue` | Safe on game thread; must mark dirty |
| Mesh UV data | `UStaticMesh::GetRenderData()` → `FStaticMeshLODResources` | Read-only at runtime; modifying UVs requires re-import |
| World color palette sampling | Custom viewport readback via `FViewport::ReadPixels` or a dedicated SceneCapture2D | Async; ~1–3 ms per readback at 256x256 |
| Decal placement | `ADecalActor` spawn + `UDecalComponent::SetDecalMaterial` | Game-thread |
| Curve / animation asset writes | `UCurveBase::GetCurves()`, `UAnimSequence` editing APIs | Must use editor-only paths; transaction system for undo |
| Asset save | `UEditorAssetLibrary::SaveAsset` (Python) or `UPackage::SavePackage` (C++) | Always wrap in `FScopedTransaction` |
| Event stream (selection changed, etc.) | `USelection::SelectionChangedEvent`, `FEditorDelegates` | Subscribe in plugin module startup |

**Decision: the bridge plugin is C++, not Python.** Python Editor Scripting is convenient but (a) is sandboxed away from many native APIs we need (viewport readback, custom Slate hooks), (b) has GIL overhead under high-frequency operations, and (c) startup cost is too high for tools that need instant response. We *will* optionally expose a Python surface within PrismApp for user scripting, but the bridge itself is native.

### Threading model

UE5's editor APIs are overwhelmingly **game-thread-only**. The bridge cannot do its work from arbitrary IPC threads.

Design:
- An IPC reader thread drains the socket / shared memory.
- Operations are encoded as commands and pushed onto a thread-safe queue.
- A `FTickableEditorObject` drains the queue on the game thread once per editor tick.
- Reads that don't mutate state (and are confirmed thread-safe) can short-circuit and return immediately.
- Writes always go through the game-thread queue.

### Latency / safety tradeoffs

- **Sliders (high frequency).** The bridge accepts a "parameter stream" subscription — PrismApp publishes new values into a shared-memory ring at up to 240 Hz, the bridge consumes the latest value each editor tick and applies it. Intermediate values are dropped. The user sees a viewport update at editor frame rate (typically 60+ fps in the editor's preview).
- **Discrete writes (decal placement, asset save).** Go through the transaction system. Always undoable. Latency: 5–30 ms; acceptable because these are non-interactive commits.
- **Reads (selection, material params).** Cached aggressively in the bridge with invalidation on the relevant `FEditorDelegates` event. PrismApp queries hit the cache, not the engine.

### Safety

- All writes wrapped in `FScopedTransaction` so the editor's undo stack stays consistent.
- Dirty flags propagated to the content browser so users see the save badge.
- Bridge refuses writes during PIE (Play-in-Editor) by default to prevent corrupting transient state — configurable.

---

## 4. Asset Round-Trip

The user-facing contract: **if I change something in Prism and then save my project, the change is in the asset on disk.** This is the difference between "live preview" and "real tool."

### Flow

1. **User edits in Prism.** PrismApp publishes a parameter change to the shared-memory stream.
2. **Bridge applies to in-memory UObject.** On the next editor tick, the bridge resolves the target asset (e.g., `MaterialInstance_Hero`), opens a scoped transaction, and writes the new parameter value via the appropriate editor-only setter. The asset is marked dirty (`UPackage::MarkPackageDirty`).
3. **Viewport reflects change.** UE5's normal material-update path triggers viewport repaint.
4. **Commit signal.** When the user releases the slider (or hits "Apply" / "Save" in the tool), PrismApp sends a `commit` command. The bridge calls `UEditorAssetLibrary::SaveAsset` on the affected packages.
5. **Content Browser badge.** Until commit, the asset shows the standard "unsaved" asterisk — this is the user's safety net.

### Special cases

- **Decals.** The bridge spawns the `ADecalActor` directly into the active level. Commit saves the level package, not a separate asset.
- **Curve edits feeding `UAnimSequence`.** Curve data is staged in a sidecar struct in the bridge, then applied as a single transaction on commit (animation re-bake is expensive; we don't do it per-drag).
- **Generated materials / new assets.** When a tool creates a new asset (e.g., "save palette as `UCurveLinearColorAtlas`"), PrismApp sends a `create_asset` command with a target path; the bridge uses `UAssetToolsModule::CreateAsset`. Naming collisions are surfaced to PrismApp for user resolution.

### Auto-save policy

Off by default. Prism never silently writes to disk. Every commit is user-initiated. This is a deliberate trust-building choice for a tool that touches user content.

---

## 5. Scope Ladder (Phases)

### Phase 1 — Proof of Concept (4 weeks)

**Goal:** End-to-end round-trip works for exactly one tool. No aesthetics polish. No tool catalogue. No AI palette. Prove the pipe.

**Deliverables:**
- `PrismBridge` plugin (UE5 5.5) exposes: get selected material instance, set scalar parameter, save asset.
- `PrismApp` in Rust: single window, one card visible (the material color picker), wgpu-rendered HSV wheel.
- Shared-memory parameter stream + local WS control channel.
- Round-trip: pick color → see viewport update within 1 frame → press Save → reopen the project → color is persisted.

**Explicit non-goals:** multi-tool, launcher rail, node wiring, AI palette, blur/bloom, animated icons, installer.

**Success criterion:** A 30-second video shows the round-trip. Cold-start time PrismApp → first interactive paint < 1.5s.

### Phase 2 — Alpha (3 months total / +2 months after PoC)

**Goal:** A coherent, usable subset of the product. Internal dogfooding.

**Deliverables:**
- 8–12 tools, spanning the three integration depth tiers:
  - **Tier 1 (pure UI tools):** color wheel, palette puller (from viewport), gradient designer, curve editor.
  - **Tier 2 (parameter writers):** material color/scalar tweaker, light color/intensity tweaker, post-process slider rig.
  - **Tier 3 (asset writers):** decal placer, palette → curve asset exporter.
- Launcher rail UI with the dark canvas, basic bloom, animated card open/close.
- Cards have wire connections (visual only in alpha — wires carry color/scalar values between two specific tools, not a general node graph).
- 3D-rendered icons for at least the 8 shipping tools.
- Installer (single MSI for `PrismApp` + drop-in plugin folder for `PrismBridge`).
- Telemetry opt-in for crash + perf.
- Supports UE5 5.5 and 5.6.

**Explicit non-goals:** AI command palette (deferred to beta), Mac support, full node-graph, third-party tool SDK.

**Success criterion:** 5 internal users use Prism for a real project task for 1 week and report it saved time.

### Phase 3 — Beta / Early Access (6 months total / +3 months after Alpha)

**Goal:** Shippable to paying early-access users.

**Deliverables:**
- 25–35 tools across all categories from the brief (color, gradient, mesh paint, decals, curves, palette).
- Ctrl+K AI command palette — natural-language tool discovery + parameter setting. Uses a small local model for intent classification + a cloud fallback (user-configurable).
- General node-graph wire system: any tool can publish typed outputs and consume typed inputs.
- Theming (light/dark variants of the canvas, accent colors).
- First-class undo integration with UE5's transaction stack.
- Tool SDK doc (internal) so adding tool #36 takes <1 day.
- Public crash reporting + auto-updater for `PrismApp`.
- Supports UE5 5.5, 5.6, and whatever is current at ship.
- Pricing/licensing integration (license server, offline grace period).

**Explicit non-goals for Beta:** Mac/Linux (Windows-only at launch — UE5 user base is overwhelmingly Windows), public third-party plugin SDK, marketplace.

**Success criterion:** 50 paying EA users, NPS ≥ 30, P95 tool-open latency < 200ms, P95 round-trip latency < 33ms.

---

## 6. Top 5 Technical Risks

### Risk 1 — UE5 game-thread bottleneck under high-frequency writes

**What breaks.** When a user drags a slider at 144Hz, the bridge queues writes faster than the editor tick can drain them. Viewport stutters, slider feels laggy.

**Likelihood:** High. This is the default failure mode of any bridge architecture against UE5.

**Mitigation:**
- Last-value-wins coalescing on the queue (drop intermediate values).
- Shared-memory ring buffer where bridge reads only the most recent sample per tick.
- Profile early in PoC with a torture-test slider — this is one of the PoC success gates.
- If the editor tick rate itself becomes the bottleneck, evaluate `ForceRealtimeViewports` for affected viewports.

### Risk 2 — UE5 version churn breaks the bridge plugin every 6 months

**What breaks.** Epic ships UE5 5.7; private editor APIs we depend on shift. Bridge fails to compile or behaves incorrectly. Customers can't upgrade their UE5 without losing Prism.

**Likelihood:** High. This has happened to every UE5 plugin author across 5.0 → 5.3 → 5.5.

**Mitigation:**
- Keep the bridge surface area small (target <10k LoC).
- Pin to the *most stable* APIs (transaction system, `UEditorAssetLibrary`, `FProperty` reflection) and avoid the *most volatile* (Slate internals, editor module DDC). Where volatile APIs are unavoidable, wrap them in our own seam.
- Bridge IDL is versioned; PrismApp negotiates protocol version on handshake and degrades gracefully for older bridges.
- Maintain a bridge build per supported UE5 version in CI. Don't wait for users to discover breakage.
- Budget: 1 engineer-week per UE5 major release for bridge re-port. Plan it.

### Risk 3 — Visual aesthetic underdelivers vs. brief

**What breaks.** The "luminous 3D-rendered glow" looks cheap in practice. Mockups looked great in Figma; the real product looks like a Discord clone. Brand promise broken.

**Likelihood:** Medium. The technology can deliver, but achieving the *art direction* is its own skill.

**Mitigation:**
- Hire (or contract) a technical artist with real-time PBR + shader-graph experience before Phase 2 begins, not during it.
- Build a "visual gym" mini-app in Phase 1 — a sandbox of 5 icon styles, 3 bloom profiles, 4 card animation styles — and lock the visual language *before* tool authoring scales up.
- Reference benchmarks: the AA app rail visuals (Sky: Children of the Light home screen, Apple's Vision Pro launcher), the bloom/glass of Blender 4.x splash screens, the iconography of Linear's command palette.

### Risk 4 — Asset round-trip corrupts user content

**What breaks.** A bug in the bridge writes wrong-typed data to a `UMaterial` or skips a transaction wrapper. User's asset is broken; if auto-save was on, the broken state is on disk. Trust evaporates.

**Likelihood:** Medium-low (with discipline), but catastrophic when it occurs.

**Mitigation:**
- All writes go through the transaction system. No exceptions. Enforced by code review + a unit test that scans for raw `FProperty` writes outside `FScopedTransaction`.
- Auto-save off by default; explicit user commit. (Section 4.)
- "Prism shadow copy": before any commit, the bridge copies the affected `.uasset` to a `.prism-backup` sibling. Background sweeper trims backups older than 7 days.
- Beta requires a 48-hour internal fuzz run that creates, edits, saves, and reloads 10k assets without corruption.

### Risk 5 — IPC discovery and resilience under editor restarts / multiple UE5 instances

**What breaks.** User has two UE5 editors open. Which one does PrismApp connect to? Or: user crashes the editor mid-session, PrismApp doesn't notice, the next click pushes commands into the void.

**Likelihood:** Medium. Common in practice for users with multiple projects.

**Mitigation:**
- Bridge advertises itself on a known port range (`52310`–`52319`) and writes a discovery file at `%APPDATA%/Prism/instances/<pid>.json` containing port, project path, UE5 version, focus state.
- PrismApp's title bar shows which editor instance it's bound to; clicking switches binding.
- Heartbeat every 1s; on missed heartbeat, PrismApp shows a "disconnected" state and reconnects automatically when the bridge returns.
- Commands carry a session ID; bridge rejects commands from stale sessions after reconnect.

---

## 7. Recommended Tech Stack

Opinionated and specific.

### Languages

- **`PrismBridge` (UE5 plugin):** C++20, UE5 module conventions. No Python in the bridge itself.
- **`PrismApp` (companion process):** Rust (stable channel, MSRV pinned per release).
- **AI command palette intent model:** ONNX runtime, Rust bindings. Optional cloud fallback via OpenAI-compatible API.
- **Build / glue scripts:** PowerShell + a small Rust `xtask` crate. No `make`, no shell scripts that only work on POSIX.

### Build systems

- **`PrismBridge`:** UBT (mandatory — it's a UE5 plugin). Built via a Rust `xtask` wrapper that invokes UAT.
- **`PrismApp`:** Cargo workspace. `cargo-dist` for installer packaging.

### Key Rust dependencies (locked at PoC)

- `wgpu` — GPU rendering.
- `winit` — window/event loop.
- `tiny-skia` + `skia-safe` — 2D rasterization.
- `cosmic-text` — text shaping/layout.
- `tokio` — async runtime for IPC.
- `tungstenite` — local websocket.
- `shared_memory` + a custom ring-buffer crate for SHM transport.
- `serde` + `rkyv` — `serde` for the WS control protocol, `rkyv` for zero-copy SHM frames.
- `tracing` — structured logs.
- `anyhow` / `thiserror` — error handling.

### Toolchain

- **Source control:** Git, GitHub. Submodules only for the UE5 plugin folder structure if required by UBT.
- **CI:** GitHub Actions. Matrix builds for UE5 5.5 and 5.6 on Windows-latest runners. PrismApp builds also on macOS for future portability (but not shipped).
- **Crash reporting:** Sentry (Rust SDK in PrismApp; native breakpad on the bridge).
- **Telemetry:** Self-hosted ClickHouse + a tiny ingest service. Opt-in only.
- **License/auth (Beta):** Keygen.sh or equivalent (build vs. buy decision deferred to Phase 3 kickoff).
- **Designer pipeline:** Figma → Lottie export for animated micro-icons; Blender → glTF for 3D-rendered icons.

### Platform support

- **Phase 1–3:** Windows 10/11 x64 only.
- **Post-Beta:** macOS (Apple Silicon) is the next platform. Linux is not planned; the UE5 editor on Linux is a tiny, technical audience that doesn't justify the test matrix.

### Coding standards (summary)

- **Rust:** `rustfmt` enforced; `clippy::pedantic` allowed-by-default-with-targeted-exceptions; no `unsafe` outside the IPC ring-buffer crate; every public function in the IPC layer has a property test.
- **C++ (bridge):** UE5 conventions (`F`/`U`/`A` prefixes etc.); every editor-state mutation wrapped in `FScopedTransaction`; no static globals; ASan build in CI.
- **Cross-cutting:** every bridge IDL change requires an ADR. The IDL is the contract.

---

## 8. Open Questions (flag for follow-up)

These are decisions I have *not* made and will need user input on before the relevant phase begins:

1. **AI palette hosting model.** Local-only (privacy, latency, hardware cost) vs. cloud-only (capability ceiling, BYOK) vs. hybrid. Decide before Phase 3.
2. **Licensing model.** Per-seat subscription, perpetual + maintenance, or hybrid. Decide before Phase 3.
3. **Third-party tool SDK.** Public after Beta, or never? Affects internal API hygiene from day one.
4. **Fab listing or direct sales.** Affects how the bridge plugin is distributed and discovered.

---

## 9. Validation Criteria — "We'll know this architecture was right if…"

- Phase 1 ships on time with the round-trip latency target met.
- A new tool of average complexity can be added in <3 engineer-days during Phase 2.
- The bridge port from UE5 5.5 → 5.6 takes <1 engineer-week.
- A bug in any single tool never crashes the user's UE5 editor session.
- At Beta, P95 drag-to-viewport latency is under 33 ms on a mid-spec dev workstation.

If any two of these fail, this document should be revisited and a follow-up ADR issued.
