@tool
class_name R6SouthBank
extends R8Forest
## The river's far side in R6, south of the bridge, on the author's paint: tall poplars and thick
## bushes over F19 and F20, white poplars along C20 and D20, a medieval army's tent in D19, a ring
## of stones round an old post in E18, and rocks, plants and small finds through the rest. The
## trees and plants are masses worked out from the land; the rest are props to move by hand. The
## places below are in metres (x east, y north, so negative here), and tools/paint_south_bank.gd
## reads them too. The brief is in docs/DESIGN_DECISIONS.md; the layout is placeholder.

## The poplars' sectors, and the white poplars'.
const POPLARS := Rect2(50.0, -20.0, 10.0, 20.0)
const WHITE_POPLARS := Rect2(20.0, -10.0, 20.0, 10.0)
## How thick each stands, and the odd stand elsewhere, where the stands' noise is above this.
const POPLARS_THICK := 1.2
const WHITE_THICK := 0.9
const STAND_THICK := 0.2
const STAND_FROM := 0.16
const TENT := Vector2(34.5, -15.2)
## Metres the tent's camp keeps clear.
const CAMP_REACH := 8.5
const RING := Vector2(45.0, -25.0)
const RING_REACH := 4.5
## Metres between the places a tree is tried: 16 a sector, so the poplars can cover theirs.
const TREE_STEP_HERE := 2.5
## Metres a trunk in the stands keeps from the author's strokes, which lie all through F19 and F20,
## and from the next trunk.
const STAND_WAY_CLEAR := 1.2
const TREE_ROOM_HERE := 0.6
## Metres what's tall here may reach past its block.
const TALL_REACH := 8.0
## The tent's camp and what stands by name: a design, its place and its turn, in radians. A model's
## front turns to +X at about 1.57. Pairs either side of the door match (docs/world/art.md).
const THINGS: Array[Array] = [
	["military_tent", TENT, 1.57],
	["war_banner", Vector2(39.6, -12.0), 1.57],
	["war_banner", Vector2(39.6, -18.4), 1.57],
	["weapon_rack", Vector2(33.2, -10.0), 3.14],
	["campfire", Vector2(41.8, -15.2), 0.5],
	["cook_tripod", Vector2(41.8, -15.2), 1.2],
	["log_seat", Vector2(40.2, -16.0), 1.2],
	["log_seat", Vector2(43.0, -13.8), 4.0],
	["camp_barrel", Vector2(30.0, -11.6), 0.0],
	["camp_crates", Vector2(30.8, -19.8), 0.8],
	["firewood_pile", Vector2(37.2, -20.6), 0.2],
	["chopping_block", Vector2(40.0, -20.8), 2.0],
	["hand_cart", Vector2(29.0, -15.6), 1.8],
	["stone_ring", RING, 0.0],
	["forest_idol", RING, 0.4],
]
## Places tried per sector for what's scattered about, the most it gets, and where on the patches'
## noise the thickets gather.
const FIELD_TRIES := 20
const FIELD_MOST := 4
const THICKET_FROM := 0.02
## How much of the paint's stony ground means a rock belongs there.
const STONY := 0.15


func _init() -> void:
	super()
	overhang = TALL_REACH
	mass_tries = 430


func _tree_step() -> float:
	return TREE_STEP_HERE


func _tree_room() -> float:
	return TREE_ROOM_HERE


func _from_camp(xz: Vector2) -> float:
	var at := _north(xz)
	return minf(at.distance_to(TENT), at.distance_to(RING) + CAMP_REACH - RING_REACH)


func _north(xz: Vector2) -> Vector2:
	return Vector2(xz.x, -xz.y)


func _tree_ground(xz: Vector2) -> bool:
	var at := _north(xz)
	var clear := STAND_WAY_CLEAR if POPLARS.has_point(at) or WHITE_POPLARS.has_point(at) else WAY_CLEAR
	return height_at(xz) > RIM_LEVEL and _slope(xz) < TREE_STEEPEST and _shore_at(xz) > 2.5 and _from_road(xz) > clear and _from_camp(xz) > CAMP_REACH


func _thickness(xz: Vector2) -> float:
	var at := _north(xz)
	if POPLARS.has_point(at):
		return POPLARS_THICK
	if WHITE_POPLARS.has_point(at):
		return WHITE_THICK
	return STAND_THICK if _stands.get_noise_2d(xz.x, xz.y) > STAND_FROM else 0.0


func _tree_at(xz: Vector2) -> String:
	var at := _north(xz)
	var roll := rng.randf()
	if POPLARS.has_point(at):
		return "tall_poplar_a" if roll < 0.62 else "tall_poplar_b"
	if WHITE_POPLARS.has_point(at):
		return "white_poplar_a" if roll < 0.42 else "white_poplar_b"
	if roll < 0.22:
		return "tall_poplar_b"
	if roll < 0.42:
		return "white_poplar_b"
	if roll < 0.6:
		return "forest_hornbeam"
	return "field_maple" if roll < 0.78 else "white_birch"


## What grows: the waterside's by the water, bushes crowding under the poplars, flowers along the
## white poplars and the way, little in the camp, and grass, weeds and berries in the rest.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	if depth > 0.0 or shore < WATER_PLANTS:
		return super(xz, shore, depth)
	var at := _north(xz)
	var roll := rng.randf()
	if at.distance_to(TENT) < CAMP_REACH or at.distance_to(RING) < RING_REACH:
		return "meadow_grass_a" if roll < 0.05 else ""
	var away := _from_road(xz)
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	var bed := _beds.get_noise_2d(xz.x, xz.y)
	if POPLARS.has_point(at):
		if roll < 0.16:
			return "hazel_bush"
		if roll < 0.29:
			return "dog_rose"
		if roll < 0.36:
			return "elder_bush"
		if roll < 0.4:
			return "bramble_thicket"
		if roll < 0.52:
			return "bracken"
		return "meadow_grass_b" if roll < 0.66 else ("cow_parsley" if roll < 0.7 else "")
	if away < VERGE:
		if roll < 0.24:
			return "meadow_grass_a" if rng.randf() < 0.65 else "meadow_grass_b"
		if roll < 0.3:
			return "cow_parsley"
		return _any_stone() if roll < 0.36 else ""
	if WHITE_POPLARS.has_point(at):
		if roll < 0.08:
			return "cow_parsley"
		if roll < 0.14:
			return "foxglove"
		if roll < 0.2:
			return "dog_rose" if patch > 0.0 else "hazel_bush"
		if roll < 0.3:
			return "leaf_litter"
		return "meadow_grass_a" if roll < 0.46 else ""
	if patch > 0.05:
		if roll < 0.14:
			return "meadow_grass_a" if rng.randf() < 0.6 else "meadow_grass_b"
		if roll < 0.18 and bed > 0.0:
			return _flower(bed)
		if roll < 0.205:
			return "foxglove" if bed < 0.0 else "cow_parsley"
		if roll < 0.225:
			return "berry_patch"
		return "dock_weeds" if roll < 0.24 else ""
	if patch < -0.25:
		return "nettle_patch" if roll < 0.03 else ("moss_patch" if roll < 0.045 else "")
	return "meadow_grass_a" if roll < 0.04 else ""


func _place_props() -> void:
	for thing in THINGS:
		var xz := _world(thing[1])
		if owns(xz):
			_place(thing[0], Transform3D(Basis(Vector3.UP, thing[2]), Vector3(xz.x, lowest_ground(xz, 0.5) - 0.04, xz.y)))
	_place_field()


## Rocks where the paint lay stony ground, bushes in thickets, and small finds.
func _place_field() -> void:
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed + 7, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for attempt in FIELD_TRIES:
			if placed >= FIELD_MOST:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if _from_camp(xz) < CAMP_REACH or _shore_at(xz) < WATER_PLANTS or _slope(xz) > 0.6 or TerrainPaint.road_at(xz) > 0.6:
				continue
			var stony := TerrainPaint.share(roundi(xz.x), roundi(-xz.y), 2) > STONY
			if not stony and _patches.get_noise_2d(xz.x, xz.y) < THICKET_FROM:
				continue
			var slug := _rock() if stony else _field_thing()
			if slug.is_empty():
				continue
			var room := PropLibrary.asset_room(PropLibrary.asset_scene(slug))
			if not fits(xz, room * 1.2) or not is_clear(xz, PropLibrary.FEET.get(slug, room * 0.8), 0.9):
				continue
			var size := rng.randf_range(0.85, 1.2)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			_place(slug, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.5) - 0.04, xz.y)))
			placed += 1


func _rock() -> String:
	var roll := rng.randf()
	if roll < 0.3:
		return "field_rock_a"
	if roll < 0.55:
		return "field_rock_b"
	return "field_rock_c" if roll < 0.82 else "mossy_boulder_b"


func _field_thing() -> String:
	var roll := rng.randf()
	if roll < 0.14:
		return "gnawed_stump"
	if roll < 0.28:
		return "bracket_log"
	if roll < 0.36:
		return "shed_antlers"
	if roll < 0.46:
		return "willow_shrub"
	if roll < 0.56:
		return "mossy_stump"
	return _rock() if roll < 0.72 else ""


func _place(slug: String, where: Transform3D) -> void:
	var solid := slug not in ["willow_shrub", "shed_antlers", "stone_ring", "campfire", "cook_tripod"]
	place_prop(PropLibrary.Kind.ASSET, 0, where, solid, PropLibrary.asset_scene(slug))
