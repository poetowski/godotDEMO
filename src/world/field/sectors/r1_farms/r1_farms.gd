@tool
class_name R1Farms
extends R8Forest
## The farms round Aiwyk, R1's village, and the fields between them. A working farm in H9 with
## its doors open to the south, its fences closing a yard across H8, G8 and G9 on the author's
## painted ways. A poor one in F9 behind a broken fence, where their way west ends. A croft in
## H11 that never had a fence, its corners marked by heaps of cleared stone. Rocks, bushes, weeds
## and small stands of trees fill the land between. The places below are in metres (x east,
## y north), and tools/paint_farms.gd reads them too, so paint and props agree. The brief is in
## docs/DESIGN_DECISIONS.md; the layout is placeholder.

## The buildings: a design, its place, and the point its door turns to.
const BUILDINGS: Array[Array] = [
	["farmhouse_open", FARMHOUSE_DOOR_SOUTH, Vector2(75.5, 80.0)],
	["farm_barn", Vector2(65.5, 87.6), Vector2(65.5, 80.0)],
	["farmhouse_old", Vector2(52.6, 87.8), Vector2(55.0, 81.0)],
	["farm_shed", Vector2(47.0, 85.4), Vector2(52.0, 83.0)],
	["croft_cottage", Vector2(73.6, 106.6), Vector2(73.6, 100.0)],
	["farm_shed", Vector2(65.6, 109.0), Vector2(70.0, 103.0)],
]
const FARMHOUSE_DOOR_SOUTH := Vector2(75.5, 87.2)
## The yard's fence, closed by the barn and the house along its north. Gates stand where the
## author's ways come through.
const WEST_GATE: Array[Vector2] = [Vector2(61.0, 82.2), Vector2(61.0, 79.8)]
const SOUTH_GATE: Array[Vector2] = [Vector2(76.9, 71.6), Vector2(79.3, 71.7)]
const FARM_FENCES: Array[Array] = [
	["farm_fence_a", [Vector2(61.0, 84.6), Vector2(61.0, 82.2)]],
	["farm_fence_gate", WEST_GATE],
	["farm_fence_a", [Vector2(61.0, 79.8), Vector2(61.6, 72.0), Vector2(70.0, 71.4), Vector2(76.9, 71.6)]],
	["farm_fence_gate", SOUTH_GATE],
	["farm_fence_a", [Vector2(79.6, 72.0), Vector2(79.6, 84.6)]],
	["farm_fence_b", [Vector2(69.9, 84.9), Vector2(72.1, 84.9)]],
]
## The poor farm's fence, a length of each design in turn along its line; "" is a gap where
## nothing's left at all.
const BROKEN_DESIGNS: Array[String] = ["farm_fence_a", "farm_fence_down_a", "farm_fence_c", "", "farm_fence_stubs", "farm_fence_c", "farm_fence_down_a", "farm_fence_stubs", "", "", "farm_fence_a", "farm_fence_down_b", "farm_fence_stubs"]
const BROKEN_FENCE: Array[Vector2] = [Vector2(59.3, 85.0), Vector2(59.3, 92.4), Vector2(44.6, 92.6), Vector2(44.4, 82.0), Vector2(53.0, 81.6)]
## Things that stand by name: a design, its place and its turn, in radians.
const THINGS: Array[Array] = [
	# The working farm.
	["hay_stack", Vector2(69.5, 77.6), 0.4],
	["hay_stack", Vector2(70.2, 74.4), 1.9],
	["hay_rack", Vector2(72.7, 76.6), 1.5],
	["chicken_coop", Vector2(77.6, 80.2), -1.4],
	["garden_bed", Vector2(77.6, 75.4), 1.57],
	["chopping_block", Vector2(70.4, 82.8), 0.6],
	["firewood_pile", Vector2(70.9, 84.0), 0.1],
	["hand_cart", Vector2(68.2, 82.6), 2.4],
	["water_trough", Vector2(62.8, 83.4), 1.57],
	["camp_barrel", Vector2(78.5, 83.8), 0.0],
	["camp_crates", Vector2(62.6, 84.0), 0.5],
	# The poor one.
	["old_plough", Vector2(56.8, 90.2), 0.7],
	["hay_stack", Vector2(47.6, 90.2), 2.6],
	["garden_bed", Vector2(57.2, 84.6), 1.2],
	["hand_cart", Vector2(50.0, 83.0), 4.0],
	["camp_barrel", Vector2(56.6, 85.8), 0.0],
	["field_rock_a", Vector2(46.6, 88.6), 0.8],
	# The croft, and the stones cleared to its field's corners.
	["hay_stack", Vector2(62.6, 104.6), 0.2],
	["hay_stack", Vector2(65.4, 104.0), 1.3],
	["hay_rack", Vector2(69.4, 100.8), 0.08],
	["water_trough", Vector2(76.8, 102.8), 0.3],
	["chopping_block", Vector2(70.0, 104.2), 2.1],
	["chicken_coop", Vector2(79.0, 106.2), 1.5],
	["garden_bed", Vector2(77.8, 111.4), 0.1],
	["field_cairn", Vector2(60.6, 92.0), 0.4],
	["field_cairn", Vector2(73.6, 92.4), 2.0],
	["field_cairn", Vector2(60.8, 100.8), 3.4],
	["field_cairn", Vector2(74.4, 99.6), 1.1],
]
## Barley, in strips, in the yard and in the croft's field.
const CROPS: Array[Rect2] = [Rect2(62.6, 72.6, 5.4, 6.2), Rect2(62.0, 93.0, 11.0, 6.4)]
## The trees that stand by name: a design, its place and its size.
const FARM_TREES: Array[Array] = [
	["apple_tree", Vector2(72.6, 92.0), 1.0],
	["apple_tree", Vector2(78.6, 92.4), 0.95],
	["white_birch", Vector2(62.8, 93.0), 0.95],
	["apple_tree", Vector2(57.6, 93.2), 0.9],
	["white_birch", Vector2(46.6, 94.6), 1.05],
	["big_oak", Vector2(76.0, 116.0), 1.0],
	["white_birch", Vector2(68.0, 114.0), 1.0],
	["field_maple", Vector2(60.6, 111.4), 0.95],
]
## The farms' ground, kept free of what's scattered between them.
const YARDS: Array[Rect2] = [Rect2(59.0, 70.0, 22.0, 22.0), Rect2(43.0, 80.0, 18.0, 15.0), Rect2(59.0, 91.0, 21.5, 23.0)]
## The poor farm's ground, which the weeds are taking.
const GONE_WILD := Rect2(43.0, 80.0, 18.0, 15.0)
## The tracks the paint lays, read by tools/paint_farms.gd: [points, half width, how worn].
const TRACKS: Array[Array] = [
	[[Vector2(60.5, 80.8), Vector2(57.5, 82.2), Vector2(55.0, 83.8), Vector2(53.6, 84.8)], 0.8, 0.55],
	[[Vector2(92.8, 102.6), Vector2(86.0, 103.4), Vector2(80.0, 102.6), Vector2(75.0, 102.4), Vector2(73.6, 103.4)], 0.85, 0.7],
	[[Vector2(81.6, 88.0), Vector2(81.2, 94.0), Vector2(79.6, 100.0), Vector2(78.0, 102.4)], 0.6, 0.4],
	[[Vector2(66.0, 84.0), Vector2(70.0, 82.6), Vector2(75.5, 83.2)], 1.0, 0.75],
	[[Vector2(69.0, 103.4), Vector2(72.0, 103.2)], 0.9, 0.7],
]
## Bare patches the paint lays, read by tools/paint_farms.gd: a surface, the place and its reach.
const WORN: Array[Array] = [
	[0, Vector2(75.5, 83.0), 2.4],
	[0, Vector2(65.5, 83.2), 2.8],
	[1, Vector2(62.8, 82.4), 1.6],
	[1, Vector2(61.0, 81.0), 1.1],
	[1, Vector2(78.1, 71.65), 1.2],
	[0, Vector2(70.5, 83.0), 1.5],
	[0, Vector2(77.6, 80.2), 1.7],
	[0, Vector2(54.2, 83.8), 2.0],
	[1, Vector2(56.6, 85.8), 1.0],
	[0, Vector2(73.6, 103.0), 2.4],
	[1, Vector2(76.8, 102.4), 1.4],
	[0, Vector2(79.0, 105.2), 1.4],
	[0, Vector2(70.0, 104.0), 1.5],
]
## Metres what's tall here may reach past its block.
const TALL_REACH := 8.0
const GROVE_FROM := 0.16
const GROVE_THICK := 0.5
## Places tried per sector for what's scattered between the farms, the most it gets, and where
## on the patches' noise the thickets gather, with open field left between them.
const FIELD_TRIES := 18
const FIELD_MOST := 4
const THICKET_FROM := 0.08
## How much of the paint's stony ground means a rock belongs there.
const STONY := 0.15


func _init() -> void:
	super()
	overhang = TALL_REACH
	mass_tries = 340


func _from_camp(_xz: Vector2) -> float:
	return INF


## Small stands of broad trees and birch with open field between, none on the farms.
func _thickness(xz: Vector2) -> float:
	if _in_yard(_north(xz)):
		return 0.0
	return GROVE_THICK if _stands.get_noise_2d(xz.x, xz.y) > GROVE_FROM else 0.0


func _north(xz: Vector2) -> Vector2:
	return Vector2(xz.x, -xz.y)


func _in_yard(at: Vector2) -> bool:
	for yard in YARDS:
		if yard.has_point(at):
			return true
	return false


func _in_crops(at: Vector2) -> bool:
	for crops in CROPS:
		if crops.has_point(at):
			return true
	return false


func _tree_at(_xz: Vector2) -> String:
	var roll := rng.randf()
	if roll < 0.2:
		return "young_fir"
	if roll < 0.45:
		return "white_birch"
	if roll < 0.65:
		return "forest_hornbeam"
	if roll < 0.8:
		return "field_maple"
	return "forest_ash" if roll < 0.92 else "tall_pine"


## What grows: barley on the strips, little in the worked yards, weeds taking the poor farm, and
## out in the fields grass in clumps, flowers in drifts and thistle, dock and nettle among them.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	if depth > 0.0 or shore < WATER_PLANTS:
		return super(xz, shore, depth)
	var at := _north(xz)
	var roll := rng.randf()
	if _in_crops(at):
		return "crop_patch" if roll < 0.75 else ""
	if GONE_WILD.has_point(at):
		if roll < 0.14:
			return "nettle_patch"
		if roll < 0.28:
			return "dock_weeds"
		if roll < 0.36:
			return "thistle_patch"
		return "meadow_grass_b" if roll < 0.62 else ("meadow_grass_a" if roll < 0.78 else "")
	if _in_yard(at):
		return "meadow_grass_a" if roll < 0.1 else ("dock_weeds" if roll < 0.112 else "")
	var away := _from_road(xz)
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	var bed := _beds.get_noise_2d(xz.x, xz.y)
	if away < VERGE:
		if roll < 0.24:
			return "meadow_grass_a" if rng.randf() < 0.65 else "meadow_grass_b"
		return _any_stone() if roll < 0.31 else ("pebbles_patch" if roll < 0.33 else "")
	if patch > 0.05:
		if roll < 0.14:
			return "meadow_grass_a" if rng.randf() < 0.6 else "meadow_grass_b"
		if roll < 0.18 and bed > 0.0:
			return _flower(bed)
		if roll < 0.2:
			return "thistle_patch"
		return "dock_weeds" if roll < 0.215 else ""
	if patch < -0.25:
		return "nettle_patch" if roll < 0.03 else ("moss_patch" if roll < 0.04 else "")
	return "meadow_grass_a" if roll < 0.04 else ""


func _place_props() -> void:
	for building in BUILDINGS:
		var xz := _world(building[1])
		if owns(xz):
			var to: Vector2 = building[2]
			var from: Vector2 = building[1]
			# A model's front is its +Z here, and north is -Z.
			var angle := atan2(to.x - from.x, -(to.y - from.y))
			_place(building[0], Transform3D(Basis(Vector3.UP, angle), Vector3(xz.x, lowest_ground(xz, 2.6) - 0.05, xz.y)))
	for thing in THINGS:
		var xz := _world(thing[1])
		if owns(xz):
			_place(thing[0], Transform3D(Basis(Vector3.UP, thing[2]), Vector3(xz.x, lowest_ground(xz, 0.5) - 0.04, xz.y)))
	for run in FARM_FENCES:
		var corners: Array = run[1]
		_place_fence_run(run[0], corners)
	_place_broken_fence()
	for tree in FARM_TREES:
		_place_tree(tree[0], tree[1], tree[2])
	_place_field()


## The broken fence, a length at a time, each its turn from the list.
func _place_broken_fence() -> void:
	var lengths := 0
	for k in BROKEN_FENCE.size() - 1:
		var a: Vector2 = BROKEN_FENCE[k]
		var b: Vector2 = BROKEN_FENCE[k + 1]
		var count := maxi(roundi(a.distance_to(b) / FENCE_LENGTH), 1)
		for n in count:
			var slug := BROKEN_DESIGNS[lengths % BROKEN_DESIGNS.size()]
			lengths += 1
			if not slug.is_empty():
				_place_fence(slug, _world(a.lerp(b, float(n) / count)), _world(a.lerp(b, float(n + 1) / count)))


## Rocks, bushes and stumps between the farms, the rocks where the paint lay stony ground.
func _place_field() -> void:
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed + 7, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for attempt in FIELD_TRIES:
			if placed >= FIELD_MOST:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if _in_yard(_north(xz)) or _shore_at(xz) < WATER_PLANTS or _slope(xz) > 0.6 or TerrainPaint.road_at(xz) > 0.6:
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
			var size := rng.randf_range(0.8, 1.2)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			_place(slug, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.5) - 0.05, xz.y)))
			placed += 1


func _rock() -> String:
	var roll := rng.randf()
	if roll < 0.3:
		return "field_rock_a"
	if roll < 0.55:
		return "field_rock_b"
	return "field_rock_c" if roll < 0.85 else "mossy_boulder_a"


func _field_thing() -> String:
	var roll := rng.randf()
	if roll < 0.14:
		return "elder_bush"
	if roll < 0.32:
		return "bramble_thicket"
	if roll < 0.42:
		return "willow_shrub"
	if roll < 0.52:
		return "mossy_stump"
	if roll < 0.6:
		return "field_cairn"
	return _rock() if roll < 0.72 else ""


func _near_fence(xz: Vector2, metres: float) -> bool:
	var at := _north(xz)
	for run in FARM_FENCES:
		var corners: Array = run[1]
		for k in corners.size() - 1:
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, corners[k], corners[k + 1])) < metres:
				return true
	return false


func _place(slug: String, where: Transform3D) -> void:
	var solid := slug not in ["willow_shrub", "garden_bed", "elder_bush", "bramble_thicket", "farm_fence_down_b", "farm_fence_stubs"]
	place_prop(PropLibrary.Kind.ASSET, 0, where, solid, PropLibrary.asset_scene(slug))
