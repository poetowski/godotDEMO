# Architecture

What the project has today, and the technical questions to settle as the
design arrives.

## What exists

| Piece | Where | Purpose |
|---|---|---|
| Engine | Godot 4.7.2, Forward+, Jolt physics | Pinned in `tools/dev.mjs` and `project.godot` |
| DevTools autoload | `src/autoload/dev_tools.gd` | `--shot` screenshots for `npm run shot`, F12 screenshots, F3 performance overlay. Frees itself in release builds. |
| MCPRuntime autoload | `addons/godot_mcp/runtime/` | Lets the MCP server screenshot, drive input in and inspect the running game. Editor builds only (local patch). |
| Field | `src/world/field/` | The main scene: grass everywhere, the sector grid, and the sector designs under `Sectors` (see the design record). `grass_grid.gdshader` paints the grass, designed ground's colours and the glowing lines, `sector_grid.gd` raises the light curtains and paints sector names (not in designed sectors), and `field.gd` starts the player on dry ground in A1 (or the `--sector` given). |
| SectorMap | `src/world/field/sector_map.gd` | Sector maths: which sector a point is in, names to cells and back, sector centres, corners and start points. Everything that talks about sectors goes through it. |
| Sector designs | `src/world/field/sector_design.gd`, `src/world/field/sectors/` | A `SectorDesign` owns some sectors and shapes only them: its hooks describe ground height, water level and flow, and ground colour, sampled every 0.25 m; it places its own props. The ground eases back to flat within 2 m of every edge shared with a sector it doesn't own. Built with the `/environment-design` skill. |
| FieldTerrain | `src/world/field/field_terrain.gd` | The field's ground and collision: one flat mesh for undesigned sectors plus a 900 m ring around the grid, and one shaped mesh per designed sector. Answers height and water questions for the whole field. |
| Nature kit | `src/shared/nature/` | Low-poly rocks, bushes, grass tufts and lily pads (`NatureKit`), stream courses (`StreamPath`), and shaders for flowing water, swaying grass and floating things. |
| Player | `src/player/` | Third-person hero from the castle PoC: SpringArm camera, camera-relative movement, sprint, jump, procedural walk cycle, sword pickup and swing with a swoosh trail. |
| Swords | `src/items/sword/`, `src/items/flame_katana/` | `SwordHolder` offers a blade to the player: the sword-in-the-stone (not placed now) and `SwordChest`, which holds the `FlameKatana` on top of the C2 tower. The katana is built in code: burning blade shader, flame particles, flickering light. |
| HUD | `src/ui/hud/` | Current sector, interaction prompt, controls line, mouse-capture hint; opens the inventory on I and freezes the hero while it's open. |
| Inventory | `src/items/inventory.gd`, `src/items/item_data.gd`, `src/ui/inventory/`, `data/items/` | `Inventory` (4 x 6 slots, on the player) holds `ItemData` resources: name, description, facts and model. `InventoryPanel` is the drawer sliding in from the right over 40% of the screen, with 3D slot pictures and a viewer (`ItemPreview`, a model in its own small world, dragged to turn). |
| Interaction | `src/items/interactable.gd`, `src/items/item_pickup.gd`, `src/items/gesture_spot.gd` | `Interactable` offers itself to the player inside its area with a prompt, and acts on E. `ItemPickup` puts an item in the inventory; `SwordHolder` hands over a blade; `GestureSpot` asks the player to choose a gesture (pray, cry) and has the hero perform it. |
| Choices and gestures | `src/ui/choice/choice_menu.gd`, `Player.ask`, `Player.perform` | `Player.ask` raises a choice the HUD's `ChoiceMenu` shows (numbered buttons, Esc cancels). `Player.perform` plays a timed gesture (kneeling prayer, crying with tears) while the hero stands still. |
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
is the world origin; letters grow east (+X), numbers north (-Z). The flat
grass continues 900 m past the grid on every side.

Player controls: WASD or the left stick to move, Shift to sprint, Space to jump,
E to interact, left click to swing, the mouse to look (click the window to
capture it, Esc to release), the wheel to zoom. Gamepad: A jump, Y interact,
X swing, right stick look.

Sandbox controls: WASD or the left stick to move, E/Q to rise and sink, Shift
for speed, hold the right mouse button (or use the right stick) to look, the
mouse wheel to change speed. F3 (overlay) and F12 (screenshot) work everywhere.

Code-generated parts of the world (the ground, sector designs, curtains,
sector names and clouds) are built by `@tool` scripts, so the editor shows
them too. Their generated
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
10. **Generated content at scale.** Sector designs are generated in
    GDScript every time the field loads: about 100 ms per designed sector on
    the dev machine (A1 to A3 take about 300 ms of the field's
    400 ms). A fully designed 400-sector world would take most of a minute.
    Before then: bake each design's meshes into resources at edit time, or
    build sectors near the player only. Recommended: baking, since it keeps
    designs deterministic and loads fastest.
11. **Exports.** No export presets yet. When adding them, exclude `tests/*`,
    `tools/*` and `addons/gut/*`. The export templates are a separate download
    from the editor (Editor > Manage Export Templates).
