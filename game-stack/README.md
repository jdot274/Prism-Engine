# AAA Web Game Stack

Welcome to the **AAA Web Game Stack** – a cutting-edge, OS, Mobile, and PC Agnostic meta tech stack pipeline schema architecture.

This architecture proves that you can deliver high-performance, physics-based AAA experiences directly in the browser by relying purely on Web-Based Tech. No native wrappers, no bulky downloads, just a seamless, containerized cloud development environment with an authoritative live multiplayer server.

## Meta Tech Stack Pipeline Schema Architecture

### 1. Cross-Platform Web-Based Technologies
This stack relies *strictly* on standard web tech mapped to high-performance APIs:
*   **React 19 & Vite:** The backbone of the application component hierarchy and instantaneous local development.
*   **Three.js & React Three Fiber (R3F):** Bridging declarative UI components to an imperative WebGL scene graph.
*   **@react-three/drei:** Essential helpers and abstractions for AAA visuals.
*   **@react-three/rapier:** Native WASM physics integration (Rapier) directly in the React tree, providing high-fidelity determinism without layout thrashing.
*   **Framer Motion:** Powering the 2D DOM UI, HUDs, and state-driven spatial transitions.

### 2. Live Authoritative Server
*   **Node.js & Colyseus:** WebSockets-based backend handling room matches, authoritative state simulation (preventing client-side physics spoofing), and delta-compressed network state propagation.
*   **Shared Schema:** A strict Monorepo design using NPM Workspaces to share `@game/shared` types and math across both backend and frontend execution environments.

### 3. USDZ Asset Pipeline Integration
*   To guarantee truly cross-platform agnostic fidelity (crucial for iOS Safari / VisionOS alongside desktop browsers), the pipeline enforces **USDZ** as a primary 3D delivery format.
*   Integrating `usdz` loading bridges spatial-computing ecosystem standards natively into the web context, unlocking AR Quick Look natively alongside the R3F Canvas.

### 4. Containerized Environment
*   **Docker & Docker Compose:** The entire dev environment, frontend (`5173`) and live server (`3000`), is spun up with a single `docker-compose up` command, guaranteeing identical dev experiences everywhere.

---

## 📋 Kanban & Backlog (GitHub Issues)

We have scaffolded our foundational Kanban board directly via GitHub issues. Click below to view the active sprint progress:

*   [Issue #1: Scaffold Containerized Monorepo (Frontend/Backend)](https://github.com/jdot274/Prism-Engine/issues/1)
*   [Issue #2: Implement R3F + Rapier Physics Engine Base](https://github.com/jdot274/Prism-Engine/issues/2)
*   [Issue #3: Design USDZ Asset Loading Pipeline](https://github.com/jdot274/Prism-Engine/issues/3)
*   [Issue #4: Setup Live Authoritative Multiplayer Server](https://github.com/jdot274/Prism-Engine/issues/4)
