# Architecture

What the project has today, and the technical questions to settle as the
design arrives.

## What exists

| Piece | Where | Purpose |
|---|---|---|
| Engine | Godot 4.7.2, Forward+, Jolt physics | Pinned in `tools/dev.mjs` and `project.godot` |
| DevTools autoload | `src/autoload/dev_tools.gd` | `--shot` screenshots for `npm run shot`, F12 screenshots, F3 performance overlay, F4 streaming map, F7 fast time, and the console. Frees itself, and all of these, in release builds. |
| Developer console | `src/autoload/dev_console.gd` | Opened with ` (left of 1). Commands: help, where, goto <sector>, time [hh:mm], fast, give <item> [n], items, radius <load> [unload], reset, save/load [slot], map, fps, clear, quit. Other code adds commands with `register`. Its text is for developers and isn't translated. |
| Streaming map | `src/autoload/streaming_map.gd` | F4 or `map`: the 20 x 20 grid from above, each sector coloured loaded (green), loading (yellow), distant view only (blue) or empty; the hero's arrow, the load and unload radius, design counts, memory, draw calls and fps. |
| MCPRuntime autoload | `addons/godot_mcp/runtime/` | Lets the MCP server screenshot, drive input in and inspect the running game. Editor builds only (local patch). |
| Field | `src/world/field/` | The main scene: the ground, the sector grid, and sector designs under `Sectors` (none yet). `grass_grid.gdshader` paints the grass, designed ground's colours and the glowing lines, `sector_grid.gd` raises the light curtains and paints sector names, and `field.gd` starts the player on dry ground in A1 (or the `--sector` given). |
| SectorMap | `src/world/field/sector_map.gd` | Sector maths: which sector a point is in, names to cells and back, sector centres, corners and start points. Everything that talks about sectors goes through it. Cells run across the whole world; names carry the region in a multi-region world (`R45:J10`), and stay plain (`C4`) in a one-region world such as the main field. |
| Regions | `src/world/field/region_map.gd` | `RegionMap`: the world is `columns` x `rows` regions of 20 x 20 sectors (200 m), numbered R1, R2... from the south-west corner, east along each row and then north. The world's root configures it (the main field is R1 alone). The sector grid, the HUD, the console's `goto` and the streaming map all work per region. |
| The world | `src/world/field/field_world.gd` | `FieldWorld` sets the world up, for the game and the editor alike: R1 alone (200 m; `--regions=N` makes more, for testing), rolling with Perlin noise (`WorldShape`, 1.8 m, one bump about every 70 m), easing flat over the last 12 m. Flat grass continues 900 m past it on every side. |
| Hand sculpting | `addons/terrain_sculpt/`, `src/world/land/terrain_sculpt.gd`, `sculpt_brush.gd`, `data/world/sculpt/` | An editor plugin: select Terrain and paint in the 3D view (raise, lower, smooth, flatten, restore), with undo. `TerrainSculpt` holds what was sculpted, metres added to the land on a 1 m grid in 100 m tiles, one `.res` file per tile that holds anything, saved after every stroke. `WorldShape.height` adds it last, so everything reading the land follows: ground, collision, designs, grid, water edges. In the editor the open ground streams around the view, the 1 m tiles under the brush change at once (`TerrainChunks.reshape`) and are rebuilt whole after the stroke; designed sectors' ground follows every 0.25 s (`SectorDesign.reshape_ground`). The game reads the tiles once at start; a sculpt makes baked content stale, so the next `npm run game` bakes again. Tests ignore the author's sculpts (`tests/pre_run.gd`). `npm run sculpt-check` drives the plugin in the real editor with made-up mouse events. |
| Hand painting | `addons/terrain_sculpt/paint_panel.gd`, `src/world/land/terrain_paint.gd`, `paint_brush.gd`, `paint_tile.gd`, `data/world/paint/` | The Sculpt tab's sister: eight surfaces (placeholders) painted in the 3D view, with undo. `TerrainPaint` holds one byte per surface per metre in 100 m tiles, saved after every stroke. It changes no heights or meshes: `grass_grid.gdshader` reads the shares from two world-sized RGBA8 textures (global shader parameters), so a stroke shows at once at every distance, on all ground sharing that material, and baked ground needs no copy. Costs nothing while nothing is painted. Each surface's pattern runs in the fragment shader only where it's painted. A stroke sends the whole texture again: fine for R1, to be split into tiles if the world grows to many regions. |
| Landforms | `src/world/land/`, `data/world/landforms/` | Region designs (none yet): each `LandformSet` (made by `/region-design`) is a few `Landform`s (mountain, hill, ridge, valley, plateau) for some regions. `WorldShape` adds them up with the rolling hills and a little small detail; `Landforms` also answers where trees would thin out and the ground's colour (rock where steep, snow above a snow line). Tests keep every landform inside its regions and off designed sectors. |
| Streamed ground | `src/world/field/terrain_chunks.gd` | `TerrainChunks`, the ground of a `chunked` FieldTerrain: the 3 x 3 regions around the player in 100 m chunks with collision (1 m samples next to the player, 4 m beyond), farther regions as single 200 m tiles (8 m, then 20 m) out to 6 regions. Skirts hide the cracks between levels of detail; tiles are built on worker threads and attached two a frame. Designed sectors are left open for their designs' own ground. Also runs in the editor (see Hand sculpting). |
| Props | `src/world/props/`, `tools/freeze_props.gd` | Bushes, rocks and trees as `Prop` nodes under a design's `Props` node in `field.tscn`: selected, moved, turned, scaled, duplicated or deleted in the editor, where each shows a preview. The game never draws them one by one: the design merges them (`PropLibrary`) into one mesh per kind and sector, with their collision, when its content is built and baked. A design's code places props with `place_prop` while it's being made; `npm run props -- <Design>` freezes them into the scene for hand editing. |
| R1's waterside | `tools/blender/riverside.py`, `src/world/field/sectors/r1_waterside/`, `src/world/props/mass_prop.gdshader` | 22 riverside assets sharing one palette and set of shapes, one thin script each. Nine designs share one script, one per block of up to 5 x 5 sectors so they stream, with `decorates_land`: they own no ground, so their sectors keep the open ground and poured water, and `FieldTerrain` treats them as undesigned. Masses are MultiMeshes of the assets' meshes (`PropLibrary.mass_mesh`), tinted, swaying and bobbing in a shader; landmarks are frozen `Prop` nodes. Bakes in about 2 s; 8.5 ms a frame walking along the river, about 420 draw calls, 620 at most. |
| Assets | `tools/blender/assets/`, `tools/blender/kit.py`, `assets/models/props/`, `src/world/props/assets/` | Objects made by `/asset-design`: a Blender script per asset (`npm run models -- <slug>`) builds it low-poly with its own convex collision and exports a `.glb`; `npm run asset-preview -- <slug>` renders it in Godot next to a 1.8 m figure. Each has a prop scene (a Prop of kind ASSET) to place it under a design's `Props`; it's placed whole, streamed and baked with the design (as a reference to the `.glb`). `tests/smoke/test_assets.gd` covers every one. |
| Poured water | `src/world/land/water_field.gd`, `region_water.gd`, `water_course.gd`, `data/world/water/` | Water filling the land as it lies, without changing it: `RegionWater` is a lake (a seed point and a level) and rivers (`WaterCourse`: a middle line with a surface level at each point, and a speed). `WaterField` works out a 1 m grid when the world is set up: each river's level holds within 25 m of its middle, the lake's elsewhere, and water stands where the land lies below that and connects to them. About 0.2 s for R1, so it runs once at start, and again in the editor after each stroke, so water follows the land. `Waters` draws it with the flowing water shader, one mesh, and answers `level_at` for swimming and footsteps. Tests ignore the saved water (`tests/pre_run.gd`). |
| Waters | `src/world/land/waterfall.gd`, `lake.gd`, `waters.gd`, `waterfall.gdshader` | Region designs' water. Waterfalls (`LandformSet.waterfalls`): `Waters` drapes a streaming sheet over WorldShape's ground from top to bottom, with a pool and spray. Lakes (`LandformSet.lakes`): a basin carved after the landforms (`Landforms.shape_lakes`, in `WorldShape.height`) with a flat surface, green banks, an optional island and thick shore woods; no trees in the water. Both are water for `FieldTerrain.water_level_at` (swimming, footsteps). |
| Sound | `src/audio/`, `default_bus_layout.tres` | Made in code like the models (`SoundSynth`): footsteps on grass and splashing in water (`Footsteps` on the player: a step every stride, longer strides when sprinting, a heavier one on landing), swimming splashes (`SwimSounds` on the player: a splash per stroke in time with the swim animation, soft laps while paddling), and one ambient for the whole world (`Ambience`: wind always, birds by day, crickets by night, by the light). Buses: Effects and Ambient, for volume settings later. |
| Benchmark | `tools/perf.gd`, `npm run perf` | Travels the player across a world in a straight line and reports frame times, GPU time, draw calls, memory over time, streamed tiles and every frame over 40 ms with where it happened, to `.perf/<world>.json`. |
| Sector designs | `src/world/field/sector_design.gd`, `src/world/field/sectors/` | A `SectorDesign` owns some sectors and shapes only them: its hooks describe ground height, water level and flow, and ground colour, sampled every 0.25 m; it places its own props. The ground eases back to flat within 2 m of every edge shared with a sector it doesn't own. Built with the `/environment-design` skill. |
| FieldTerrain | `src/world/field/field_terrain.gd` | The field's ground: one flat mesh and collision for the undesigned sectors plus a 900 m ring around the grid, and a coarse (1 m) stand-in for each designed sector and a far model (`FarModel`) for each design, shown while its content isn't loaded. Answers height and water questions for the whole field. |
| Streaming | `src/world/streaming/` | `SectorStreamer` loads a design's content while one of its sectors is within `load_radius` (4) sectors of the player or the camera, nearest first, and unloads it beyond `unload_radius` (5). Content comes from scenes baked by `tools/bake_sectors.gd` (`npm run bake`) into `baked/sectors/`, read on a background thread, or is generated live when the bake is stale. `SectorGround` keeps every design's heights, water and flow loaded. `WorldState` remembers what the player took, so reloaded content stays changed. |
| Nature kit | `src/shared/nature/` | Low-poly rocks, bushes, grass tufts and lily pads (`NatureKit`), stream courses (`StreamPath`), and shaders for flowing water, swaying grass and floating things. |
| Player | `src/player/` | Third-person hero: SpringArm camera, camera-relative movement, sprint, jump, holding a sword and swinging it with a swoosh trail, swimming in water at least 1 m deep (`swim_depth`; floats at the surface, slower, no jumping or swinging; any `FieldTerrain` water, waterfall pools included). The body is `HeroBody`: the skinned hero from `assets/models/hero/hero.glb` and an `AnimationTree` built in code (idle/walk/run blended by speed, fall, the sword arm, a swing over the upper body, swim over everything in deep water, paced by speed), with the right hand as an attachment point. |
| World clock | `src/world/time/world_clock.gd`, `Clock` in the field | Time of day and day count, part of every field world and of saves (`time`). A game day lasts 24 real minutes; F7 (dev builds only) runs it at a game hour per second. The HUD shows it top right. `--hour=21.5` starts at another time (`npm run game`, `npm run shot`). |
| Day and night | `src/world/time/day_night.gd`, `DayNight`, `Sun` and `Moon` in the field | Lights the world by the clock: the sun rises in the east at 6:00, stands 60 degrees high in the south at 13:00 and sets in the west at 20:00; at night a dimmer blue moon lights from the other side, casting the shadows, stars fade in (a generated texture on the sky's cover), and the sky, fog and ambient light pass through dawn, day, dusk and night. |
| Dialogue | `src/dialogue/`, `data/dialogue/` | Conversations as data (`DialogueData`: entries with a line and answers; a conversation opens at the first opening entry whose condition holds). `DialogueRules` is the small language for conditions (`quest:<id>:none\|active\|done`, `has:<item>`, `!has:`, joined by `&`) and actions (`start:`, `complete:`, `take:`, `give:`, joined by `;`). A villager with `dialogue` gets a `Talk` interactable ("[E] Talk to ..."), stops and faces the player; the HUD runs the conversation through the choice menu (title = speaker, body = line). |
| Quests | `src/quests/`, `data/quests/`, `src/ui/quests/` | Quests as data (`QuestData`: id, title, giver, description, `QuestStep`s; an item step is done while the item is carried, the rest when the quest is). `QuestLog` keeps each quest's state (active, done), saved in format 4. Q opens `QuestPanel`, a drawer from the left. No quests yet. |
| Villagers | `src/npc/villager.gd` | NPCs with a daily program: from each hour, go home, to work or to the meeting place and rest, work or talk there. The program and walking run everywhere; the body (`HeroBody` with its own tunic colour) is only shown and animated within 60 m of the player. No collision or path finding: they walk straight over the ground. Residents of the field live under its `Residents` node (none yet), wired to the clock by `field.gd`. |
| Hero model | `tools/blender/build_hero.py`, `assets/models/hero/` | Built in Blender by a script (`npm run models`): a low-poly body skinned to 22 bones named after Godot's humanoid profile, and 7 animations (idle, walk, run, fall, hold_sword, swing, swim). |
| HUD | `src/ui/hud/` | Current sector, interaction prompt, controls line, mouse-capture hint; opens the inventory on I and freezes the hero while it's open. |
| Inventory | `src/items/inventory.gd`, `src/items/item_data.gd`, `src/ui/inventory/`, `data/items/` | `Inventory` (4 x 6 slots, on the player) holds `ItemData` resources: name, description, facts, model and stack size. No items yet; tests use their own in `tests/fixtures/items/`. `InventoryPanel` is the drawer sliding in from the right over 40% of the screen, with 3D slot pictures and a viewer (`ItemPreview`, a model in its own small world, dragged to turn). |
| Interaction | `src/items/interactable.gd`, `src/items/item_pickup.gd` | `Interactable` offers itself to the player inside its area with a prompt, and acts on E. `ItemPickup` puts an item in the inventory. |
| Save and load | `src/save/save_game.gd`, `src/save/save_migration.gd`, `src/ui/game_menu/`, `Field.capture` / `Field.apply`, `src/items/item_catalog.gd` | JSON saves in `user://saves/slot_<name>.json` (a quicksave and slots 1 to 3): the player's position and facing, the inventory by item id and amount, and `WorldState`'s record per object. Saves carry a format number (2 now); `SaveMigration` upgrades older ones step by step, checked against a frozen save of every old format in `tests/fixtures/saves/`. Loading happens in place: the world state, inventory and sword are restored, then every streamed design reloads around the player. The game menu (Esc) pauses the game; F5 quicksaves, F9 quickloads. |
| Stable ids | `SectorDesign.design_id`, `content_id`, `scatter_id`, `WorldState` | Everything saved about the world is keyed by ids that survive renaming nodes and retuning scatters: `<design_id>/<local name>` for hand-placed things, `<design_id>/<kind>@<x>,<z>` (decimetres) for scattered ones. A design issuing the same id twice is an error. `WorldState` keeps a small record per id (`taken` now; doors, NPCs and the like later). |
| Localization | `src/shared/text.gd`, `tools/extract_strings.gd`, `locale/messages.pot` | English only for now, ready for translation: player-facing text goes through `tr`, `TranslationServer.translate`, plural forms or `Text.mark`; `npm run strings` collects it, with item texts, into `messages.pot`. Adding a language means translating that file into `locale/<lang>.po` and listing it under Localization in the project settings. |
| Choices | `src/ui/choice/choice_menu.gd`, `Player.ask` | `Player.ask` raises a choice the HUD's `ChoiceMenu` shows (numbered buttons, Esc cancels). |
| Shared mesh tools | `src/shared/mesh_kit.gd`, `src/shared/shaders/lowpoly.gdshader` | Primitive-mesh merging, MultiMesh setup and a flat-shaded low-poly material (a shared look for what's built in code). |
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
is the world origin; letters grow east (+X), numbers north (-Z).

Player controls: WASD or the left stick to move, Shift to sprint, Space to jump,
E to interact, left click to swing, the mouse to look (click the window to
capture it, Esc to release), the wheel to zoom. Gamepad: A jump, Y interact,
X swing, right stick look.

Code-generated parts of the world (the ground, sector designs, curtains and
sector names) are built by `@tool` scripts, so the editor shows
them too. In the editor every design generates its content live; the game
streams the baked content. Their generated
children have no owner, so the editor never saves them into the scene file.

The castle proof of concept is kept at git tag `poc-castle`, the whole demo
(sector designs, landforms, assets, woods, swords, NPC, stress test and big
world benchmarks) at `demo-final`. `demo-final` also holds tests worth restoring
once designs exist: far models and a design unloaded mid-read.

Battery note: on battery this laptop caps games at 30 fps (NVIDIA Battery
Boost or Windows power saving). Measure performance on AC power.

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
3. **Terrain.** In: our own streamed ground (`TerrainChunks`) from a height
   function (`WorldShape`: noise plus hand-sculpted tiles, `TerrainSculpt`).
   Sculpting was built on this rather than the Terrain3D add-on, so the
   streaming, designs and tools all keep working. Open: a resolution finer than
   1 m, painting the ground's colour by hand, and loading tiles by streaming
   instead of all at the start once whole regions are sculpted (about 40 KB
   each before compression).
4. **World size.** Regions and streaming held at 4 km (benchmark at tag `demo-final`).
   Single-precision floats start to jitter around 8 km from the origin:
   beyond that, shift the origin with the player (not built yet) or split
   the world into zones. Double-precision builds need custom-built export
   templates.
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
