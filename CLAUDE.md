# godotDEMO

A 3D RPG in Godot 4.7.2: GDScript, Forward+, Jolt physics. "godotDEMO" is a
working title and the game's design is not decided yet.

## Who decides what

- **We never use third-party assets.** Everything in the game (models,
  animations, textures, materials, sounds, music, fonts) is made in this project,
  by our own scripts, or by the author. No downloads, asset stores, marketplaces,
  free packs or AI-generated assets from outside services, whatever their license.
  Third-party code for development (`addons/`) is a separate matter and is not a
  game asset.
- Game content is the author's call: names, story, characters, mechanics,
  numbers, controls, art direction. Propose, then wait for a yes before
  building it.
- `docs/DESIGN_DECISIONS.md` is the author's record. Build what it says;
  anything else is a placeholder and is marked as one.
- `docs/world/` holds the author's notes on the world and each region: art, lore,
  terrain, flavor text. Before working on a place, read `docs/world/art.md`,
  `lore.md` and that region's folder, and keep to them. Write there only what the
  author said or approved (see `docs/world/README.md`).
- Engineering (architecture, tooling, tests, performance) is yours to propose
  and build. Spell out the tradeoffs when a choice is hard to undo.
  `docs/ARCHITECTURE.md` lists what exists and the open technical questions.

## Commands

| Command | What it does |
|---|---|
| `npm run check` | Imports assets, then loads every script, scene and resource in `src/ data/ assets/ tests/ tools/`. Fails on any error. |
| `npm test` | Runs the GUT suite headless. Add `-- -gselect=test_player` to run one file. |
| `npm run verify` | `check`, then `test`. |
| `npm run shot -- [scene] [--out=x.png] [--frames=60] [--size=1280x720]` | Plays a scene (default: the main scene) in a window, saves `.shots/<scene>.png` and quits. Read the PNG to see it. |
| `npm run shot -- --camera=x,y,z --look=x,y,z --out=.shots/view.png` | The same, shot from a temporary camera at any viewpoint. |
| `npm run shot -- --frame=A1:C3 --out=.shots/area.png` | The same, from a camera framing those sectors from above. |
| `npm run shot -- --player=x,y,z --hold=move_forward --press=interact,1,quests` | Puts the hero somewhere, holds an input action, and presses actions or digit keys (dialogue answers) in turn before the shot. |
| `npm run shot -- --hour=0 --out=.shots/night.png` | Any shot at a time of day: the world is lit by the clock, so check designs by night too. |
| `npm run import` | Headless import, after adding or changing assets outside the editor. |
| `npm run bake` | Generates every sector design's content into `baked/sectors/` (not committed). `game`, `shot` and `test` run it first whenever the baked files are older than `src/`, `data/` or the bake tool. |
| `npm run asset-preview -- <slug>` | Renders an asset in Godot from three sides next to a 1.8 m figure, into `.shots/assets/`. |
| `npm run models [-- <slug>]` | Runs the Blender scripts headless with factory settings (the hero, `build_hero.py`, and every asset in `tools/blender/assets/`, or only the named asset), writing `.glb` files into `assets/models/`, then imports them. Commit the `.glb` with the script that made it. |
| `npm run blender` | Opens Blender for the MCP tools, with the add-on's telemetry and update check off. |
| `npm run props -- <Design>` | Freezes the props a sector design's code places (`place_prop`) into `field.tscn` as `Prop` nodes to edit by hand, and marks the design `props_frozen`. Adds lines only. Close the editor first. |
| `npm run strings` | Collects every player-facing English string into `locale/messages.pot`. Run it after changing any text; a test fails while the file is out of date. |
| `npm run api` | Dumps the 4.7.2 class reference to `.godot-api/doc/classes/*.xml`. |
| `npm run editor -- [scene]` | Opens the editor, on the given scene if one is named. The MCP tools need it. |
| `npm run sculpt-check` | Drives the Sculpt and Paint tabs inside the real editor with made-up mouse events, prints what it checked and screenshots the editor into `.shots/sculpt_*.png` and `paint_*.png`. Leaves the project's sculpted and painted ground alone. Close the editor first. |
| `npm run game -- --regions=5` | A test world of 5 x 5 regions instead of the starting zone. |
| `npm run perf -- [scene] [--seconds=60] [--speed=12] [--regions=20] [--without=Waters]` | Benchmarks a world (default: the field) in a window; writes `.perf/<world>.json`. `--without` switches nodes off to measure what they cost. Only compare runs made plugged in: on battery the laptop caps at 30 fps and throttles, and one run then took 223 ms a frame. Check first: `powershell -NoProfile -Command "(Get-CimInstance -Namespace root/wmi -ClassName BatteryStatus).PowerOnline"`. |
| `npm run game -- [scene] [--sector=C4] [--hour=21.5]` | Plays until the window is closed, starting in the given sector and at the given time of day. It blocks, so run it in the background when asked to launch the game. |

Godot lives in `%LOCALAPPDATA%\Programs\Godot\4.7.2\`, pinned in
`tools/dev.mjs`. The `GODOT` environment variable overrides it. Blender 5.2.3
LTS lives in `%LOCALAPPDATA%\Programs\Blender\5.2.3\`, pinned the same way
(`BLENDER` overrides it).

## Definition of done

1. `npm run verify` passes. Untyped declarations are compile errors in this
   project, so the check also enforces static typing.
2. If the change is visible, look at it: `npm run shot` (or MCP
   `take_screenshot`), Read the PNG, and judge it. Iterate before calling it
   done.
3. New behaviour gets a GUT test: `tests/unit/` for logic, `tests/smoke/` for
   scenes loading and wiring together.

## Models from Blender

- Models are made by Python scripts in `tools/blender/`, run by
  `npm run models`, never by hand-editing a `.blend` in the repo: the script
  is the source, the `.glb` its output. Same idea as the sector designs.
- Characters use the bone names of Godot's `SkeletonProfileHumanoid` (Hips,
  Spine, Chest, LeftUpperArm...), so animations from elsewhere can be
  retargeted onto them later.
- Every part of a mesh that spans a joint needs rings along its length, or
  it stretches straight from end to end instead of bending (see
  `Body.cylinder` in `build_hero.py`).
- Check animations by rendering them in Godot, not by reading numbers:
  bone-axis signs are easy to get backwards.

## MCP: the `blender` server

`.mcp.json` also starts `mcp-for-blender==2.2.4` with `DISABLE_TELEMETRY`.
Its add-on (`blender_mcp.py`, in Blender's user add-ons, enabled) listens on
`localhost:9876` while Blender is open: run `npm run blender` first. Its
asset services (Poly Haven, Sketchfab, Hyper3D and the like) stay off; we
never use third-party assets. Use it to look at and try things in a live
scene; anything worth keeping goes into a script in `tools/blender/`.

## MCP: the `godot` server

`.mcp.json` starts `godot-mcp-server@0.6.1`, and the editor plugin
(`addons/godot_mcp`) connects to it on `ws://127.0.0.1:6505`.

- The tools only work while the editor has this project open. If
  `get_godot_status` reports no connection, run `npm run editor` and wait
  about 10 seconds.
- Live testing loop: `run_scene {wait_for_runtime: true}`, then `send_input`,
  `query_runtime_node` and `take_screenshot`, then `get_errors`, then
  `stop_scene`. Node paths start at the `runtime_root` that `run_scene`
  returns, e.g. `/root/Field/Player`.
- Pass `take_screenshot {save_to: "res://.shots/<name>.png"}`. The default
  folder is inside `addons/`, where the editor would import every PNG.
- Run `stop_scene` before editing scripts the running game uses.
- `send_input` actions go through the input map's 0.2 dead zone, so a
  strength `s` acts as `(s - 0.2) / 0.8`. Use 1.0 for full input.
- `call_method {runtime: true}` calls methods on live game nodes. For
  example, `Player.look_toward` aims the hero at a waypoint before walking
  there with `move_forward`.
- `mcp_undo` undoes changes made through MCP; Ctrl+Z in the editor doesn't.
- `validate_script` can't report diagnostics for `class_name` scripts, so treat
  `npm run check` as the source of truth.
- `classdb_query` answers API questions from the live engine.
- `map_project` starts a visualizer on port 6510 that listens on all network
  interfaces. Use it only on a trusted network.

## Sculpting terrain by hand

The author sculpts the ground in the editor with the Terrain Sculpt plugin
(`addons/terrain_sculpt/`, ours, not vendored): select the Terrain node and
paint in the 3D view. It lives in `src/world/land/` (`TerrainSculpt`,
`SculptBrush`) and `data/world/sculpt/`, one `.res` per 100 m tile, saved after
every stroke.

- The tiles in `data/world/sculpt/` are the author's work: commit them, and never
  overwrite or delete them.
- Ask `WorldShape.height` for the land, sculpts included;
  `WorldShape.base_height` is what code makes without them.
- Sculpting moves the ground, not what stands on it: hand-placed `Prop` nodes
  and a design's water stay where they are.
- Tests start with `TerrainSculpt.start_empty()` (`tests/pre_run.gd`) so they
  don't depend on sculpts, and baked content counts as stale then.
- GDScript classes have a built-in `reload()`: never name a static function
  that.
- A design with `decorates_land` adds content without owning ground, for sectors
  that keep the hand-sculpted land and poured water. Split wide areas into blocks
  of about 5 x 5 sectors: a design streams as one unit.
- Water in carved ground is data in `data/world/water/` (`RegionWater`,
  `WaterField`): it never changes the ground, and it refills itself when the
  land changes. Rivers' levels must not rise downstream, and must stand above
  their beds.

## Painting the ground by hand

The Paint tab, the Sculpt tab's sister, in the same plugin: press Paint in the 3D
view's toolbar and drag. It lives in `src/world/land/` (`TerrainPaint`,
`PaintBrush`) and `data/world/paint/`, one `.res` per 100 m tile, saved after
every stroke.

- The tiles in `data/world/paint/` are the author's work: commit them, and never
  overwrite or delete them.
- Painting changes no heights or meshes. `grass_grid.gdshader` draws the surfaces
  from two textures (global shader parameters, in `project.godot`).
- A new surface needs a name and swatch in `TerrainPaint` and a block in the shader.
  All eight places in the two textures are in use; a ninth surface needs a third.
- Tests start with `TerrainPaint.start_empty()` (`tests/pre_run.gd`).
- `TerrainPaint.paving_at` says where paving lies. R1's waterside plants keep off it
  the next time content is baked.

## Sectors

The world is built sector by sector. Sectors are 10 x 10 m, named A1 to T20:
A1 is the south-west corner sector and the start, letters grow east (+X) and
numbers north (-Z). Use `SectorMap` for all sector maths and names, and
`--sector=<name>` with `npm run game` or `npm run shot` to start there. When a
sector gets content, record what was decided for it in
`docs/DESIGN_DECISIONS.md`, under its name.

The demo's sector designs are at git tag `demo-final`.
Sector content is built with the `/environment-design <sectors> <brief>`
skill (`.claude/skills/environment-design/`). Each design is a `SectorDesign`
in `src/world/field/sectors/<slug>/`, registered under the field's `Sectors`
node. It owns its sectors and shapes only them: their ground, water and
props. `FieldTerrain` turns the designs into the ground, and
`tests/smoke/test_sector_designs.gd` checks that every design stays inside its
sectors.

The world streams. `Streamer` (`SectorStreamer`) loads a design's content
while any of its sectors is within 4 sectors of the player or the camera,
reading the baked scene on a background thread, and unloads it beyond 5.
Unloaded designs leave a coarse stand-in of their ground in `FieldTerrain`;
heights, water and flow stay known everywhere. So:

- A design's nodes go into its content with `add_content` and the add_*
  helpers, never `add_child`. Read them back with `design.part("Name")`.
- Content comes and goes. Anything the player changes must be recorded in
  `WorldState` (see `persist_id` on `ItemPickup` and `SwordChest`), or it
  resets when its sector reloads.
- Bushes, rocks and trees are props (`Prop`, `PropLibrary`): code places
  them with `place_prop` while a design is being made, and
  `npm run props -- <Design>` freezes them into the scene, after which
  they're edited by hand and the code places none (`props_frozen`). Grass,
  flowers and other masses stay scattered in code (MultiMesh).
- Ids in `WorldState` end up in players' saves, so they must never change:
  every design has a `design_id` (lowercase, unique, set once), hand-placed
  things use `content_id("local_name")` and scattered ones
  `scatter_id("kind", xz)`. Never build an id from a node name or a
  placing order. `test_sector_designs` checks the ids.

## Regions

- Design skills at three scales: `/region-design <regions> <brief>` shapes
  the land of whole regions with landforms (data in
  `data/world/landforms/`); `/environment-design <sectors> <brief>` builds
  the detail of sectors on top; `/asset-design <brief>` makes one object in
  Blender (`tools/blender/assets/`) to place as a prop. Shape the regions
  first.

- The world is regions of 20 x 20 sectors (200 m): the starting zone, with R1 in
  the middle and R2 to R9 clockwise around it from the north (`FieldWorld`,
  `RegionMap.STARTING_ZONE`). R1's A1 stays at world (0, 0), so its neighbours have
  negative coordinates: use `SectorMap.bounds()`, never assume the world starts at
  zero. Sector names carry their region (`R4:J10`); a name without one means R1.
- Region borders and names are gold, drawn by the ground shader and `SectorGrid`:
  always in the game; in the editor the names show only when zoomed out, past
  `label_visible_distance`.
- The hills ease flat around R1's rim (`WorldShape.rim`), which keeps its land as
  carved. `WaterField`'s grid covers R1 only; water elsewhere must widen it.
- Never loop over the whole world's sectors: at 2 km it would be 40,000. Work per
  region (SectorGrid, the streaming map) or per streamed chunk.
- Anything slow that a region change triggers runs on a worker thread
  (`WorkerThreadPool`) and is swapped in when ready; check with
  `npm run perf`, which lists every slow frame and where it happened.

## Saves

- A save is plain JSON with a format number, `SaveGame.FORMAT`. Older
  formats are upgraded on reading by `SaveMigration`; saves from a newer
  game are refused.
- Changing what a save holds, or renaming any id a save refers to (design
  ids, local names, item ids), means a new format: bump `FORMAT`, add a
  `_from_<N>` step to `SaveMigration`, and add
  `tests/fixtures/saves/format_<N>.json` in the old shape. Never edit an old
  fixture or step; a test upgrades every one.

## Text and localization

- The game is English only for now, but every string the player reads goes
  through translation: `tr("...")` in nodes,
  `TranslationServer.translate("...")` in static code, `tr_n` /
  `translate_plural` for counts, and `Text.mark("...")` for English stored
  now and translated where it's shown (prompts and titles set by designs,
  which are baked). Item names, descriptions and facts are translated where
  they're shown.
- Translate the format string, not the result: `tr("Sector %s") % name`.
- Run `npm run strings` after changing any text. `test_localization` fails
  when the catalog is stale or when text is set from a bare literal.
- Tests that look inside designs call `load_all_now()` on the streamer
  first; it loads everything and stops streaming.
- Nodes with their own script are baked without their children and build
  them again on `_ready`.

## Editing while the editor is open

The editor keeps open scenes and the project settings in memory. A scene or
`project.godot` edited on disk while the editor is open can be overwritten
the next time the editor saves; this once dropped two sector designs and the
inventory key. `tests/unit/test_project_setup.gd` checks that every input
action and sector design is still there. Check `tasklist` for a running
Godot before editing those files, and ask the author to close the editor
first.

- `.gd` files: edit on disk freely; the editor reloads them.
- Scenes and resources open in the editor: change them through MCP tools, or
  close their tabs first (`close_editor_tabs`).
- New or changed assets need `rescan_filesystem` (MCP) or `npm run import`
  before anything can load them.

## Layout

```
src/autoload/    global singletons (DevTools; MCPRuntime comes from the add-on)
src/shared/      reusable code, components and shaders; nature/ holds the rocks, plants, water and stream kit
src/world/       levels; field/ is the one world (the sector grid and the ground); land/ holds the land's layers
src/world/field/sectors/   one folder per sector design
src/world/streaming/ streaming: SectorStreamer, baked files, WorldState
src/audio/       sound made in code: footsteps, the world's ambience
src/save/        save files (JSON in user://saves) and SaveMigration
locale/          messages.pot, generated by npm run strings
baked/           generated by npm run bake; not committed
src/player/      the player character and HeroBody, the animated body
src/npc/         NPCs (villagers with daily programs)
src/items/       carrying and picking up items
src/ui/          HUD and menus
data/            game data as Resources (.tres); world/sculpt/ and world/paint/ hold the hand-sculpted and hand-painted ground
assets/          imported art and audio: models/ textures/ materials/ audio/ fonts/; models/ holds .glb built by tools/blender/
tests/unit/      logic tests
tests/smoke/     scene loading and wiring tests
tests/fixtures/  frozen inputs, such as saves in every old format, and a design and items only tests use
tools/           dev.mjs (the npm commands), check_project.gd
docs/            DESIGN_DECISIONS.md (the author's record), ARCHITECTURE.md, world/ (art, lore and notes per region)
addons/          vendored third-party code, read addons/README.md before touching it; terrain_sculpt/ (sculpting and painting) is ours
```

Organise by feature: a scene, its scripts and its local resources live in one
folder, like `src/world/field/`.

## GDScript conventions

- Follow the official style guide: snake_case for files, functions and
  variables, PascalCase for `class_name` and node names, CONSTANT_CASE for
  constants, tabs for indentation.
- Type everything. Use `:=` when the type is obvious from the right-hand side.
- Write `##` doc comments on classes and public functions. Comments say why,
  not what.
- Give a script a `class_name` only when other code refers to its type, and
  never one that matches an autoload name.
- Put tunable numbers in `@export` variables or Resources, not literals in
  logic, so the author can tune them.
- Call down, signal up. Name signals with past-tense verbs (`died`,
  `item_picked_up`).
- Script order: signals, enums, constants, `@export`, public vars, private
  vars (`_`-prefixed), `@onready`, built-in callbacks, public methods, private
  methods.

## Godot gotchas

- A runtime error in a `--script` tool's `_initialize` leaves Godot running
  forever. Run throwaway tools under `timeout`.
- Lambdas kept in a long-lived Dictionary or Array (a command table, say)
  leak at exit ("ObjectDB instances were leaked"); register methods instead.

- `--headless` can't render, so screenshots need a window. `npm run shot`
  opens one for a few seconds.
- Commit `.uid` and `.import` files; never commit `.godot/`.
- A hand-written `.tscn` stores each `Transform3D` basis row by row. Prefer
  building scenes through MCP or a Godot script, and let Godot serialize them.
- APIs changed between 4.4 and 4.7. When unsure about a class, grep
  `.godot-api/doc/classes/<Class>.xml` (run `npm run api` first if it's
  missing) or use `classdb_query`.
- Physics runs on Jolt (a project setting), not Godot Physics.
- Code-generated content lives in `@tool` scripts that add children without an
  owner, so the editor shows the result but never saves it into the scene.
  Don't set generated data on nodes that are saved in the `.tscn`.
- Vertex and MultiMesh colours aren't converted from sRGB automatically. The
  low-poly shader converts them; on a StandardMaterial3D, set
  `vertex_color_is_srgb`.
- Interpolated vertex colours dip below 0 at triangle edges (MSAA shades pixel
  centres outside the triangle). Clamp them before `pow()`, or the NaN blooms
  into white blobs with a black centre.
- Headless runs (the tests, the bake) can't read MultiMesh data back: the
  dummy renderer keeps no buffers. Designs use `BakedMultiMesh`, which keeps
  its copies in its own buffer (`instance_transforms` reads them).
- `Control.set_anchors_preset()` keeps the control's current rectangle by
  moving its offsets, so a new control stays 0 x 0. Use
  `set_anchors_and_offsets_preset()` to fill the parent.
- Packed arrays are values: one stored in a Dictionary or Array must be read,
  changed and stored back.
- On battery this laptop caps games at 30 fps. Measure performance on AC power.
- Folders starting with `.` (`.shots/`, `.godot-api/`) are invisible to Godot.

## Git

The repo is github.com/poetowski/godotDEMO, branch `main`. Run
`git lfs install` once per machine; `.gitattributes` routes binary assets
through Git LFS.
