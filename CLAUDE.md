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
| `npm run import` | Headless import, after adding or changing assets outside the editor. |
| `npm run api` | Dumps the 4.7.2 class reference to `.godot-api/doc/classes/*.xml`. |
| `npm run editor` | Opens the editor, which the MCP tools need. |
| `npm run game -- [scene]` | Plays until the window is closed. It blocks, so don't run it unless asked. |

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
- `mcp_undo` undoes changes made through MCP; Ctrl+Z in the editor doesn't.
- `validate_script` can't report diagnostics for `class_name` scripts, so treat
  `npm run check` as the source of truth.
- `classdb_query` answers API questions from the live engine.
- `map_project` starts a visualizer on port 6510 that listens on all network
  interfaces. Use it only on a trusted network.

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
src/shared/      reusable code, components and shaders
src/world/       levels and world scenes; sandbox/ is the dev test ground
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
- Folders starting with `.` (`.shots/`, `.godot-api/`) are invisible to Godot.

## Git

There's no repo yet. Once there is: run `git lfs install` once per machine;
`.gitattributes` already routes binary assets through Git LFS.
