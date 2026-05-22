# Workflow Innovations & Achievements: The Prism Ledger

Welcome to the engineering documentation for the **Prism Engine Workflow Innovation System**. This document outlines our custom Developer Experience (DX) architecture, which transforms the traditional "passive" relationship between autonomous AI agents and codebases into an active, self-documenting, and self-graduating engine.

We call this system **The Prism Ledger**.

---

## The Vision: A Self-Documenting AAA Engine

In standard development environments, research discoveries, architectural pivots, and development TODOs are ephemeral—lost in chat transcript history, Slack messages, or forgotten design documents. 

**The Prism Ledger** solves this by establishing a double-durable, real-time sync between Cursor agent sessions and GitHub. Every single technical fact, architectural decision, and requirement discovered during an agent session automatically flows into the repository as **GitHub Issues** and **Project Kanban Cards**, completely bypass-free.

### High-Level Workflow
```
┌─────────────────────────────────────────────────────────────┐
│                      Cursor Agent Turn                      │
│ Agent loads the `github-knowledge-capture` skill.          │
│ Emits a `finding`, `decision`, or `action` markdown block.   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                      (Cursor stop event)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            Local Hook: `sync-to-github.ps1`                 │
│ 1. Scans latest transcript JSONL.                           │
│ 2. Extracts capture blocks & redacts potential secrets.     │
│ 3. Formats rich markdown issue payload.                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ├──────────────────────────────┐
                    (Checks GitHub Reachability)              │
                               │                              │ (offline/error)
                               ▼ (online)                     ▼
┌─────────────────────────────────────────────────────────────┐┌──────────────────────────────┐
│                  GitHub Issues (REST API)                   ││    Offline Queue Folder      │
│  - Automatically creates labelled Issue cards                ││  - Saves JSON payload to:    │
│  - Assigns `@me` to Action Items                           ││    `tools/` queue/ directory │
│  - De-duplicates identical titles to prevent noise          ││  - Drained by `flush-queue.ps1`│
└─────────────────────────────────────────────────────────────┘└──────────────────────────────┘
```

---

## Core Pillars of the Innovation

### 1. Zero-Friction GitHub-Native Link
Unlike previous prototypes built on complex web APIs, OAuth flows, and third-party database brokers (such as Notion), the Prism Ledger is **100% GitHub-Native**. 
*   **Authentication-Free**: It executes through the developer's pre-existing, local `gh` CLI session. No external secrets, database credentials, or tokens are required.
*   **Version-Controlled Integration**: The entire automation infrastructure—from hooks and parsers to templates and recovery mechanisms—lives directly in the repository under `tools/cursor-github-bridge/`.

### 2. The Trello-Style "Graduation" Loop
The Ledger integrates seamlessly into a GitHub Projects board to establish a clear graduation loop for tools and prototypes:
1.  **Creation**: A requirement (e.g. "Create 3D HSL Color Wheel tool") is logged by the agent (or developer) as a `type/action-item` card.
2.  **Tracking**: It lands on the Project Kanban Board in the **Backlog** or **In Progress** column.
3.  **Implementation**: The developer or agent implements the code. Every commit is tagged with metadata linking back to the issue (e.g. `Closes #14`).
4.  **Graduation**: When merged, GitHub automatically closes the issue. The card is tagged with **`status/graduated-tool`** and moved to the **Done/Active Stack** column. It is now officially a graduated, active tool in the Prism Engine ecosystem!

### 3. Fail-Open Offline Queueing
Developer environments are dynamic. If a developer works offline, on a flight, or behind a restrictive proxy, the Ledger never blocks the agent or the workspace.
*   The script catches any execution failures gracefully.
*   It logs the events to `tools/cursor-github-bridge/queue/.hook.log` (guaranteed secret-free).
*   It dumps the issue payload to `tools/cursor-github-bridge/queue/<timestamp>.json`.
*   Running `pwsh tools/cursor-github-bridge/flush-queue.ps1` when back online automatically drains the queue, creating all issues in sequence.

---

## Pipeline Tools & Directory Structure

All Ledger automation scripts reside in the repository under `tools/cursor-github-bridge/`:

| File Path | Role |
| --- | --- |
| `tools/cursor-github-bridge/github-lib.ps1` | Shared module: handles secret redaction, YAML parsing, `gh` issue creation, label management, and transcript tracking. |
| `tools/cursor-github-bridge/sync-to-github.ps1` | The main Cursor `stop` event hook script. Scans and extracts blocks. |
| `tools/cursor-github-bridge/flush-queue.ps1` | Drains the offline queue when internet or authentication is restored. |
| `tools/cursor-github-bridge/backfill.ps1` | Historical backfill utility. Converts past conversation transcript findings into GitHub Issues. |
| `tools/cursor-github-bridge/_parse-check.ps1` | Self-diagnostic: verifies that all scripts parse cleanly under PowerShell 7. |
| `tools/cursor-github-bridge/queue/` | Offline buffer folder. Houses queued JSON items, offset positions, and logs. |

---

## Setup & Operational Instructions

To get the Prism Ledger running on your local machine, run the following steps:

### 1. Ensure `gh` CLI is Authenticated
Open your terminal and confirm you are logged in:
```bash
gh auth status
```
If you are not logged in, run:
```bash
gh auth login
```

### 2. Verify Your Global Cursor Hooks Config
Your global Cursor hook file (`~/.cursor/hooks.json`) should point to our repository script:
```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "pwsh.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\joeyw\\Desktop\\Prism-Engine\\tools\\cursor-github-bridge\\sync-to-github.ps1\"",
        "timeout": 25,
        "failClosed": false
      }
    ]
  }
}
```

### 3. Run Self-Diagnostics
To verify that the scripts compile and parse correctly, execute:
```powershell
pwsh tools/cursor-github-bridge/_parse-check.ps1
```

### 4. Manually Flush Queued Issues
To view what is currently queued offline:
```powershell
pwsh tools/cursor-github-bridge/flush-queue.ps1 -DryRun
```
To push queued issues live:
```powershell
pwsh tools/cursor-github-bridge/flush-queue.ps1
```

---

## Strategic Achievements & Impact

1.  **Elimination of Knowledge Rot**: Research studies (such as WebGL instancing, ThreeJS↔UE5 streaming, SpacetimeDB integration) are preserved forever as indexed, searchable, and labeled engineering articles on GitHub.
2.  **Bit-Identical Requirements Traceability**: Commit metadata links code directly to design issues, fulfilling the AAA design requirement for complete traceability without overhead.
3.  **Active Progress Metrics**: Project boards reflect real-world progress instantly based on closed cards, transforming agent productivity into a visual, measurable metric.
