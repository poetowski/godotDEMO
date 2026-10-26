# godotDEMO

A 3D RPG in Godot 4.7.2: GDScript, Forward+, Jolt physics. "godotDEMO" is a
working title and the game's design is not decided yet.

## Who decides what

- Game content is the author's call: names, story, characters, mechanics,
  numbers, controls, art direction. Propose, then wait for a yes before
  building it.
- `docs/DESIGN_DECISIONS.md` is the author's record. Build what it says;
  anything else is a placeholder and is marked as one.
- Engineering (architecture, tooling, tests, performance) is yours to propose
  and build. Spell out the tradeoffs when a choice is hard to undo.
  `docs/ARCHITECTURE.md` lists what exists and the open technical questions.

## Commands

| Command | What it does |
|---|---|
| `npm run check` | Imports assets, then loads every script, scene and resource in `src/ data/ assets/ tests/ tools/`. Fails on any error. |
| `npm test` | Runs the GUT suite headless. Add `-- -gselect=test_fly_camera` to run one file. |
| `npm run verify` | `check`, then `test`. |
| `npm run shot -- [scene] [--out=x.png] [--frames=60] [--size=1280x720]` | Plays a scene (default: the main scene) in a window, saves `.shots/<scene>.png` and quits. Read the PNG to see it. |
| `npm run shot -- --camera=x,y,z --look=x,y,z --out=.shots/view.png` | The same, shot from a temporary camera at any viewpoint. |
| `npm run shot -- --frame=A1:C3 --out=.shots/area.png` | The same, from a camera framing those sectors from above. |
| `npm run import` | Headless import, after adding or changing assets outside the editor. |
| `npm run api` | Dumps the 4.7.2 class reference to `.godot-api/doc/classes/*.xml`. |
| `npm run editor` | Opens the editor, which the MCP tools need. |
| `npm run game -- [scene] [--sector=C4]` | Plays until the window is closed, starting in the given sector. It blocks, so run it in the background when asked to launch the game. |

Godot lives in `%LOCALAPPDATA%\Programs\Godot\4.7.2\`, pinned in
`tools/dev.mjs`. The `GODOT` environment variable overrides it.

## Definition of done

1. `npm run verify` passes. Untyped declarations are compile errors in this
   project, so the check also enforces static typing.
2. If the change is visible, look at it: `npm run shot` (or MCP
   `take_screenshot`), Read the PNG, and judge it. Iterate before calling it
   done.
3. New behaviour gets a GUT test: `tests/unit/` for logic, `tests/smoke/` for
   scenes loading and wiring together.

## MCP: the `godot` server

`.mcp.json` starts `godot-mcp-server@0.6.1`, and the editor plugin
(`addons/godot_mcp`) connects to it on `ws://127.0.0.1:6505`.

- The tools only work while the editor has this project open. If
  `get_godot_status` reports no connection, run `npm run editor` and wait
  about 10 seconds.
- Live testing loop: `run_scene {wait_for_runtime: true}`, then `send_input`,
  `query_runtime_node` and `take_screenshot`, then `get_errors`, then
  `stop_scene`. Node paths start at the `runtime_root` that `run_scene`
  returns, e.g. `/root/Sandbox/FlyCamera`.
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

## Sectors

The world is built sector by sector. Sectors are 10 x 10 m, named A1 to T20:
A1 is the south-west corner sector and the start, letters grow east (+X) and
numbers north (-Z). Use `SectorMap` for all sector maths and names, and
`--sector=<name>` with `npm run game` or `npm run shot` to start there. When a
sector gets content, record what was decided for it in
`docs/DESIGN_DECISIONS.md`, under its name.

Sector content is built with the `/environment-design <sectors> <brief>`
skill (`.claude/skills/environment-design/`). Each design is a `SectorDesign`
in `src/world/field/sectors/<slug>/`, registered under the field's `Sectors`
node. It owns its sectors and shapes only them: their ground, water and
props. `FieldTerrain` turns the designs into the ground, and
`tests/smoke/test_sector_designs.gd` checks that every design stays inside its
sectors.

## Editing while the editor is open

The editor keeps open scenes in memory. A scene edited on disk while it's open
there can be overwritten the next time the editor saves.

- `.gd` files: edit on disk freely; the editor reloads them.
- Scenes and resources open in the editor: change them through MCP tools, or
  close their tabs first (`close_editor_tabs`).
- New or changed assets need `rescan_filesystem` (MCP) or `npm run import`
  before anything can load them.

## Layout

```
src/autoload/    global singletons (DevTools; MCPRuntime comes from the add-on)
src/shared/      reusable code, components and shaders; nature/ holds the rocks, plants, water and stream kit
src/world/       levels; field/ is the main scene (the sector grid), sandbox/ the dev test ground
src/world/field/sectors/   one folder per sector design
src/player/      the player character
src/items/       items such as the sword
src/ui/          HUD and menus
data/            game data as Resources (.tres)
assets/          imported art and audio: models/ textures/ materials/ audio/ fonts/
tests/unit/      logic tests
tests/smoke/     scene loading and wiring tests
tools/           dev.mjs (the npm commands), check_project.gd
docs/            DESIGN_DECISIONS.md (the author's record), ARCHITECTURE.md
addons/          vendored third-party code; read addons/README.md before touching it
```

Organise by feature: a scene, its scripts and its local resources live in one
folder, like `src/world/sandbox/`.

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
- Headless runs (the tests) can't read MultiMesh transforms back: the dummy
  renderer keeps no buffers. Sector designs remember theirs
  (`instance_transforms`).
- Packed arrays are values: one stored in a Dictionary or Array must be read,
  changed and stored back.
- On battery this laptop caps games at 30 fps. Measure performance on AC power.
- Folders starting with `.` (`.shots/`, `.godot-api/`) are invisible to Godot.

## Git

The repo is github.com/poetowski/godotDEMO, branch `main`. Run
`git lfs install` once per machine; `.gitattributes` routes binary assets
through Git LFS.
