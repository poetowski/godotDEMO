# R4: terrain

## The lay of the land

Low Perlin noise, with the author's hand sculpting along its west edge
(`data/world/sculpt/`).

## Water

- **The lake:** the east half of R1's lake, carved by the author across the border, from
  A to about D and rows 1 to 4, with a tip south into R5 (A-D 18-20) and one into R6
  (R-T 18-20). Its deepest point is about 12 m down, right at the border with R1 near
  row 5. Flat surface at -1.4 m.
  It's one body of water with R1's, so it's poured from
  `data/world/water/r1_water.tres`, and its `lake_reach` is what lets it fill this far.
- **The inflow's bank:** R1's inflow runs just west of column A; A8-A16 are its east bank.

## The lakeside

Decorated by the blocks `R4Lakeside*`, `R5Lakeside` and `R6Lakeside*` under `Sectors` in
`field.tscn`, from `src/world/field/sectors/r4_lakeside/`. They change neither the land
nor the water.

- **Masses** are as at R1's waterside, and follow if the land or water changes.
- **Props** are nodes under each block's `Props`, to move or delete by hand: full-grown
  alders standing back from the water, flat slabs at the waterline, alders fallen into
  the lake, and R1's boulders, driftwood, stumps and willows. **Placeholder:** the layout.

## High ground

## By sector
