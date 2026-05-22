# UnrealClaudeMCP — drop-in quickstart

Make any UE 5.7 project drivable by Claude / Cursor / any MCP client in under 10 minutes.

## 1. Drop the plugin

```
git clone https://github.com/Donchitos/UnrealClaudeMCP <Project>/Plugins/UnrealClaudeMCP
```

## 2. Regenerate + build

Right-click `<Project>.uproject` → **Generate Visual Studio project files**. Open the `.sln`, build **Development Editor | Win64**.

## 3. Launch and verify

Launch the editor. Output Log should show:

```
[LogUnrealClaudeMCP] Module started
LogUCMCPHandler: Registered handler 'execute_unreal_python'
... (64 lines)
[LogUCMCP] Listening on 127.0.0.1:18888
```

## 4. Wire your MCP client

### Claude Desktop

`%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "unreal-claude": {
      "command": "py",
      "args": ["C:/Path/To/UnrealClaudeMCP/bridge/unreal_claude_mcp_bridge.py"]
    }
  }
}
```

### Cursor

`.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "unreal-claude": {
      "command": "py",
      "args": ["C:/Path/To/UnrealClaudeMCP/bridge/unreal_claude_mcp_bridge.py"]
    }
  }
}
```

### Codex CLI

```bash
codex mcp add unreal-claude -- py C:/Path/To/UnrealClaudeMCP/bridge/unreal_claude_mcp_bridge.py
```

## 5. Test

From the project root:

```bash
py examples\smoke_test.py
```

Should print structured JSON for each tool and end with:

```
Smoke test complete.
```

## 6. Use it

In your MCP client, you now have access to:

- `execute_unreal_python` — run any Python
- `spawn_actor`, `set_actor_property`, `delete_actor`
- `inspect_blueprint`, `compile_blueprint`
- `get_viewport_screenshot`
- ... 60 more

Example prompt (in any MCP client):

> Spawn a cube at the origin, focus the editor camera on it, and screenshot the viewport.

The client will issue:

```
spawn_actor(class="/Script/Engine.StaticMeshActor", location=[0,0,0])
focus_actor(label="StaticMeshActor_1")
get_viewport_screenshot()
```

## Pair with CCGS

If you also want studio-style agent coordination (49 specialized AI agents + 72 workflow skills), see [Claude Code Game Studios](https://jdot274.github.io/Prism-KB/ai-integration/ccgs/).

## See also

- [Plugins → UnrealClaudeMCP](https://jdot274.github.io/Prism-KB/plugins/unreal-claude-mcp/)
- [AI Integration → UnrealClaudeMCP](https://jdot274.github.io/Prism-KB/ai-integration/unreal-claude-mcp/)
