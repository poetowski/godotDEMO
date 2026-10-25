# godotDEMO

A 3D RPG built in Godot 4.7.2 with Claude Code. Working title.

## Setup (already done on this machine)

- Godot 4.7.2 in `%LOCALAPPDATA%\Programs\Godot\4.7.2\`
- Node.js 20 or newer (the dev commands have no npm dependencies)
- Add-ons vendored in `addons/`: GUT 9.7.1 for tests, Godot MCP 0.6.1 for
  Claude Code (see `addons/README.md`)

## Start working

1. `npm run editor` opens the project in the Godot editor.
2. Start Claude Code in this folder. Approve the `godot` MCP server when it
   asks; `/mcp` should then list it as connected.
3. The editor's top-right status reads **MCP: Agent Active** once Claude Code
   and the editor are talking.

## Playing the proof of concept

`npm run game` opens the castle proof of concept. Walk the paved path, take the
sword from the stone beside it, and head for the castle.

WASD move, Shift sprint, Space jump, E take the sword, left click swing, mouse
look (click the window first; Esc frees the mouse), wheel zoom, F3 performance
overlay, F12 screenshot. A gamepad works too.

## Commands

```
npm run check     load everything, fail on any error
npm test          run the GUT tests headless
npm run verify    check + test
npm run shot      play the main scene, save .shots/main.png, quit
                  (add -- --camera=x,y,z --look=x,y,z for any viewpoint)
npm run game      play the game
npm run import    import new assets without the editor
npm run api       dump the engine class reference to .godot-api/
```

`CLAUDE.md` covers working rules, conventions and gotchas.
`docs/ARCHITECTURE.md` covers what exists and the open technical questions.
`docs/DESIGN_DECISIONS.md` is the design record.
