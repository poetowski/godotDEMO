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

## 2026-10-26 to 2026-10-29: Design tools

Skills that design at three scales, used on request:

- `/region-design <regions> <brief>` shapes regions with landforms (mountains,
  hills, ridges, valleys, plateaus, lakes, waterfalls), kept as data in
  `data/world/landforms/`.
- `/environment-design <sectors> <brief>` builds the detail of sectors.
- `/asset-design <description>` builds an object with a Blender script,
  exports it with its own collision, previews it in Godot next to a 1.8 m
  figure, and gives it a prop scene to place it with.

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

## 2026-10-28: Regions

Regions are 20 x 20 sectors (200 m), named R1, R2, R3... R1 is the south-west
corner; numbers run east along the southern row, then on along the next row
north. In a world of several regions a sector's full name carries its region:
R45:J10. R1 is the starting region, from which the world gets built.

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

## 2026-10-31: No third-party assets

Rule, from the author: we never use third-party assets.

## 2026-10-31: The character panel, falls and respawning

Request: "also implement character view on buttton 'c' like vie have for inventory and
quests. this character popup comes from top of screen. contains Hero Level, and then
we will add additional info. you can add HP now. 100/100. also, implement fall
damage, so if player fall for more than 10m, he dies. when player dies, he respawn
at the spawn point." **Placeholder:** level 1; water catches a fall; the message "You
died"; neither level nor HP is saved yet.

## 2026-10-31: Camera zoom

Request: "make zoom out ingame limited to 10 meters away of player up to 1m close. do
not allow bigger zoom outs", "also make zoom in and zoom out slower".
**Placeholder:** 0.25 m per notch of the wheel, half what it was.

## 2026-10-31: Levels

Request: "we need to somehow implement also if something is meters below in cave
system or in upper third or fifth level of tall building, those are just examplease.
implement system so we are ready when this happen. because - problem now is when i
walk on the bridge it thinks in the middle of the bridge that i am in the water
beneath because i start to swim." The system is "Levels" in `docs/world/README.md`:
questions about where someone is take their height too, a `LevelVolume` makes a place
of its own, and a `GroundOpening` is a way down. No cave, tower or volume exists in
the game yet. **Placeholder:** the wind dropping 20 dB in 1.5 s when enclosed, a fall
of 150 m with nothing to land on counting as dying, and the place's name following the
sector's on the HUD.

## 2026-10-31: Keeping the world in line with the land

Request: "i changed terrain, please redecorate like you did and also define this as a
skill so if i change terrain, you detect and propose lowering of flying objects, or
puting new objects, or even generating new assets." The skill is `/land-sync`, with
`npm run land-check`. **Placeholder:** the thresholds in `land_check.gd`.

## 2026-11-01: Showing and hiding the borders

Request: "[...] then implement some way ingame to show and thhem hide all sector and
region border. this is for develomental purpose and real play/testing." G shows or
hides every grid mark in any build, starting shown. **Placeholder:** the key.

## 2026-11-01: The start

Request: "change startin point to region R1 , sector E1. in the iddle pf bridge and
sector F1, but" (the message ended there). New games and respawns start in R1's E1,
facing north.

## 2026-11-07: A fresh start

Request: "i want to remove everything specific we have here, this includes all
generated assets. i want to have brand new world of 20x20 sectors, without perlin
noise flat. we should have LoD streaming, sector, region rules applied. but i want to
start designing the game from zero. prepare for this and consider everything done so
far as proof of concept and prototyping and testing engine and technology. we
delivered inventory system, character system and quest system. these should stay of
course, because it is good stuff. cleanup totally all documents and assets so we have
plain start again and remove existing scenes as not relevant anymore."

- Everything built until now is kept at git tag `prototype-final`, with its full
  design record. The demo before it is at `demo-final`, and the castle proof of
  concept at `poc-castle`.
- Gone: the starting zone (R2 to R9) and everything in it: every sector design, every
  Blender-made asset and its family, the sculpted and painted ground and the poured
  water, the river, lake and falls, the village and its name, the farms, forest and
  camps, the ravine with its border and mist, the region notes, and the art rule that
  things facing each other match.
- The world is R1 alone: 20 x 20 sectors of 10 m, flat, with no Perlin noise, and flat
  grass past its edge. Its ground streams in levels of detail around the player,
  sector designs stream in and out, and the sector and region rules above hold.
- Kept as systems, and recorded above: the hero (body, animations, swimming, sword arm),
  the inventory, the character panel with falls and respawning, quests and dialogue,
  saving and loading, the clock with day and night, footsteps and the ambient, and the
  design tools: sculpting and painting by hand, `/region-design`,
  `/environment-design`, `/asset-design`, `/land-sync` and `/gallery-pdf`. Villagers
  keep their daily programs; there are none in the world.
- **Placeholder:** the start at E1's usual spot, south of its middle (the bank it
  stood on is gone), the grass, the flat land around R1, and the world being empty.
