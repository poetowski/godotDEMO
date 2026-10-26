# Design decisions

The author's record of decided game design: the world, story, characters,
mechanics, numbers, controls and art direction. Claude builds what this file
says; anything not recorded here is a placeholder and is marked as one.

Add an entry per decision, newest last:

```
## YYYY-MM-DD: <topic>
<the decision, with the details needed to build it>
```

"godotDEMO" is a working title.

## 2026-10-25: Castle proof of concept

Requested as a proof of concept, not final content:

- An environment with a fantasy castle, many trees, a paved path and bumpy
  terrain, with some light details such as clouds. Nothing very detailed.
- A sword placed nearby that the player can pick up and swing.
- The player is controlled from a third-person perspective.

Built in `src/world/poc_castle/`, which is the main scene. Everything not listed
above is a placeholder: the layout, colours, the hero's look, the controls,
speeds and swing timing. Whether third-person carries over to the real game
is still open.

## 2026-10-25: Sector grid on a grass field

The castle proof of concept's terrain and map are removed (kept at git tag
`poc-castle`). The world starts again as flat grass everywhere, divided into
sectors that we build one by one.

- Each sector is 10 x 10 m.
- The grid is 20 x 20 sectors (200 x 200 m), named by column letter and row
  number: A to T, 1 to 20.
- The start is in A1, a corner of the grid. Letters grow to the east and
  numbers grow forward, to the north, the way the player faces at the start.
- The grid lines are visible on the ground and light up toward the sky.

Placeholders: the light colour (pale cyan), the curtains' height (3 m) and
strength, how the sector names are painted, the HUD readout, and keeping the
third-person hero and the clouds.

## 2026-10-26: Sectors A1 to A3: a small stream

The brief, as given to `/environment-design`:

> Sector A1, A2, A3. Put there small river with floating water, some lillies
> and small bushes. make terrain little bumpy and put some rocks and grass
> around.

"Floating water" was read as flowing water.

Built in `src/world/field/sectors/a1_a3_stream/`:

- A small stream, about 1.2 m wide, rises from a spring among rocks in A3
  (around x 6, z -26), winds south through A2 and opens into a pond about
  3 m across in A1 (around x 4, z -6). Its course stays inside the three
  sectors, since the neighbouring sectors are still flat grass. The water
  visibly flows downstream, slower in the pond.
- Lily pads float on the pond and the spring pool, some with white and pink
  flowers.
- The ground rolls gently, by about 0.2 m, with three low mounds, each topped
  by a boulder. Muddy banks line the water.
- Small bushes grow along the banks and a few out in the grass. Rocks sit
  around the spring, along the banks, two in the stream itself, and scattered
  over the grass. Tufts of grass grow in patches, lusher along the banks.

Placeholders: the stream's course, width and depth; the spring and the pond;
the mounds; every count, size and colour; the flow speed; the drifting flecks
of foam that show the flow. The painted sector names are hidden in designed
sectors, where they would hover over the water; the HUD still names the
sector.

## 2026-10-26: Sector C2: an archer tower

The brief, as given to `/environment-design`:

> in segment C2 generate an archer fantasy tower built from bricks with
> staircase. put foliage and big pine in the same segment.

Built in `src/world/field/sectors/c2_archer_tower/`:

- A round tower of stone bricks, about 3.6 m across and 9.5 m tall, near the
  middle of C2 (x 24, z -16.6). It has a doorway facing south toward the
  sector's start, arrow slits at two heights, and an open battlement with
  merlons and a red pennant.
- A staircase of stone steps spirals 1.25 turns up the outside to the
  battlement, which the player can climb.
- A big pine, about 11 m tall, in the north-west corner (x 22, z -12).
- Foliage: bushes around the pine and the tower, ferns in the shade, grass
  in patches, a few rocks, and trodden earth at the tower's foot.

Placeholders: every size, position and colour; the stairs running outside
rather than inside; the pennant; the doorway left open with a dark
interior that can't be entered.

## 2026-10-26: Sector C2: a flame katana in a chest on the tower

The brief: "add chest with a sword on the top of archer tower. sword must be
equipable. the srod should be flame katana".

- An iron-banded wooden chest stands on the tower's battlement, across from
  where the stairs arrive, with a flame katana lying on its lid.
- Walking up to it shows "[E]  Take the flame katana". E puts the katana in
  the hero's hand, and left click swings it, like the plain sword.
- The katana: a gently curved blade that burns, glowing orange at the edge
  with flames flickering up it, sparks of fire streaming off it as it
  moves, a warm flickering light, a round dark guard, and a red and black
  wrapped grip with gold fittings.

Placeholders: the chest's look and place; the katana's look, size and glow;
the chest staying closed; the katana's flames being only visual (no fire
damage, since there is nothing to hit yet).

## 2026-10-26: Sectors D1, D2, E1, E2: Bratislava Castle

The brief, as given to `/environment-design`:

> in sector D1 D2 E1 E2 generate bratislava castle on the hill

Built in `src/world/field/sectors/d1_e2_castle/`, a stylised, low-poly take
on the real castle:

- A hill about 3 m high fills the four sectors, with a flat top around
  x 40, z -11.
- The palace: a white rectangular block of four wings around a courtyard,
  about 8 x 6 m and 4 m to the eaves, with rows of dark windows and a red
  hipped roof. A square white tower at each corner rises to about 6 m under
  a red pyramid roof and a gold finial. The gateway is in the south wing.
- A low white wall runs along the hilltop's edges, open where the road
  arrives.
- A dirt road climbs the south slope from near D1's start to the gate.
- Round-crowned trees, bushes, rocks and grass cover the slopes.

Placeholders: all proportions and sizes (the real castle is far larger
than four sectors allow), the window rows, the colours, the road's route, the
trees, and the courtyard and interior, which can't be entered.

## 2026-10-26: Sector A5: a cottage in the rain

The brief, as given to `/environment-design`:

> generate medieval cottage with open door and closed wooden windows in
> sector A5. i want to have a static cloud over sector A5 which rains
> moderately.

Built in `src/world/field/sectors/a5_rainy_cottage/`:

- A medieval half-timbered cottage, about 4.6 x 3.4 m: white plaster walls
  in dark oak framing on a stone foundation, a steep thatched gable roof,
  and a stone chimney at the east end.
- The door, facing south toward the sector's start point, stands open
  outward; the player can walk inside, under a plank ceiling.
- Five windows, each shut with two plank shutters with iron straps.
- A dark grey cloud hangs still about 14 m above the sector and rains
  moderately. The rain stops on the roof and the ground, and the grass
  under the cloud is darker with wet. A dirt path leads to the door.
- Bushes and grass around.

Placeholders: the cottage's size, colours and layout; the thatch; the rain's
amount, speed and look (no sound, splashes or puddles yet); the cloud's
height and shape; the bright, empty interior.
