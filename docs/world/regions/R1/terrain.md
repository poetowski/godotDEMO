# R1: terrain

## The lay of the land

Gently rolling, from Perlin noise, with the author's hand sculpting on top
(`data/world/sculpt/`). The land eases flat at the region's edge.

## Water

A lake and two rivers, carved by hand as natural lowered terrain and filled with
water (`data/world/water/r1_water.tres`). The water fits the carved ground, not
the other way round: it follows if the ground is sculpted again.

- **Lake:** in the south-east, around P-R 2-4, its deepest point about 8.6 m down
  near Q3. Flat surface at -1.4 m. Still.
- **River in:** rises at T15 and flows south down the S and T columns into the
  lake. Surface from -0.95 m to -1.4 m. **Placeholder:** 0.55 m/s. Shallowest
  about 0.7 m, around T7.
- **River out:** leaves the lake through N4 and flows west to the edge at A1.
  Surface from -1.4 m to -2.15 m. **Placeholder:** 0.55 m/s. Shallowest about
  0.5 m at the sill near N4, then 0.2 m at the very edge.
- **Sectors with water in R1:** A1, B1, C1-2, D1-2, E1-2, F1-3, G1-3, H2-3, I2-4, J3-5,
  K3-5, L3-5, M3-5, N2-4, O2-5, P1-5, Q1-5, R1-6, S1-13, T1-15.
- **River on:** the outflow crosses R1's edge at A1 and runs on to the western
  ravine; see `R8/terrain.md`.
- **Open:** R1's edge is a low wall along the east shore of the lake and the inflow.

## The waterside

Decorated by the blocks `R1Waterside<sector>` under `Sectors` in `field.tscn`, each
5 x 5 sectors or less, covering every sector with water or within about 7 m of it.
They change neither the land nor the water.

- **Masses** (lilies, reeds, cattails, sedge, ferns, flowers, small stones) are
  worked out from the land and water when content is built, so they follow if
  either changes. **Lilies** keep to still water up to about 3 m deep; **reeds and
  cattails** to the waterline, in beds; **stones** gather where the rivers run
  shallow.
- **Props** (51: boulders, driftwood, stumps, willow shrubs, young willows) are nodes
  under each block's `Props`, to move or delete by hand. They stay put if the land
  is sculpted again. Add more from `src/world/props/assets/`.
- The deep middle of the lake is left open.

## High ground

## By sector
