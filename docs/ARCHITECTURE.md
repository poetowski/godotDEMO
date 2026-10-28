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
| FieldTerrain | `src/world/field/field_terrain.gd` | The field's ground: one flat mesh and collision for the undesigned sectors plus a 900 m ring around the grid, and a coarse (1 m) stand-in for each designed sector and a far model (`FarModel`) for each design, shown while its content isn't loaded. Answers height and water questions for the whole field. |
| Streaming | `src/world/streaming/` | `SectorStreamer` loads a design's content while one of its sectors is within `load_radius` (4) sectors of the player or the camera, nearest first, and unloads it beyond `unload_radius` (5). Content comes from scenes baked by `tools/bake_sectors.gd` (`npm run bake`) into `baked/sectors/`, read on a background thread, or is generated live when the bake is stale. `SectorGround` keeps every design's heights, water and flow loaded. `WorldState` remembers what the player took, so reloaded content stays changed. |
| Nature kit | `src/shared/nature/` | Low-poly rocks, bushes, grass tufts and lily pads (`NatureKit`), stream courses (`StreamPath`), and shaders for flowing water, swaying grass and floating things. |
| Player | `src/player/` | Third-person hero: SpringArm camera, camera-relative movement, sprint, jump, sword pickup and swing with a swoosh trail, gestures. The body is `HeroBody`: the skinned hero from `assets/models/hero/hero.glb` and an `AnimationTree` built in code (idle/walk/run blended by speed, fall, the sword arm, a swing over the upper body, pray and cry over everything), with the right hand and eyes as attachment points. |
| World clock | `src/world/time/world_clock.gd` | Time of day and day count; a game day lasts 24 real minutes, `speed` fast-forwards. Only the stress world has one so far (T toggles fast time, the HUD shows the time). Not saved yet. |
| Villagers | `src/npc/villager.gd` | NPCs with a daily program: from each hour, go home, to work or to the meeting place and rest, work or talk there. The program and walking run everywhere; the body (`HeroBody` with its own tunic colour) is only shown and animated within 60 m of the player. No collision or path finding: they walk straight over the ground. Ten of them live around J10 in the stress world. |
| Hero model | `tools/blender/build_hero.py`, `assets/models/hero/` | Built in Blender by a script (`npm run models`): a low-poly body skinned to 22 bones named after Godot's humanoid profile, and 8 animations (idle, walk, run, fall, hold_sword, swing, pray, cry). |
| Swords | `src/items/sword/`, `src/items/flame_katana/` | `SwordHolder` offers a blade to the player: the sword-in-the-stone (not placed now) and `SwordChest`, which holds the `FlameKatana` on top of the C2 tower. The katana is built in code: burning blade shader, flame particles, flickering light. |
| HUD | `src/ui/hud/` | Current sector, interaction prompt, controls line, mouse-capture hint; opens the inventory on I and freezes the hero while it's open. |
| Inventory | `src/items/inventory.gd`, `src/items/item_data.gd`, `src/ui/inventory/`, `data/items/` | `Inventory` (4 x 6 slots, on the player) holds `ItemData` resources: name, description, facts, model and stack size (mushrooms stack 20 to a slot). `InventoryPanel` is the drawer sliding in from the right over 40% of the screen, with 3D slot pictures and a viewer (`ItemPreview`, a model in its own small world, dragged to turn). |
| Interaction | `src/items/interactable.gd`, `src/items/item_pickup.gd`, `src/items/gesture_spot.gd` | `Interactable` offers itself to the player inside its area with a prompt, and acts on E. `ItemPickup` puts an item in the inventory; `SwordHolder` hands over a blade; `GestureSpot` asks the player to choose a gesture (pray, cry) and has the hero perform it. |
| Save and load | `src/save/save_game.gd`, `src/save/save_migration.gd`, `src/ui/game_menu/`, `Field.capture` / `Field.apply`, `src/items/item_catalog.gd` | JSON saves in `user://saves/slot_<name>.json` (a quicksave and slots 1 to 3): the player's position, facing and sword, the inventory by item id and amount, and `WorldState`'s record per object. Saves carry a format number (2 now); `SaveMigration` upgrades older ones step by step, checked against a frozen save of every old format in `tests/fixtures/saves/`. Loading happens in place: the world state, inventory and sword are restored, then every streamed design reloads around the player. The game menu (Esc) pauses the game; F5 quicksaves, F9 quickloads. |
| Stable ids | `SectorDesign.design_id`, `content_id`, `scatter_id`, `WorldState` | Everything saved about the world is keyed by ids that survive renaming nodes and retuning scatters: `<design_id>/<local name>` for hand-placed things, `<design_id>/<kind>@<x>,<z>` (decimetres) for scattered ones. A design issuing the same id twice is an error. `WorldState` keeps a small record per id (`taken` now; doors, NPCs and the like later). |
| Localization | `src/shared/text.gd`, `tools/extract_strings.gd`, `locale/messages.pot` | English only for now, ready for translation: player-facing text goes through `tr`, `TranslationServer.translate`, plural forms or `Text.mark`; `npm run strings` collects it, with item texts, into `messages.pot`. Adding a language means translating that file into `locale/<lang>.po` and listing it under Localization in the project settings. |
| Choices and gestures | `src/ui/choice/choice_menu.gd`, `Player.ask`, `Player.perform` | `Player.ask` raises a choice the HUD's `ChoiceMenu` shows (numbered buttons, Esc cancels). `Player.perform` plays a timed gesture (kneeling prayer, crying with tears) while the hero stands still. |
| Shared mesh tools | `src/shared/mesh_kit.gd`, `src/shared/shaders/lowpoly.gdshader` | Primitive-mesh merging, MultiMesh setup and a flat-shaded low-poly material (the clouds use it). |
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

Code-generated parts of the world (the ground, sector designs, curtains,
sector names and clouds) are built by `@tool` scripts, so the editor shows
them too. In the editor every design generates its content live; the game
streams the baked content. Their generated
children have no owner, so the editor never saves them into the scene file.

The castle proof of concept (terrain, castle, path, trees) was removed when
the sector grid replaced it. It is kept at git tag `poc-castle`.

Battery note: on battery this laptop caps games at 30 fps (NVIDIA Battery
Boost or Windows power saving). Measure performance on AC power.

## Stress test (2026-10-27)

`src/world/stress/stress_field.tscn` fills all 400 sectors with woodland
(`StressWoods`: 4 to 9 trees, bushes, rocks, 900 grass tufts and up to 3 mushrooms to collect each) on
Perlin hills from `WorldShape` (3.5 m), which runs under every sector so
hills cross sector borders without a step. It's generated by
`tools/make_stress_field.py` and isn't game content. Play it with
`npm run game -- src/world/stress/stress_field.tscn`; the player starts in
J10, where ten villagers live by daily programs (T fast-forwards time).

Measured on the dev laptop (GTX 1650) on battery, running from A1 to T20 at
sprint speed:

| | Result |
|---|---|
| Bake, 400 designs | 18 s; 44 MB of content, 10 MB of far models, 3 MB of ground |
| Designs loaded at once | 115 with load radius 4, 43 with 2 (the stress world uses 2) |
| Draw calls | up to 1,067 with radius 4, 869 with 2, of which about 600 are far models and ground stand-ins |
| Memory | 200 MB with radius 4, 169 MB with 2; video 290 MB |
| GPU time per frame | median 21 ms (13.5 ms in the main field) |
| Frame times | median at the battery's 30 fps cap; 95th percentile 54 ms |

Findings:

- Attaching designs isn't the bottleneck: frames with a load have the same
  median as frames without.
- The slow 5% of frames come from the laptop on battery: the nearly empty
  main field shows the same pattern (95th percentile 59 ms). Measure on
  mains power before drawing conclusions about frame rate.
- Dense content needs a smaller load radius; far models and stand-ins carry
  the distance. Load radius should be set per world.
- Next levers when needed: merge far models and stand-ins per region to
  cut draw calls, give trees visibility ranges, and limit shadow distance
  for forests.

## Open technical questions

Each depends on design decisions. Each has a recommended default, which isn't
decided until the author says so.

1. **Camera and controls.** The PoC is third-person, as requested. Whether
   the game stays third-person, and its real controls, are still the author's
   call.
2. **World structure.** Streaming is in (see above), at the scale of sector
   designs, with far models for distant views: the bake merges each
   design's meshes (not ground, water or MultiMesh copies such as grass and
   ivy), simplifies them with Godot's LOD generation to about a quarter of
   the triangles, and saves `<design>.far.res` (40 to 200 KB each now).
   `FieldTerrain` keeps them loaded and shows each one out to
   `far_distance` (150 m), fading out, while its design's content is away.
   Far models cast no shadows and leave out particles such as rain.
   Still open: attaching a design costs 5 to 25 ms on the main thread
   (mostly collision for its ground and nodes that build their own parts);
   spreading that over frames is the next optimisation. Far model files
   could shrink by dropping vertices their simplified triangles no longer
   use. Once the world is full, merging the far models of a whole region
   would cut draw calls.
3. **Terrain.** For large outdoor areas, the Terrain3D add-on (GDExtension,
   clipmap terrain with sculpting and painting in the editor). For mostly built
   spaces, meshes from a DCC tool.
4. **World size.** Single-precision floats start to jitter several kilometres
   from the origin. Either keep each zone within a few kilometres or shift the
   origin. Double-precision builds need custom-built export templates.
5. **Game data.** Items, stats and abilities as typed custom `Resource`
   classes in `data/`: editable in the inspector, diffable as `.tres`, and
   testable.
6. **Saves.** In: plain JSON with a format number (`SaveGame.FORMAT`), never
   Resources, since a crafted `.tres` can run code. Older formats are
   converted on read (`SaveMigration`); the rules are in CLAUDE.md.
7. **Dialogue and quests.** Dialogic 2, or a small Resource-based system.
   Decide when writing starts.
8. **Performance budget.** Visibility ranges (HLOD), automatic mesh LODs,
   MultiMesh for foliage and props, occluders. Profile with the F3 overlay
   and the editor profiler on the target hardware (the dev machine has a
   GTX 1650).
9. **Art pipeline.** In: Blender 5.2.3 LTS, driven by scripts in
   `tools/blender/` that export `.glb` into `assets/models/` (the hero
   first). The Blender MCP server is connected for live work in Blender.
   Open: whether later characters and props are scripted like the hero,
   modelled by hand, or bought; the humanoid bone names keep all three
   open.
10. **Generated content at scale.** Settled: designs are baked to scenes
    (`npm run bake`, about 1 s for six designs) and streamed. Baked files
    aren't committed; exports must run the bake first (add it to the export
    preset's pre-export step when presets exist). `WorldState` is saved with
    the rest of a save game.
11. **Exports.** No export presets yet. When adding them, exclude `tests/*`,
    `tools/*` and `addons/gut/*`. The export templates are a separate download
    from the editor (Editor > Manage Export Templates).
