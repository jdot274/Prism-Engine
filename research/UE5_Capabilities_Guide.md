# Unreal Engine 5.7 — Live Coding, Python & Editor Capabilities Guide

---

## What Each Thing Is & What It's Used For

### 1. Live Coding
**What it is:** Hot-reload for C++ code. You can change C++ logic while the editor (or game) is running and push the compiled changes instantly — no full editor restart.

**Used for:**
- Tweaking gameplay logic in C++ without closing the editor
- Iterating on actor behavior, game modes, components fast
- Fixing bugs in `.cpp` files mid-session
- Any C++ game code: movement, damage, abilities, AI logic, custom systems

**NOT for:** Changing `.h` header files, constructors, or class structure — those still require a full restart.

**Shortcut:** `Ctrl + Alt + F11` triggers a Live Coding recompile from anywhere.

---

### 2. Python Scripting (Editor Only)
**What it is:** Runs Python scripts inside the Unreal Editor via an embedded Python 3 interpreter. **Does NOT run at game runtime** — this is purely an editor tool.

**Used for:**
- Automating repetitive editor tasks (batch rename assets, set LODs on 100 meshes at once)
- Procedurally generating or placing actors in your level via script
- Modifying asset properties in bulk
- Building custom editor pipelines and import/export workflows
- What Claude (via MCP) uses to control your editor — every MCP tool call runs Python under the hood

**Example use cases:**
- "Place 50 trees randomly in a radius" → one Python script
- "Set all static meshes in Content/ to Nanite-enabled" → one Python script
- "Rename every asset with 'old_' prefix to 'new_'" → one Python script

---

### 3. Editor Scripting Utilities Plugin
**What it is:** A UE plugin that exposes simplified Blueprint and Python APIs for common editor actions that normally require C++.

**Used for:**
- Blueprint-accessible versions of editor functions (move asset, set material, build lighting)
- Works hand-in-hand with Python scripting
- Enables `unreal.EditorLevelLibrary`, `unreal.EditorAssetLibrary` etc. in Python
- Required for most serious Python automation — Python alone is limited without it

---

### 4. Editor Utility Widgets & Blueprints (Blutility)
**What it is:** UMG widgets or Blueprint classes that run inside the editor itself, not in the game. You build custom tools that appear as panels in the editor UI.

**Used for:**
- Building custom editor tools with buttons, sliders, dropdowns
- "One-click" tools your team can use without knowing Python or C++
- Level design helpers, content validators, batch operations with a UI
- Example: a panel that lets you pick a biome and auto-populates the level with foliage

---

### 5. AI Capabilities (Built-in UE5 Systems)
**What it is:** A full suite of AI tools built into UE5 for NPC behavior, pathfinding, and perception.

| System | What it does |
|---|---|
| **Behavior Trees** | Visual scripted AI decision-making (patrol, attack, flee) |
| **Blackboard** | Shared memory for a Behavior Tree (stores "target actor", "is alerted", etc.) |
| **NavMesh** | Auto-generated walkable area map — AI uses it to pathfind around your level |
| **AI Perception** | AI can "see" and "hear" the player via sight/hearing sensors |
| **EQS (Environment Query System)** | AI asks spatial questions: "find best cover position", "find nearest pickup" |
| **State Trees** | Newer, lighter alternative to Behavior Trees — good for simple AI |
| **Mass AI** | Crowd simulation for hundreds/thousands of agents (birds, soldiers, NPCs) |
| **NNE (Neural Network Engine)** | Run ML models inside UE5 — experimental AI inference |
| **AI Assistant Plugin** | Experimental in 5.7 — Epic's built-in AI coding assistant |

---

---

## SETUP: Live Coding

### Step 1 — Install Visual Studio 2022
1. Download **Visual Studio 2022 Community** (free) from microsoft.com
2. In the **Visual Studio Installer**, select **Modify**
3. Under **Workloads**, check: `Game development with C++`
4. Under **Individual Components**, also add:
   - `MSVC v143 - VS 2022 C++ x64/x86 build tools`
   - `Windows 10/11 SDK`
   - `C++ CMake tools for Windows`
5. Click **Install / Modify**

### Step 2 — Convert Your Project to C++
Your current project (`TopSceneProject`) has a C++ module declared in the `.uproject` but no source files yet. To activate it:

1. Open the project in UE5.7
2. Go to `Tools > New C++ Class`
3. Pick **None (Empty Class)** → name it `TopSceneGameMode` → click **Create Class**
4. UE will generate the `Source/` folder and open Visual Studio
5. Let it compile — this is a one-time full build (takes ~5–15 min)

### Step 3 — Enable Live Coding
1. In the editor, click the **dropdown arrow** next to the Compile button (bottom toolbar)
2. Check **Enable Live Coding**
3. OR go to `Edit > Editor Preferences > General > Live Coding` → toggle on

### Step 4 — Use It
- Make a change in any `.cpp` file in Visual Studio
- Press `Ctrl + Alt + F11` — changes compile and push live in ~10–30 seconds
- The editor does NOT restart

---

## SETUP: Python Scripting

### Step 1 — Enable the Plugins
1. Open your project in UE5.7
2. Go to `Edit > Plugins`
3. Search **"Python Editor Script Plugin"** → Enable it
4. Search **"Editor Scripting Utilities"** → Enable it
5. Restart the editor when prompted

> No external Python install needed — UE5 ships with an embedded Python 3 interpreter.

### Step 2 — Enable Developer Mode (for autocomplete)
1. Go to `Edit > Editor Preferences`
2. Search **"Python"**
3. Enable **Developer Mode** — this generates Python stub files so you get autocomplete in VS Code

### Step 3 — Run Python Scripts
**Option A — Output Log console:**
1. `Window > Output Log`
2. Change the dropdown from `Cmd` to `Python`
3. Type Python commands directly

**Option B — Run a script file:**
1. `File > Execute Python Script`
2. Browse to any `.py` file on your machine

**Option C — Startup scripts:**
In `Edit > Editor Preferences > Plugins > Python`, add paths to scripts that run automatically when the editor opens.

### Step 4 — What Claude Can Now Do Via MCP
Once Python + Editor Scripting Utilities are enabled and the UnrealClaudeMCP plugin is running, Claude can:
- Spawn and configure actors in your level
- Create and modify Blueprint assets
- Batch-process any content in your project
- Set up lighting, post-process volumes, sky atmosphere
- Build the entire scene automatically from a single instruction

---

## Quick Reference: Which Tool For What Job

| You want to... | Use this |
|---|---|
| Change gameplay C++ without restarting | **Live Coding** |
| Automate placing/modifying assets in bulk | **Python Scripting** |
| Build a custom editor panel with buttons | **Editor Utility Widget** |
| Run a one-click batch operation in editor | **Editor Utility Blueprint** |
| Give an NPC patrol/attack behavior | **Behavior Tree + Blackboard** |
| Let AI navigate around your level | **NavMesh** |
| AI that reacts to player being seen/heard | **AI Perception** |
| AI that picks best tactical position | **EQS** |
| Simulate a crowd of 500 NPCs | **Mass AI** |
| Let Claude control the editor for you | **Python Plugin + UnrealClaudeMCP** |

---

## Files in Your TopSceneProject That Use These

| Config | What it activates |
|---|---|
| `TopSceneProject.uproject` | Niagara, PCG, EnhancedInput, UnrealClaudeMCP declared |
| `DefaultEngine.ini` | Lumen, Nanite, VSM, Raytracing, TSR at max settings |
| `DefaultScalability.ini` | All quality tiers locked to Epic |

---

*Sources:*
- [UE5.7 Python Scripting Docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/scripting-the-unreal-editor-using-python)
- [UE5.7 Live Coding Docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-live-coding-to-recompile-unreal-engine-applications-at-runtime)
- [Visual Studio Setup for UE5](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine)
- [Live Coding Community Wiki](https://unrealcommunity.wiki/live-compiling-in-unreal-projects-tp14jcgs)
