# Design decisions

The author's record of decided game design: the world, story, characters,
mechanics, numbers, controls and art direction. Claude builds what this file
says; anything not recorded here is a placeholder and is marked as one.

Add an entry per decision, newest last:

```
## YYYY-MM-DD: <topic>
<the decision, with the details needed to build it>
```

"godotDEMO" is a working title.

## 2026-10-25: Castle proof of concept

Requested as a proof of concept, not final content:

- An environment with a fantasy castle, many trees, a paved path and bumpy
  terrain, with some light details such as clouds. Nothing very detailed.
- A sword placed nearby that the player can pick up and swing.
- The player is controlled from a third-person perspective.

Built in `src/world/poc_castle/`, which is the main scene. Everything not listed
above is a placeholder: the layout, colours, the hero's look, the controls,
speeds and swing timing. Whether third-person carries over to the real game
is still open.

## 2026-10-25: Sector grid on a grass field

The castle proof of concept's terrain and map are removed (kept at git tag
`poc-castle`). The world starts again as flat grass everywhere, divided into
sectors that we build one by one.

- Each sector is 10 x 10 m.
- The grid is 20 x 20 sectors (200 x 200 m), named by column letter and row
  number: A to T, 1 to 20.
- The start is in A1, a corner of the grid. Letters grow to the east and
  numbers grow forward, to the north, the way the player faces at the start.
- The grid lines are visible on the ground and light up toward the sky.

Placeholders: the light colour (pale cyan), the curtains' height (3 m) and
strength, how the sector names are painted, the HUD readout, and keeping the
third-person hero and the clouds.
