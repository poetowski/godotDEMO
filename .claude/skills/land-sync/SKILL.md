---
name: land-sync
description: Bring everything standing on the land back in line after the author sculpts terrain or changes water - detect floating, buried or drowned props, water cut off or missing, undecorated shores, borders that no longer fit, and propose lowering objects, placing new ones or generating new assets. Use whenever the author says they changed, remodeled or sculpted the terrain, asks to redecorate or fix flying objects, or whenever the land-changed hook reports uncommitted land.
argument-hint: "[what the author wants done, if anything]"
---

# Land sync

The author sculpts the land by hand. This skill finds what the change broke or made
possible, and fixes or proposes it. It sits on the other skills: new decoration follows
`/environment-design` (rule 9, `decorates_land`), new objects follow `/asset-design`.

**Noticing a change:** at the start of work on the world, run `git status --short data/world`.
Uncommitted files in `data/world/sculpt/` or `data/world/water/` mean the land changed.
`tools/land_changed.mjs` does the same check, for use as a `UserPromptSubmit` hook; the
author decides whether to turn it on in `.claude/settings.json`, and it only runs in a
Claude session started in this project.

## Propose or act

- **Noticed it yourself, or the hook did:** report and propose, then wait for a yes. A
  message about something else gets its answer first, with the proposal in a short note.
- **The author asked** ("redecorate", "fix the flying objects"): do the repairs and the
  decoration without asking, and say what you did. New assets too if they said "if
  needed" or "generate"; otherwise propose them.
- **Always ask first:** deleting or moving a prop the author placed by hand, adding water
  they didn't mention to a hollow, moving a border by more than following the same rim.

## Rules

1. **The land is theirs.** Sculpt tiles are never changed or overwritten. Commit them
   first, in a commit of their own, so your work can be told from theirs.
2. **Close the editor first.** Check `tasklist` for Godot before touching `field.tscn`;
   an open editor overwrites it. If it's open, say so and wait. Never kill it.
3. **Their scene edits stay.** Before changing `field.tscn`, compare it with the last
   commit node by node. An editor re-save only adds uids and unique ids and drops
   defaults; a changed transform or a missing node is the author's and stays.
4. **Heights only, by default.** `npm run settle` changes only props' heights, so where
   a prop was moved by hand stays as it is.
5. **We never use third-party assets.** New objects come from a script in
   `tools/blender/`, in the region's family. See `/asset-design`.

## Workflow

1. **Detect.** `npm run land-check` (read-only). It names the changed tiles and regions.
2. **Look.** Map the changed area and shoot it from above and from the ground
   (`npm run shot -- --hour=15 --camera=x,y,z --look=x,y,z --out=.shots/<name>.png`). Numbers
   miss what the land now reads as, such as a new bay, cliff or island.
3. **Propose,** or act under the rules above, from this table:

   | The report says | What to do |
   |---|---|
   | floating, buried | `npm run settle` |
   | drowned | Delete it if code placed it; a prop the author placed is theirs to decide |
   | stranded from the water | Move it back to the shore, or remove it |
   | lake cut off by `lake_reach` | Widen `lake_reach` in `data/world/water/`; check it doesn't run on down its river |
   | river points above their water | If the channel moved, move those `points` into it; if its bed rose, lower `levels`, never rising downstream |
   | dug hollow with no water | Propose a `RegionWater` (`lake_seed`, a `lake_level` below where it spills) |
   | shores with no decoration | Add blocks, one per line of the report, to the region's design; new props frozen with `npm run props -- <Block>` |
   | block with no water near | Propose removing it |
   | border or fog points off the drop | Drag them back on the same rim: `ZoneBorder/Line` about 6 m below the land, `MistBarrier/FogLine` about 15 m |
   | undecorated land: steep, high, dug | Propose props, or new assets if nothing suits |

4. **New assets: only when nothing fits.** Check `src/world/props/assets/` first. Name what
   the land now has that nothing suits, such as bare rock on a new cliff, and say what
   you'd make and where it would go.
5. **Regenerating.** Frozen props that rule 3's comparison shows nobody moved may be
   regenerated against the new shore: remove the block's `Props` and `props_frozen`, then
   `npm run props -- <Block>` and `npm run settle`. Anything moved by hand stays.
6. **Decoration rules.** A region's decoration lives in
   `src/world/field/sectors/<region_theme>/`, and blocks are 5 x 5 sectors at most. Masses rebuild on
   their own from the land at the next bake, so only frozen props need help. Keep props'
   reach inside their block (`fits(xz, room * 1.7)`), and nothing below the ravine's mist.
7. **Check.** Run `npm run land-check` again, then `npm run verify`, and read the totals. Walk
   the area with `npm run perf -- --seconds=25 --heading=<radians>` if much was added, and
   shoot it again.
8. **Record.** Update the region's `terrain.md`, `docs/DESIGN_DECISIONS.md` for new
   requests (word for word), and mark your choices **Placeholder:**.
9. **Commit and push** to `main`, and report what changed and anything left to decide.

## Reading the report

- A clean line means that check found nothing, not that it looks right: step 2 still counts.
- `land-check` looks at the whole world, not only the changed tiles, so older findings
  show too. Say which ones are new.
- A hollow is ground sculpted down more than 0.8 m. A shallow dip, or a basin in land
  raised by noise, isn't listed.
