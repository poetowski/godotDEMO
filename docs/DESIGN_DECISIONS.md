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
