# godotDEMO

A 3D RPG built in Godot 4.7.2 with Claude Code. Working title.

## Setup (already done on this machine)

- Godot 4.7.2 in `%LOCALAPPDATA%\Programs\Godot\4.7.2\`
- Blender 5.2.3 LTS in `%LOCALAPPDATA%\Programs\Blender\5.2.3\`, only to
  rebuild models (`npm run models`); the built `.glb` files are committed
- uv (for the Blender MCP server)
- Node.js 20 or newer (the dev commands have no npm dependencies)
- Add-ons vendored in `addons/`: GUT 9.7.1 for tests, Godot MCP 0.6.1 for
  Claude Code (see `addons/README.md`)

## Start working

1. `npm run editor` opens the project in the Godot editor.
2. Start Claude Code in this folder. Approve the `godot` MCP server when it
   asks; `/mcp` should then list it as connected.
3. The editor's top-right status reads **MCP: Agent Active** once Claude Code
   and the editor are talking.

## Playing

`npm run game` opens the world: R1, one region of 20 x 20 sectors of 10 x 10 m,
named A1 to T20, rolling gently and otherwise empty. You start in A1 at the
south-west corner; letters grow east and numbers grow north, ahead of you. The
top-left corner shows the sector you're in. `npm run game -- --sector=C4` starts
you in C4.

WASD move, Shift sprint, Space jump, E interact, I inventory, Q quests, mouse
look (click the window first), wheel zoom. Esc opens the game menu, which pauses
the game and saves and loads; F5 quicksaves and F9 quickloads. F3 shows the
performance overlay and F12 takes a screenshot. A gamepad works too.

## Sculpting the terrain

In `npm run editor`, open `src/world/field/field.tscn`, go to the 3D view and
press **Sculpt** in its toolbar (or select the Terrain node). Paint with the left
mouse button; move the view as usual with the right button.

| | |
|---|---|
| 1 to 5 | Raise, Lower, Smooth, Flatten (to the height where the stroke starts), Restore (back to what the code makes) |
| Shift | swaps raising and lowering |
| Ctrl + wheel, or [ and ] | brush size |
| Sliders in the panel | size, strength, softness (0 for hard edges and cliffs) |
| Ctrl + Z | undo a stroke |

Every stroke saves itself into `data/world/sculpt/`; commit those files. The game
shows the sculpted ground the next time it starts.

The demo built before this is kept at git tag `demo-final`, the earlier castle
proof of concept at `poc-castle`.

## Commands

```
npm run check     load everything, fail on any error
npm test          run the GUT tests headless
npm run verify    check + test
npm run shot      play the main scene, save .shots/main.png, quit
                  (add -- --camera=x,y,z --look=x,y,z for any viewpoint,
                  or -- --frame=A1:A3 to frame sectors from above)
npm run game      play the game (-- --hour=21 to start at night; F7
                  runs time fast in dev builds)
npm run import    import new assets without the editor
npm run bake      bake the sector designs for streaming (game, shot and
                  test do it when needed)
npm run models    rebuild the Blender-made models (the hero, any assets) and import them
npm run asset-preview -- <slug>   render an asset next to a 1.8 m figure
npm run blender   open Blender for the Blender MCP tools
npm run strings   collect the player-facing text into locale/messages.pot
npm run perf      benchmark the world
npm run sculpt-check   drive the sculpting plugin in the real editor
npm run props     freeze a sector design's props into the scene to edit by hand
npm run api       dump the engine class reference to .godot-api/
```

In dev builds: ` opens the developer console (help lists its commands), F3
shows the performance overlay, F4 the streaming map, F7 runs time fast, F12
saves a screenshot.

`CLAUDE.md` covers working rules, conventions and gotchas.
`docs/ARCHITECTURE.md` covers what exists and the open technical questions.
`docs/DESIGN_DECISIONS.md` is the design record.
