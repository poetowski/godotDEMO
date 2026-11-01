@tool
class_name R1Village
extends "res://src/world/field/sectors/r8_forest/r8_forest.gd"
## The village in the middle of R1, on the author's paint: houses in K10, K11, L9 and M9 round
## a square with a well, the overgrown stave church on its hill in M11 among pines, a farm in
## J8 with its fences running down into J7, and a forest climbing the rise in N and O. The
## places below are in metres (x east, y north), and tools/shape_village_land.gd and
## tools/localize_village_paint.gd read them too, so land, paint and buildings agree. The
## brief is in docs/DESIGN_DECISIONS.md; the layout is placeholder.

## The buildings: a design, its place, the point its door turns to, and metres kept clear.
const BUILDINGS: Array[Array] = [
	["village_house_b", Vector2(104.6, 95.2), Vector2(105.8, 88.2), 6.0],
	["village_house_a", Vector2(102.6, 103.0), Vector2(110.0, 101.0), 5.2],
	["village_loft", Vector2(108.2, 106.4), Vector2(110.0, 101.0), 3.8],
	["village_smithy", Vector2(113.4, 84.9), Vector2(113.0, 91.0), 4.5],
	["village_house_c", Vector2(121.6, 85.0), Vector2(121.2, 90.0), 4.8],
	["village_house_a", Vector2(128.6, 84.4), Vector2(124.5, 89.5), 4.8],
	["nordic_church", CHURCH, Vector2(120.0, 98.6), 8.5],
	["farmhouse", Vector2(95.4, 74.2), Vector2(95.0, 80.0), 5.0],
	["farm_shed", Vector2(91.9, 68.9), Vector2(96.0, 72.0), 2.6],
]
const CHURCH := Vector2(124.4, 106.8)
const SQUARE := Vector2(114.4, 92.2)
const SQUARE_RADIUS := 4.8
## The main street, from where the road comes in, across the square and up to the church.
const MAIN_STREET: Array[Vector2] = [Vector2(89.0, 83.0), Vector2(96.0, 84.0), Vector2(104.0, 87.0), Vector2(110.0, 90.0), SQUARE, Vector2(118.0, 97.0), Vector2(120.6, 99.6)]
## Lanes off the square.
const LANES: Array[Array] = [
	[SQUARE, Vector2(111.0, 96.5), Vector2(109.6, 101.0), Vector2(112.0, 106.0)],
	[SQUARE, Vector2(118.5, 90.2), Vector2(124.5, 89.6), Vector2(131.0, 90.2)],
	[Vector2(95.0, 84.0), Vector2(95.0, 80.0)],
]
## The author's ring road, where their gravel ran, as a wagon track round the village.
const RING: Array[Vector2] = [
	Vector2(92.8, 85.6), Vector2(93.0, 90.0), Vector2(94.0, 99.0), Vector2(93.0, 105.0), Vector2(96.0, 110.0), Vector2(101.0, 111.5), Vector2(108.5, 111.0), Vector2(112.0, 106.0), Vector2(114.0, 101.0), Vector2(117.0, 97.0),
	Vector2(121.0, 98.0), Vector2(126.0, 93.0), Vector2(132.0, 91.0), Vector2(136.0, 88.0), Vector2(136.0, 82.0), Vector2(132.0, 76.0), Vector2(127.0, 72.0), Vector2(117.0, 72.0), Vector2(111.0, 75.5), Vector2(107.0, 79.0), Vector2(101.0, 82.0), Vector2(99.0, 84.6),
]
## The farm: its fence's two runs (leaving a gate on the road), and the strips of barley.
const FARM_FENCES: Array[Array] = [
	["farm_fence_a", [Vector2(92.8, 78.6), Vector2(90.0, 78.6), Vector2(90.0, 61.8), Vector2(101.0, 61.8), Vector2(101.0, 78.6), Vector2(97.2, 78.6)]],
]
const CROPS := Rect2(91.0, 62.8, 9.0, 6.0)
## Everything else in the village: a design, its place and its turn, in radians.
const THINGS: Array[Array] = [
	["village_well", SQUARE, 0.5],
	["market_stall", Vector2(120.7, 92.6), -1.2],
	["hand_cart", Vector2(108.8, 88.0), 2.1],
	["village_bench", Vector2(108.8, 92.6), 1.6],
	["village_bench", Vector2(119.4, 87.4), 0.1],
	["camp_barrel", Vector2(118.8, 83.8), 0.0],
	["camp_crates", Vector2(117.7, 85.0), 0.6],
	["firewood_pile", Vector2(109.6, 82.6), 1.6],
	["garden_bed", Vector2(99.6, 89.6), 0.25],
	["garden_bed", Vector2(126.6, 80.4), -0.2],
	["garden_bed", Vector2(101.8, 108.6), 0.5],
	["clothes_line", Vector2(118.0, 79.8), 0.3],
	["clothes_line", Vector2(98.6, 99.8), 1.3],
	["drying_rack", Vector2(111.2, 110.2), 0.4],
	["hay_stack", Vector2(99.0, 71.6), 0.7],
	["water_trough", Vector2(98.8, 76.4), 1.5],
	["hand_cart", Vector2(92.6, 75.8), 0.8],
	["firewood_pile", Vector2(95.4, 69.4), 3.1],
	["rune_stone", Vector2(118.9, 100.4), 0.8],
	["rune_stone", Vector2(121.9, 97.7), 0.8],
	["mossy_boulder_a", Vector2(116.8, 104.4), 1.0],
	["big_boulder_b", Vector2(133.0, 101.0), 2.1],
	["big_boulder_a", Vector2(113.8, 114.2), 0.4],
	["mossy_stump", Vector2(117.6, 108.6), 0.6],
	["willow_shrub", Vector2(119.3, 103.4), 0.0],
	["willow_shrub", Vector2(130.8, 104.2), 1.2],
	["willow_shrub", Vector2(121.8, 113.3), 2.2],
]
## Lanterns in matching pairs, a design per place (docs/world/art.md).
const VILLAGE_LANTERNS: Array[Array] = [
	# Where the street comes into the village.
	["lantern_post", Vector2(96.0, 86.6), Vector2(96.0, 84.0)],
	["lantern_post", Vector2(97.0, 81.8), Vector2(96.0, 84.0)],
	# The square's way up to the church.
	["lantern_hook", Vector2(114.8, 98.0), Vector2(117.6, 96.2)],
	["lantern_hook", Vector2(120.4, 94.4), Vector2(117.6, 96.2)],
	# The way out east.
	["lantern_stone", Vector2(132.6, 92.4), Vector2(132.6, 90.5)],
	["lantern_stone", Vector2(132.8, 88.6), Vector2(132.6, 90.5)],
	# The farm's gate.
	["lantern_stone", Vector2(92.4, 79.8), Vector2(95.0, 79.4)],
	["lantern_stone", Vector2(97.6, 79.8), Vector2(95.0, 79.4)],
]
## The trees that stand by name, to move by hand: a design, its place and its size.
const VILLAGE_TREES: Array[Array] = [
	["white_birch", Vector2(106.8, 99.4), 1.0],
	["white_birch", Vector2(99.0, 95.0), 0.9],
	["white_birch", Vector2(110.8, 104.4), 0.85],
	["white_birch", Vector2(119.5, 88.2), 0.95],
	["apple_tree", Vector2(97.4, 91.8), 1.0],
	["apple_tree", Vector2(124.0, 80.2), 0.95],
	["apple_tree", Vector2(106.0, 82.0), 1.05],
	["field_maple", Vector2(112.8, 77.4), 1.0],
	["big_oak", Vector2(109.0, 115.2), 1.0],
	["tall_beech", Vector2(87.0, 92.0), 1.0],
	["tall_pine", Vector2(116.5, 110.2), 1.1],
	["tall_pine", Vector2(121.0, 116.0), 1.2],
	["forest_spruce_b", Vector2(128.0, 116.5), 1.0],
	["tall_pine", Vector2(133.8, 109.4), 1.1],
	["forest_spruce_b", Vector2(116.2, 102.2), 0.85],
	["white_birch", Vector2(87.5, 69.0), 1.0],
	["white_birch", Vector2(103.5, 68.0), 0.9],
]
## Metres from the church where its pines start and stop.
const PINES_FROM := 9.5
const PINES_TO := 17.0
## x where the forest in N and O begins.
const FOREST_WEST := 130.0
## Metres between the places a tree is tried: closer than R8's, for a real forest.
const TREE_STEP_HERE := 3.3
## Metres what's tall here may reach past its block.
const TALL_REACH := 8.0


func _init() -> void:
	super()
	overhang = TALL_REACH
	mass_tries = 460


func _tree_step() -> float:
	return TREE_STEP_HERE


func _from_camp(_xz: Vector2) -> float:
	return INF


## How thick the trees stand: all but a gap down to the village round the church, and the
## forest east of it, thinning at its edges. Elsewhere they're the odd one.
func _thickness(xz: Vector2) -> float:
	var at := _north(xz)
	if at.x >= FOREST_WEST:
		return smoothstep(FOREST_WEST - 1.0, FOREST_WEST + 4.0, at.x) * 0.92
	var from_church := at.distance_to(CHURCH)
	if from_church > PINES_FROM and from_church < PINES_TO:
		var toward_village := (SQUARE - CHURCH).normalized().dot((at - CHURCH).normalized())
		return 0.0 if toward_village > 0.72 else 0.88
	return 0.0


func _north(xz: Vector2) -> Vector2:
	return Vector2(xz.x, -xz.y)


func _tree_ground(xz: Vector2) -> bool:
	var at := _north(xz)
	for building in BUILDINGS:
		if at.distance_to(building[1]) < float(building[3]) + 1.5:
			return false
	return super(xz) and not CROPS.has_point(at) and not _on_farm(at)


func _on_farm(at: Vector2) -> bool:
	return at.x > 88.5 and at.x < 102.5 and at.y > 60.0 and at.y < 80.0


## Pines round the church; in the forest, spruce and pine with broad trees and birches in
## stands of their own.
func _tree_at(xz: Vector2) -> String:
	var roll := rng.randf()
	if _north(xz).x < FOREST_WEST:
		if roll < 0.08:
			return "young_fir"
		return "tall_pine" if roll < 0.68 else "forest_spruce_a"
	var stand := _stands.get_noise_2d(xz.x, xz.y)
	if roll < 0.03:
		return "dead_pine"
	if roll < 0.18:
		return "young_fir"
	if stand > 0.08:
		return "forest_spruce_b" if roll < 0.3 else ("tall_pine" if roll < 0.55 else "forest_spruce_a")
	if stand < -0.1:
		return "white_birch" if roll < 0.45 else ("forest_ash" if roll < 0.7 else "tall_beech")
	return "forest_hornbeam" if roll < 0.5 else ("field_maple" if roll < 0.62 else "forest_spruce_a")


## What grows: the forest's floor under the trees, barley on the farm's strips, moss and fern
## in the church's shade, and grass and flowers along the lanes.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	var at := _north(xz)
	if CROPS.has_point(at):
		return "crop_patch" if rng.randf() < 0.75 else ""
	if at.x >= FOREST_WEST + 1.0:
		return super(xz, shore, depth)
	var roll := rng.randf()
	var from_church := at.distance_to(CHURCH)
	if from_church < PINES_TO + 1.0:
		if roll < 0.2:
			return "waterside_fern" if rng.randf() < 0.45 else "bracken"
		if roll < 0.34:
			return "moss_patch"
		return "leaf_litter" if roll < 0.44 else ("meadow_grass_b" if roll < 0.52 else "")
	var away := _from_road(xz)
	var bed := _beds.get_noise_2d(xz.x, xz.y)
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	if away < VERGE:
		if roll < 0.22:
			return "meadow_grass_a" if rng.randf() < 0.7 else "meadow_grass_b"
		if roll < 0.29 and patch > -0.05:
			return _flower(bed)
		return _any_stone() if roll < 0.32 else ""
	if away < NEAR:
		if roll < 0.13:
			return "meadow_grass_a"
		if roll < 0.18:
			return "meadow_grass_b"
		return _flower(bed) if roll < 0.23 and bed > 0.0 else ""
	if patch > 0.05:
		if roll < 0.09:
			return "meadow_grass_a" if rng.randf() < 0.7 else "meadow_grass_b"
		return _flower(bed) if roll < 0.115 and bed > 0.1 else ""
	return "moss_patch" if roll < 0.006 else ("meadow_grass_a" if roll < 0.022 else "")


func _place_props() -> void:
	for building in BUILDINGS:
		var xz := _world(building[1])
		if owns(xz):
			var to: Vector2 = building[2]
			var from: Vector2 = building[1]
			# A model's front is its +Z here, and north is -Z.
			var angle := atan2(to.x - from.x, -(to.y - from.y))
			var foot := minf(float(building[3]) * 0.75, 3.5)
			_place_flat(building[0], Transform3D(Basis(Vector3.UP, angle), Vector3(xz.x, lowest_ground(xz, foot) - 0.05, xz.y)))
	for thing in THINGS:
		var xz := _world(thing[1])
		if owns(xz):
			_place_flat(thing[0], Transform3D(Basis(Vector3.UP, thing[2]), Vector3(xz.x, lowest_ground(xz, 0.5) - 0.04, xz.y)))
	for run in FARM_FENCES:
		_place_fence_run(run[0], run[1])
	for lantern in VILLAGE_LANTERNS:
		_place_lantern(lantern[0], lantern[1], lantern[2])
	for tree in VILLAGE_TREES:
		_place_tree(tree[0], tree[1], tree[2])
	for cell in cells():
		if Vector2(SectorMap.corner_of(cell).x, 0.0).x >= FOREST_WEST:
			_place_wood_props(cell)


func _place_flat(slug: String, where: Transform3D) -> void:
	_place(slug, where)


## A forest's fallen things and rocks, where nothing's been built.
func _prop_ground(xz: Vector2, slug: String) -> bool:
	return _tree_ground(xz) and super(xz, slug)


func _near_fence(xz: Vector2, metres: float) -> bool:
	var at := _north(xz)
	for run in FARM_FENCES:
		var corners: Array = run[1]
		for k in corners.size() - 1:
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, corners[k], corners[k + 1])) < metres:
				return true
	return false


func _place(slug: String, where: Transform3D) -> void:
	var solid := slug not in ["willow_shrub", "garden_bed", "bedroll"]
	place_prop(PropLibrary.Kind.ASSET, 0, where, solid, PropLibrary.asset_scene(slug))
