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
    R1/               one per region, copied from _template once work on it starts
      README.md       the region at a glance, and its decisions, newest last
      art.md          how it looks: colours, materials, mood, what to avoid
      lore.md         its history, places and people, and flavor text
      terrain.md      its land and water: what's where, and why
      notes.md        anything else: ideas, questions, references
```

## Levels

The land has one height at each spot, and so does its water. Anything else that can be
walked on is a level of its own, above or below the land: a bridge, the fifth floor of a
tower, a cave under a lake. The game asks what's around someone from where they really
are, height included, so the water under a bridge stays under it.

- **A floor needs no setting up.** Anything solid can be stood on at any height. It only
  needs collision, with slopes for stairs: the hero walks up slopes, not steps.
- **A named place** is a `LevelVolume`, a box you can place and size in the editor: a floor
  of a building, a chamber of a cave. Its name shows beside the sector. Inside it the wind
  drops and the birds stop, unless `Enclosed` is off, as on a rooftop. Underground counts
  as enclosed without one. In a building, one box per floor. A smaller box inside a bigger
  one wins.
- **A pool at its own height** is a `LevelVolume` with `Water Depth`, for water in a cave or
  on a roof, where the land's water can't be. It only says where the water is, and the
  design draws it.
- **A way down** is a `GroundOpening`, a rectangle cut out of the land's mesh and collision,
  which you can drag in the editor. It goes in the scene, not in a design's content, and only
  cuts land a design doesn't shape. Its rim is jagged to the metre, so what goes in the hole
  has to hide it.
- **Props on a floor:** tick `Keep Height` on the prop, or `npm run settle` puts it back
  on the land. An asset that spans ground, such as a bridge, listed in `PropLibrary.SPANS`,
  doesn't need it.
- **Falling:** a fall lands on whatever is really there, and water only catches it at its
  surface. Falling 150 m with nothing to land on counts as dying.

Say which levels a place has in its region's `terrain.md`. **Placeholder:** how far the wind
drops, and the 150 m.

**Not there yet:** a cave is lit by the sky's ambient light until the first one decides how
dark it should be. Villagers walk only the land. Footsteps sound like grass on everything
but water, bridges included.

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
