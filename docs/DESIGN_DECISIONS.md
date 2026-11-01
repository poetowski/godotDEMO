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

## 2026-10-31: Real development starts: the demo is cleared

Rule, from the author (2026-10-31): we never use third-party assets.

Request (2026-10-31): "i extended river outflow from lake to other regions, and i
created in west regions a natural barrier for a movement, which should be a hige
drop in latitude. use decorative skill, extend river and make waterfall into ravine
on west. decorate surrounding of river and its delta before waterfall. create new
assets in blender if needed." And: "you can also extend ravin on western border and
make it much deeper and put a fog over there is player cannot enter and does not
properly see what is too much behind." **Placeholder:** water levels, the tarn, all
the new assets and their layout, and the abyss's depth, the fog's line and look. See
`docs/world/regions/R8/terrain.md`.

Request (2026-10-31): "put two lanterns at D4 crossroad. also put two lanterns at E5 and G4
crossroads i painted. also put one in E6 near road and G5 near road. one in E7 near road. in
D5 and surroundings i put some dirt and i created some road / pavement around. this place his
for  a farm house small from wood with closed widows and some grass and hay on roof. and some
low medieval wooden primitive fences. prepare these assets in blender using skill and then
place them there. aldo you can decorate sectors with basic grass, rocks and some assets in
sectors where i painted some pavement or pseudostreets. create few more assets to diversify,
like some flowers ambient. or moss or some big boulder." and "also generate some new trees
variations and some bigger trees maybe as well." Built in `src/world/field/sectors/r1_roadside/`,
with the `farmstead` and `woodland` Blender families. G4 itself has no paint, so its pair
stands either side of the bend on its north edge, one in G4 and one in G5. **Placeholder:**
which lantern goes where, the house's place and look, the fences' lines, the kinds of tree and
where they stand, and every plant's density. The hay stack, apple trees and firewood weren't
asked for.

Request (2026-11-01): "i adjusted terrain, please move assets accordingly. then generate
forest in R8 west from orchard, i painted some terrain pavement dirt etc which is a way from
orchard to the west into forest, i want you to generate more trees in blender and place them in
R8 up to western cliff, put there some rocks. in R8 sector R3 and R2 i want to have semi
abandoned camp with campfire, generate assets in blender and then place them there. also check
all terrain painted by me and maybe stick to their positions where i painted them, but maybe
repaint with better brush and texture so it looks more realistic." and "you can also redesign
terrain hills and slops to make it more realistic". Built in
`src/world/field/sectors/r8_forest/`, with the `wildwood` Blender family. The paint files are
unchanged: `grass_grid.gdshader` draws them better, wherever they lie. `tools/relax_hills.gd`
smoothed the sculpted hills once over R8 and R1's west, up to about 2.5 m, leaving the river,
banks and cliff as they were; the author's sculpt before that is commit `c5d801c`. R8:R2 moved
from `RiverDelta` to the block `R8CampR2`, with the two props standing in it.
**Placeholder:** the kinds of tree and how thick they stand, where the forest ends, every camp
object's place and look, how the paint's surfaces look, how far the hills were smoothed, and
that the fire smoulders and lights only at night. The bracken, mushrooms, twigs, leaf litter,
fallen trunks, crates, barrel, firewood, drying rack and bedroll weren't asked for by name.

Request (2026-11-01): "change startin point to region R1 , sector E1. in the iddle pf bridge and sector
F1, but" (the message ended there). New games and respawns start at `Field.START_POINT` in E1, on the
south bank by R1's southern edge, between the bridge's foot and F1; the author moved it back from the river. **Placeholder:** the exact spot.

Request (2026-11-01): "in region R1 in sectors A2 B2 C2 C3 D3 F3 F5 H4 H5 I6 j5 j6 add some wet dirt
as ground. generate new assets in blender to fill this like near side items. you can put some fishing
stuff there and nearby. stay consistent and creative, also put some rocks there and maybe some
shipwreck or something and ship on boulders, some knife and hammers on ground. be crative and
consistent like always." `tools/paint_wet_ground.gd` paints the mud, the `shoreside` Blender family
makes the things, and R1Waterside plants what grows on the mud. The land wasn't reshaped. The
author's sculpt and paint before this are `9af959e`. **Placeholder:** where everything stands, what
kinds there are, and how much mud, all beyond the sectors, the fishing things, the rocks, the ship on
boulders, the wreck, and the knives and hammers they asked for.

Request (2026-11-01): "the name of this village in region R1 is Aywik. remember that in our design
documents and md files. you can even design a sign Welcome to Aiwik and place it before entrance to
village from the bridge site road." and "Aiwyk is correct, not Aiwik." **The village in the middle of
R1 is named Aiwyk.** The sign (`aiwyk_sign`) stands in I8, beside the road in from the bridge.
**Placeholder:** the sign's look and where it stands.

Request (2026-11-01): "put farm house in H9 rotated with open doors to south. then design a farm space
by fences at H8 and maybe a bit to G8 and G9. further new farms can be with broken fence or even
somewhere without fence. generate new assets in blender. will emoty places around with rocks, foliage
etc. create new assets in blender with variations if needed. also use paint yourself on ground more
often if ytou find it more realistic." Built in `src/world/field/sectors/r1_farms/`, with the
`homestead` Blender family, on the ways and dry grass the author painted in `32982f9`, which
`tools/paint_farms.gd` adds to and never paints over. The land wasn't reshaped. **Placeholder:** the
barn, the farm in F9 and the croft in H11 and where they stand, the yard's layout, the kinds and
number of rocks and weeds, and all the paint added.

Request (2026-11-01): "in the middle of R1 i just painted some new roads and different terrain
in several sectors in the middle. create assets of village houses in blender, also create one
overgrown church, not christian but little nordic. put some decorations around the village, like
trees and rocks and some foliage and grass. so we can have buildings of village in sectors of
r1: k10, k11, l9, m9. nordic church wooden on m11 surrounded by pine trees. put a farm with fences
and small shed in J8 with fences going to J7 as well. sectors O-N 7-12 can be another forest with
trees. you can also adjust terrain painting, make pavement more realisticaly localized. you can
also redesign hills and terrains around if you find it to be creative. stay very consistent in
visuals. be creative. go". Built in `src/world/field/sectors/r1_village/`, with the `village`
Blender family. `tools/shape_village_land.gd` smoothed the land, lifted the church's hill, raised a
rise for the forest and levelled terraces under the buildings; `tools/localize_village_paint.gd`
repainted x 88 to 140, 60 to 116 m north. The author's sculpt and paint before that are commit
`50784c2`. **Placeholder:** where every building, lane and thing stands, how far the land changed,
the church's dragons and sun wheel, and the forest's kinds and thickness. The well, stall, carts,
gardens, benches, clothes lines, rune stones, lanterns, smithy, storehouse, trough and barley
weren't asked for by name.

Request (2026-11-01): "make spawn point region r1, sector B2." New games and respawns
start there.

Request (2026-10-31): "regarding different lanterns, i ment you can use different in eadh
segment, not opposite. opposite must be same of course so it makes sense and in this case
brudge should have been covered just by 1 design" **Rule:** things facing each other match;
variety is between segments. The bridge now has two pairs of `lantern_post`, one pair at each
end. `lantern_hook` and `lantern_stone` stay for other places. **Placeholder:** which design.

Request (2026-10-31): "we need to somehow implement also if something is meters below in
cave system or in upper third or fifth level of tall building, those are just examplease.
implement system so we are ready when this happen. because - problem now is when i walk on
the bridge it thinks in the middle of the bridge that i am in the water beneath because i
start to swim." The system is "Levels" in `docs/world/README.md`: questions about where
someone is take their height too, a `LevelVolume` makes a place of its own, and a
`GroundOpening` is a way down. No cave, tower or volume exists in the game yet. **Placeholder:**
the wind dropping 20 dB in 1.5 s when enclosed, a fall of 150 m with nothing to land on
counting as dying, and the place's name following the sector's on the HUD.

Request (2026-10-31): "now generate new asset in blender. it is wooden curven bridge with
small fences, some logs might be missing, few columns in the water. then put it to cross
river on R1 sectors near E sector column or D. rotate a bit. then redecorate if needed.
also generate lantern asset in blender which emits some light during night and create few
variants you can put them near bridge." The bridge (`wooden_bridge`) spans the outflow
across D and E, turned about 13 degrees, and two props were moved out from under it.
Lanterns: `lantern_post`, `lantern_hook`, `lantern_stone`, two of each at the ends. They
burn from 19:30 to 05:30, fading over half an hour. **Placeholder:** the bridge's size and
the place of its ends, how many logs are gone, the lanterns' look and places, and the
light's colour, strength, reach and hours.

Request (2026-10-31): "i changed terrain, please redecorate like you did and also define
this as a skill so if i change terrain, you detect and propose lowering of flying
objects, or puting new objects, or even generating new assets." The skill is `/land-sync`,
with `npm run land-check`. The lake's blocks were regenerated on the new shore, none having
been moved by hand; no new assets were needed. **Placeholder:** the thresholds in
`land_check.gd`, and the new layout.

Request (2026-10-31): "fix water in R4 i cannot see lake there but i am sure i put it
there. i just changed terrain. please decorate properly. also, the "you should not be
here line" should not block southern regions, rather it should follow few meters into
crater ravine only. decorate surroundings of lake with our assets and if needed
generate more. make sure location is correct in folder structure. update docs if
needed." The author's lake runs from R1 into R4, R5 and R6; its `lake_reach` was cutting
it off at x 201, so it's now 75 m. Decorated by `src/world/field/sectors/r4_lakeside/`,
with three new assets in the riverside family: `lake_alder`, `fallen_alder`, `shore_slab`.
Three props left deep under the new water were removed, and the rest settled. The border
is now a line of draggable points, `ZoneBorder/Line`, where the ground is about 6 m below
the land, so it also frees the land in R9 that the old straight line blocked.
**Placeholder:** the layout, the three assets, the line's points, and returning the
player 8 m past it.

Request (2026-10-31): "i remodeled terrain again. remove details and props from the
bottom of waterfall, add mist which prevents player to see meters below into
ravine. also implement character view on buttton 'c' like vie have for inventory and
quests. this character popup comes from top of screen. contains Hero Level, and then
we will add additional info. you can add HP now. 100/100. also, implement fall
damage, so if player fall for more than 10m, he dies. when player dies, he respawn
at the spawn point." **Placeholder:** level 1; water catches a fall; the message "You
died"; neither level nor HP is saved yet.

Request (2026-10-31): "highlight "I should not be here" border line and also
incorporate this mechanics in md files, we will use it to define world border or
zones border." The mechanic is in `docs/world/README.md`, under Borders.

Request (2026-10-31): "make zoom out ingame limited to 10 meters away of player up
to 1m close. do not allow bigger zoom outs", "also make zoom in and zoom out slower".
**Placeholder:** 0.25 m per notch of the wheel, half what it was.

Request (2026-10-31): "i redesigned western terrain, please fix flying objects now.
also, please make the western fog polygonal or something in sence that i want to
move it further in some areas even severals ectors more east, please make it follow
the shape of the heavy drop and make fog more gradual, like looking through first 3
sectors better but then worse etc." The fog's line is points in `MistBarrier/FogLine`.
**Placeholder:** where they start, and how fast the fog thickens.

Request (2026-10-31): "also create a hardcoded barrier on M sector of western
regions, if player approach, he will get message "I should not be here..." and he
will be teleported to spawn point if he approaches further to west". Column M of
R7, R8 and R9: x -80 to -70. Entering it warns; past its west side (x -80) returns
the player to the spawn point. In `field.gd`.

Request (2026-10-31): nine regions around and including R1 make the starting zone,
named R2 to R9 in clockwise order. **Placeholder:** the clock starts at north.

Request: remove the placeholder world, the assets generated through skills and
the assets used in demo placeholders, and start with an empty world: one
region, R1, of the classic 20 x 20 sectors, with Perlin noise so the terrain
isn't flat, and low amplitude, so the bumps are small. The player character and
his animations stay, except crying and praying, which are removed.

- Everything from the demo is kept at git tag `demo-final`, with its full
  design record (the castle proof of concept stays at `poc-castle`).
- Gone: every sector design (stream, tower, castle, cottage, statue, meadow,
  great tree, oasis), the R2 mountain and R11 lake, the alchemist's column and
  weapon rack, the swords, flowers and mushrooms, Samir and his quest, the
  procedural woods and distant forest, the clouds, the planets and nebulae,
  and the 2 km world around R1.
- The world is now R1 alone, 200 x 200 m. Placeholders: the noise (rises and
  falls about 1.8 m, one bump about every 70 m) and its easing flat over the
  last 12 m at the region's edge, the flat grass plain around R1, and the
  player starting in A1.

## 2026-10-31: Terrain sculpted by hand in the editor

Request: an option to draw terrain by hand in the editor: raise it, lower it,
and so on.

- Select the Terrain node (or press Sculpt in the 3D view's toolbar) and paint
  with the left mouse button. Five brushes: Raise, Lower, Smooth, Flatten (to
  the height where the stroke starts) and Restore (back to the land as the code
  makes it). Shift swaps raise and lower. Sliders set size, strength and
  softness; Ctrl + wheel or [ ] also set the size, and Ctrl + Z undoes.
- Strokes save themselves into `data/world/sculpt/`, and the game shows them.

Placeholders: the brushes' ranges and defaults, the 1 m sculpting resolution,
the keys.

## 2026-10-25: Sectors

The world is divided into sectors that we build one by one.

- Each sector is 10 x 10 m.
- The grid is 20 x 20 sectors (200 x 200 m), named by column letter and row
  number: A to T, 1 to 20.
- The start is in A1, a corner of the grid. Letters grow to the east and
  numbers grow forward, to the north, the way the player faces at the start.
- The grid lines are visible on the ground and light up toward the sky.

Placeholders: the light colour (pale cyan), the curtains' height (3 m) and
strength, how the sector names are painted, the HUD readout.

## 2026-10-28: Regions

Regions are 20 x 20 sectors (200 m), named R1, R2, R3... R1 is the south-west
corner; numbers run east along the southern row, then on along the next row
north. In a world of several regions a sector's full name carries its region:
R45:J10. R1 is the starting region, from which the world gets built.

## 2026-10-27: Inventory

- The inventory holds 24 items in a grid 4 wide and 6 tall. I (or the
  gamepad's Back button) slides it in from the right edge over 40% of the
  screen's width, full height; I or Esc closes it. While it's open the hero
  stands still and the mouse is free.
- Each filled slot shows a small 3D picture of its item. Clicking it opens
  a viewer on the left: the item's model turning slowly (drag to turn it),
  its name, a short description and a list of facts.
- Items are data (`data/items/*.tres`): name, description, facts, model and how
  many stack in a slot. Anything carrying an item in the world offers it with
  "[E]  Pick up <name>"; E puts it in the first free slot.

Placeholders: the inventory's look, slide speed and layout; the viewer's
place; no way yet to drop or use items.

## 2026-10-27: Saving and loading

- Esc opens a game menu and pauses the game: Resume, Save game, Load game,
  Quit. Save and Load list a quicksave and three slots, each showing the
  sector, the date and time, and how many items were carried.
- F5 quicksaves and F9 quickloads; a short message confirms either.
- A save keeps where the player stands and faces, the inventory, what was taken
  from the world, the quest log and the time.

Placeholders: the keys, the number of slots, the menu's look and wording, and
Quit leaving the game at once without asking.

## 2026-10-28: The hero

Install Blender and its MCP, design a skeleton for the hero and make it work in
the game. Camera and controls stay as they are for now.

- The hero is a skinned model built in Blender by
  `tools/blender/build_hero.py`: green tunic, brown trousers, boots, brown
  hair, low-poly and flat-shaded, on 22 bones named after Godot's humanoid
  profile.
- Animations: idle, walk, run, fall, holding a sword, a diagonal swing, and
  swimming. The game blends them by speed and state.

Placeholders: the body's proportions and parts, every animation's poses and
timing, holding a sword raised before the body.

## 2026-10-28: Hours, days, day and night

The system stays for production.

- The world has a clock, and it's saved. The HUD shows "Day 1  08:00" top right.
- The sun rises in the east, crosses the southern sky and sets in the west;
  at night the moon lights the land in blue and stars come out. Dawn and
  dusk tint the sky and the light.

Placeholders: a game day lasting 24 real minutes, a new game starting at 8:00,
sunrise at 6:00 and sunset at 20:00 all year, the sun's height, every colour
and brightness, and F7 as the dev key that runs time fast.

## 2026-10-28: Footsteps and an ambient

Weather and seasons are skipped for now. For sound, footsteps and one ambient.

- Footsteps on grass, splashes in water, a heavier step on landing.
- One ambient for the whole world: a soft wind, birds by day, crickets by
  night.

Placeholders: every sound (made in code), their loudness, and how often the
birds and crickets call.

## 2026-10-29: Swimming

- A front crawl: the body face down along the surface, arms reaching and
  pulling in turn, legs fluttering. It plays slower when swimming slowly and as
  a gentle paddle when still.
- From 1 m of water the hero swims: floats with the back at the surface,
  2.4 m/s (3.6 sprinting), no jumping, no sword swings, no footsteps. They
  stop swimming below 0.85 m, so the shore doesn't flicker.
- A stroke sounds mostly of bubbles: 10 to 16 small rising bubble tones over a
  soft low wash (3 to 5 while paddling), in time with the strokes. The author
  asked for "more bubbly" over a first slap-like splash.

Placeholders: the stroke, the speeds, how high the hero floats, the sounds.

## 2026-10-29: Talking and quests

- Walk up to someone and press E to talk: they stop and turn to you, and the
  conversation runs in the choice menu (their name, their line, your numbered
  answers).
- Q opens the quest log, a drawer sliding in from the left like the inventory
  from the right: active quests with giver, description and steps; completed
  quests below, dimmed.
- Dialogue and quests are data (`data/dialogue/`, `data/quests/`) with a small
  condition/action language, so new NPCs and quests need no code.

Placeholders: the quest log's look. There are no NPCs or quests in the world
yet.

## 2026-10-26 to 2026-10-29: Design tools

Skills that design at three scales, used on request:

- `/region-design <regions> <brief>` shapes regions with landforms (mountains,
  hills, ridges, valleys, plateaus, lakes, waterfalls), kept as data in
  `data/world/landforms/`.
- `/environment-design <sectors> <brief>` builds the detail of sectors.
- `/asset-design <description>` builds an object with a Blender script,
  exports it with its own collision, previews it in Godot next to a 1.8 m
  figure, and gives it a prop scene to place it with.
