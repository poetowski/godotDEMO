---
name: environment-design
description: Design the environment of chosen field sectors from a written brief, including the terrain shape, water, rocks, plants and other props, without touching anything outside those sectors. Use when asked to design, build, landscape, decorate or populate sectors of the field, for example "A1, A2, A3: a small river with lilies".
argument-hint: <sectors> <description>
---

# Environment design

This is the sector-scale design skill. For the shape of the land over whole
regions (mountains, valleys, ridges) use `/region-design`; a sector design
sits on that land and blends into it at its edges.

Build one area of the field from a brief: shape its ground, add water and
place props inside the given sectors, and leave everything else as it was.
`src/world/field/sectors/a1_a3_stream/` at git tag `demo-final` is a finished example, made with this
skill: a spring, a stream, a lily pond, bushes, rocks and grass over three
sectors.

## Input

`/environment-design <sectors> <description>`, for example
`/environment-design A1, A2, A3: small river with flowing water, some lilies and small bushes; little bumpy terrain, rocks and grass around.`

- **Sectors.** Names (`A1 B2`), runs within one column or row (`A1-A3`), or
  rectangles given by opposite corners (`B2:D4`). Resolve each name with
  `SectorMap.cell_named`. Sectors run A to T and 1 to 20, and A1 is the
  south-west corner, where the player starts. Letters grow east (+x) and
  numbers grow north (-z).
- **Description.** What should be there. If the sectors or the description
  are missing, ask for them before doing anything.

## Rules

1. **Only the listed sectors change.** All the work goes into one new
   `SectorDesign` that owns exactly those sectors. Don't edit `FieldTerrain`,
   `SectorGrid`, other designs or field-wide settings (sky, sun, fog, the
   player) for a brief. If the brief seems to need one of those, say so and ask.
2. **One owner per sector.** Before starting, list the current owners:
   `grep -n "sectors = " src/world/field/field.tscn`. If a listed sector is
   already owned, ask whether to replace that design, extend it (widen its
   `sectors` and its script), or use other sectors.
3. **Nothing continues past the edge.** The ground eases back to flat within
   `edge_blend` (2 m) of every edge shared with an unlisted sector or the
   grid's border. Keep water and tall features at least `edge_blend + 0.5` m
   from those edges. A river needs a source and an end inside the area,
   such as a spring and a pond. When the brief implies more, such as a river
   that runs on, build the closed version and say so.
4. **The brief is the author's request.** Build what it says without asking
   for approval. Your own choices (layout, sizes, colours, small extra
   details) are placeholders, recorded as such. Don't add big things the brief
   didn't ask for, such as buildings, creatures or items; propose them instead.
5. **Generated in code.** Low-poly, built from the kit below, and the same
   every run, decided by `design_seed`. We never use third-party assets.
6. **Built for streaming.** The world loads a design's content only while
   the player is near, from a baked copy. Add every node with `add_content`
   or the add_* helpers, never `add_child`. Anything the player can change
   (take, open, destroy) records it in `WorldState` through a `persist_id`
   built with `content_id("local_name")` for one hand-placed thing or
   `scatter_id("kind", xz)` for scattered ones, so it stays changed when the
   sector reloads. Those ids go into saves: never derive them from node
   names or placing order, and never change one once it has shipped.
   Anything the player reads (prompts, titles, choices) is English wrapped
   in `Text.mark("...")`; the node translates it where it's shown.
6b. **Props for things worth placing by hand.** Bushes, rocks and trees go
   through `place_prop(kind, variant, where, solid)` (PropLibrary.Kind:
   BUSH, ROCK, ROUND_TREE, PINE), never straight into a merged mesh, and
   only while `props_frozen` is false (`if not props_frozen:` around the
   placing code). Once the design is done (step 6b of the workflow) they're
   frozen into the scene as Prop nodes the author edits by hand. Grass,
   flowers, lilies and other masses stay scattered in code. See the A1-A3 (`demo-final`)
   stream.
7. **The player can always start.** Props stay clear of every owned sector's
   start point (`crowds_start`), and A1's start point stays dry ground.
8. **Budget per sector:** about 1,500 grass tufts. Use one merged mesh per
   prop group per sector (`merged`/`commit_merged`), and a MultiMesh
   (`add_multimesh`) for anything repeated more than about 50 times. Add
   colliders only for props the player shouldn't walk through (about 0.45 m
   and up). Aim for about 100 ms of build time per sector; measure with a
   scratch script if unsure.

9. **Land the author sculpted stays theirs.** To decorate sectors with
   hand-sculpted ground or poured water (`data/world/sculpt/`, `data/world/water/`),
   set `decorates_land = true` on the design: it adds content only, and
   `_ground`, `_water_level` and `_flow` aren't used. `height_at`, `water_level_at`
   and `flow_at` still answer, from the land. Cover a wide area with several designs
   of about 5 x 5 sectors sharing a script, since a design streams as one unit.
   `src/world/field/sectors/r1_waterside/` is a finished example.

10. **More than one level.** `height_at`, `is_dry`, `claim` and `is_clear` are about the
   land. For a building, a bridge or a cave, see "Levels" in `docs/world/README.md`: floors
   are colliders with ramps, named places and pools are `LevelVolume`s added with
   `add_content`, a way through the land is a `GroundOpening` in the scene, frozen props on a
   floor set `keep_height`, and repeated floors put the level in `scatter_id`'s kind. Keep
   masses off a hole yourself: nothing else does.

11. **Opposite things match.** Lanterns and the like facing each other are the same design;
   vary them between segments, and a bridge is one segment. See `docs/world/art.md`.

## Workflow

1. **Resolve the sectors.** Write down each sector's bounds: a sector at column
   `c` and row `r` (A1 = 0, 0) spans x `10c` to `10c + 10` and z `-10r` to
   `-10r - 10`. Note which edges border unlisted sectors.
2. **Plan the layout in metres.** List every element with its position and
   size: water course, mounds, clusters, open ground. Treat the sectors as one
   area, so features run across the boundaries between them. Check the plan
   against rules 3 and 6.
3. **Write the design.** Copy `template.gd` from this skill's folder to
   `src/world/field/sectors/<slug>/<slug>.gd`. Name the slug from the sectors and
   the theme, such as `a1_a3_stream`. Fill in the hooks, remove what the brief
   doesn't need, and put tunable numbers in `@export`s.
4. **Register it** in `src/world/field/field.tscn`, as an `ext_resource` and a
   node under `Sectors`:
   ```
   [ext_resource type="Script" path="res://src/world/field/sectors/<slug>/<slug>.gd" id="8_<slug>"]
   ...
   [node name="<PascalSlug>" type="Node3D" parent="Sectors"]
   editor_description = "<one line>"
   script = ExtResource("8_<slug>")
   sectors = PackedStringArray("A1", "A2")
   design_id = "<slug>"
   design_seed = <any int>
   ```
   `design_id` names the design in saves for good: the slug, lowercase,
   unique. In a world of several regions, sector names carry their region
   ("R45:J10"); in the main field (R1 only) plain names ("A1") work.
   Give it no transform: designs sit at the origin. If the editor has the field
   open, close its tab first, or use the MCP tools.
5. **Test it.** Add `tests/smoke/test_<slug>.gd` asserting the brief's key
   elements: water where asked, plants on the right ground, each sector
   populated. Call `load_all_now()` on the field's `Streamer` in
   `before_all`, and read the content with `design.part("Name")`. See
   `tests/smoke/test_a1_a3_stream.gd` at git tag `demo-final`.
   `tests/smoke/test_sector_designs.gd` already checks every design for the
   invariants: nothing outside its sectors, no step at the edges, no sector
   claimed twice, A1's start dry. Run `npm run verify`.
6. **Look at it.** Shoot and Read each of these:
   - `npm run shot -- --frame=A1:A3 --out=.shots/<slug>_overview.png` (the
     area from above)
   - `npm run shot -- --sector=<first sector> --out=.shots/<slug>_start.png`
     (the player's view)
   - two or three close views of the focal points:
     `--camera=x,y,z --look=x,y,z`, about 1.5 m up
   - one view from a neighbouring flat sector looking in, to check the seam

   Check for floating or buried props, water edges and foam, steps at the
   area's edge, density, colours that clash with the field, black pixels
   with white glow around them (NaN in a shader), and anything outside the
   sectors. Iterate until it looks right.
6b. **Freeze the props** once the shots look right:
   `npm run props -- <PascalSlug>` (editor closed). Run `npm run verify`
   again and check that `git diff src/world/field/field.tscn` only adds the
   design's `props_frozen` and its props.
7. **Record it** in `docs/DESIGN_DECISIONS.md`, newest last:
   `## YYYY-MM-DD: Sectors A1 to A3: <short title>`, with the brief quoted
   word for word, what was built and where, and a list of the placeholders.
8. **Commit and push** to `main` (project rule). Report the overview and
   start screenshots, what you interpreted, and the placeholders.

## The kit

**`SectorDesign`** (`src/world/field/sector_design.gd`). Override the hooks;
the base calls them on a 0.25 m grid over the owned sectors.

| Hook | Return |
|---|---|
| `_setup()` | Build noise, paths and anything else the hooks need. Runs before sampling. |
| `_ground(xz)` | Height in metres before edge easing, above the land (`WorldShape`). 0 is the land as it lies, which isn't flat. |
| `_water_level(xz)` | The water surface height, or `NO_WATER`. Water shows where it's above the ground. |
| `_flow(xz)` | Water flow, m/s along x and z, drawn by the water shader. |
| `_ground_tint(xz)` | `GRASS`, or an sRGB colour whose alpha is how much grass still shows (mud = alpha 0). |
| `_populate()` | Place props. Ground and water exist by now; `rng` is seeded. |

Helpers to use in `_populate`:

- **Ground and water:** `height_at`, `water_level_at`, `flow_at`, `is_dry(xz, margin)`, `surface(xz)`, and `lowest_ground(xz, r)` to seat wide props without floating.
- **Placement:** `fits(xz, r)` (inside the owned sectors), `crowds_start(xz, r)`, `claim(xz, r)` and `is_clear(xz, r, spacing)` to keep props apart, `random_point()`, and `cells()`.
- **Output:** `merged(group, xz)`, which returns a `NatureKit.Batch` per sector, then `commit_merged(group, material)`; `add_multimesh(name, mesh, material, transforms, colors, visible_distance)`, one node per sector, read back with `instance_transforms(name)`; `add_mesh`; `add_collider(shape, transform)`; `add_content(node)` for anything else, such as an `ItemPickup`, a `GestureSpot` or particles.

**`StreamPath`** (`src/shared/nature/stream_path.gd`). Takes control points
as `Vector4(x, z, half_width, water_level)` and smooths them into a line.
`nearest(xz)` returns a `Hit` with `distance`, `half_width`, `edge()` (metres
outside the water), `reach()`, `level`, `direction` and `along`. It returns
null beyond `reach_metres`. A wide last point makes a pond. `points` and
`distances` let you walk along the stream to place things on the banks.

**`NatureKit`** (`src/shared/nature/nature_kit.gd`):

- **Shapes:** `rock_shape(rng)` with `rock_color(rng)`, `add_bush(batch, rng, transform)`, `lumpy_sphere(rng, r, lumpiness)`.
- **MultiMesh meshes:** `grass_tuft(rng, blades)` and `lily_pad(rng, with_flower)`.
- **Assets in masses:** `PropLibrary.mass_mesh(slug, sway, bob)` is an `/asset-design` asset's mesh for `add_multimesh` (pass `null` as the material). `PropLibrary.asset_scene(slug)` is its scene, for `place_prop(PropLibrary.Kind.ASSET, 0, where, solid, scene)`.
- **Materials:** `grass_material()` (sways), `floating_material()` (bobs on water), `water_material()` (made automatically from your water hooks), and `MeshKit.lowpoly_material()` for merged props.

**`FieldTerrain`** builds the ground meshes and collision from the samples.
It also answers `height_at`, `water_level_at`, `surface_height_at`,
`is_dry` and `find_dry_spot` for the whole field. `SectorGrid` bends the
light curtains over the new ground and hides the painted names in designed
sectors.

## Recipes

- **Bumpy ground:** FastNoiseLite at frequency 0.12 to 0.2 with 3 octaves,
  0.2 to 0.4 m of amplitude, plus a few smooth mounds,
  `height * (1 - t²)²` with `t` the distance over the radius.
- **Water:** carve a bed below the level (`level - depth * (1 - reach²)`), add a lip
  rising about 0.16 m out of the water, and keep land near the water above the
  level. Report a water level only within about 0.6 m of the water's edge, so
  low ground elsewhere stays dry. Narrow water flows faster. Still water
  (flow under 0.2 m/s) suits lilies.
- **Placement:**
  - Walk a `StreamPath` for bank props.
  - Scatter grass with a patch noise, so there are clumps and clearings.
  - Seat wide props on `lowest_ground`, sunk a little.
  - Claim rocks and bushes so later props keep clear of them.
- **Colours:** pick them in sRGB. Use greens and greys near the field's grass
  (0.27, 0.46, 0.18 to 0.44, 0.62, 0.26), so a design sits in the field instead of
  floating on it.

## Gotchas

- The game shows baked content: `npm run game`, `shot` and `test` re-bake
  when sources changed, but a game started another way may show the old
  version until `npm run bake` runs.
- MultiMesh data can't be read back headless. The helpers use
  `BakedMultiMesh`; read copies with `instance_transforms`.
- In shaders, clamp vertex and instance colours before `pow()`. Interpolated
  values dip below 0 at triangle edges under MSAA, and the NaN blooms into
  white blobs.
- Packed arrays inside dictionaries are values: read, change, store back.
- Untyped `for` variables are compile errors here; write
  `for index: int in [...]`.
