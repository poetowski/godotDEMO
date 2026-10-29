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

## 2026-10-27: Sector A7: an ivy-covered phallic statue

The brief, as given to `/environment-design`:

> in sector A7 create big falus statue overgrown by ivy.

Built in `src/world/field/sectors/a7_ivy_statue/`, styled like a weathered
ancient fertility monument:

- A stone phallus about 4.8 m tall (5 m with its two stone steps) in the
  middle of A7 (x 5, z -66), facing south toward the sector's start. It is
  solid to the player.
- Ivy covers it: about 5,000 three-lobed leaves on the statue and plinth,
  thickest at the foot and thinning toward the head, six woody vines
  spiralling up the shaft, and ivy creeping over the dark earth around
  the plinth.
- Rubble and grass around.

Placeholders: the statue's shape, size and stone colour; how much ivy and
where; the plinth; the rubble.

## 2026-10-27: Inventory, and a cornflower in B1

The brief:

> i want you to build inventory system. opened on clicking button I. it
> should cover 40% of screen, poping from right screen corner. wide 4
> objects, tall for 6 objects. generate in B1 sector a flower which can be
> picked up to inventory and then observable. show basic info about the
> flower in inventory

Built:

- The inventory holds 24 items in a grid 4 wide and 6 tall. I (or the
  gamepad's Back button) slides it in from the right edge over 40% of the
  screen's width, full height; I or Esc closes it. While it's open the hero
  stands still and the mouse is free.
- Each filled slot shows a small 3D picture of its item. Clicking it opens
  a viewer on the left: the item's model turning slowly (drag to turn it),
  its name, a short description and a list of facts.
- Items are data (`data/items/*.tres`): name, description, facts and model.
  Anything carrying an item in the world offers it with "[E]  Pick up
  <name>"; E puts it in the first free slot.
- B1 is a small meadow of white and yellow wildflowers with one cornflower,
  sparkling faintly, a few steps ahead of the sector's start.
- The cornflower's info: "A slender wildflower with a head of frilled, deep
  blue florets. It grows in sunny meadows and among grain, and keeps its
  colour long after it is picked." Kind: Wildflower. Found in: Sector B1, a
  sunny meadow. Colour: Cornflower blue. Height: About 70 cm. Rarity: Common.

Placeholders: the inventory's look, slide speed and layout; the viewer's
place; the flower's text and facts, which Claude wrote; the cornflower being
larger than a real one so it can be found; the meadow; no way yet to drop or
use items, stack them, or keep them between sessions.

## 2026-10-27: Praying or crying before the A7 statue

The brief:

> I want to have interaction option in front of A7 statue. player can
> choose between crying in front of statue or praying. based on that player
> protagonist will either knee or cry for few seconds and then stop.

Built:

- Standing in front of the statue shows "[E]  Stand before the statue". E
  turns the hero to face it and opens a choice, "Before the statue":
  1 Pray, 2 Cry (click or press the number; Esc cancels).
- Pray: the hero kneels, bows slightly and holds the hands together for
  5 seconds, then stands up.
- Cry: the hero hunches, covers the face with the hands and sobs, tears
  falling, for 4 seconds, then stops.
- The hero can't move during either; afterwards the statue offers the
  choice again.

Placeholders: the prompt and menu wording, the durations, the poses (the
hero's limbs are single pieces, so the kneel is approximated), the tears,
and that neither choice has any effect beyond the gesture yet.

## 2026-10-27: Saving and loading

The brief: "implement save and load with user interface for that."

- Esc opens a game menu and pauses the game: Resume, Save game, Load game,
  Quit. Save and Load list a quicksave and three slots, each showing the
  sector, the date and time, and how many items were carried.
- F5 quicksaves and F9 quickloads; a short message confirms either.
- A save keeps where the player stands and faces, the sword in hand, the
  inventory, and what was taken from the world. Loading puts all of it back.

Placeholders: the keys (Esc used to only free the mouse; the menu frees it
too), the number of slots, the menu's look and wording, and Quit leaving
the game at once without asking.

## 2026-10-27: Mushrooms to collect in the woods

Brief: "scatter mushrooms in the forest. all mushrooms are collectable and
shown in inventory after collecting."

- The forest is the stress world's woodland (`StressWoods`), the only forest
  so far: up to 3 mushrooms per sector, more where the wood is thick, several
  hundred over the 400 sectors. Each is an `ItemPickup` remembered in
  `WorldState`, so a picked mushroom stays gone after streaming and loading.
- Three kinds, each an item with a description and facts shown in the
  inventory: Penny Bun (brown, domed), Fly Agaric (red with white spots,
  poisonous), Chanterelle (golden funnel). Models are built in code
  (`src/items/mushroom/`).
- Items can now stack: `ItemData.stack_size`, 20 for mushrooms, 1 for the
  cornflower. The slot shows the amount and the viewer shows "x N". Saves
  store each slot's amount (older saves read as 1).

Placeholders (Claude's choices beyond the brief): the three kinds, their
texts and facts, the density, the stack size of 20.

## 2026-10-28: A skinned hero with skeletal animation

Request: install Blender and its MCP, connect them to the project, design a
skeleton for the hero and make it work in the game. Camera and controls stay
as they are for now.

- The hero is now a skinned model built in Blender by
  `tools/blender/build_hero.py`: the same look as before (green tunic,
  brown trousers, boots, brown hair), low-poly and flat-shaded, on 22 bones
  named after Godot's humanoid profile.
- Animations: idle, walk, run, fall, holding the sword, a diagonal swing,
  kneeling prayer and crying with hands to the face. The game blends them
  by speed and state.

Placeholders (Claude's choices beyond the request): the body's proportions
and parts, every animation's poses and timing, holding the sword raised
before the body rather than pointing ahead.

## 2026-10-28: Villagers with daily programs in the stress world

Request: remove the sandbox; in the stress world, add some NPCs with their
own daily program, very simplistic.

- The sandbox (dev test ground and fly camera) is gone.
- The stress world has a clock (a game day is 24 real minutes; T
  fast-forwards to one game hour per second) and starts the player in J10.
- Ten villagers live around J10, each with a home and a work place. Their
  day: work from about 6:00, lunch together at the middle of J10 at 12:00,
  work again from 13:00, an evening together from about 18:00, home from
  about 21:00. Hours differ by up to an hour between them. At work they
  swing their arms as if chopping.

Placeholders (Claude's choices beyond the request): the names (Ada, Bran,
Cora, Dain, Elin, Finn, Greta, Hal, Ivy, Jory), tunic colours, the program
and its hours, where homes and work places are, the day's length, the T key,
and no houses, sleeping or collision.

## 2026-10-28: Hours, days, day and night

Request: proper hours and days, as in the stress world, with night and day
changing; the system stays for production.

- Every world has the clock now; it's saved (save format 3; older saves
  start at 8:00 on day 1). The HUD shows "Day 1  08:00" top right.
- The sun rises in the east, crosses the southern sky and sets in the west;
  at night the moon lights the land in blue and stars come out. Dawn and
  dusk tint the sky and the light.
- The rain under the A5 cloud is now lit, so it darkens at night.

Placeholders (Claude's choices beyond the request): a game day lasting 24
real minutes, a new game starting at 8:00, sunrise at 6:00 and sunset at
20:00 all year, the sun's height, every colour and brightness, and F7 as
the dev key that runs time fast (it doesn't exist in release builds).

## 2026-10-28: Regions and a big world

Request: prepare and build the big world as proposed (one continuous world
in regions, streamed ground with detail falling off with distance), stress
test it, and name regions R1, R2, R3...

- Regions are 20 x 20 sectors (200 m). R1 is the south-west corner; numbers
  run east along the southern row, then on along the next row north. A
  sector's full name carries its region: R45:J10. The main field is R1, and
  its sector names stay as they were.
- The big world is 10 x 10 regions (R1 to R100, 2 km) of rolling hills and
  woods, with no designed sectors yet. It starts in R56:J10, near the middle.
  It also runs at 20 x 20 (4 km) for testing.

Placeholders (Claude's choices beyond the request): the world's size, the
hills (34 m high, about one every 250 m), the woods and their density, the
thinner fog, the start, and how far detail and trees reach.

## 2026-10-28: One world from R1, footsteps and an ambient

Decisions: R1 is the starting region, from which the world gets built; skip
weather and seasons for now; for sound, footsteps and one ambient.

- The main field is the world now: 10 x 10 regions (2 km). R1, with the
  designed sectors, is where the player starts. It stays flat and clear of
  the procedural woods, as room to build; hills rise beyond it over 300 m.
- Footsteps on grass, splashes in water, a heavier step on landing.
- One ambient for the whole world: a soft wind, birds by day, crickets by
  night.

Placeholders (Claude's choices beyond the request): R1 kept flat and clear,
how the hills rise around it, every sound (made in code; listen to them in
.shots/sounds/), their loudness, and how often the birds and crickets call.

## 2026-10-28: Region design, and a big mountain in R2

Request: a skill that designs environment at region scale (one region or
several), alongside the sector-scale one, using landforms with small noise
detail on top; try it with a big mountain in R2 spanning several sectors.

- `/region-design <regions> <brief>` shapes regions with landforms
  (mountains, hills, ridges, valleys, plateaus), kept as data in
  `data/world/landforms/`. The land is rolling hills + landforms + small
  detail; R1 stays flat unless a brief puts a landform there.
- R2: a big craggy mountain, about 85 m above the land around it, its top
  near the middle of R2, with a snow cap above 70 m, bare rock on its steep
  flanks, trees on the lower slopes up to 45 m, a shoulder ridge running
  north-east and a low foothill toward R1.

Placeholders (Claude's choices beyond the brief): the mountain's exact
height, shape and craggedness, the snow cap, the tree line, the shoulder
ridge and the foothill, and the rock and snow colours.

## 2026-10-29: Asset design, and an alchemist's column

Request: a skill that takes a description and makes the object in Blender,
exported as an asset to use in the game; first: "alchemist column system
medieval flasks, whole object size around 2m".

- `/asset-design <description>` builds an object with a Blender script
  (`tools/blender/assets/<slug>.py`), exports it with its own collision,
  previews it in Godot next to a 1.8 m figure, and gives it a prop scene to
  place it with.
- The alchemist's column, 2.07 m: a dark wooden column on an octagonal
  stone plinth with three brass-bound round shelves of glass flasks and
  stoppered bottles holding glowing potions (green, violet, amber, red,
  blue); a copper alembic on top whose pipes run down from flask to flask
  into a big round flask over a burner of glowing coals.
- Placed beside the A5 cottage's open door, as one Prop under the cottage's
  `Props` node, to show it in the world.

Placeholders (Claude's choices beyond the brief): every part of the column's
look (wood, brass, copper, how many shelves and flasks, their shapes and
colours, the burner), and placing it by the A5 cottage (move or delete the
Prop to change that).


## 2026-10-29: A weapon rack

Request (`/asset-design`): "weaponry rack 4m width 3m tall, containing some
spears and shields behind them".

- The weapon rack, 4.2 × 0.8 × 3.0 m (4 m between the posts, the roof
  overhangs): three oak posts, a plank back wall with iron bands, a small
  shingled roof; six painted shields hang on the wall (five round, one tower
  shield) and eleven iron-tipped spears stand in front of them between two
  rails.
- Not placed in the world; its prop scene is
  `src/world/props/assets/weapon_rack.tscn`.

Placeholders (Claude's choices beyond the brief): the roof, the wood and
iron, the number of shields and spears, the shields' shapes, colours and
crosses.

The weapon rack was then placed against the A5 cottage's east wall, facing
east, so the author could see it in the game (a placeholder spot: one Prop
under `Sectors/A5RainyCottage/Props`).

## 2026-10-29: Sectors C5, C6, D5, D6: an oasis, and its resident

Request: "in region 1, sectors C5, C6, D5, D6 - model oasis with tents and
put there one living npc with routine around".

- A patch of low sand dunes in the field around a still pond (centre
  30, -49, about 3.8 m across the radius) ringed by green grass, reeds and
  lilies, with nine date palms leaning over it.
- A camp of three tents around a campfire south of the pond (north on the
  map): a big tent striped cream and red with an awning, a rug and clay
  water jars; two small plain tents. Logs to sit on round the fire, which
  glows.
- Samir, a villager in a rust tunic, the field's first resident (under
  `Residents` in `field.tscn`, wired to the clock by `field.gd`): works at
  the pond's east bank from 5:30, rests at his tent from 11:30 through the
  midday heat, works again from 15:00, sits by the fire from 18:30, and goes
  to his tent at 22:00.

Placeholders (Claude's choices beyond the brief): the layout, sizes and
colours, the palms, reeds, lilies, rug and jars, the number of tents, the
name Samir, his look and his hours.

## 2026-10-29: One world

Request: "remove stresstest world so we will have just 1 world where we
demonstrate further". The stress world (`src/world/stress/`, its test and
`tools/make_stress_field.py`) is removed; the field is the one world. Its
ten villagers went with it. Its measurements stay in ARCHITECTURE.md as
history, and old saves from it still load (their mushrooms grow back).
