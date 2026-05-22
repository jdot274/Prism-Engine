---
title: "Fake Rendering / Display-Layer Tricks"
category: research
status: research
date: 2026-05-22
source: subagent research run
report_section: "§4"
---

# 4. "Fake Rendering" / Display-Layer Tricks

> _This is the genuinely creative section. Six of these are real shipping techniques; two are speculative._

§4.4 (Gaussian splatting) is the single most important subsection in this report. If you read nothing else, read it.

Related reading: [01-scene-interchange-formats.md](01-scene-interchange-formats.md) for non-display-layer asset interchange; [06-streaming-protocols.md](06-streaming-protocols.md) for the transport bits underlying Pixel Streaming and WebCodecs; [09-experimental-tricks.md](09-experimental-tricks.md) for the latent-diffusion speculative wildcard.

---

## 4.1 UE5 Pixel Streaming 2 (the most "fake" but most polished)

- [Pixel Streaming 2 docs](https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-pixel-streaming-reference), [migration guide](https://github.com/EpicGamesExt/PixelStreamingInfrastructure/blob/master/Docs/pixel-streaming-2-migration-guide.md), [stream tuning](https://dev.epicgames.com/documentation/en-us/unreal-engine/stream-tuning-guide).
- **2026 codec latency**: AV1 (Ada+) ≈ 8.98 ms encode / 15.8 ms decode; H.264 ≈ 8.97 ms / 24.17 ms; VP9 ≈ 15 ms / 50 ms.
- **Capacity**: ~1 user per 2 vCPUs on G4dn/NVadsA10 ([AWS reference](https://aws.amazon.com/blogs/gametech/unreal-engine-pixel-streaming-in-aws-with-ubuntu-os/), [Azure reference](https://learn.microsoft.com/en-us/gaming/azure/reference-architectures/unreal-pixel-streaming-at-scale)). L40S typically does 4–6 1080p60 streams.
- **FOSS alternatives**: [Selkies](https://selkies-project.github.io/selkies/) (MPL-2.0, the credible OSS option since [Hathora shut down May 5, 2026](https://gameye.com/blog/game-server-shake-up-2026/) — migrate to GameFabric or Gameye for orchestration).
- **The "creative" usage**: Don't render the *whole* game via Pixel Streaming. Render it via Pixel Streaming **plus** layer Three.js in the same browser tab as an HTML/WebGL UI overlay (minimap, particles, asymmetric inputs, player-authored cosmetics). The Three.js layer is cheap at 60 fps and offloads UI complexity from the GPU pool.

## 4.2 Reverse direction: Three.js → UE5 video texture

- **WebRTC path**: `canvas.captureStream()` → SFU ([Janus](https://janus.conf.meetecho.com/) / [mediasoup](https://mediasoup.org/) / [LiveKit](https://livekit.io/)) → relay to RTMP/SRT → UE5 Media Framework.
- **Plugins**: [Medialooks Unreal Media Plugin](https://medialooks.com/plugins/unreal-engine-media-plugin), [VlcMedia ue5.6-support fork](https://github.com/online5880/VlcMedia/tree/ue5.6-support) — both write incoming RTSP/SRT to a `UMediaTexture` you can sample in any material.
- **WebCodecs path**: [WebCodecs](https://developer.mozilla.org/en-US/docs/Web/API/WebCodecs_API) gives per-frame `VideoEncoder` chunks at ~1 ms encode in Chromium. Wrap in WebTransport, decode on UE5 side via a custom `IMediaPlayer`. Latency floor ~30–60 ms hardware-accel both sides.
- **Status**: Production for the WebRTC path; experimental for raw WebCodecs.

## 4.3 RGBD / depth-peel transfer

- **Codecs**: [MV-HEVC](https://hevc.hhi.fraunhofer.de/mvhevc) (Apple Vision Pro), 3D-HEVC, [MPEG Immersive Video](https://mpeg-miv.org/). **WebCodecs MV-HEVC decode** landed in Chrome 125+; encode is *not* yet web-exposed.
- **2026 practical recipe**: Three.js renders color + depth to a side-by-side or top-bottom atlas (depth as R32F packed into RGBA8). Send as normal H.264 WebRTC. UE5 material samples both halves, reconstructs world position from depth, renders as either (a) parallax billboard, (b) sparse point cloud via Niagara, or (c) single-frame Gaussian splat surrogate.
- **Research reference**: [CVPR 2024 sandwiched RGB-D paper](https://openaccess.thecvf.com/content/CVPR2024W/AI4Streaming/papers/Hu_One-Click_Upgrade_from_2D_to_3D_Sandwiched_RGB-D_Video_Compression_CVPRW_2024_paper.pdf) gets ~30% bitrate savings.
- **Status**: Experimental. Production-tractable in 12–18 months once WebCodecs adds encode for MV-HEVC.

## 4.4 Gaussian Splatting — **The most important trick in this report**

The only format that gives you *bit-equivalent geometry* in both runtimes without FBX/GLTF. **Treat this as your primary photoreal asset format if your art direction allows it.**

**Format landscape:**
- `.ply` — INRIA reference, large
- `.splat` — [antimatter15](https://github.com/antimatter15/splat) packed binary
- `.ksplat` — [mkkellogg](https://github.com/mkkellogg/gaussiansplats3d) compact (superseded by Spark)
- `.spz` — Niantic, ~10× compression vs `.ply`
- `.sog` — Self-Organizing Gaussians, SuperSplat default
- `.gsd` — DazaiStudio 4DGS sequence container

**Three.js renderers:**

| Renderer | Repo | Notes |
|---|---|---|
| **[Spark (World Labs)](https://github.com/sparkjsdev/spark)** ★ | MIT | v2.1.0 May 2026, LOD streaming, supports PLY/SPZ/SPLAT/KSPLAT/SOG ([blog](https://www.worldlabs.ai/blog/spark-2.0)) |
| [antimatter15/splat](https://github.com/antimatter15/splat) | MIT | WebGL 1.0 hackable reference |
| [SuperSplat](https://github.com/playcanvas/supersplat) | MIT | Editor not renderer; v2.24.4 March 2026 |

**UE5 plugins:**

| Plugin | Repo | License | Notes |
|---|---|---|---|
| **Luma AI Unreal** ★ | [Marketplace](https://www.unrealengine.com/marketplace/) | Proprietary, free | UE 5.3–5.7, drag-drop `.ply`/`.luma`, relighting ([overview](https://radiancefields.com/luma-gaussian-splatting-unreal-engine-plugin-unveiled)) |
| **Volinga Plugin Pro 0.8.0** | [volinga.ai](https://web.volinga.ai/volinga-plugin-pro/) | Commercial | Watermark-free Jan 2026, mesh-relighting, ACES, nDisplay |
| **[DazaiStudio SplatRenderer](https://github.com/DazaiStudio/SplatRenderer-UEPlugin)** | Apache-2.0 | 4DGS via `.gsd`, Level Sequencer keyframing ([v1.1.0](https://github.com/DazaiStudio/SplatRenderer-UEPlugin/releases/tag/v1.1.0)) | |
| [NanoGaussianSplatting](https://github.com/TimChen1383/NanoGaussianSplatting) | MIT | Nanite-style LOD, ~7M splats @ 60 fps on RTX 4070 Ti | |
| [MLSLabs Renderer-Lite](https://github.com/mlslabs/MLSLabsGaussianSplattingRenderer-UE) | Apache-2.0 | High perf, 4DGS playback | |
| [XVerse XV3DGS](https://github.com/xverse-engine/XV3DGS-UEPlugin/) | Apache-2.0 | Niagara emitters, BP integration | |

**Capture-to-game pipeline writeups**: [StraySpark guide](https://www.strayspark.studio/blog/gaussian-splatting-unreal-engine-5-capture-to-game-pipeline), [Magnopus Niagara war-story](https://www.magnopus.com/blog/how-we-wrote-a-gpu-based-gaussian-splats-viewer-in-unreal-with-niagara).

**Gotchas**: Lighting is the open problem — splats are baked radiance, so dynamic UE5 lights need mesh-relit splats (Volinga's feature) or hybrid rendering. Mobile is hostile (WebGL2 fillrate). 4DGS is multi-GB per minute.

**The pattern**: Author once as `.ply` or `.spz`. Spark on the web; Luma/Volinga/SplatRenderer on UE5. **Same bytes.** This is the only realistic 2026 path to "same scene, both engines" without a video stream.

## 4.5 NeRFs — *skip, displaced by Gaussians*

[Volinga deprecated their NeRF workflow](https://help.disguise.one/workflows/3dgs/volinga-3dgs) for 3DGS in 2025; [UE4-NeRF](https://arxiv.org/pdf/2211.13494) never matured into a commercial plugin. Use Gaussians.

## 4.6 Octahedral impostors — *one of the few cleanly-shareable visual assets*

- **UE5**: Official [Impostor Baker plugin](https://dev.epicgames.com/documentation/en-us/unreal-engine/impostor-baker-plugin-in-unreal-engine), bakes 12×12 or 16×16 octahedral atlases.
- **Three.js**: [Ctrlmonster/three-octahedral-impostor](https://github.com/Ctrlmonster/three-octahedral-impostor) (WIP); stalled [PR #22043](https://github.com/mrdoob/three.js/pull/22043).
- **Shared artifact**: Bake the atlas in UE5; ship the resulting `Texture2D` to web. Both shaders consume the same octahedron→sprite math. Common in older AAA mobile games — Hearthstone, Marvel Strike Force.

## 4.7 Spout / NDI / Syphon — *local zero-copy bridges*

- **Spout (Windows)**: [UE5_Spout2_DX12](https://github.com/GPUbrainStorm/UE5_Spout2_DX12) v2.0.1 (March 2026, UE 5.2.1–5.7.2). Zero-copy D3D12 texture share. **Web side**: [SpoutBrowser](https://github.com/bntre/SpoutBrowser) (Feb 2026) — a forked Chromium that publishes its WebGL/WebGPU framebuffer to Spout. UE5 samples it as a regular material texture. **Sub-frame latency. No encoder.**
- **NDI (network)**: [Official NDI Unreal SDK v3.8](https://ndi.video/for-developers/ndi-unreal-engine-sdk/). Wrap `canvas.captureStream()` → MediaRecorder → ffmpeg-relay → NDI in <100 ms. No first-party browser source.
- **Syphon (macOS)**: Counterpart to Spout. Skip for a Windows-first UE5 server.
- **Status**: Production for **local installations**, kiosks, devkits, asymmetric VR. Not useful for shipped multiplayer (the Spout share is local-only).

## 4.8 WebView2 / CEF / Coherent Gameface — Three.js inside UE5

- **CEF**: [UCefView](https://cefview.github.io/UCefView/) (cross-platform, UE 5.0–5.7), [Uranium](https://github.com/microdee/Uranium), built-in [`WebBrowser`](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/WebBrowser?application_version=5.7).
- **WebView2 (Windows)**: [SteveSantoso/CBWebView2](https://github.com/SteveSantoso/CBWebView2) — platform-native Edge engine, full UMG support, JS↔UE message bridge, IME-aware.
- **Coherent Gameface v3.0.1.1** (May 12, 2026) — commercial, AAA-only license.
- **WebGPU**: WebView2 has it (follows Edge stable); CEF lags by ~6 months.
- **Use case**: Render a Three.js minimap, UI, or asymmetric 2D scene as part of the UE5 HUD. Single-process CEF/WebView2 textures cap at ~30 fps for non-trivial 3D content — don't run the whole game inside.

## 4.9 Vulkan / D3D12 shared-memory texture interop

- [VK_KHR_external_memory](https://registry.khronos.org/vulkan/specs/1.3-extensions/man/html/VK_KHR_external_memory.html) + `VK_KHR_external_memory_win32`; D3D12 `OpenSharedHandle`.
- **Could Chromium expose this to UE5?** **Not in a stock build** — the GPU process is sandboxed, the shared handle is private to renderer↔gpu-process IPC. Spout is the publicly-blessed escape hatch. With a *custom* Electron/CEF build you can punch a handle out via FFI — that's [electron-texture-bridge (April 2026)](https://github.com/naporin0624/electron-texture-bridge)'s entire premise.

## 4.10 Latent video diffusion world models — *the speculative wildcard*

- **Matrix-Game 3.0** ([arXiv 2604.08995](https://arxiv.org/html/2604.08995)): 40 FPS @ 720p, 5B-param world model on H100, minute-long memory consistency.
- **LTX-Video** ([arXiv 2501.00103](https://arxiv.org/html/2501.00103)): 5 s @ 24 fps in 2 s on H100.
- **GameNGen** ([arXiv 2408.14837](https://arxiv.org/html/2408.14837)): DOOM at 20 FPS as a diffusion model.
- **HY-WorldPlay (Tencent)**: 24 FPS streaming ([HF model](https://huggingface.co/tencent/HY-WorldPlay/blob/refs%2Fpr%2F1/README.md)).
- **AlayaRenderer ([ShandaAI](https://github.com/ShandaAI/AlayaRenderer))**: Fine-tunes diffusion to *re-render* AAA G-buffers in a different style.
- **Cost**: ~1 H100 per player. Absurd for indie in 2026. **Watch this space, don't ship on it.**

## 4.11 Best bets in this domain

1. **Gaussian Splatting (Spark + Luma/Volinga/DazaiStudio)** as the shared photoreal geometry format.
2. **Pixel Streaming 2 + Three.js HTML overlay** as the cloud-render fallback tier.
3. **SpoutBrowser + UE5_Spout2_DX12** for any local-machine asymmetric setup (devkits, location-based, VR hardware).

---

**Up next:** [05 — UE5 for physics/networking only](05-ue5-physics-only-architecture.md). **Back to:** [README](README.md).
