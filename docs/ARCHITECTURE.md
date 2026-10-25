# Architecture

What the project has today, and the technical questions to settle as the
design arrives.

## What exists

| Piece | Where | Purpose |
|---|---|---|
| Engine | Godot 4.7.2, Forward+, Jolt physics | Pinned in `tools/dev.mjs` and `project.godot` |
| DevTools autoload | `src/autoload/dev_tools.gd` | `--shot` screenshots for `npm run shot`, F12 screenshots, F3 performance overlay. Frees itself in release builds. |
| MCPRuntime autoload | `addons/godot_mcp/runtime/` | Lets the MCP server screenshot, drive input in and inspect the running game. Editor builds only (local patch). |
| Sandbox | `src/world/sandbox/` | Main scene for now: greybox blocks with collision, a 1.8 m human-scale marker, sun, sky, fog and a fly camera. |
| Prototype grid shader | `src/shared/shaders/prototype_grid.gdshader` | World-space metre grid for greybox geometry, so scale reads at a glance. |
| Tests | `tests/`, GUT 9.7.1 | `npm test`; failing asserts, engine errors and `push_error` all fail a run. |
| Project check | `tools/check_project.gd` | `npm run check` loads everything and fails on parse, load and typing errors. |

Project settings worth knowing: base resolution 1920x1080 with the window
opening at 1280x720 (`canvas_items` stretch, `expand` aspect), MSAA 2x,
occlusion culling enabled, untyped GDScript declarations are errors, and unsafe
property and method access are warnings.

Sandbox controls: WASD or the left stick to move, E/Q to rise and sink, Shift
for speed, hold the right mouse button (or use the right stick) to look, the
mouse wheel to change speed, F3 for the overlay, F12 for a screenshot.

## Open technical questions

Each depends on design decisions. Each has a recommended default, which isn't
decided until the author says so.

1. **Camera and controls.** Third-person, isometric or first-person shapes the
   player controller, the input map and level scale. This is the first
   gameplay decision to make.
2. **World structure.** Separate zones loaded with
   `ResourceLoader.load_threaded_request` (simple and robust), or seamless
   streaming of world chunks (open world, much more work). Recommended: start
   with zones and move to streaming only if the design needs seamlessness.
3. **Terrain.** For large outdoor areas, the Terrain3D add-on (GDExtension,
   clipmap terrain with sculpting and painting in the editor). For mostly built
   spaces, meshes from a DCC tool.
4. **World size.** Single-precision floats start to jitter several kilometres
   from the origin. Either keep each zone within a few kilometres or shift the
   origin. Double-precision builds need custom-built export templates.
5. **Game data.** Items, stats and abilities as typed custom `Resource`
   classes in `data/`: editable in the inspector, diffable as `.tres`, and
   testable.
6. **Saves.** Serialize state to plain dictionaries or JSON in `user://`.
   Don't load saves as Resources, because a crafted `.tres` can run code.
7. **Dialogue and quests.** Dialogic 2, or a small Resource-based system.
   Decide when writing starts.
8. **Performance budget.** Visibility ranges (HLOD), automatic mesh LODs,
   MultiMesh for foliage and props, occluders. Profile with the F3 overlay
   and the editor profiler on the target hardware (the dev machine has a
   GTX 1650).
9. **Art pipeline.** Blender to glTF (`.glb`) into `assets/models/`. Blender
   isn't installed. Godot can import `.blend` files directly once it is.
10. **Exports.** No export presets yet. When adding them, exclude `tests/*`,
    `tools/*` and `addons/gut/*`. The export templates are a separate download
    from the editor (Editor > Manage Export Templates).
