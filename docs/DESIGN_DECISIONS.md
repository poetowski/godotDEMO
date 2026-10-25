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
