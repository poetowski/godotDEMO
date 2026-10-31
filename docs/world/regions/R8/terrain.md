# Rn: terrain

## The lay of the land

## Water

Rivers, lakes and springs: where they run, how deep, and their state (carved,
filled).

## High ground

## By sector

## The ravine, the delta and the fall

The author carved a huge drop through the west of the starting zone, in R7, R8 and
R6, as a natural barrier to movement. The ravine's floor lies about 55 m down.

- **Delta:** R1's outflow broadens to 15-20 m around deep pools and shoals, from A1
  to about R7:P20 and R8:P1. Surface -2.15 m to -2.7 m. **Placeholder:** the levels.
- **Rapids:** from the sill at about x -40, a stepped run to the rim at x -63. Surface
  -3.6 m to -8 m. **Placeholder.**
- **The fall:** from x -64 down the author's slope into the tarn at about (-112, 3
  north), 9 m wide. It's in `RegionWater.falls`. **Placeholder:** its line and width.
- **Tarn:** in the hollow on the floor, around R8:F3, surface -57 m. **Placeholder.**
- **The abyss and the fog:** the land runs down to -220 m at the world's west edge. Fog
  (`MistBarrier`) fills everything beyond a line of points along the rim of the drop,
  from R9's north edge round to R6's south edge: thin for about the first 3 sectors,
  then thickening, with a wall inside it at about 6 sectors. To change where it
  starts, drag the points under `MistBarrier/FogLine` in the editor. **Placeholder:**
  the points, and how fast it thickens.
- **The limit:** the player is warned in column M (x -80 to -70) and returned to the
  spawn point past it, so the fall's foot and the tarn are seen from above only.
- **Decoration:** the blocks `River*` in `field.tscn`. Their props can be moved by
  hand, and stay put if the land is sculpted again. New assets are in R1's family:
  rapid stones, gravel bars, spray moss, cliff outcrops and dead trees on the rim.

