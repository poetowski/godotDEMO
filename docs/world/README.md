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
