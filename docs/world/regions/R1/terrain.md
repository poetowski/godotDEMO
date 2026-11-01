# R1: terrain

## The lay of the land

Gently rolling, from Perlin noise, with the author's hand sculpting on top
(`data/world/sculpt/`). The land eases flat at the region's edge.

## Water

A lake and two rivers, carved by hand as natural lowered terrain and filled with
water (`data/world/water/r1_water.tres`). The water fits the carved ground, not
the other way round: it follows if the ground is sculpted again.

- **Lake:** in the south-east, around P-T 1-5, running on east into R4 (see
  `R4/terrain.md`) with a tip south into R6. Flat surface at -1.4 m. Still.
- **River in:** rises at T15 and flows south down the S and T columns into the
  lake, swinging east around T6-T7 where the author moved its channel. Surface from -0.95 m to -1.4 m. **Placeholder:** 0.55 m/s. Shallowest
  about 0.7 m, around T7.
- **River out:** leaves the lake through N4 and flows west to the edge at A1.
  Surface from -1.4 m to -2.15 m. **Placeholder:** 0.55 m/s. Shallowest about
  0.5 m at the sill near N4, then 0.2 m at the very edge.
- **Sectors with water in R1:** A1, B1, C1-2, D1-2, E1-2, F1-3, G1-3, H2-3, I2-4, J3-5,
  K3-5, L3-5, M3-5, N2-4, O2-5, P1-5, Q1-5, R1-6, S1-13, T1-15.
- **Bridge:** a log bridge over the outflow, from about E1 to D3, with a matching pair of post lanterns at
  each end. It's a prop under `R1WatersideA1/Props`, and being turned, it keeps its height
  when the land is sculpted: move it by hand if the banks change. **Placeholder:** where.
- **River on:** the outflow crosses R1's edge at A1 and runs on to the western
  ravine; see `R8/terrain.md`.

## The waterside

Decorated by the blocks `R1Waterside<sector>` under `Sectors` in `field.tscn`, each
5 x 5 sectors or less, covering every sector with water or within about 7 m of it.
They change neither the land nor the water.

- **Masses** (lilies, reeds, cattails, sedge, ferns, flowers, small stones) are
  worked out from the land and water when content is built, so they follow if
  either changes. **Lilies** keep to still water up to about 3 m deep; **reeds and
  cattails** to the waterline, in beds; **stones** gather where the rivers run
  shallow.
- **Props** (boulders, driftwood, stumps, willow shrubs, young willows) are nodes
  under each block's `Props`, to move or delete by hand. They stay put if the land
  is sculpted again. Add more from `src/world/props/assets/`.
- The deep middle of the lake is left open.

## The roads and the farm

The author painted the roads and the farmyard (`data/world/paint/`). The blocks `R1Roadside*`
under `Sectors` in `field.tscn` decorate them, from `src/world/field/sectors/r1_roadside/`.
They change neither the land, the water nor the paint.

- **Roads:** from the bridge's north end through D4's crossroad, west through C4 to B3, and
  north-east to the long east-west road along row 5's south edge. From E5's crossroad a loop runs
  through F5, F6 and G6 and back down G5, and a road runs north through E6 and E7.
- **Farm:** the house stands in D5, facing south over the dirt of its yard, with a hay stack and
  an apple tree beside it. Fences run along its east and north sides and round the west of the
  yard, leaving it open to the road in the south-east and to the path behind the house.
  **Placeholder:** where the house and fences stand.
- **Lanterns:** a matching pair at each crossroad: hanging lanterns at D4, posts at E5 and low
  stone ones at the bend on G4's north edge, which is the nearest junction to G4 as G4 itself
  has no paint. Singles carry on along those roads: posts in E6 and E7, a stone one in G5.
  **Placeholder:** which design goes where.
- **Trees:** a big oak behind the farm and another inside the loop, an orchard of apple trees
  west of the fence, and stands of pine, beech and birch. **Placeholder:** where they stand.
- **Plants and stones:** grass, flowers, moss and stones are worked out from the land and paint
  when content is built, thick on the verges and thinning away from them, and they keep off
  anything painted bare. Boulders, stumps and shrubs are props to move by hand.

## Aiwyk, the village

The village in the middle of R1 is named Aiwyk. The author painted two plazas, a ring road and a junction in the middle of R1, with a hill for the
church. The blocks `R1VillageI7`, `R1VillageK12` and `R1ForestN7` under `Sectors` in `field.tscn`
build on it, from `src/world/field/sectors/r1_village/`.

- **Land:** smoothed, the church's terrace at 3 m on long easy slopes, a rise of about
  4.5 m for the forest east of the village, and level terraces under the buildings and the square,
  by `tools/shape_village_land.gd`. **Placeholder:** how far.
- **Paint:** cobbles on the square and the middle of the street up to the church's way, flagstones to
  its door, dirt at the street's edges and before doors, and a gravel wagon track where the author's
  ring road ran, by `tools/localize_village_paint.gd`. Their plazas are trodden dry grass now.
- **Buildings:** a long thatched house in K10, a turf-roofed cottage and a raised storehouse in K11,
  a smithy in L9, a thatched cottage and a turf-roofed cottage in M9. **Placeholder:** where each is.
- **Square:** in L10 with a well, a market stall and benches. Matching lanterns stand where the street
  comes in, on the way up to the church, on the way out east and at the farm's gate.
- **Church:** in M11 on its hill, facing the village, with rune stones either side of its way and pines
  round the rest of it.
- **Farm:** a farmhouse and shed in J8, a hay stack and a trough, barley in strips in J7 and fences
  round both, open at the gate on the road.
- **Forest:** in N and O, rows 7 to 12, climbing the rise. Spruce and pine, hornbeam, ash, beech,
  maple and birch in stands. Worked out from the land at each bake.

## The wet banks

The author asked for wet dirt in A2, B2, C2, C3, D3, F3, F5, H4, H5, I6, J5 and J6. `tools/paint_wet_ground.gd`
paints it, thickest low by the water, in patches that wander across the sectors' edges. Rushes,
butterbur, sunk stones, puddles and the river's wrack grow and lie on it, worked out at each bake. The
rest are props under the blocks that own those sectors, to move by hand. **Placeholder:** where each
stands.

- **The ship on boulders:** a longship thrown up on rocks in C2, across the river from the start, its yard
  fallen and sail in rags. Shipwright's tools, a mallet, a hammer and a knife lie round it.
- **The fishing camp:** above the ship in C3, with a smoke hut, a drying rack, nets and a gutting table.
  Another stands on the bank in F3 with a beached boat.
- **The old wreck:** bare ribs on the bank in H4, and a ship's broken stern in H5.
- **The jetty:** in J5, reaching out over the river, with nets drying behind it. It keeps the height it
  was given, so move it by hand if the bank changes.
- **Inland:** boats laid up in A2 and I6, racks and a table in J6, traps and boulders in F5. `R1RoadsideI6`
  is a block of its own for I6.

## The farms round Aiwyk

The blocks `R1FarmH8`, `R1FarmB9` and `R1FarmG13` under `Sectors` in `field.tscn` build on the land
as it was, from `src/world/field/sectors/r1_farms/`. G8 and H8 moved to them from `R1RoadsideE4`.

- **The working farm:** the house in H9, its doors open to the south, and a barn in G9 beside it, the
  two closing the north of a yard fenced across H8, G8 and G9. Gates stand where the author's painted
  ways come through, on the west and in the south-east. Barley, hay stacks and a rack, a coop, a
  garden, and worn ground at the doors. **Placeholder:** where each stands.
- **The poor farm:** in F9, where the author's way west ends, a house with a hole in its roof behind a
  fence mostly fallen, with nettles and docks taking the yard.
- **The croft:** in H11, a low stone house under turf with no fence, its barley field in G10 and H10
  marked by heaps of cleared stone at the corners, and a track from the village's ring road.
- **The sign:** "Welcome to Aiwyk" in I8, beside the road in from the bridge. It's a prop in
  `R1VillageI7`.
- **The fields between:** rows 9 to 13 from B to H, and I and J 12 to 13. `tools/paint_farms.gd` lays
  drifts of dry and lush grass and stony patches, and rocks stand on the stony ones. Bushes gather in
  thickets, with weeds, grass and small stands of trees, all worked out at each bake or frozen as
  props. **Placeholder:** all of it.

## High ground

## By sector
