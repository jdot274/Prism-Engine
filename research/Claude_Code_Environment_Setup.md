# Claude & Claude Code — Full Environment Setup Guide
**System:** Windows 11 | Node v26.1.0 | npm 11.13.0 | Python 3.13.13 | Claude Code 2.1.138 | uv 0.11.13

---

## 1. Config File Locations — Where Everything Lives

| File | Path | What it controls |
|---|---|---|
| Claude Desktop MCP config | `%APPDATA%\Claude\claude_desktop_config.json` | MCP servers for Claude Desktop app |
| Claude Code user settings | `%USERPROFILE%\.claude\settings.json` | Your global Claude Code preferences |
| Claude Code project settings | `<project>\.claude\settings.json` | Per-project settings and permissions |
| Claude Code project memory | `<project>\.claude\CLAUDE.md` | Instructions Claude reads every session |
| Claude user memory | `%USERPROFILE%\.claude\projects\...\memory\` | Persistent memory across sessions |

> The `claude_mcp_settings_TEMPLATE.json` on your Desktop is a reference template.
> To activate MCP servers, copy the `mcpServers` block into `%APPDATA%\Claude\claude_desktop_config.json`
> then restart Claude Desktop.

---

## 2. MCP Servers — Best Connectors (With Install Commands)

### What MCP Is
MCP (Model Context Protocol) gives Claude tools to interact with your system, files, web, databases, and external services. Each server you add = new capabilities.

### Tier 1 — Install These First (No API Key Needed)

#### desktop-commander ✅ Already installed
```bash
npx -y @wonderwhy-er/desktop-commander
```
**Does:** Full desktop control — run processes, manage files, interact with terminal, screenshot.

#### filesystem
```bash
npm install -g @modelcontextprotocol/server-filesystem
```
**Does:** Direct read/write/list on specified folders. Faster than desktop-commander for pure file ops.
**Config paths to include:** Desktop, Documents, your UE5 project.

#### memory
```bash
npm install -g @modelcontextprotocol/server-memory
```
**Does:** Persistent knowledge graph Claude can write to and recall across sessions. Entities + relations.

#### sequential-thinking
```bash
npm install -g @modelcontextprotocol/server-sequential-thinking
```
**Does:** Structured multi-step reasoning. Claude breaks complex problems into explicit thought chains.

#### fetch (via uv — already have uv)
```bash
uvx mcp-server-fetch
```
**Does:** Claude fetches any URL and reads the content. No API key. Great for docs, GitHub raw files, APIs.

#### git (via uv)
```bash
uvx mcp-server-git --repository C:\Users\joeyw\Desktop\TopSceneProject
```
**Does:** Git operations — log, diff, blame, branch, status — directly from Claude.

#### sqlite (via uv)
```bash
uvx mcp-server-sqlite --db-path C:\Users\joeyw\Desktop\claude_memory.db
```
**Does:** Claude can create, query, and update a local SQLite database. Good for game data, logs, saves.

---

### Tier 2 — Needs API Key

#### github
```bash
npm install -g @modelcontextprotocol/server-github
```
**Env:** `GITHUB_PERSONAL_ACCESS_TOKEN` = your GitHub PAT (Settings → Developer Settings → Tokens)
**Does:** Create/read issues, PRs, repos, gists, search code on GitHub.

#### brave-search
```bash
npm install -g @modelcontextprotocol/server-brave-search
```
**Env:** `BRAVE_API_KEY` = free tier at api.search.brave.com
**Does:** Live web search from Claude. Free tier: 2000 queries/month.

---

### Tier 3 — Optional / Project-Specific

#### puppeteer (browser automation)
```bash
npm install -g @modelcontextprotocol/server-puppeteer
```
**Does:** Claude controls a real Chrome browser — navigate, click, screenshot, scrape.

#### postgres (if you use a database)
```bash
npm install -g @modelcontextprotocol/server-postgres
```
**Env:** `POSTGRES_CONNECTION_STRING`
**Does:** Claude queries and writes to a PostgreSQL database.

#### unreal-claude-mcp (for your UE5 project)
```bash
# Install the UE editor plugin side first (see UE5 guide)
# Then add to config - connects to port 18888 when editor is open
```

---

## 3. npm — All Install Commands in One Block

Run these in any terminal (PowerShell, CMD, Warp):

```bash
# Core MCP servers
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-memory
npm install -g @modelcontextprotocol/server-sequential-thinking
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-brave-search
npm install -g @modelcontextprotocol/server-puppeteer
npm install -g @modelcontextprotocol/server-postgres

# Claude Code is already installed:
# npm install -g @anthropic-ai/claude-code   (skip — already v2.1.138)

# Verify all installs:
npm list -g --depth=0
```

### npm Path on Your PC
Global packages install to: `C:\Users\joeyw\AppData\Roaming\npm`
This is already in your PATH. ✅

---

## 4. Python & .venv — Best Practice Setup

### Why .venv (Virtual Environment)
Installing packages globally (`pip install X`) pollutes your system Python and causes version conflicts. A `.venv` is an isolated Python environment per project — clean, reproducible, deletable.

### You Have Two Options: venv (built-in) or uv (faster, already installed)

#### Option A — Standard venv (built-in Python)
```powershell
# Create venv in your project folder
cd C:\Users\joeyw\Desktop\TopSceneProject
python -m venv .venv

# Activate it (PowerShell)
.\.venv\Scripts\Activate.ps1

# Activate it (CMD)
.\.venv\Scripts\activate.bat

# You'll see (.venv) in your prompt when active
# Now install packages — they go into .venv only:
pip install requests numpy pillow

# Deactivate when done
deactivate

# Save what's installed (for sharing/reinstalling)
pip freeze > requirements.txt

# Reinstall from requirements on another machine:
pip install -r requirements.txt
```

#### Option B — uv (Recommended, 10-100x faster) ✅ Already installed
```powershell
# Create a new project with venv automatically
uv init my-project
cd my-project

# Or add venv to existing project
cd C:\Users\joeyw\Desktop\TopSceneProject
uv venv

# Activate (same as standard venv)
.\.venv\Scripts\Activate.ps1

# Install packages via uv (much faster than pip)
uv pip install requests numpy pillow anthropic

# Add to project (tracks in pyproject.toml)
uv add anthropic

# Run a script without activating venv
uv run script.py

# Sync all dependencies
uv sync
```

### Claude Code Python MCP Servers (via uvx)
`uvx` runs a Python MCP server in a temporary isolated env — no install needed:
```powershell
# These run directly, no venv or pip needed:
uvx mcp-server-fetch
uvx mcp-server-git --repository C:\path\to\repo
uvx mcp-server-sqlite --db-path C:\path\to\db.sqlite
uvx mcp-server-filesystem C:\path\to\folder
```

### Python Path on Your PC (Already Correct) ✅
```
C:\Users\joeyw\AppData\Local\Programs\Python\Python313
C:\Users\joeyw\AppData\Local\Programs\Python\Python313\Scripts
C:\Users\joeyw\AppData\Local\Programs\Python\Launcher
```

---

## 5. PATH & Environment — What You Have vs What to Add

### Current PATH (Already Correct) ✅
| Entry | Status | Why it matters |
|---|---|---|
| `C:\Program Files\nodejs` | ✅ Present | node, npm, npx |
| `C:\Users\joeyw\AppData\Roaming\npm` | ✅ Present | globally installed npm packages |
| `C:\Users\joeyw\AppData\Local\Programs\Python\Python313` | ✅ Present | python.exe |
| `C:\Users\joeyw\AppData\Local\Programs\Python\Python313\Scripts` | ✅ Present | pip, uv, uvx |
| `C:\Program Files\Git\cmd` | ✅ Present | git |
| `C:\Program Files\PowerShell\7` | ✅ Present | pwsh |

### Nothing Missing — Your PATH is Complete ✅

### To Permanently Add a Custom PATH Entry (if ever needed)
```powershell
# PowerShell (run as Admin) — adds to system PATH permanently:
[Environment]::SetEnvironmentVariable(
  "PATH",
  $env:PATH + ";C:\Your\New\Path",
  "Machine"
)

# Or for current user only (no Admin needed):
[Environment]::SetEnvironmentVariable(
  "PATH",
  $env:PATH + ";C:\Your\New\Path",
  "User"
)
```

### Verify Everything is Working
```powershell
node --version        # should show v26.x.x
npm --version         # should show 11.x.x
npx --version         # should match npm version
python --version      # should show 3.13.x
uv --version          # should show 0.11.x
uvx --version         # same as uv
git --version         # should show 2.x.x
claude --version      # should show 2.1.x (Claude Code)
```

---

## 6. Terminal Commands — Claude Code CLI Reference

### Starting Claude Code
```powershell
# Start in current directory
claude

# Start in a specific project
claude --project C:\Users\joeyw\Desktop\TopSceneProject

# Start with a specific model
claude --model claude-opus-4-7

# Start with bypass permissions (your Desktop already has this)
claude --dangerously-skip-permissions
```

### In-Session Slash Commands
```
/help                   -- show all commands
/clear                  -- clear conversation context
/compact                -- summarize context to save tokens
/config                 -- open settings editor
/cost                   -- show token usage for session
/doctor                 -- diagnose Claude Code health
/ide                    -- connect to VS Code / Cursor / Zed
/init                   -- create CLAUDE.md for current project
/memory                 -- open memory files
/model                  -- switch model mid-session
/review                 -- review current branch changes
/status                 -- show git status + project info
/fast                   -- toggle fast mode (Opus 4.6 faster output)
```

### CLAUDE.md — Project Instructions File
```bash
# Auto-generate for your UE5 project:
cd C:\Users\joeyw\Desktop\TopSceneProject
claude /init
```
Claude reads `CLAUDE.md` at the start of every session in that folder.
Put your project rules, conventions, and context here.

---

## 7. Activating All MCP Servers — Step-by-Step

### Step 1 — Install npm servers
```powershell
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-memory
npm install -g @modelcontextprotocol/server-sequential-thinking
npm install -g @modelcontextprotocol/server-puppeteer
```

### Step 2 — Copy template to Claude Desktop config
```powershell
# Open the config file in VS Code:
code "$env:APPDATA\Claude\claude_desktop_config.json"

# Or open directly:
notepad "$env:APPDATA\Claude\claude_desktop_config.json"
```
Copy the `mcpServers` section from `claude_mcp_settings_TEMPLATE.json` on your Desktop into that file.
Replace any `REPLACE_WITH_YOUR_*` values with your actual keys.

### Step 3 — Restart Claude Desktop
Close and reopen the Claude Desktop app. MCP servers auto-connect on startup.

### Step 4 — Verify MCP is working
In Claude Desktop, type:
```
What MCP tools do you have available?
```
Claude should list all the connected servers and their tools.

### Step 5 — For Claude Code CLI (separate from Desktop)
Claude Code reads MCP config from:
```powershell
# Project-level (only for this project):
C:\Users\joeyw\Desktop\TopSceneProject\.claude\settings.json

# User-level (all projects):
C:\Users\joeyw\.claude\settings.json
```
Add the same `mcpServers` block to either file.

---

## 8. Environment Variables for API Keys — Best Practice

Never hardcode API keys. Store them as environment variables:

```powershell
# Set permanently for current user (PowerShell as normal user):
[Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "your_token", "User")
[Environment]::SetEnvironmentVariable("BRAVE_API_KEY", "your_key", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "your_key", "User")

# Verify it's set:
[Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
```

Then in your MCP config, reference them:
```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "%GITHUB_PERSONAL_ACCESS_TOKEN%"
}
```

Or in Python (after `uv add python-dotenv`):
```python
from dotenv import load_dotenv
import os

load_dotenv()  # reads from .env file in project root
api_key = os.getenv("ANTHROPIC_API_KEY")
```

`.env` file (put in project root, NEVER commit to git):
```
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
BRAVE_API_KEY=BSA...
```

Add `.env` to `.gitignore`:
```
echo ".env" >> .gitignore
```

---

## 9. Quick Diagnostic Checklist

Run this block in PowerShell to verify your full environment:

```powershell
Write-Host "=== Node ===" -ForegroundColor Cyan
node --version; npm --version; npx --version

Write-Host "=== Python ===" -ForegroundColor Cyan
python --version; uv --version; uvx --version

Write-Host "=== Git ===" -ForegroundColor Cyan
git --version

Write-Host "=== Claude Code ===" -ForegroundColor Cyan
claude --version

Write-Host "=== Global npm packages ===" -ForegroundColor Cyan
npm list -g --depth=0

Write-Host "=== Python packages ===" -ForegroundColor Cyan
pip list

Write-Host "=== Claude Desktop config ===" -ForegroundColor Cyan
Get-Content "$env:APPDATA\Claude\claude_desktop_config.json" | ConvertFrom-Json | Select-Object -ExpandProperty mcpServers | Get-Member -MemberType NoteProperty | Select-Object Name
```

---

## 10. Recommended .claude/settings.json for TopSceneProject

Create this file at `C:\Users\joeyw\Desktop\TopSceneProject\.claude\settings.json`:

```json
{
  "model": "claude-sonnet-4-6",
  "permissions": {
    "allow": [
      "Bash(python:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(git:*)",
      "Bash(uv:*)",
      "Bash(uvx:*)",
      "Bash(node:*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)"
    ]
  },
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\Users\\joeyw\\Desktop\\TopSceneProject"
      ]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "."]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "unreal-claude-mcp": {
      "command": "npx",
      "args": ["-y", "unreal-claude-mcp"],
      "env": {
        "UE_HOST": "127.0.0.1",
        "UE_PORT": "18888"
      }
    }
  }
}
```

---

*Generated with Claude Code | jdw274@cornell.edu | Windows 11 | AMD Ryzen + NVIDIA GeForce*
