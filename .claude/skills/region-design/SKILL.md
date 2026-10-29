---
name: region-design
description: Shape the land of whole regions (200 m each) from a written brief - mountains, hills, ridges, valleys, plateaus, with rock, snow and how thick the woods grow on them - without touching anything outside those regions. Use when asked to design terrain or landscape at region scale, or across several regions, for example "R2: a big mountain" or "R12-R14: a long valley". For detail inside sectors (water, props, buildings) use /environment-design instead.
argument-hint: <regions> <description>
---

# Region design

Shape the land of one or more regions from a brief. A region design is a
set of **landforms** (mountains, hills, ridges, valleys, plateaus) kept as
data in `data/world/landforms/<slug>.tres`. The world adds them to its
height everywhere (`WorldShape`): rolling hills, then the landforms, then a
little small detail. The ground turns to rock where it's steep and to snow
above a landform's snow line, and the procedural woods thin out on them as
told. `data/world/landforms/r2_mountain.tres` is a finished example: a big
mountain in R2, with a shoulder ridge and a foothill.

The two design skills work at two scales and stack:

| Skill | Scale | Makes | Where it lives |
|---|---|---|---|
| `/region-design` | regions (200 m) | the shape of the land, rock, snow, tree cover | `data/world/landforms/` |
| `/environment-design` | sectors (10 m) | detailed ground, water, props, buildings | `src/world/field/sectors/` |

A sector design sits on whatever land is under it and blends into it at its
edges. So shape the regions first, then detail sectors on top.

## Input

`/region-design <regions> <description>`, for example
`/region-design R2: a big mountain spanning several sectors`.

- **Regions.** Names (`R2`), several (`R2 R3`), or a run (`R12-R14`).
  Regions are 20 x 20 sectors (200 m), numbered R1, R2... from the
  south-west corner, east along each row, then north (`RegionMap`). The
  world is 10 x 10 regions: R1 to R100. Resolve names with
  `RegionMap.named`.
- **Description.** What the land should be. If the regions or the
  description are missing, ask for them first.

## Rules

1. **Only the listed regions change.** Every landform stays inside them:
   its `bounds()` (radius plus a margin for roughness) must lie within the
   regions' area. `tests/smoke/test_landforms.gd` checks this for every set.
   Keep about 10 m clear of the regions' outer edges.
2. **Designed sectors stay as they are.** No landform may reach a sector a
   `SectorDesign` owns (the test checks this too); designs sit on the land
   around them, and a landform under one would lift or bury it. List them
   first: `grep -n "sectors = " src/world/field/field.tscn`. If the brief
   needs land under a design, say so and ask.
3. **R1 is the flat building ground.** The hills and the small detail stay
   off in R1 (`WorldShape.home`). Landforms may go into R1 only when the
   brief asks for it there.
4. **The brief is the author's request.** Build what it says without asking
   for approval. Your own choices (exact heights, how many landforms, rock,
   snow, tree lines) are placeholders, recorded as such. Don't add things the
   brief didn't ask for, like lakes or rivers (those need sector designs);
   a waterfall or lake the brief asks for is a `Waterfall` or `Lake` in the
   set.
5. **Data, not code.** A region design is a `LandformSet` resource; don't
   change `WorldShape`, `Landforms` or the streaming for a brief. If a brief
   needs a kind of landform that doesn't exist, say so and propose adding it.
6. **Walkable where it should be.** The hero climbs slopes up to about 45
   degrees. A big mountain may be steep near its top, but leave its feet and
   some approach gentle, and keep any spot the brief calls a path, pass or
   meadow under 0.6 rise per metre.

## Landforms

`src/world/land/landform.gd`. Positions are world metres: `centre.x` east,
`centre.y` north (the world's -z). Region R's south-west corner is
`RegionMap.corner_of(region)`; R2 runs x 200 to 400 and north 0 to 200.

| Kind | `kind` | Shape |
|---|---|---|
| MOUNTAIN | 0 | gentle feet, steep flanks, a sharp top; with roughness, ridges and gullies |
| HILL | 1 | a smooth rounded rise |
| RIDGE | 2 | a long rise from `centre` to `end`, `radius` wide on each side |
| VALLEY | 3 | sinks by `height` |
| PLATEAU | 4 | steep sides, a flat top |

| Field | Meaning |
|---|---|
| `radius` | metres from the centre (or the ridge's line) to where it meets the land |
| `height` | metres at its highest (a valley sinks this much) |
| `roughness` | 0 smooth to 1 craggy; also makes the outline uneven |
| `tree_density` | trees on it compared with the woods around, 0 to 1 |
| `tree_line` | absolute height above which no trees grow on it; 0 for none |
| `snow_line` | absolute height above which its ground is snow; 0 for none |
| `tropical` | palms and jungle trees instead of round trees and pines; jungle grows and grass shows on slopes up to 1.7 rise per metre, so only cliffs are bare rock |
| `noise_seed` | so twin landforms differ |

**Waterfalls** (`src/world/land/waterfall.gd`) go in the set's `waterfalls`:
`top` and `bottom` (x east, y north), `width`, `pool_radius`, `pool_depth`.
`Waters` drapes streaming water over the ground from top to bottom, with
a pool and spray. Shape the land for it with landforms: a PLATEAU's edge
makes a cliff, a small VALLEY at the foot holds the pool. Falling south
faces R1. (The first one, a tropical range in R11, was replaced by the lake;
see git history before 2026-10-29's lake for its data.)

**Lakes** (`src/world/land/lake.gd`) go in the set's `lakes`: `centre`,
`radius`, `level` (the absolute water height: measure the land around the
shore first and pick a level near its low side; the bank rises where the
land is lower), `depth`, `island_radius` and `island_height` (an island in
the middle, 0 for none), `shore_woods` (tree cover on the shores). A lake
carves its basin after the landforms, its banks stay green, nothing grows
in its water, the hero swims in it, and `Waters` draws its surface. It
reaches `radius * 1.3 * 1.08` from its centre: keep that inside the
regions. `data/world/landforms/r11_lake.tres` is an example.

Landforms add up: a mountain with a ridge from its side makes a shoulder;
hills around a mountain's foot make foothills. The land under them already
rolls by up to 34 m outside R1, so a 20 m hill on a hill is 50 m high.

## Workflow

1. **Resolve the regions.** Write down each one's bounds in metres and which
   of their edges are the world's border.
2. **Plan in metres.** List every landform with kind, centre, radius and
   height. Check rules 1 to 3 against the plan: the outermost reach is about
   `radius * 1.15` for a rough landform.
3. **Write the set.** Copy `template.tres` from this skill's folder to
   `data/world/landforms/<slug>.tres`, the slug from the regions and the
   theme (`r2_mountain`). Fill in `id` (the slug), `regions`, `brief` (the
   author's words) and the landforms. One file per design; it's picked up
   on its own.
4. **Test it.** `npm run verify`. `test_landforms.gd` checks every set for
   rules 1 and 2. Add assertions for the brief's key features to
   `test_landforms.gd` (as the R2 mountain's are): heights, snow, rock, trees.
5. **Look at it.** Shoot and Read each:
   - from R1 or the nearest built place, the way a player first sees it:
     `npm run shot -- --hour=15 --camera=x,y,z --look=x,y,z --out=.shots/<slug>_far.png`
   - from close and above, to check the shape and the woods on it;
   - at dusk or night if it has snow (`--hour=20`).
   Fix what looks wrong and shoot again.
6. **Record it** in `docs/DESIGN_DECISIONS.md`: the brief verbatim, what was
   built, and the placeholders.
7. **Commit and push** to `main` with the attribution lines.

## Gotchas

- Positions are north-up (`centre.y` = -z). A landform placed with the
  world's z sign lands in the wrong place, south of the world.
- Heights are absolute for `tree_line` and `snow_line`: include the rolling
  hills under the landform when choosing them.
- The ground's detail falls off with distance (1 m near, 20 m far), so a
  thin spire narrower than about 20 m only shows close up.
