# Prism Tool Catalog
> Version 0.1 — authored 2026-05-21
> Status: Pre-production planning document

---

## Table of Contents

1. [Full Tool Catalog](#1-full-tool-catalog)
   - [Color & Material Tools](#color--material-tools)
   - [Geometry & Mesh Tools](#geometry--mesh-tools)
   - [Lighting Tools](#lighting-tools)
   - [Animation & Motion Tools](#animation--motion-tools)
   - [Audio Tools](#audio-tools)
   - [Level Design / World Building Tools](#level-design--world-building-tools)
   - [VFX / Particle Tools](#vfx--particle-tools)
   - [UI / HUD Design Tools](#ui--hud-design-tools)
   - [Data / Balance Tools](#data--balance-tools)
   - [Asset Management Tools](#asset-management-tools)
   - [Debugging / Profiling Tools](#debugging--profiling-tools)
   - [Shader & Texture Tools](#shader--texture-tools)
   - [Collaboration & Review Tools](#collaboration--review-tools)
2. [Priority Tiers](#2-priority-tiers)
3. [Three Deep-Dive Tool Specs](#3-three-deep-dive-tool-specs)
4. [The 5 Killer Tools](#4-the-5-killer-tools)
5. [Tools That Should NOT Be Built](#5-tools-that-should-not-be-built)

---

## 1. Full Tool Catalog

### Difficulty & Value Key
- **Difficulty:** S = very hard (custom renderer, deep engine fork, novel algorithm), A = hard (complex UE5 API surface, significant state management), B = moderate (well-documented UE5 APIs, standard UI patterns), C = straightforward (thin UI wrapper over existing UE5 functionality)
- **Value:** 1 = minor convenience, 5 = eliminates an entire external app

---

### Color & Material Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 1 | **3D HSL Color Wheel** | Spherical hue/saturation/luminance picker with live material preview on selected mesh | Reads/writes `UMaterialInstanceDynamic` scalar and vector parameters; hooks `FEditorDelegates::OnAssetPostImport` for live preview | S | 5 |
| 2 | **Gradient Designer** | Multi-stop gradient editor that outputs UE5 Curve Linear Color assets or material gradient textures | Reads/writes `UCurveLinearColor`; can bake to `UTexture2D` via `FImageUtils` | A | 4 |
| 3 | **Palette Extractor** | Drag a reference image in; auto-extracts a 5–8 color palette and applies it to a selected material's parameter collection | Reads `UTexture2D` pixel data; writes `UMaterialParameterCollection` | B | 4 |
| 4 | **Material Slot Mapper** | Shows all material slots on a selected static mesh as a visual grid; click any slot to open a mini color/material picker inline | Reads `UStaticMeshComponent::GetMaterials()`; writes per-slot material overrides | B | 3 |
| 5 | **Tone Mapper Preview** | Side-by-side comparison of up to 4 post-process tone mapper presets on the current viewport frame | Reads/writes `UPostProcessComponent` settings; captures viewport via `FViewport::ReadPixels` | A | 4 |
| 6 | **Material Comparator** | Two-up diff of any two materials with labeled parameter deltas highlighted in red/green | Reads `UMaterial` and `UMaterialInstance` parameter tables via `UMaterialInterface::GetAllScalarParameterInfo` | B | 3 |
| 7 | **PBR Validator** | Checks selected material against PBR physically correct value ranges (albedo 30–240, metallic 0 or 1, etc.) and reports violations | Reads material scalar/vector parameters; no write; outputs a diagnostic list | B | 4 |
| 8 | **Swatch Library** | Persistent color swatch palettes synced to `UMaterialParameterCollection`; drag a swatch onto any actor to apply | Reads/writes `UMaterialParameterCollection`; drag target calls `AActor::SetMaterial` | C | 3 |
| 9 | **Decal Brush Painter** | Paint decals onto mesh surfaces with controllable size, opacity, angle, and blend mode in real time | Uses `UDecalComponent`; raycasts via `FEditorViewportClient::GetHitResultUnderCursor` | A | 4 |
| 10 | **Color Temperature Wheel** | Kelvin-based color temperature picker (1000K–12000K) with direct Blackbody material output | Writes `UMaterialInstanceDynamic` vector parameter; computes CIE 1931 chromaticity internally | B | 3 |

---

### Geometry & Mesh Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 11 | **Mesh Stats HUD** | Live panel showing triangle count, UV channel count, LOD levels, and draw calls for selected mesh | Reads `UStaticMesh::GetRenderData()`; reads `FStaticMeshLODResources` | C | 3 |
| 12 | **LOD Tuner** | Visual slider controls for each LOD's screen-size threshold with live viewport feedback | Reads/writes `UStaticMesh::SourceModels[n].ScreenSize`; triggers `UStaticMesh::Build()` | B | 4 |
| 13 | **Pivot Relocator** | Click anywhere on a mesh in the viewport to set the world-space pivot without leaving context | Uses `UMeshEditingToolsEditorModeToolkit`; writes `AActor::SetActorTransform` after pivot offset | B | 4 |
| 14 | **Boolean Visualizer** | Shows a live boolean (union/intersect/subtract) preview between two selected meshes before committing | Uses `UGeometryScriptLibrary_MeshBooleanFunctions`; preview via temp `UDynamicMeshComponent` | A | 4 |
| 15 | **UV Checker** | Overlays a procedural UV checker texture onto selected mesh with grid scale control | Writes a temporary `UMaterialInstanceDynamic` override on selection; removes on close | C | 3 |
| 16 | **Vertex Painter** | Per-vertex color painting on `UStaticMeshComponent` with brush size/falloff controls | Reads/writes `FStaticMeshComponentLODInfo::OverrideVertexColors` | A | 4 |
| 17 | **Snap Grid Designer** | Visual design of custom snap grids (irregular spacing, rotational snap presets) per-level | Reads/writes `ULevelEditorViewportSettings` snap values via `GEditor` | B | 3 |
| 18 | **Modular Snap Assistant** | Detects modular kit pieces and suggests auto-snapping positions/rotations based on their bounding boxes | Reads `UStaticMeshComponent` bounds; writes `AActor` transforms | A | 4 |
| 19 | **Proxy Mesh Previewer** | Generates and previews a merged proxy mesh from a selection before committing to disk | Uses `IMeshMerging::CreateProxyMesh`; output to temp `UStaticMesh` | A | 3 |
| 20 | **Spline Mesh Shaper** | Visual tangent handle editor for `USplineMeshComponent` with real-time preview | Reads/writes `USplineComponent` control points and tangents | B | 4 |

---

### Lighting Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 21 | **Light Mixer** | Multi-light intensity/color/temperature mixer; like a stage lighting board for all lights in the scene | Reads/writes `ULightComponent` intensity, color temp, and `bUseTemperature`; uses `ILightingViewportClient` | A | 5 |
| 22 | **HDRI Swapper** | Thumbnail grid of all HDRIs in the project; one-click swap on the scene's Sky Light with live preview | Reads `USkyLightComponent::Cubemap`; writes via `USkyLightComponent::SetCubemap` | C | 4 |
| 23 | **Shadow Inspector** | Overlays shadow cascade boundaries in the viewport; adjust cascade distances via visual drag handles | Reads/writes `UDirectionalLightComponent` cascade shadow map distances | B | 3 |
| 24 | **Lumen Probe Visualizer** | Renders and displays Lumen radiance cache probe positions in the current level as a point cloud overlay | Reads Lumen `ILumenSceneData` debug buffers; read-only display tool | S | 3 |
| 25 | **Exposure Ramp** | Timeline scrubber showing auto-exposure EV100 values over a 10-second simulated scene play; flag problem frames | Reads `UPostProcessComponent` min/max brightness; hooks `FEngineShowFlags` | B | 3 |
| 26 | **Light Budget Tracker** | Shows per-light GPU cost estimate (shadow casting, resolution) against a configurable budget bar | Reads `ULightComponent` shadow settings; uses `FSceneView` stat data | B | 4 |
| 27 | **IES Profile Loader** | Drag-and-drop IES photometric files onto point/spot lights with instant viewport preview | Reads/writes `UPointLightComponent::IESTexture`; imports via `FIESLoader` | B | 3 |
| 28 | **Light Linking Panel** | Visual matrix showing which lights affect which actor groups; toggle cells to override light channel masks | Reads/writes `FLightingChannels` on both actors and lights | A | 4 |
| 29 | **Time-of-Day Scrubber** | Single slider mapping to `UDirectionalLightComponent` rotation + sky atmosphere + exponential height fog blended presets | Reads/writes directional light pitch, `USkyAtmosphereComponent` parameters | B | 4 |
| 30 | **Emissive Harvester** | Finds all emissive materials in the scene and offers one-click "promote to real light" conversion | Reads material emissive values; creates `URectLightComponent` or `UPointLightComponent` in place | B | 3 |

---

### Animation & Motion Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 31 | **Curve Editor Lite** | Compact float curve editor for single-variable animation curves with easing preset buttons | Reads/writes `UCurveFloat`; triggers `FAssetEditorManager::OpenEditorForAsset` on expand | B | 3 |
| 32 | **Physics Curve Editor** | Drag-edit physical simulation response curves (bounce, friction, damping) with live ragdoll preview | Reads/writes `UPhysicsAsset` constraint profiles; triggers `USkeletalMeshComponent::RecreatePhysicsState` | S | 4 |
| 33 | **Blend Space Visualizer** | 2D heat-map view of a `UBlendSpace` showing coverage gaps and redundant samples | Reads `UBlendSpace` sample points and axes; read-only with suggestion annotations | B | 4 |
| 34 | **Anim Notify Timeline** | Compact single-track view of all `UAnimNotify` events on a selected animation sequence | Reads `UAnimSequence::Notifies`; writes notify add/remove/move via existing Anim Sequence API | B | 3 |
| 35 | **Root Motion Preview** | Plots root motion trajectory as a 3D spline in the viewport for a selected animation sequence | Reads `UAnimSequence` root motion curves; renders via `FPrimitiveDrawInterface` | B | 3 |
| 36 | **Sequencer Clip Browser** | Thumbnail strip of all `ULevelSequence` assets; drag one onto an actor to bind it instantly | Reads `ULevelSequence` assets via Asset Registry; writes bindings via `FMovieSceneBinding` | B | 3 |
| 37 | **IK Reach Debugger** | Shows IK chain reach radii as transparent spheres in the viewport for selected skeletal mesh | Reads `UIKRig` chain definitions; renders debug geometry | B | 3 |
| 38 | **Control Rig Quick Pose** | Stores and recalls named Control Rig poses with one click; like bookmarks for rig positions | Reads/writes `UControlRig` control transforms via `FRigControlElement` | A | 4 |
| 39 | **Timeline Minimap** | Thumbnail-density overview of the current Sequencer timeline showing clip density and gaps | Reads `UMovieScene` track/section data; read-only navigation aid | C | 3 |
| 40 | **Transition Graph Compressor** | Scans an `UAnimStateMachine` for redundant or unreachable transitions and suggests removal | Reads `UAnimStateMachine` node graph; write suggestions require user approval | A | 3 |

---

### Audio Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 41 | **Sound Cue Mixer** | Compact fader board for all `UAudioComponent` instances in the current level with solo/mute | Reads/writes `UAudioComponent` volume multipliers; hooks `FAudioDevice` | B | 4 |
| 42 | **Attenuation Visualizer** | Renders sound attenuation spheres/capsules for all audio sources as colored overlays in viewport | Reads `FSoundAttenuationSettings` from `UAudioComponent`; renders debug shapes | C | 3 |
| 43 | **Metasound Patch Bay** | Visual I/O matrix for `UMetaSoundSource` parameter pins; wire them to Blueprint variables | Reads/writes `UMetaSoundSource` input parameters via `IMetaSoundParameterInterface` | S | 4 |
| 44 | **MIDI Note Preview** | Plays back a MIDI file and previews how it maps to in-game MetaSound triggers | Hooks `FMIDIFileReader`; sends to `UMetaSoundSource` parameter interface | A | 3 |
| 45 | **Reverb Zone Painter** | Paint reverb volumes directly onto a top-down level map with blend radius visualization | Creates/edits `UAudioVolume` with `FReverbSettings`; uses editor brush tools | B | 3 |
| 46 | **Waveform Scrubber** | Waveform display of a selected `USoundWave` with loop-point drag handles | Reads `USoundWave` PCM data via `USoundWave::GetPCMBuffer`; writes loop points | B | 3 |

---

### Level Design / World Building Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 47 | **Scatter Brush** | Paint static mesh instances across a surface with density, scale, and rotation randomization controls | Uses `UInstancedStaticMeshComponent`; raycasts via `FEditorViewportClient` line trace | B | 5 |
| 48 | **Room Planner** | 2D top-down grid view of the current level chunk with drag-to-resize rooms and auto-wall generation | Reads actor transforms from `UWorld::GetCurrentLevel`; writes `AActor` placement | A | 4 |
| 49 | **Foliage Density Map** | Heatmap overlay showing foliage instance density per-cell; click-to-thin dense areas | Reads `UFoliageInstancedStaticMeshComponent` instance data; writes removal | B | 4 |
| 50 | **Streaming Volume Wizard** | Guides you through creating correctly sized `ALevelStreamingVolume` around a selected group of actors | Reads actor bounds; creates/writes `ALevelStreamingVolume` with computed extents | B | 3 |
| 51 | **Navigation Mesh Preview** | Single-button live recast nav mesh bake with colored reachability overlay by agent type | Calls `UNavigationSystemV1::Build()`; reads `ARecastNavMesh` tile data | B | 4 |
| 52 | **Grid Ruler** | Drop measurement rulers in the viewport that display world-unit distances between two points | Uses `FPrimitiveDrawInterface` debug lines; read-only world-space overlay | C | 3 |
| 53 | **Blueprint Spawner Pad** | Drag any Blueprint class from the tool's list directly into the viewport at cursor position | Reads Asset Registry for `UBlueprint` assets; calls `GEditor->ClickPlacingActorsBegin` pattern | C | 3 |
| 54 | **Biome Brush** | Paints landscape layer weights (grass, rock, sand) using a radius brush with falloff | Reads/writes `ULandscapeComponent` layer weight data | A | 4 |
| 55 | **Collision Profile Painter** | Batch-set collision profiles on selected actors via dropdown; shows current profile per actor in list | Reads/writes `UPrimitiveComponent::SetCollisionProfileName` | C | 3 |

---

### VFX / Particle Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 56 | **Niagara Emitter Scrubber** | Playback scrubber for a selected Niagara system with pause/step/loop controls in a compact card | Reads/writes `UNiagaraComponent` playback state; hooks `FNiagaraSystemSimulation` | B | 4 |
| 57 | **Particle Budget Meter** | Live particle count and GPU particle texture sample budget gauge for all active Niagara systems | Reads `UNiagaraComponent::GetActiveParticleCount()`; reads Niagara performance stats | B | 4 |
| 58 | **VFX Color Override** | Overrides the primary color parameter of any Niagara emitter with a color picker, non-destructively | Reads/writes Niagara user-exposed `FNiagaraVariable` of type `FLinearColor` | B | 3 |
| 59 | **Fluid Simulation Tuner** | Compact parameter panel for Niagara Fluids (viscosity, surface tension, vorticity) with preset library | Reads/writes Niagara Fluids `UNiagaraDataInterfaceGrid3D` parameters | S | 4 |
| 60 | **Decal Lifetime Animator** | Visual timeline for `UDecalComponent` fade-in/fade-out with curve editor | Reads/writes `UDecalComponent::FadeStartDelay`, `FadeDuration`; previews in viewport | C | 3 |

---

### UI / HUD Design Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 61 | **UMG Theme Editor** | Edit a shared style/theme (font, color, padding tokens) that propagates to all UMG widgets referencing it | Reads/writes `UWidgetBlueprintGeneratedClass` style data via Designer property system | A | 4 |
| 62 | **Widget Spacing Grid** | Overlay a configurable baseline grid and spacing guides onto the UMG Designer canvas | Hooks UMG Designer viewport; renders overlay via `FEditorViewportClient` | B | 3 |
| 63 | **HUD Safe Zone Tester** | Previews TV and mobile safe-zone masks on the viewport at 16:9, 16:10, 4:3, and ultrawide aspect ratios | Renders overlay rect via `FViewport::Draw`; reads `FDisplayMetrics::GetDisplayMetrics` | B | 3 |
| 64 | **Icon Atlas Builder** | Drag a folder of icon PNGs in; outputs a `UTexture2D` atlas and matching `UDataTable` UV manifest | Uses `FImageUtils::CreateTexture2D`; writes via `AssetToolsModule.CreateAsset` | B | 4 |
| 65 | **Widget Performance Profiler** | Shows render call count, overdraw, and invalidation rate per widget in a running pie | Reads `FSlateDrawElement` stats; hooks `FSlateApplication::GetStats` | A | 4 |
| 66 | **Localization Preview** | Live-swaps the active locale in the viewport to preview translated text wrapping/overflow | Calls `FInternationalization::SetCurrentCulture`; restores on card close | B | 4 |
| 67 | **Responsive Layout Tester** | Resizes the game viewport to common device resolutions with one click and reports layout breaks | Calls `FSystemResolution::RequestResolutionChange`; marks break annotations | B | 3 |

---

### Data / Balance Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 68 | **Curve Balancer** | Side-by-side visual editor for game economy curves (XP, damage, cost) with formula overlay | Reads/writes `UCurveFloat` and `UCurveTable`; renders chart inline | B | 5 |
| 69 | **DataTable Diff** | Two-column visual diff of two `UDataTable` snapshots with changed rows highlighted | Reads `UDataTable` via `FDataTableEditorUtils`; read-only display | B | 4 |
| 70 | **Stat Variable Monitor** | Live chart of any Blueprint variable (float/int) on any running actor during PIE | Uses `FBlueprintCoreDelegates` property watcher; hooks PIE start/stop events | A | 4 |
| 71 | **Probability Inspector** | Enter a loot table (item/weight pairs); shows a histogram of expected drop distribution over N trials | Pure logic tool; writes back to a `UDataTable` loot table row | C | 4 |
| 72 | **Formula Node** | Scratchpad calculator with live bindings to DataTable column values; export result as a new column | Reads `UDataTable` column types; writes new row entries | B | 3 |
| 73 | **Balance Snapshot** | Saves a named snapshot of all `UCurveFloat` values in a package; diffs against current to show drift | Reads curve assets; writes snapshot JSON to project `Saved/` dir | B | 3 |

---

### Asset Management Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 74 | **Orphan Asset Finder** | Scans the content browser for unreferenced assets; shows dependency graph before deletion | Reads `FAssetRegistry` reference data; deletion calls `ObjectTools::DeleteAssets` | B | 4 |
| 75 | **Texture Budget Tracker** | Shows per-texture memory footprint vs. a configurable VRAM budget with overbudget flagging | Reads `FTexturePlatformData::Mips` size data; read-only | B | 4 |
| 76 | **Asset Renamer** | Batch rename with regex find/replace + prefix/suffix with live preview before committing | Uses `FAssetRenameManager`; supports undo via transaction | B | 3 |
| 77 | **Redirect Cleaner** | Lists all `ObjectRedirector` assets and offers one-click mass fixup and deletion | Reads Asset Registry for `UObjectRedirector`; calls `AssetTools.FixupReferencers` | C | 3 |
| 78 | **Material Instance Flattener** | Collapses a chain of `UMaterialInstance` overrides into a single MI preserving effective values | Reads MI parent chain via `UMaterialInstance::GetParent()`; writes a new flat MI | B | 3 |
| 79 | **Import Settings Batch Editor** | Edit `UAssetImportData` reimport settings across multiple selected assets simultaneously | Reads/writes `UAssetImportData` source paths and settings | B | 3 |
| 80 | **Asset Size Treemap** | Interactive treemap of project content folder sizes down to individual asset level | Reads `FAssetRegistry` asset sizes; read-only navigation | B | 3 |

---

### Debugging / Profiling Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 81 | **Blueprint Breakpoint Manager** | Lists all active Blueprint breakpoints across the project with jump-to and batch-disable controls | Reads `UBlueprint::DebugData.BreakpointMap`; writes enable/disable state | B | 3 |
| 82 | **Console Command Palette** | Searchable, categorized, pinnable list of all registered UE5 console commands with descriptions | Reads `IConsoleManager::ForEachConsoleObjectThatStartsWith`; executes via same API | C | 4 |
| 83 | **Tick Budget Profiler** | Live bar chart of per-actor tick costs in ms during PIE with freeze-and-inspect mode | Hooks `FTickTaskManager` stat output; reads `FActiveObjectIterator` | A | 5 |
| 84 | **Actor Inspector** | Compact property browser for a selected actor showing only non-default-value properties highlighted | Reads `FProperty` values via UObject reflection; writes via `FPropertyChangedEvent` | B | 4 |
| 85 | **Memory Flamegraph** | Flamegraph-style visualization of object allocation by class during a PIE session | Hooks `FMalloc` tracking or reads LLM tracker output; read-only | S | 4 |
| 86 | **Network Condition Simulator** | Sliders for packet loss %, latency, and jitter that hot-apply to `UNetDriver` simulation settings | Reads/writes `UNetDriver::MaxInternetClientRate` and simulation vars | B | 4 |
| 87 | **Log Filter Board** | Real-time `UE_LOG` output with per-category toggle, severity filter, and keyword highlight | Hooks `FOutputDevice`; read-only display | B | 3 |
| 88 | **Shader Compile Queue** | Live list of in-flight shader compilations with per-shader estimated time and cancel button | Reads `GShaderCompilingManager` queue; cancel calls `GShaderCompilingManager->CancelCompilation` | B | 3 |

---

### Shader & Texture Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 89 | **Texture Channel Viewer** | Shows R/G/B/A channels of any texture in isolation with histogram per channel | Reads `UTexture2D` mip data; renders via a custom `UMaterialInstanceDynamic` | B | 3 |
| 90 | **Normal Map Validator** | Runs a per-texel normalization check on a normal map and overlays problem regions in red | Reads `UTexture2D` pixel data; read-only annotation overlay | B | 3 |
| 91 | **Substance-to-UE5 Mapper** | Maps Substance parameter names to equivalent UE5 material parameter names in bulk | Reads MI parameter names; writes a rename mapping JSON; applies via batch rename | B | 4 |
| 92 | **Heightmap Sculptor** | Compact sculpt/smooth/flatten brushes for `ULandscapeComponent` height data | Reads/writes `ULandscapeComponent` height data via `FLandscapeEditDataInterface` | A | 4 |
| 93 | **Texture Resolution Downscaler** | Batch downsample selected textures with format and mip settings preview before committing | Reads `UTexture2D` source data; writes via `FTextureBuildSettings` reimport | B | 3 |
| 94 | **Channel Packer** | Pack R/G/B/A from up to 4 source textures into a single output texture (ORM packer) | Reads multiple `UTexture2D` assets; writes new `UTexture2D` via `FImageUtils` | B | 4 |

---

### Collaboration & Review Tools

| # | Name | Description | UE5 Integration Point | Difficulty | Value |
|---|------|-------------|----------------------|------------|-------|
| 95 | **Screenshot Annotator** | Capture viewport, draw on it, and save annotated PNG + metadata JSON to a review folder | Reads viewport via `FHighResScreenshotConfig`; writes to `Saved/Reviews/` | C | 3 |
| 96 | **Change Diff Viewer** | Shows a before/after split of actor property changes since last source-control sync | Reads current UObject state vs. source control base via `ISourceControlProvider` | A | 3 |
| 97 | **Task Pin Board** | In-editor sticky notes pinned to world-space locations; persists in a JSON sidecar file | Uses `FEditorViewportClient` world-space overlays; no UE5 asset writes | B | 3 |
| 98 | **Build Report Card** | Summarizes the last cook/build output (errors, warnings, asset counts) as a scannable dashboard | Reads `Saved/Logs/` cook log; parses error patterns; read-only display | C | 3 |

---

**Total tools cataloged: 98**

---

## 2. Priority Tiers

### Tier 1 — Ship First (Hero Launch Set)
*8 tools. Collectively tell the story: "Prism eliminates Blender color workflows, Photoshop palette work, and the missing lighting board that UE5 never shipped."*

| # | Tool | Rationale |
|---|------|-----------|
| 1 | **3D HSL Color Wheel** | The product's signature demo moment. Nothing like it exists in UE5. Visual proof of concept. |
| 2 | **Gradient Designer** | Complements the color wheel; completes the "color authoring" story without leaving UE5. |
| 3 | **Light Mixer** | Eliminates the biggest daily pain for any environment artist — tweaking 20 lights one at a time. |
| 4 | **Scatter Brush** | Eliminates Houdini/Blender scatter for the vast majority of indie use cases. Highly visual. |
| 5 | **Curve Balancer** | No indie team has a real economy curve tool. This is Desmos inside UE5. Immediate wow factor. |
| 6 | **Tick Budget Profiler** | Developers stay in flow instead of alt-tabbing to Unreal Insights for simple tick cost questions. |
| 7 | **PBR Validator** | Immediate value, low effort, builds trust that Prism actively prevents mistakes. |
| 8 | **Channel Packer** | Replaces a Photoshop/Affinity workflow that every UE5 artist does manually every week. |

---

### Tier 2 — Alpha Expansion (Months 1–3)
*18 tools. Deepens each launch category and adds Audio and Data verticals.*

| # | Tool |
|---|------|
| 9 | Palette Extractor |
| 10 | Tone Mapper Preview |
| 11 | LOD Tuner |
| 12 | Boolean Visualizer |
| 13 | Vertex Painter |
| 14 | HDRI Swapper |
| 15 | Time-of-Day Scrubber |
| 16 | Light Budget Tracker |
| 17 | Niagara Emitter Scrubber |
| 18 | Particle Budget Meter |
| 19 | Sound Cue Mixer |
| 20 | Attenuation Visualizer |
| 21 | DataTable Diff |
| 22 | Probability Inspector |
| 23 | Texture Budget Tracker |
| 24 | Orphan Asset Finder |
| 25 | Actor Inspector |
| 26 | Console Command Palette |

---

### Tier 3 — Beta / GA
*All remaining tools, organized by category for staged release.*

**Color & Material:** Material Slot Mapper, Material Comparator, Swatch Library, Decal Brush Painter, Color Temperature Wheel

**Geometry & Mesh:** Mesh Stats HUD, Pivot Relocator, UV Checker, Snap Grid Designer, Modular Snap Assistant, Proxy Mesh Previewer, Spline Mesh Shaper

**Lighting:** Shadow Inspector, Lumen Probe Visualizer, Exposure Ramp, IES Profile Loader, Light Linking Panel, Emissive Harvester

**Animation & Motion:** Curve Editor Lite, Blend Space Visualizer, Anim Notify Timeline, Root Motion Preview, Sequencer Clip Browser, IK Reach Debugger, Control Rig Quick Pose, Timeline Minimap, Transition Graph Compressor

**Audio:** Metasound Patch Bay, MIDI Note Preview, Reverb Zone Painter, Waveform Scrubber

**Level Design / World Building:** Room Planner, Foliage Density Map, Streaming Volume Wizard, Navigation Mesh Preview, Grid Ruler, Blueprint Spawner Pad, Biome Brush, Collision Profile Painter

**VFX / Particle:** VFX Color Override, Fluid Simulation Tuner, Decal Lifetime Animator

**UI / HUD Design:** UMG Theme Editor, Widget Spacing Grid, HUD Safe Zone Tester, Icon Atlas Builder, Widget Performance Profiler, Localization Preview, Responsive Layout Tester

**Data / Balance:** Stat Variable Monitor, Formula Node, Balance Snapshot

**Asset Management:** Asset Renamer, Redirect Cleaner, Material Instance Flattener, Import Settings Batch Editor, Asset Size Treemap

**Debugging / Profiling:** Blueprint Breakpoint Manager, Memory Flamegraph, Network Condition Simulator, Log Filter Board, Shader Compile Queue

**Shader & Texture:** Texture Channel Viewer, Normal Map Validator, Substance-to-UE5 Mapper, Heightmap Sculptor, Texture Resolution Downscaler

**Collaboration & Review:** Screenshot Annotator, Change Diff Viewer, Task Pin Board, Build Report Card

---

## 3. Three Deep-Dive Tool Specs

---

### Spec A: 3D HSL Color Wheel

#### Card Layout (480x480dp)

```
┌──────────────────────────────────────────────────────┐  ← 480dp wide
│  ● 3D HSL Color Wheel          [M] [Pin] [×]         │  ← 32dp header bar
├──────────────────────────────────────────────────────┤
│                                                      │
│              ┌──────────────────┐                    │
│              │                  │                    │
│              │  HSL Sphere      │   ┌──────────────┐ │
│              │  (240dp diam.)   │   │ Live Preview │ │
│              │  3D rendered,    │   │  (120x120dp) │ │
│              │  rotatable       │   │  Mesh swatch │ │
│              │                  │   │  real-time   │ │
│              └──────────────────┘   └──────────────┘ │
│                                                      │
│  H  [────────●────────────────]   000°               │  ← Hue readout
│  S  [──────────────●──────────]   075%               │  ← Sat readout
│  L  [──────●──────────────────]   045%               │  ← Lum readout
│                                                      │
│  ┌─────────────────────────────────────────────────┐ │
│  │  A  [──────────────────────●──]   100%          │ │  ← Alpha
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  HEX [#7F3F1A      ]  sRGB [ 0.498 / 0.247 / 0.102 ] │  ← Text inputs
│                                                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────┐  │
│  │ HSL     │ │ sRGB    │ │ Linear  │ │ Kelvin    │  │  ← Mode tabs
│  └─────────┘ └─────────┘ └─────────┘ └───────────┘  │
│                                                      │
│  Recent: ■ ■ ■ ■ ■ ■ ■ ■     [ Apply ] [ Copy ]     │  ← Bottom bar
└──────────────────────────────────────────────────────┘
```

#### Interactive Elements

**HSL Sphere (primary interaction surface)**
- Rendered as a 3D sphere in a headless offscreen render target (512x512), composited onto the card.
- Hue maps to longitude; Saturation maps to radial distance from the polar axis; Luminance maps to the vertical latitude band.
- Left-drag rotates the sphere to reach any color. The selected color point is shown as a glowing white dot with a thin corona ring.
- Right-drag or two-finger-scroll zooms into the sphere for fine color selection.
- The sphere surface shader uses a custom `UMaterialInstance` that renders the HSL space directly as a procedural texture. No CPU pixel buffer; the GPU does the color math.
- Hover state: the point under the cursor shows a 2dp tooltip with color preview and hex value.

**H / S / L Sliders**
- Sliders are live-linked to the sphere: dragging a slider moves the selection dot on the sphere.
- Each slider background is itself a gradient rendered by the card's shader (H slider shows the full hue rainbow; S slider shows the current hue at 0–100% saturation; L slider shows black→current hue→white).
- Click the numeric readout to type a value directly; Enter or Tab to commit.

**Alpha Slider**
- Only affects materials that have opacity inputs. If the selected material has no opacity pin, the slider is grayed out with a tooltip: "Selected material does not expose opacity."

**HEX and sRGB text inputs**
- Hex input accepts 6-digit (#RRGGBB) or 8-digit (#RRGGBBAA). Invalid input highlighted in red; reverts on blur.
- sRGB fields accept 0.0–1.0. Out-of-gamut values clamped with a warning chip ("Clamped to sRGB").

**Mode Tabs**
- HSL: default; spherical view.
- sRGB: flat square picker (like Photoshop color picker) — Hue on the horizontal rail, SV on the square.
- Linear: same as sRGB but inputs/outputs are linear (no gamma). Labeled "Linear (no gamma)" for clarity.
- Kelvin: replaces all controls with a single Kelvin temperature slider (1000K–12000K) and a neutral brightness slider.

**Live Preview Mesh**
- Displays the currently selected actor's mesh (or a default sphere if nothing is selected) with the color applied as a `UMaterialInstanceDynamic` parameter in a headless viewport capture.
- Thumbnail refreshes at 15fps while actively dragging; jumps to 30fps on release.
- Click the preview to cycle through: Sphere / Plane / Selected Actor Mesh.

**Recent Colors Strip**
- Stores the last 8 colors applied (persisted in `EditorPerProjectUserSettings`).
- Click any swatch to restore it. Right-click for "Remove" or "Copy Hex."

**Apply Button**
- Writes the current color to the selected material's first exposed color parameter.
- Wrapped in a single `FScopedTransaction` so it is fully undoable (Ctrl+Z).
- If no material parameter is selected, a dropdown appears: "Which parameter? [list of all vector parameters on the material]."

**Copy Button**
- Copies the current color to clipboard in the active mode's format (hex if in HSL/sRGB mode, float3 if in Linear mode).

#### UE5 API Hooks

| Operation | API |
|-----------|-----|
| Read selected actor's material | `UStaticMeshComponent::GetMaterial(int32 ElementIndex)` |
| Create dynamic material instance | `UMaterialInstanceDynamic::Create(UMaterialInterface*, UObject*)` |
| Write color parameter | `UMaterialInstanceDynamic::SetVectorParameterValue(FName, FLinearColor)` |
| Enumerate material parameters | `UMaterialInterface::GetAllVectorParameterInfo(TArray<FMaterialParameterInfo>&, ...)` |
| Persist recent colors | `UEditorPerProjectUserSettings` custom property via `GetMutableDefault<>()` |
| Undo/redo transaction | `GEditor->BeginTransaction(...)` / `GEditor->EndTransaction()` |
| Live viewport capture for preview | `FRenderTarget` + `USceneCaptureComponent2D` in a headless sub-scene |
| Actor selection change notification | `USelection::SelectionChangedEvent` delegate |

#### Data Read on Open
- The currently selected actor (if any) and its static mesh component.
- All exposed `FVectorParameterInfo` parameters from the actor's first material.
- The pre-existing color value of the first color parameter (sets the initial sphere position).
- Recent color history from `UEditorPerProjectUserSettings`.

#### Data Written on Apply / Close
- On **Apply:** writes `FLinearColor` to the chosen `UMaterialInstanceDynamic` parameter inside a transaction. The DynMI is created lazily on first apply and cached per-actor.
- On **Close:** nothing is written. The card is non-destructive until Apply is explicitly called. The live DynMI preview is reverted to the original material on close without apply.
- On **Copy:** writes to OS clipboard only.

#### Edge Cases & Error States

| Situation | Behavior |
|-----------|----------|
| No actor selected on open | Preview shows default sphere. Apply button grayed out with tooltip "Select an actor in the viewport first." |
| Selected actor has no exposed color parameters | Apply button grayed out. Tooltip: "No vector parameters found. Expose a parameter in the Material Editor first." |
| Multiple actors selected | Shows a count badge: "3 actors selected." Apply writes to all matching parameter names across all selected DynMIs. |
| Material is a base UMaterial (not an instance) | Offers: "Create a Material Instance to edit non-destructively? [Create MI] [Edit Base Material]" |
| Actor's mesh has no material assigned | Shows error chip: "Slot [0] has no material. Assign one first." |
| Color value outside linear 0–1 range (HDR emissive) | A small "HDR" badge appears. Sliders switch to 0–10 range. Warning: "Writing HDR values to non-emissive slots will clamp." |
| Undo performed externally while card is open | Card listens to `FEditorDelegates::PostUndoRedo` and refreshes its preview. |

#### Visual Design Notes

- **Card background:** `#0D0D0F` near-black with a subtle radial vignette.
- **Sphere glow:** The selected color point emits a soft bloom ring matching the current color's hue at 80% saturation, 90% luminance — always readable against the sphere surface.
- **Header bar:** Thin `1dp` separator line in `#2A2A2E`. Tool name in `SF Pro Display` Medium 13pt, color `#C8C8D0`.
- **Sliders:** Track is `4dp` tall, rounded caps, `#1E1E24` fill. Thumb is a `14dp` circle with a `1dp` glow in the current color.
- **Apply button:** `88dp × 32dp`, background is the current color at 80% luminance, text `#FFFFFF`. Pulses with a single 300ms ease-in-out scale pop on click.
- **Open animation:** Card scales from 0.85 to 1.0 over 200ms with a cubic-out ease. The sphere fades in from 0 to 1 opacity over a separate 300ms.
- **Error states:** Red `#FF4D4F` chip at the bottom of the card; never blocks interaction.

---

### Spec B: Light Mixer

#### Card Layout (480x480dp)

```
┌──────────────────────────────────────────────────────┐
│  ● Light Mixer            [Filter ▼] [+] [Pin] [×]   │  ← 32dp header
├──────────────────────────────────────────────────────┤
│  Search lights...          [ All | Selection | Level ]│  ← 32dp filter bar
├──────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐ │
│  │ ■ Sun_Directional    [S][M]  ████░░░░░░  3.4 EV  │ │  ← Light row (48dp)
│  │ ■ FillLight_01       [S][M]  ██░░░░░░░░  1.2 EV  │ │
│  │ ● RectLight_Shelf    [S][M]  ███████░░░  250 lux │ │
│  │ ● PointLight_Candle  [S][M]  █░░░░░░░░░  40 lux  │ │
│  │ ○ SpotLight_Sign     [S][M]  ████░░░░░░  180 cd  │ │
│  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ [+ Add Group] ─ ─ ─  │ │
│  └──────────────────────────────────────────────────┘ │
│  (scrollable list, max ~6 visible rows, 240dp tall)   │
├──────────────────────────────────────────────────────┤
│  Selected: RectLight_Shelf                            │  ← Detail panel
│                                                      │
│  Color  [■■■■■■■■■■■■■■■■■■■■■■■■]  ████  5500K      │
│  Intens [──────────────●──────────]  250 lux          │
│  Radius [──────────────────●──────]  8.5 cm           │
│  SourceW[─────●────────────────── ]  40 cm            │
│  SourceH[───────●────────────────── ]  20 cm          │
│  Shadow  ● Soft  ○ Hard  ○ None                       │
│                                                      │
│  [Isolate] [Focus in Viewport] [Duplicate] [Delete]  │  ← Action strip
└──────────────────────────────────────────────────────┘
```

#### Interactive Elements

**Light List**
- Each row shows: colored icon (matching light color), light actor name, Solo [S] button, Mute [M] button, horizontal intensity bar (draggable inline), and intensity value.
- Mute sets `ULightComponent::SetVisibility(false)` temporarily (non-destructive; reverts if card is closed without saving muted state).
- Solo isolates that light by muting all others. A banner at the top of the card reads "SOLO MODE" in amber.
- Intensity bar drag: drag left/right on the bar to scrub intensity. Scroll wheel over the row also adjusts. Hold Shift for fine-grain (10x slower).
- Double-click a row name to rename the light actor in-place.
- Rows are reorderable via drag handle (leftmost edge of each row). Reorder persists via actor layer ordering in the level.
- Color swatch (leftmost icon) opens the 3D HSL Color Wheel card, wired to this light's color — a live card-to-card wire appears.

**Filter Bar**
- "All" shows all `ULightComponent` instances in the open level.
- "Selection" shows only lights attached to or within 500cm of selected actors.
- "Level" filters to lights in the currently active sub-level.
- Search box filters by actor label (case-insensitive prefix match).

**Detail Panel (bottom half)**
- Appears when a row is clicked. Shows light-type-appropriate controls:
  - Directional: EV100, Color Temp, Shadow Cascade Count, Atmosphere Sun Disc.
  - Point/Spot: Lumens/Lux/Candela toggle, Attenuation Radius, Shadow resolution.
  - Rect: Source width/height, Barn door controls.
- Kelvin color temperature gradient bar: drag to change temperature; updates both `ULightComponent::SetLightColor` and the color swatch simultaneously.
- All edits are wrapped in a single per-field transaction: every slider release commits one undo step.

**Action Strip**
- Isolate: Same as Solo but persists in the level (actually sets `bVisible` on all non-isolated lights — a destructive write, so a confirm dialog appears: "This will save visibility state to the level. Continue?").
- Focus in Viewport: Calls `GEditor->MoveViewportCamerasToActor` for the selected light.
- Duplicate: Calls `GEditor->edactDuplicateSelected`.
- Delete: Calls `GEditor->edactDeleteSelected` after a single confirmation.

#### UE5 API Hooks

| Operation | API |
|-----------|-----|
| Enumerate all lights in level | `TActorIterator<ALight>` over `UWorld::GetCurrentLevel` |
| Read/write intensity | `ULightComponent::SetIntensity(float)` |
| Read/write color | `ULightComponent::SetLightColor(FLinearColor)` |
| Read/write color temperature | `ULightComponent::SetTemperature(float)`, `SetUseTemperature(bool)` |
| Mute/unmute (visibility) | `ULightComponent::SetVisibility(bool)` |
| React to scene light changes | `FEditorDelegates::OnActorMoved` + `FWorldDelegates::LevelAddedToWorld` |
| Focus viewport on actor | `GEditor->MoveViewportCamerasToActor(AActor&, bool)` |
| Undo transaction | `FScopedTransaction` per slider commit |

#### Data Read on Open
- All `ALight`-derived actors in `GEditor->GetEditorWorldContext().World()`.
- Current intensity, color, temperature, visibility, and shadow settings for each.
- A snapshot of visibility states is taken on open so Mute can be non-destructively reverted.

#### Data Written on Apply / Close
- Every individual slider/color edit writes immediately (live editing) within a transaction.
- Muted state: if the user closes the card while lights are muted, a dialog asks: "Restore muted lights? [Restore] [Keep Muted]."
- No batch "Apply" button — the Light Mixer is always live.

#### Edge Cases & Error States

| Situation | Behavior |
|-----------|----------|
| Level has 0 lights | Empty state illustration: "No lights in this level. Add one from the [+] button above." |
| Level has >50 lights | Virtualizes the list (only renders visible rows). Warns: "Large scene: 80 lights found. Consider using the Group filter." |
| Light actor deleted externally while card is open | Row grays out and shows "Deleted" tag. Refreshes on next edit. |
| Undo of a light edit performed externally | Card listens to `PostUndoRedo` delegate and refreshes all rows. |
| Solo + Sub-level switch | Solo is cleared automatically when the active level changes. |
| Rect light with no source dimensions | Shows "0 × 0 cm" in red; writes minimum 1cm×1cm on first drag to avoid a UE5 zero-area assertion. |

#### Visual Design Notes

- Light icons use the actual light color as fill, providing at-a-glance scene context.
- The intensity bar background gradient goes from `#111114` (zero) to the light's current color at full brightness, so intensity is readable without looking at the number.
- Muted rows are desaturated and 40% opaque.
- Solo mode: non-soloed rows have a `#FF8C00` amber overlay at 20% opacity.
- The detail panel slides up from the bottom with a 160ms ease-out; collapsing is 120ms ease-in.
- Card wire to Color Wheel: a `2dp` bezier arc in the light's color, animated with a slow pulse (opacity 60–100% over 2s).

---

### Spec C: Curve Balancer

#### Card Layout (480x480dp)

```
┌──────────────────────────────────────────────────────┐
│  ● Curve Balancer        [New] [Load] [Export] [×]   │  ← 32dp header
├──────────────────────────────────────────────────────┤
│  ┌──────────────────────┐  ┌──────────────────────┐  │
│  │  Curve A             │  │  Curve B             │  │  ← Curve name tabs
│  └──────────────────────┘  └──────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────────┐ │
│  │ Y                                                │ │
│  │ |          *                                     │ │
│  │ |        *   *                                   │ │  ← Chart area
│  │ |      *       *                                 │ │  (220dp tall)
│  │ |   **           ****                            │ │
│  │ |**                  ****                        │ │
│  │ └──────────────────────────────── X              │ │
│  └──────────────────────────────────────────────────┘ │
│                                                      │
│  X axis: [Level 1-100    ▼]   Y axis: [XP Required ▼]│  ← Axis config
│  Formula:  [y = x^1.8 * 100         ]  [Apply]       │  ← Formula bar
│                                                      │
│  Presets: [Linear] [Ease In] [Ease Out] [S-Curve]    │
│           [Exponential] [Logarithmic] [Custom...]    │
│                                                      │
│  Key X: [  50  ]  Key Y: [ 28450 ]  [+ Add Point]   │  ← Point editor
│  [Smooth Tangents] [Step] [Auto]         [Bake →UE5] │  ← Bottom controls
└──────────────────────────────────────────────────────┘
```

#### Interactive Elements

**Chart Area**
- Renders a live line chart of the active `UCurveFloat` (or an in-memory curve if not yet saved).
- X/Y axes auto-scale to fit all key values; scale labels on both axes.
- Click anywhere on the chart to add a new keyframe at that position.
- Drag existing keyframe dots to reposition them. The key's X/Y coordinates update in the Point Editor below in real time.
- Right-click a keyframe: context menu with "Delete Point," "Set Tangent Flat," "Set Tangent Auto," "Set Tangent Step."
- Two curves can be overlaid simultaneously (Curve A and Curve B tabs) for comparison. Curve A is `#4FC3F7` (blue), Curve B is `#FF8A65` (orange). Overlap region tinted purple.
- Hover over any point on the curve line: tooltip shows the interpolated Y value for that X.
- Grid lines auto-snap to "nice" round numbers (powers of 10 or halves/quarters thereof).

**Formula Bar**
- Type any mathematical expression using variable `x` (e.g., `x^1.8 * 100`, `log(x+1) * 500`, `x < 50 ? x*2 : 100 + (x-50)*1.5`).
- Supported operators: `+`, `-`, `*`, `/`, `^`, `log()`, `sqrt()`, `sin()`, `cos()`, `min()`, `max()`, ternary `? :`.
- Click Apply (or press Enter): samples the formula at N evenly-spaced X values (default 100 samples, configurable) and creates keyframes.
- Parse errors highlighted inline: invalid tokens underlined in red with tooltip explaining the issue.

**Axis Config Dropdowns**
- X axis: user-typed label (e.g., "Level 1-100"). The numeric range is derived from the curve's min/max key X values; editable via the axis label editor (click the label text).
- Y axis: same. These labels are cosmetic and saved in a project-local JSON sidecar (`Saved/PrismCurves/[AssetName].meta.json`), not inside the UE5 asset.

**Preset Buttons**
- Each preset instantly replaces the current curve's keyframes with a standard shape sampled at 10 points.
- Switching presets is undoable (one undo step per preset click).
- "Custom..." opens a popover where you can save the current curve shape as a named preset.

**Point Editor (Key X / Key Y)**
- Shows the selected keyframe's values. Edit directly; Tab between fields.
- "+ Add Point": adds a keyframe at the specified X/Y, selecting it for immediate editing.

**Smooth Tangents / Step / Auto buttons**
- Apply the chosen tangent mode to all keyframes simultaneously. Step is useful for item tier breakpoints.

**Bake to UE5 button**
- If the card is working on an in-memory curve: prompts for a save path via `FDesktopPlatformModule::SaveFileDialog` (scoped to Content/), creates a `UCurveFloat` asset.
- If the card is already bound to an existing `UCurveFloat`: saves in-place. Wrapped in a transaction.
- Triggers a "Bake complete" toast notification at the bottom of the Prism canvas.

#### UE5 API Hooks

| Operation | API |
|-----------|-----|
| Read/write curve keys | `UCurveFloat::FloatCurve` (`FRichCurve`) — direct key manipulation via `FRichCurve::AddKey`, `UpdateOrAddKey` |
| Enumerate all float curves in project | `FAssetRegistry::GetAssets` filtered by class `UCurveFloat` |
| Save asset | `UPackage::SavePackage` via `FEditorFileUtils::SaveDirtyPackages` pattern |
| Undo transactions | `FScopedTransaction` per drag-end or formula apply |
| CurveTable support | `UCurveTable::GetRichCurve(FName RowName)` — enables editing DataTable-embedded curves |

#### Data Read on Open
- If launched from the Asset Browser: loads the targeted `UCurveFloat`'s `FRichCurve` keyframes.
- If launched standalone: starts with a default linear curve (2 keyframes: 0,0 and 100,100).
- Recent curves list (last 5 used) from `EditorPerProjectUserSettings`.

#### Data Written on Apply / Close
- All edits are buffered in memory. The curve is only written to the UE5 asset on "Bake to UE5" or Ctrl+S.
- On close without saving: "Unsaved changes. [Save] [Discard] [Cancel]."
- Undo history is maintained within the card session; after close, the single "Bake" action appears in the UE5 undo history.

#### Edge Cases & Error States

| Situation | Behavior |
|-----------|----------|
| Formula produces NaN or infinity | Formula bar shows red underline; Apply is blocked. Error tooltip: "Formula produces undefined values at x=[value]." |
| Two keyframes with the same X value | Silently merges them (last write wins) with a warning chip: "Duplicate X values merged." |
| Curve linked to CurveTable (not a standalone UCurveFloat) | Card enters "read-only preview" mode with a banner: "This curve is embedded in a CurveTable. Open the CurveTable to edit." |
| Axis min == axis max (all keys same Y value) | Y axis shows a ±10% padding band so the flat line is still visible. |
| Bake target path already exists | "Overwrite existing curve? [Overwrite] [Save As New]" |
| More than 500 keyframes | Warning chip: "High key count may cause performance issues in gameplay code. Consider reducing sample points." |

#### Visual Design Notes

- Chart background: `#0D0D0F` with `#16161A` grid lines at 1dp. Axis labels in `#5A5A6A` mono font.
- Curve A: `#4FC3F7` (Prism signature cyan), 2dp stroke, with a 4dp glow blur.
- Curve B: `#FF8A65` (warm orange), 2dp stroke, with a 4dp glow blur.
- Keyframe dots: 8dp circles, filled with the curve color, `1dp` white outline, scale up to 12dp on hover.
- Formula bar: `#1A1A22` background, monospace font, `#C8C8D0` text. Cursor blink in current curve color.
- Preset buttons: pill-shaped, `#1E1E28` background, `#8888A0` text. Active preset has a `1dp` border in curve color.
- Bake button: filled with Prism accent gradient (cyan→violet left-to-right), white text. 200ms glow pulse animation on hover.

---

## 4. The 5 "Killer Tools"

---

### Killer Tool 1: 3D HSL Color Wheel

**Workflow it replaces:** The current workflow for setting a material color in UE5 involves opening the Material Editor, finding the constant node, clicking the color swatch, using the flat Unreal color picker (which has no material preview), applying, recompiling the shader, switching back to the viewport to judge it, then back to the Material Editor to adjust — 6–10 context switches per color decision.

**The emotional moment:** The developer opens Prism, a sphere glows to life with their mesh wrapped around it in the preview window, they drag the luminous 3D color sphere to the right hue, push the saturation up, and watch the mesh in the preview update in real time — all in 8 seconds without leaving the viewport. "This is what I always wanted the UE5 color picker to be."

**Why no other tool does this inside UE5:** UE5's built-in color picker is a flat 2D HSV square with no live material preview. Blender has a better picker but it's in Blender. There is no tool that combines a visually rich 3D color selection surface with a live bound-material preview without leaving UE5.

---

### Killer Tool 2: Light Mixer

**Workflow it replaces:** Lighting a scene currently means clicking each light in the outliner, waiting for the Details panel to load, adjusting one value, clicking the next light, repeating. For 20+ lights this is 40–80 clicks per iteration cycle. Artists routinely do 10–20 iteration cycles per session.

**The emotional moment:** The artist opens Light Mixer, sees every light in the scene as a row with a drag-to-adjust intensity bar. They grab the fill light's bar and drag left — instantly dimmer. They hit Solo on the key light to isolate it. They pull the color temperature bar from 5500K to 3200K warm, watching the scene shift as they drag. In 30 seconds they've done what previously took 5 minutes. It feels like a professional stage lighting console.

**Why no other tool does this inside UE5:** UE5 has no multi-light control surface. The Outliner is for hierarchy management, not fast numeric editing. There is no equivalent of a DAW's mixer view for lights anywhere in UE5. Dedicated software like Lightwright exists for physical productions but has no UE5 integration.

---

### Killer Tool 3: Curve Balancer

**Workflow it replaces:** Game balance tuning currently means: open a spreadsheet in Excel/Google Sheets, calculate XP/damage/cost values, manually key them into a UE5 CurveFloat in the Curve Editor (which is functionally equivalent to the engine's basic 2D graph), run PIE to feel the values, alt-tab back to the spreadsheet to adjust, repeat. The Curve Editor built into UE5 has no formula input, no axis labeling, no preset library, and no comparison mode.

**The emotional moment:** The designer opens Curve Balancer, types `x^1.8 * 100` into the formula bar, sees the XP curve render instantly, clicks "Ease Out" preset to compare, drags a few key points by hand to flatten the late-game grind, clicks Bake — and the game's progression data is updated. No spreadsheet, no copy-paste, no reimport. "I just designed my entire level progression curve inside UE5 in 3 minutes."

**Why no other tool does this inside UE5:** UE5's Curve Editor is a key manipulation tool, not a design tool. It has no formula input, no presets, no comparison mode, and no axis context. Game balancers currently live in spreadsheets because that's where formula thinking works. Curve Balancer brings that thinking inside the engine.

---

### Killer Tool 4: Scatter Brush

**Workflow it replaces:** Scattering props across a scene (rocks, debris, barrels, foliage patches not covered by the Foliage tool) currently requires either Houdini procedural scatter (requires Houdini license + export pipeline), manual placement (tedious), or the UE5 Foliage tool (limited to foliage-type assets; awkward for arbitrary static meshes).

**The emotional moment:** The level designer selects a rock mesh, opens Scatter Brush, sets size to 400cm and density to 3/m², then paints across the terrain. Rocks appear instantly, randomly rotated, randomly scaled within limits they set, popping into existence under the brush stroke like magic. 30 seconds and the environment looks naturally cluttered. "I just did what used to take a Houdini graph in 30 seconds."

**Why no other tool does this inside UE5:** The UE5 Foliage tool is explicitly for foliage and has a cumbersome per-type setup workflow. It does not give you a context-sensitive brush you can pick up for any arbitrary static mesh. There is no tool in the UE5 editor that lets you say "I want to scatter this specific mesh right now" without a lengthy configuration detour.

---

### Killer Tool 5: Tick Budget Profiler

**Workflow it replaces:** Diagnosing tick performance currently means running Unreal Insights (a separate application), capturing a trace, loading the trace file (which can take 10–30 seconds), navigating to the CPU track, drilling into tick groups, and identifying expensive actors — a workflow that takes 3–5 minutes to answer "which actor is slow?" and is so slow that most developers only run it when performance is already catastrophic.

**The emotional moment:** The developer presses PIE and opens Tick Budget Profiler. They see a live bar chart — every actor, sorted by tick cost in ms, updating 4 times per second. The expensive one is immediately obvious: it's glowing red at 2.3ms. They click it, it pings the outliner, they open the Blueprint and fix it. Total time: 45 seconds. "I would never have found this without Insights. And I would never have opened Insights for a 2ms problem. This tool caught something that would have shipped."

**Why no other tool does this inside UE5:** The UE5 editor stat system shows aggregate tick cost (`stat game`) but does not break it down per-actor in a live, always-visible, glanceable format. Unreal Insights does per-actor breakdown but requires a full trace workflow. There is no "ambient tick health monitor" in UE5. Prism fills that gap with zero friction.

---

## 5. Tools That Should NOT Be Built

---

### Cut 1: Full Material Editor Replacement
**What it sounds like:** A Prism card that replaces the UE5 Material Editor with a friendlier node graph.
**Why to cut it:** The UE5 Material Editor is deeply integrated into the engine's shader compilation pipeline, the node system, and the property system. Replicating it inside a 480x480dp card is architecturally impossible without forking the engine. Any version we ship will be dramatically less capable than the built-in editor, making it actively harmful to the workflow. We add value by wrapping and augmenting the Material Editor (Gradient Designer, PBR Validator, 3D HSL Color Wheel), not by replacing it. **Verdict: scope trap.**

---

### Cut 2: Full Terrain Sculpting Suite
**What it sounds like:** A card-based suite of landscape sculpt, erosion, and noise tools.
**Why to cut it:** UE5's Landscape Mode already ships a professional sculpting toolkit (raise/lower, smooth, flatten, erosion, noise) with a full brush system. Building a duplicate inside Prism adds zero value density — users already have these tools a keyboard shortcut away. Our Heightmap Sculptor tool (Tier 3) is intentionally narrow: compact quick-touch adjustments. A full suite would be redundant with built-in functionality. **Verdict: covered by UE5 natively.**

---

### Cut 3: Full Animation Rigging Tool
**What it sounds like:** A card for rigging characters — creating skeletons, weight painting, and setting up IK chains.
**Why to cut it:** Character rigging is a craft that takes hours per character and is legitimately done in dedicated DCC tools (Maya, Blender) with far more control surface than 480x480dp affords. UE5's Control Rig editor already provides in-engine rigging. Building a "simplified" rigging tool would produce worse rigs and give indie developers a false sense that they can skip learning proper rigging. We should help developers use UE5's rigging tools (IK Reach Debugger, Control Rig Quick Pose) rather than replace them. **Verdict: scope trap + not enough value density for the effort.**

---

### Cut 4: Version Control / Git Client
**What it sounds like:** A Prism card showing git history, diff views, and commit controls.
**Why to cut it:** UE5 already has a source control integration layer (Perforce, Git, SVN) accessible from the editor. Third-party tools (Fork, GitLens, Sourcetree) do this far better than anything we could build in a 480dp card. Developers who are using source control already have their preferred client. Developers who are not using source control are not going to start because of a Prism card. **Verdict: not enough value density; better tools already exist in adjacent software.**

---

### Cut 5: In-Engine Web Browser / Documentation Viewer
**What it sounds like:** An embedded browser card that shows UE5 documentation or web-based references without alt-tabbing.
**Why to cut it:** UE5 already has a built-in browser widget capability. More importantly, documentation lookup is a task where the full-screen browser experience (copy, open tabs, search across pages) is strictly better. A 480x480dp browser is actively worse than alt-tabbing. The value of Prism cards comes from their deep, live access to UE5 scene data — a documentation browser has zero UE5 integration and provides no live state. **Verdict: no UE5 integration value; worse UX than existing tools.**

---

### Cut 6: AI Asset Generator
**What it sounds like:** A card that calls an image diffusion API to generate textures or meshes from a text prompt and imports them.
**Why to cut it:** This is a product category that will be commoditized and invalidated by engine-native AI tooling within the Prism development window. Epic is actively building generative AI directly into UE5. Building this now means building on a foundation that will be deprecated and will position Prism as a thin wrapper around a third-party API with no defensible differentiation. If AI generation is desired, integrate with whatever Epic ships, don't build a competing pipeline. **Verdict: commoditized vertical; short competitive window; not a durable differentiator.**

---

### Cut 7: In-Editor Chat / Messaging Tool
**What it sounds like:** A card that shows Slack/Discord messages or team chat without leaving UE5.
**Why to cut it:** Communication tools require persistent connections, notification systems, authentication integrations, and mobile/multi-platform parity that are far outside the Prism development scope. Developers already have Slack/Discord open on a second monitor. The "never leave UE5" philosophy applies to creative decisions (color, lighting, balance) — not to asynchronous team communication. The integration surface provides no UE5 scene data value. **Verdict: out of scope; zero UE5 integration; duplicates existing communication tools.**

---

*End of Prism Tool Catalog v0.1*
*Maintained by: Tools Programmer*
*Next review: scheduled at Tier 1 feature-complete milestone*
