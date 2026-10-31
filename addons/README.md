# Vendored add-ons

Third-party code, copied in at a pinned version. Don't edit it beyond the
patches listed here; to change behaviour, wrap it from `src/`.

| Add-on | Version | Source | License | Local patches |
|---|---|---|---|---|
| `godot_mcp` | 0.6.1 | [tomyud1/godot-mcp](https://github.com/tomyud1/godot-mcp) tag `v0.6.1` | MIT | `runtime/mcp_runtime.gd` `_ready()` returns early unless the `editor` feature is present |
| `gut` | 9.7.1 | [bitwes/Gut](https://github.com/bitwes/Gut) tag `v9.7.1` (the Godot 4.7 line) | MIT | none |

`terrain_sculpt/` is the exception: it's this project's own plugin, kept here
only because Godot looks for plugins in `addons/`. Edit it freely.

## godot_mcp notes

- The editor plugin talks to `godot-mcp-server` (started by `.mcp.json`) on
  `ws://127.0.0.1:6505`. Keep the npm version in `.mcp.json` equal to the
  plugin version above.
- `MCPRuntime` is the in-game half (screenshots, input, live node reads). The
  plugin registers it only when someone toggles the plugin on in the editor
  UI, so it is registered by hand in `project.godot` instead.
- The patch exists because upstream `MCPRuntime` has no release guard: an
  exported game would keep dialing `localhost:6505` and run commands from
  whatever answers. With the patch it frees itself outside editor builds.

## Updating

1. Replace the folder with the one from the new tag.
2. Re-apply the patches in the table, and update the table.
3. For `godot_mcp`, bump `godot-mcp-server@<version>` in `.mcp.json` to match.
4. Run `npm run verify`, then open the editor and check the MCP status
   indicator turns green once Claude Code is running.
