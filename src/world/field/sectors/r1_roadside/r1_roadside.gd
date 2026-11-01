@tool
extends "res://src/world/field/sectors/r1_waterside/r1_waterside.gd"
## R1's painted roads and the farm in D5. Grass, flowers, moss and stones grow along
## the roads the author painted, thick on the verges and thinning away from them, and
## boulders and shrubs lie among them. By the water it grows what the waterside grows.
## The farm, its fences, the lanterns and the big trees have places of their own below,
## in metres (x east, y north). A block of sectors per design, so they stream; each block
## places what stands in its own sectors. The brief is in docs/DESIGN_DECISIONS.md; the
## layout is placeholder.

## Metres from a road where the verge ends, and where the thicker grass ends.
const VERGE := 2.5
const NEAR := 7.0
## Metres from a road that are told apart; everything further counts as further.
const ROAD_REACH := 12
## Metres from the water within which the waterside's plants grow instead.
const WATER_PLANTS := 5.0

## The farmhouse, facing south over its yard, turned a little.
const FARMHOUSE := Vector2(35.6, 47.4)
const FARMHOUSE_TURN := 0.09
## How far around the house's middle it stands on the ground.
const FARMHOUSE_FOOT := 2.3
const HAY_STACK := Vector2(30.3, 47.0)
## The fences: a design and the corners it runs through, in lengths of about 2.4 m.
## Every `FENCE_OLD`th length of the rail fence is the old one. Both leave the yard
## open to the road in the south-east and to the path behind the house.
const FENCE_LENGTH := 2.4
const FENCE_OLD := 4
const FENCES: Array[Array] = [
	["farm_fence_a", [Vector2(39.4, 44.2), Vector2(39.4, 51.4), Vector2(34.6, 51.7)]],
	["farm_fence_b", [Vector2(29.4, 53.2), Vector2(24.6, 53.2), Vector2(23.0, 51.4), Vector2(22.7, 49.0), Vector2(21.7, 46.8), Vector2(21.5, 44.4), Vector2(22.3, 42.1)]],
]
## The lanterns: a design, its place, and the point on the road it turns to. Those
## facing each other across a crossroad match (see docs/world/art.md).
const LANTERNS: Array[Array] = [
	# D4's crossroad.
	["lantern_hook", Vector2(34.9, 30.4), Vector2(37.9, 31.6)],
	["lantern_hook", Vector2(41.0, 32.8), Vector2(37.9, 31.6)],
	# E5's crossroad, and on up the road north of it through E6 and E7.
	["lantern_post", Vector2(47.5, 38.8), Vector2(47.0, 41.5)],
	["lantern_post", Vector2(46.6, 45.0), Vector2(47.0, 41.5)],
	["lantern_post", Vector2(43.4, 54.5), Vector2(41.0, 54.5)],
	["lantern_post", Vector2(44.8, 66.7), Vector2(44.0, 63.0)],
	# The bend on G4's north edge, and on up the road through G5.
	["lantern_stone", Vector2(61.5, 38.9), Vector2(61.0, 41.2)],
	["lantern_stone", Vector2(60.5, 43.6), Vector2(61.0, 41.2)],
	["lantern_stone", Vector2(62.7, 46.8), Vector2(64.5, 46.8)],
]
## The full-grown trees: a design, its place and its size. A turned tree's box is wider
## than the tree, and it must stay inside its block.
const TREES: Array[Array] = [
	["apple_tree", Vector2(29.8, 50.2), 1.0],
	["apple_tree", Vector2(17.4, 50.2), 1.05],
	["apple_tree", Vector2(16.6, 45.8), 0.95],
	["apple_tree", Vector2(13.6, 48.2), 1.0],
	["big_oak", Vector2(28.0, 60.5), 1.0],
	["big_oak", Vector2(50.5, 55.6), 0.95],
	["tall_beech", Vector2(20.5, 54.5), 1.0],
	["tall_beech", Vector2(34.6, 63.0), 0.9],
	["tall_beech", Vector2(46.5, 69.5), 1.0],
	["tall_pine", Vector2(16.8, 60.0), 1.0],
	["tall_pine", Vector2(20.5, 67.0), 1.15],
	["tall_pine", Vector2(16.5, 71.5), 0.9],
	["tall_pine", Vector2(54.6, 67.5), 1.1],
	["tall_pine", Vector2(53.0, 73.0), 0.9],
	["white_birch", Vector2(25.0, 35.5), 1.0],
	["white_birch", Vector2(22.4, 37.6), 0.9],
	["white_birch", Vector2(27.2, 37.4), 1.1],
	["white_birch", Vector2(64.8, 63.0), 1.0],
	["white_birch", Vector2(67.0, 65.4), 0.9],
	["white_birch", Vector2(62.3, 65.6), 1.1],
	["field_maple", Vector2(15.4, 36.2), 1.0],
	["field_maple", Vector2(57.5, 45.8), 0.95],
	["field_maple", Vector2(66.0, 36.4), 0.9],
	["lake_alder", Vector2(67.0, 54.0), 0.9],
]
## Places tried per sector for boulders and shrubs, and the most a sector gets.
const WILD_TRIES := 14
const WILD_MOST := 2

## Metres to the nearest road per sample around the owned sectors.
var _roads := PackedFloat32Array()
var _roads_area := Rect2i()


func _populate() -> void:
	TerrainPaint.load_all()
	_read_roads()
	super()


func _grows_at(_xz: Vector2) -> bool:
	return true


## Metres to the nearest road at a point, by the sample nearest it.
func _from_road(xz: Vector2) -> float:
	var sample := Vector2i(roundi(xz.x), roundi(-xz.y)) - _roads_area.position
	if sample.x < 0 or sample.y < 0 or sample.x >= _roads_area.size.x or sample.y >= _roads_area.size.y:
		return ROAD_REACH + 1.0
	return _roads[sample.y * _roads_area.size.x + sample.x]


## Measures the distance to the painted bare ground, ring by ring out from it, around
## the owned sectors.
func _read_roads() -> void:
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	for cell in cells():
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x + 1), maxi(high.y, cell.y + 1))
	var size := int(SectorMap.SIZE)
	_roads_area = Rect2i(low * size - Vector2i.ONE * (ROAD_REACH + 1), (high - low) * size + Vector2i.ONE * (2 * ROAD_REACH + 3))
	var columns := _roads_area.size.x
	_roads.resize(columns * _roads_area.size.y)
	_roads.fill(ROAD_REACH + 1.0)
	var ring: Array[int] = []
	for j in _roads_area.size.y:
		for i in columns:
			if TerrainPaint.bare_at(Vector2(_roads_area.position.x + i, -(_roads_area.position.y + j))) > 0.25:
				var k := j * columns + i
				_roads[k] = 0.0
				ring.append(k)
	for distance in ROAD_REACH:
		var next: Array[int] = []
		for k in ring:
			for side: int in [1, -1, columns, -columns, columns + 1, columns - 1, -columns + 1, -columns - 1]:
				var other := k + side
				if other >= 0 and other < _roads.size() and _roads[other] > distance + 1.0:
					_roads[other] = distance + 1.0
					next.append(other)
		ring = next


## Which mass suits a point: the waterside's by the water, else grass, flowers, moss and
## stones, thick along the roads and thinning away from them, in beds and clearings.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	if depth > 0.0 or shore < WATER_PLANTS:
		return super(xz, shore, depth)
	var away := _from_road(xz)
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	var bed := _beds.get_noise_2d(xz.x, xz.y)
	var roll := rng.randf()
	if away < VERGE:
		if roll < 0.26:
			return "meadow_grass_a"
		if roll < 0.33:
			return "meadow_grass_b"
		if roll < 0.38:
			return _any_stone()
		if roll < 0.4:
			return "pebbles_patch"
		return _flower(bed) if roll < 0.46 and patch > 0.0 else ""
	if away < NEAR:
		if roll < 0.13:
			return "meadow_grass_a"
		if roll < 0.18:
			return "meadow_grass_b"
		if roll < 0.235 and bed > 0.05:
			return _flower(bed)
		if roll < 0.25 and patch < -0.05:
			return "moss_patch"
		return "river_stone_b" if roll < 0.26 else ""
	# Out in the field, clumps with clearings between them.
	if patch > 0.08:
		if roll < 0.1:
			return "meadow_grass_a" if rng.randf() < 0.7 else "meadow_grass_b"
		return _flower(bed) if roll < 0.125 and bed > 0.1 else ""
	return "moss_patch" if roll < 0.006 else ("meadow_grass_a" if roll < 0.025 else "")


## The flowers of a bed, so each kind grows in its own drifts.
func _flower(bed: float) -> String:
	if bed > 0.2:
		return "wild_flowers_c"
	if bed > 0.0:
		return "wild_flowers_a"
	return "wild_flowers_b" if bed > -0.2 else "marsh_marigold"


func _place_props() -> void:
	super()
	_place_farm()
	for lantern in LANTERNS:
		_place_lantern(lantern[0], lantern[1], lantern[2])
	for tree in TREES:
		_place_tree(tree[0], tree[1], tree[2])
	_place_wild()


func _place_farm() -> void:
	var house := _world(FARMHOUSE)
	if owns(house):
		_place("farmhouse", Transform3D(Basis(Vector3.UP, FARMHOUSE_TURN), Vector3(house.x, lowest_ground(house, FARMHOUSE_FOOT) - 0.05, house.y)))
	var stack := _world(HAY_STACK)
	if owns(stack):
		_place("hay_stack", Transform3D(Basis(Vector3.UP, 0.7), Vector3(stack.x, lowest_ground(stack, 0.7) - 0.05, stack.y)))
	for run in FENCES:
		_place_fence_run(run[0], run[1])


## Lengths of fence through a line of corners, each following the ground.
func _place_fence_run(slug: String, corners: Array) -> void:
	var lengths := 0
	for k in corners.size() - 1:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[k + 1]
		var count := maxi(roundi(a.distance_to(b) / FENCE_LENGTH), 1)
		for n in count:
			lengths += 1
			var old := slug == "farm_fence_a" and lengths % FENCE_OLD == 0
			_place_fence("farm_fence_c" if old else slug, _world(a.lerp(b, float(n) / count)), _world(a.lerp(b, float(n + 1) / count)))


func _place_fence(slug: String, a: Vector2, b: Vector2) -> void:
	var middle := a.lerp(b, 0.5)
	if not owns(middle):
		return
	var from := Vector3(a.x, height_at(a), a.y)
	var to := Vector3(b.x, height_at(b), b.y)
	var along := (to - from).normalized()
	var side := along.cross(Vector3.UP).normalized()
	var where := Transform3D(Basis(along, side.cross(along), side), Vector3(middle.x, (from.y + to.y) * 0.5 - 0.02, middle.y))
	_place(slug, where)


func _place_lantern(slug: String, at: Vector2, road: Vector2) -> void:
	var xz := _world(at)
	if not owns(xz):
		return
	var toward := road - at
	_place(slug, Transform3D(Basis(Vector3.UP, atan2(toward.y, toward.x)), Vector3(xz.x, lowest_ground(xz, 0.3) - 0.05, xz.y)))


func _place_tree(slug: String, at: Vector2, size: float) -> void:
	var xz := _world(at)
	if not owns(xz):
		return
	rng.seed = hash(at)
	var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
	_place(slug, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.6) - 0.05, xz.y)))


## Boulders, stumps and shrubs among the grass, off the roads.
func _place_wild() -> void:
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed + 3, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for attempt in WILD_TRIES:
			if placed >= WILD_MOST:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			var away := _from_road(xz)
			if away < 1.5 or away > 11.0 or _shore_at(xz) < WATER_PLANTS or _slope(xz) > 0.6:
				continue
			var slug := _wild_thing()
			if slug.is_empty():
				continue
			var room := PropLibrary.asset_room(PropLibrary.asset_scene(slug))
			# Turned and scaled up, a model reaches this much further.
			if not fits(xz, room * 1.5) or crowds_start(xz, room) or not is_clear(xz, room * 0.8, 0.9) or _near_fence(xz, room * 1.2 + 0.3):
				continue
			var size := rng.randf_range(0.85, 1.15)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			_place(slug, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.5) - 0.05, xz.y)))
			placed += 1


## True within some metres of a fence's line.
func _near_fence(xz: Vector2, metres: float) -> bool:
	var at := Vector2(xz.x, -xz.y)
	for run in FENCES:
		var corners: Array = run[1]
		for k in corners.size() - 1:
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, corners[k], corners[k + 1])) < metres:
				return true
	return false


func _wild_thing() -> String:
	var roll := rng.randf()
	if roll < 0.1:
		return "big_boulder_a"
	if roll < 0.17:
		return "big_boulder_b"
	if roll < 0.32:
		return "mossy_boulder_a"
	if roll < 0.45:
		return "mossy_boulder_b"
	if roll < 0.55:
		return "mossy_stump"
	return "willow_shrub" if roll < 0.7 else ""


func _place(slug: String, where: Transform3D) -> void:
	var solid := slug != "willow_shrub"
	place_prop(PropLibrary.Kind.ASSET, 0, where, solid, PropLibrary.asset_scene(slug))


## A place in metres (x east, y north) as a world x and z.
func _world(at: Vector2) -> Vector2:
	return Vector2(at.x, -at.y)
