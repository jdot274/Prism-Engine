# Prism Engine (Hybrid & Web-Native Blueprint)

This repository serves as the engineering blueprint and setup guide for the **Prism Engine**—a hybrid and web-native real-time 3D engine combining cutting-edge 2026 web tech with modern simulation concepts.

---

## Architectural Decision: Fork A vs. Fork B

Choose your path based on whether your core gameplay loop is heavily coupled to Unreal's proprietary simulation pipelines (Chaos physics, destruction, Niagara systems). If not, bypass Fork A and go directly to the high-performance Web-Native pathway (Fork B).

### Fork A: Unreal Engine 5.5+ & Web Hybrid Engine
Choose this path if your game **requires** Chaos vehicles, complex rigid-body fracturing, or Niagara GPU particles.

#### Architectural Blueprint
```
                   +----------------------------------+
                   |       UE5 GPU Host (Server)      |
                   | - Luma / Volinga Splat Renderer  |
                   | - Server-authoritative Chaos/NPC  |
                   +----------------------------------+
                        |                        |
             WebRTC Video Stream           WebTransport JSON State
             (Nanite/Lumen frame)          (Datagrams / HTTP/3)
                        v                        v
                   +----------------------------------+
                   |         Browser Client           |
                   | - Three.js VideoTexture Plane    |
                   | - Three.js (.spz) Splat Overlay  |
                   | - WebTransport controller link   |
                   +----------------------------------+
```

*   **Unified Assets**: Bypassing FBX/GLTF entirely, we author scenes in Gaussian Splatting formats (`.spz`/`.ply`). Three.js renders local elements or secondary cameras using `@gsplat/three`, while UE5 renders the high-fidelity host view via Luma/Volinga, feeding identical assets on both sides.
*   **Transport**: Instead of raw WebSockets which suffer from TCP head-of-line blocking, we use **WebTransport** over HTTP/3 to stream controller state datagrams up to the host and receive physics state down.

#### Actionable Steps for Fork A

##### Phase 1: Local Splat & WebTransport Setup
1.  **Scaffold Web Client**: Initialize a Vite + TypeScript project. Install `@gsplat/three` and configure the WebTransport client.
2.  **Splat Loading**: Embed a high-performance `.spz` viewer in Three.js. Confirm standard frame rates when loading photoreal environments locally.
3.  **Establish WebTransport Host**: Create a lightweight Node.js/Rust signaling and connection broker supporting HTTP/3 WebTransport.
    *   *Done Criteria*: Client connects over WebTransport and successfully receives/sends binary datagrams with sub-millisecond connection overhead.

##### Phase 2: UE5 Scaffolding & WebRTC Link
1.  **Initialize C++ UE5 Project**: Create a blank UE 5.5 C++ project inside `C:\Users\joeyw\Desktop\Prism-Engine\`.
2.  **Enable Plugins**: Enable the standard `PixelStreaming` plugin in your `.uproject` file.
3.  **Write WebTransport Bridge in C++**: Avoid WebSockets in UE5. Implement an HTTP/3 WebTransport client inside your UE C++ layer using `libdatachannel` or custom WinHTTP-based transport.
4.  **Integrate Three.js VideoTexture**: Modify your existing Three.js receiver to map the WebRTC video stream onto a `VideoTexture`.

##### Phase 3: Server-Side Authority & Custom Rendering
1.  **Eliminate Client Authority**: Implement strict validation on input events forwarded via the data channel. The UE5 server parses the input (e.g. `pointerdown` coordinates), calculates the raycast against its server-side scene geometry, and spawns actors strictly on the server.
2.  **Install Splat Plugin in UE5**: Integrate Luma/Volinga/DazaiStudio to ingest the same `.ply` or `.spz` assets. 
3.  **Run Headless**: Build and package the UE5 host. Execute with `-RenderOffScreen -AudioMixer -ForceRes -ResX=1920 -ResY=1080` to evaluate performance.

---

### Fork B: Web-Native Engine (Rust + Rapier + SpacetimeDB)
If your game does not depend on Niagara or Chaos physics, **drop Unreal Engine completely**. Running headless UE5 in production introduces massive overhead (Docker container size, GPU hosting costs, cold start times). 

Fork B achieves bit-identical client/server physics prediction, unified codebases, and seamless web delivery.

#### Architectural Blueprint
```
                   +----------------------------------+
                   |        SpacetimeDB (Cloud)       |
                   | - Rust Database & Server Logic   |
                   | - Server-authoritative Rapier 3D |
                   +----------------------------------+
                                   ^
                                   | WebTransport Datagrams (HTTP/3)
                                   v
                   +----------------------------------+
                   |         Browser Client           |
                   | - Three.js WebGL / WebGPU Render |
                   | - Local Client-Side Prediction   |
                   |   (Rapier compiled to WASM)      |
                   +----------------------------------+
```

*   **Client-Side Prediction**: By compiling your Rust/Rapier physics module to WebAssembly (WASM), your Three.js client runs the *exact* same physics calculations as the SpacetimeDB server. If the server disagrees on a state, it pushes the authoritative state down, letting the client easily reconcile positions.
*   **High-Performance Visuals**: Three.js handles the photoreal visual layer by rendering Gaussian Splats (`.ply`/`.spz`) in real-time, matching or exceeding Unreal's fidelity for static/baked environments without the rasterization overhead.

#### Actionable Steps for Fork B

##### Phase 1: SpacetimeDB and Physics Bootstrap
1.  **Install SpacetimeDB CLI**: Setup the database workspace locally on your system.
2.  **Create Server Module (Rust)**:
    *   Write your database schema and game loop inside a SpacetimeDB Rust module.
    *   Add the `rapier3d` crate for server-side physics and collision boundaries.
3.  **Entity Registry**: Define server-authoritative tables for players, physics objects, and dynamic entities.

```rust
#[spacetimedb(table)]
pub struct PlayerState {
    #[primarykey]
    pub entity_id: u64,
    pub position_x: f32,
    pub position_y: f32,
    pub position_z: f32,
    pub velocity_x: f32,
    pub velocity_y: f32,
    pub velocity_z: f32,
}
```

##### Phase 2: Web Client & WASM Prediction Link
1.  **Compile Rapier to WASM**: Build your player movement and collision detection routines into a client-side WASM assembly using Rust.
2.  **Scaffold Vite + TS Client**: Create the client application inside `C:\Users\joeyw\Desktop\Prism-Engine\`.
3.  **Integrate Three.js + Splats**: Load your `.ply`/`.spz` assets to build your photoreal world boundaries. Wrap these bounds inside Rapier's collision shapes.
4.  **Connect Client to SpacetimeDB**: Connect using the SpacetimeDB JS/TS SDK over WebTransport/HTTP/3.

##### Phase 3: Reconciliation and Client Loop
1.  **Client Tick Loop**: On every frame, sample user input, step the local Rapier physics WASM engine, and render player movements instantly (prediction).
2.  **Server Tick Loop**: SpacetimeDB executes the authoritative state update using the identical Rapier configurations. It publishes updates back to clients over WebTransport.
3.  **Local Reconciliation**: If the server state differs from the client state, interpolate the player position back to the server's correct position.

---

## Immediate Action Item (This Weekend Setup)

To help you decide between **Fork A** and **Fork B**, stand up the raw web-native transport and asset pipelines first.

Run these commands in PowerShell to bootstrap the modern web engine workspace:

```powershell
# Create workspace
mkdir C:\Users\joeyw\Desktop\Prism-Engine
cd C:\Users\joeyw\Desktop\Prism-Engine

# Scaffold high-performance Vite Web Client (Vanilla + TypeScript)
npm create vite@latest web-client -- --template vanilla-ts
cd web-client
npm install three @gsplat/three
npm run dev
```

### Your First Validation Test
1. Drag a photoreal `.spz` or `.ply` Gaussian Splat file into your `web-client` assets folder.
2. Read and display the splat inside a Three.js canvas.
3. Verify that you can orbit and navigate this world at high frame rates. 

If this performance and visual fidelity meet your art direction needs, **lock in Fork B**. You will save months of head-of-line blocking development, avoid running heavy headless instances of Unreal Engine on costly GPU instances, and own a unified, high-performance WebTransport system.

---

## Research

- [research/threejs-ue5-hybrid/](research/threejs-ue5-hybrid/README.md) — *Three.js ↔ UE5 Unconventional Interop: A 2026 Field Guide.* The long-form research drop behind the Fork A / Fork B decision above: executive summary of the five candidate architectures, deep-dives on Gaussian splat shared assets, WebTransport plumbing, headless Chaos + Rapier prediction, the `scene.v1` DSL design, prior-art catalog, and a custom-build vs off-the-shelf checklist. Start with [its README](research/threejs-ue5-hybrid/README.md).
