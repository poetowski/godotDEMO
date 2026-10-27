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

## Playing

`npm run game` opens the grass field and its sector grid: 20 x 20 sectors of
10 x 10 m, named A1 to T20. You start in A1 at the south-west corner; letters
grow east and numbers grow north, ahead of you. The top-left corner shows the
sector you're in. `npm run game -- --sector=C4` starts you in C4.

A1 to A3 are the first designed sectors: a spring, a small stream and a lily
pond. New sectors are designed with the `/environment-design` skill in Claude
Code, for example `/environment-design B1, B2: a birch grove around a
clearing`.

WASD move, Shift sprint, Space jump, E interact, I inventory, Esc game menu (save, load), F5 quicksave, F9 quickload, mouse look (click the window first; Esc
frees the mouse), wheel zoom, F3 performance overlay, F12 screenshot. A
gamepad works too.

The earlier castle proof of concept is kept at git tag `poc-castle`.

## Commands

```
npm run check     load everything, fail on any error
npm test          run the GUT tests headless
npm run verify    check + test
npm run shot      play the main scene, save .shots/main.png, quit
                  (add -- --camera=x,y,z --look=x,y,z for any viewpoint,
                  or -- --frame=A1:A3 to frame sectors from above)
npm run game      play the game
npm run import    import new assets without the editor
npm run bake      bake the sector designs for streaming (game, shot and
                  test do it when needed)
npm run api       dump the engine class reference to .godot-api/
```

`CLAUDE.md` covers working rules, conventions and gotchas.
`docs/ARCHITECTURE.md` covers what exists and the open technical questions.
`docs/DESIGN_DECISIONS.md` is the design record.
