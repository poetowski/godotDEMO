# Rn: terrain

## The lay of the land

## Water

Rivers, lakes and springs: where they run, how deep, and their state (carved,
filled).

## High ground

## By sector

## The forest and the camp

The author painted a way from R1's orchard west to about R8:R2 (`data/world/paint/`). The blocks
`R8Forest*` and `R8CampR2` under `Sectors` in `field.tscn` decorate from there, from
`src/world/field/sectors/r8_forest/`, in columns K to T and rows 3 to 12.

- **Hills:** smoothed once by `tools/relax_hills.gd` into long rolling slopes, x -85 to 45 and up
  to 140 m north. Low ground, banks and the cliff stayed as they were. **Placeholder:** how far.
- **Forest:** spruces in the west and on high ground, hornbeams and ashes further east, thinning
  out toward R1 from x -14 and toward the north from 92 m. Worked out from the land at each
  bake, so it keeps off the way, the water and the drop on its own. **Placeholder:** all of it.
- **Rocks:** crags and rocks along the cliff, more through the forest, with fallen trunks, stumps
  and big trees by the way. These are props to move by hand.
- **Camp:** the fire at about x -25.6, 16 m north, on the flattest ground by the way's end, seats
  and stores in R2, tents and the drying rack in R3. Things lie with the slope. Moved by hand they
  stay put. **Placeholder:** where each stands.

## The ravine, the delta and the fall

The author carved a huge drop through the west of the starting zone, in R7, R8 and
R6, as a natural barrier to movement. The ravine's floor lies about 55 m down.

- **Delta:** R1's outflow broadens to 15-20 m around deep pools and shoals, from A1
  to about R7:P20 and R8:P1. Surface -2.15 m to -2.7 m. **Placeholder:** the levels.
- **Rapids:** from the sill at about x -40, a stepped run to the rim at x -63. Surface
  -3.6 m to -8 m. **Placeholder.**
- **The fall:** from x -64 down the author's slope, 9 m wide, disappearing into the
  ravine's mist. Nothing is placed at its bottom, as the author asked. It's in
  `RegionWater.falls`. **Placeholder:** its line and width.
- **The abyss and the fog:** the land runs down to -220 m at the world's west edge. Fog
  (`MistBarrier`) fills everything beyond a line of points along the rim of the drop,
  from R9's north edge round to R6's south edge: thin for about the first 3 sectors,
  then thickening, with a wall inside it at about 6 sectors. To change where it
  starts, drag the points under `MistBarrier/FogLine` in the editor. **Placeholder:**
  the points, and how fast it thickens.
- **The ravine's mist:** below about -9 m the fog thickens fast, so little can be seen
  past a few metres down. **Placeholder:** those heights.
- **The limit:** a border (see `docs/world/README.md`), a few metres inside the rim,
  where the ground is about 6 m below the land. The player is warned there and returned
  to the spawn point 8 m further on, so the fall's foot is seen from above only.
- **Decoration:** the blocks `River*` in `field.tscn`. Their props can be moved by
  hand, and stay put if the land is sculpted again. New assets are in R1's family:
  rapid stones, gravel bars, spray moss, cliff outcrops and dead trees on the rim.

