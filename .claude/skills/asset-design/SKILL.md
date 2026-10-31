---
name: asset-design
description: Make a 3D object (furniture, a machine, a statue, a cart, a lamp - any prop) from a written description, built in Blender by a script and exported as a game asset with its own collision, ready to place in the world as a prop. Use when asked to create, model or design an object or asset, for example "an alchemist's column of medieval flasks, about 2 m". For land use /region-design; for whole sectors use /environment-design.
argument-hint: <description>
---

# Asset design

Make one object from a brief: a Blender Python script builds it, it's
exported as `assets/models/props/<slug>/<slug>.glb` with its own collision,
and a prop scene lets anyone place it in the world. The alchemist's column
(`tools/blender/assets/alchemist_column.py` at git tag `demo-final`) is a finished example.
Assets that belong together share a family: `tools/blender/riverside.py` holds R1's
waterside palette and shapes, and each asset's script only names which to build.
New assets for a region use its family, and its `docs/world/regions/<region>/art.md`.

The design skills at their scales:

| Skill | Makes |
|---|---|
| `/region-design` | the shape of the land over regions |
| `/environment-design` | the detail of sectors: ground, water, scattered plants, props |
| `/asset-design` | one object, placed as a prop wherever it's wanted |

## Input

`/asset-design <description>`, such as
`/asset-design alchemist column system, medieval flasks, about 2 m`. Sizes
in the brief are rules. If the description is missing, ask for it.

## Rules

1. **Built by a script, in Blender.** One Python script per asset,
   `tools/blender/assets/<slug>.py`, using `tools/blender/kit.py`. It's the
   source: the `.glb` is its output, rebuilt with `npm run models -- <slug>`.
   We never use third-party assets: no downloaded models or textures, and
   never Blender MCP's asset services (Poly Haven, Sketchfab, generators).
2. **The project's look.** Low-poly, flat-shaded, colour from materials
   (picked in sRGB with `kit.material`), no textures. Glass is
   `alpha < 1`; things that glow use `emission`. Keep it under about 10,000
   triangles for a 2 m object; repeated things (bottles, leaves) share few
   segments (6 to 12).
3. **Real size, standing on its origin.** Blender units are metres; Z is up
   and the object's base sits at Z = 0, centred on X and Y, its front facing
   -Y. Meet the brief's size within 10 %.
4. **Its own collision, if it's solid.** Things worth bumping into (not small
   plants and pebbles) add one or a few simple shapes with
   `kit.collision_box` or `kit.collision_cylinder` (the `-convcolonly`
   suffix: Godot makes them convex collision shapes and never draws them).
   Cover what the player should bump into, not every detail.
5. **The brief is the author's request.** Build what it says without asking
   for approval. Your choices beyond it (layout, colours, extra details)
   are placeholders, recorded as such.
6. **Placing it is separate.** Make the asset and its prop scene; put it
   in the world only where the brief asks. To show it off, propose a spot.
   Placing it inside a sector design changes that design (rule 1 of
   /environment-design): say so.

## Workflow

1. **Plan in metres:** the parts, their sizes and materials, and the
   collision. Name the slug (`alchemist_column`).
2. **Write the script.** Copy `template.py` from this skill's folder to
   `tools/blender/assets/<slug>.py`; describe the brief in its docstring.
3. **Build:** `npm run models -- <slug>`. It prints the size and triangle
   count; fix the script until they're right.
4. **Look at it:** `npm run asset-preview -- <slug>` renders it in Godot
   next to a 1.8 m figure, into `.shots/assets/<slug>_front.png`, `_side.png`
   and `_close.png`. Read all three. Check parts float or cut into each other,
   the scale against the figure, glass and glow, and the silhouette. Iterate.
   (In a Claude session started in this project with Blender open via
   `npm run blender`, the Blender MCP tools can also inspect the scene live;
   keep the script the source of truth.)
5. **Make its prop scene:** `src/world/props/assets/<slug>.tscn`, a Prop
   with `kind = 4` (ASSET), `solid = true` and `asset` pointing at the
   `.glb` (like `alchemist_column.tscn` at git tag `demo-final`). It's dragged under a design's
   `Props` node in the editor to place it.
6. **Test:** `npm run verify`. `tests/smoke/test_assets.gd` checks every
   asset (meshes, collision, standing on its origin, a prop scene). Add the
   brief's height to its `HEIGHTS`.
7. **Record it** in `docs/DESIGN_DECISIONS.md`: the brief verbatim, what was
   built, the placeholders.
8. **Commit and push** to `main` with the attribution lines (the `.glb` goes
   through Git LFS on its own).

## The kit (`tools/blender/kit.py`)

| Call | Makes |
|---|---|
| `kit.material(name, srgb, roughness, metallic, alpha, emission, emission_strength)` | a material |
| `kit.Model(name)` | one mesh object built from parts; `.finish()` adds it to the scene |
| `.cylinder(bottom, top, r_bottom, r_top, mat, segments)` | posts, legs, pipes, cones |
| `.sphere(centre, radius, mat, scale)` | balls, domes, blobs |
| `.box(centre, size, mat, rotation_z)` | planks, blocks |
| `.lathe(profile, mat, segments, centre)` | anything round turned from (radius, height) points: flasks, vases, bowls, columns |
| `.tube(points, radius, mat)` | a pipe along a polyline |
| `.rock(centre, radius, mat, rng, scale, subdivisions)` | a lumpy stone, or a mound of leaves or moss |
| `.blade(base, angle, height, width, bend, mat)`, `.ribbon(points, side_angle, widths, mat)` | a leaf, a hanging strand |
| `.pad(centre, radius, mat, notch)`, `.petal(centre, angle, length, width, lift, mat)`, `.frond(base, angle, length, mat)` | a floating leaf, a petal, a fern's frond |
| `kit.collision_box(name, centre, size)`, `kit.collision_cylinder(name, bottom, top, radius)` | collision |
| `kit.export(slug)`, `kit.report(slug, path)` | the `.glb`, and its size |

## Gotchas

- Blender is Z-up and the object's front faces -Y; the exported asset is
  Y-up in Godot, its front toward -Z (checked in game with the weapon rack).
  Don't rotate the model to compensate; rotate the placed Prop.
- A lathe profile must start and end where you want caps: radius 0 makes a
  point, anything else a flat cap.
- Glass must be its own material with `alpha` below 1; liquids inside are a
  smaller lathe of the same profile (see `liquid_profile` in the example).
- `npm run models` with no slug rebuilds everything, the hero too.
