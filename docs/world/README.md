# The world's notes

Where decisions, flavor text and notes about the world live, so art, visuals and
lore stay consistent from region to region. The author writes and decides what's
here. Claude reads it before working on a place, and adds to it only what the
author said or approved.

```
docs/world/
  art.md              the look of the whole world
  lore.md             the story of the whole world
  regions/
    _template/        copy this folder to start a region
    R1/
      README.md       the region at a glance, and its decisions, newest last
      art.md          how it looks: colours, materials, mood, what to avoid
      lore.md         its history, places and people, and flavor text
      terrain.md      its land and water: what's where, and why
      notes.md        anything else: ideas, questions, references
```

## The starting zone

Nine regions, each 200 x 200 m, with R1 in the middle. The numbers run clockwise.

```
R9  R2  R3      north
R8  R1  R4
R7  R6  R5
```

**Placeholder:** starting the clock at north, with R2.

## Borders

The world's edge, and the borders between zones, are drawn with one mechanic:

- **Warning line:** when the player crosses it, a message appears. In the west it runs
  a few metres inside the rim of the ravine, from R9's north edge round to R6's south
  edge at about R6:M1, and the message is "I should not be here...". All the land on
  the near side is free, in R6, R7 and R9 as much as anywhere. Drag the points under
  `ZoneBorder/Line` in the editor to move it.
- **Return line:** 8 m further on, the player is returned to the spawn point.
- **Highlight:** both lines show as red curtains, in the editor and in the game, like
  sector and region borders.

The author decides where each border runs and what it says. Say which sectors it
covers, in the region's `terrain.md`. **Placeholder:** the red highlight showing in
the game, which may go once the border is final; the points of the western line; and
the 8 m.

## Rules

- **Where a thing goes.** True everywhere: `art.md` or `lore.md` here. True of one
  region: that region's folder. Mechanics, controls and other game-wide decisions:
  `docs/DESIGN_DECISIONS.md`.
- **Ideas aren't decisions.** Decided things go in a region's Decisions list or
  under a file's headings. Anything undecided stays in `notes.md` or is marked
  **Idea:** so nobody builds it by mistake.
- **Places have names by sector.** Say where something is with sector names such
  as `C4` or `C4-F9`, so a note can be found on the map.
- **Placeholders are marked.** Anything Claude chose without being told is marked
  **Placeholder:** until the author says yes.
- **Empty is fine.** A heading with nothing under it means nothing is decided yet.
