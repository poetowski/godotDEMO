# Architecture

What the project has today, and the technical questions to settle as the
design arrives.

## What exists

| Piece | Where | Purpose |
|---|---|---|
| Engine | Godot 4.7.2, Forward+, Jolt physics | Pinned in `tools/dev.mjs` and `project.godot` |
| DevTools autoload | `src/autoload/dev_tools.gd` | `--shot` screenshots for `npm run shot`, F12 screenshots, F3 performance overlay. Frees itself in release builds. |
| MCPRuntime autoload | `addons/godot_mcp/runtime/` | Lets the MCP server screenshot, drive input in and inspect the running game. Editor builds only (local patch). |
| Field | `src/world/field/` | The main scene: flat grass everywhere and the sector grid (see the design record). `grass_grid.gdshader` paints the grass and the glowing lines, `sector_grid.gd` raises the light curtains and paints sector names, and `field.gd` starts the player in A1 (or the `--sector` given). |
| SectorMap | `src/world/field/sector_map.gd` | Sector maths: which sector a point is in, names to cells and back, sector centres. Everything that talks about sectors goes through it. |
| Player | `src/player/` | Third-person hero from the castle PoC: SpringArm camera, camera-relative movement, sprint, jump, procedural walk cycle, sword pickup and swing with a swoosh trail. |
| Sword | `src/items/sword/` | The sword model and the sword-in-the-stone pickup. Not placed in the world at the moment. |
| HUD | `src/ui/hud/` | Current sector, interaction prompt, controls line, mouse-capture hint. |
| Shared mesh tools | `src/shared/mesh_kit.gd`, `src/shared/shaders/lowpoly.gdshader` | Primitive-mesh merging, MultiMesh setup and a flat-shaded low-poly material (the clouds use it). |
| Sandbox | `src/world/sandbox/` | Dev test ground: greybox blocks with collision, a 1.8 m human-scale marker, sun, sky, fog and a fly camera. |
| Prototype grid shader | `src/shared/shaders/prototype_grid.gdshader` | World-space metre grid for greybox geometry, so scale reads at a glance. |
| Tests | `tests/`, GUT 9.7.1 | `npm test`; failing asserts, engine errors and `push_error` all fail a run. |
| Project check | `tools/check_project.gd` | `npm run check` loads everything and fails on parse, load and typing errors. |

Project settings worth knowing: base resolution 1920x1080 with the window
opening at 1280x720 (`canvas_items` stretch, `expand` aspect), MSAA 2x,
occlusion culling enabled, untyped GDScript declarations are errors, and unsafe
property and method access are warnings.

Physics layers: 1 `world` (the ground and anything built on it), 2 `player`.
The camera's spring arm only collides with `world`; the sword pickup only
sees `player`.

Sectors: 10 x 10 m, 20 x 20 of them (A to T, 1 to 20). A1's south-west corner
is the world origin; letters grow east (+X), numbers north (-Z). The grass
plane is 2 km wide, so it continues well past the grid.

Player controls: WASD or the left stick to move, Shift to sprint, Space to jump,
E to interact, left click to swing, the mouse to look (click the window to
capture it, Esc to release), the wheel to zoom. Gamepad: A jump, Y interact,
X swing, right stick look.

Sandbox controls: WASD or the left stick to move, E/Q to rise and sink, Shift
for speed, hold the right mouse button (or use the right stick) to look, the
mouse wheel to change speed. F3 (overlay) and F12 (screenshot) work everywhere.

Code-generated parts of the world (the curtains, sector names and clouds)
are built by `@tool` scripts, so the editor shows them too. Their generated
children have no owner, so the editor never saves them into the scene file.

The castle proof of concept (terrain, castle, path, trees) was removed when
the sector grid replaced it. It is kept at git tag `poc-castle`.

Battery note: on battery this laptop caps games at 30 fps (NVIDIA Battery
Boost or Windows power saving). Measure performance on AC power.

## Open technical questions

Each depends on design decisions. Each has a recommended default, which isn't
decided until the author says so.

1. **Camera and controls.** The PoC is third-person, as requested. Whether
   the game stays third-person, and its real controls, are still the author's
   call.
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
