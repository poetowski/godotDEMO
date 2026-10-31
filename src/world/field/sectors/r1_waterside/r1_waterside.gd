@tool
extends SectorDesign
## R1's waterside: the riverside assets (tools/blender/riverside.py) growing and
## lying along the lake and its two rivers, a block of sectors per design so they
## stream. It decorates the land (`decorates_land`) and reads the water from it,
## so masses follow the land when it's sculpted again. Lilies keep to still
## water, reeds to the shallows, stones gather where the rivers run shallow, and
## flowers and ferns grow on the banks above; patches of noise make beds and
## clearings. Boulders, driftwood, stumps and willows are props to move by hand.
## The brief is in docs/DESIGN_DECISIONS.md; the layout is placeholder.

## Metres from the water within which anything grows.
const REACH := 11
## Flow in metres a second below which lilies grow.
const STILL := 0.18
## Steepest ground, in rise per metre, that plants and wood sit on.
const STEEPEST := 1.1
## For each mass: how far its top sways, how far it bobs, and from how far it shows.
const MASSES: Dictionary[String, Array] = {
	"river_stone_a": [0.0, 0.0, 50.0],
	"river_stone_b": [0.0, 0.0, 50.0],
	"river_stone_c": [0.0, 0.0, 50.0],
	"pebbles_patch": [0.0, 0.0, 35.0],
	"lily_pads": [0.0, 0.006, 75.0],
	"lily_white": [0.0, 0.006, 75.0],
	"lily_pink": [0.0, 0.006, 75.0],
	"reeds_a": [0.03, 0.0, 85.0],
	"reeds_b": [0.04, 0.0, 85.0],
	"cattails": [0.022, 0.0, 85.0],
	"sedge_a": [0.09, 0.0, 45.0],
	"sedge_b": [0.08, 0.0, 45.0],
	"waterside_fern": [0.08, 0.0, 40.0],
	"blue_flag_iris": [0.03, 0.0, 55.0],
	"marsh_marigold": [0.12, 0.0, 45.0],
}
## Metres of room each mass takes.
const ROOM: Dictionary[String, float] = {
	"river_stone_a": 0.22,
	"river_stone_b": 0.16,
	"river_stone_c": 0.3,
	"pebbles_patch": 0.45,
	"lily_pads": 0.42,
	"lily_white": 0.42,
	"lily_pink": 0.42,
	"reeds_a": 0.3,
	"reeds_b": 0.25,
	"cattails": 0.32,
	"sedge_a": 0.24,
	"sedge_b": 0.3,
	"waterside_fern": 0.3,
	"blue_flag_iris": 0.2,
	"marsh_marigold": 0.22,
}

## Places tried per sector for masses, and for props.
@export var mass_tries: int = 900
@export var prop_tries: int = 26
## Metres at least between willows.
@export var willow_spacing: float = 26.0

## Beds of reeds, and which plants grow where on the banks.
var _beds: FastNoiseLite
var _patches: FastNoiseLite
## Metres to the water's edge per sample around the owned sectors: above 0 on
## land, below 0 in the water.
var _shore := PackedFloat32Array()
var _shore_area := Rect2i()
var _copies: Dictionary[String, Array] = {}
var _copy_tints: Dictionary[String, PackedColorArray] = {}


func _setup() -> void:
	_beds = FastNoiseLite.new()
	_beds.seed = 71
	_beds.frequency = 0.045
	_patches = FastNoiseLite.new()
	_patches.seed = 72
	_patches.frequency = 0.07


func _populate() -> void:
	_copies.clear()
	_copy_tints.clear()
	_read_shore()
	if not props_frozen:
		_place_props()
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		for attempt in mass_tries:
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if absf(_shore_at(xz)) < REACH:
				_try_mass(xz)
	for slug: String in _copies:
		var look: Array = MASSES[slug]
		var transforms: Array[Transform3D] = []
		transforms.assign(_copies[slug])
		add_multimesh(slug.to_pascal_case(), PropLibrary.mass_mesh(slug, look[0], look[1]), null, transforms, _copy_tints[slug], look[2])


## Metres to the water's edge at a point, by the sample nearest it.
func _shore_at(xz: Vector2) -> float:
	var sample := Vector2i(roundi(xz.x), roundi(-xz.y)) - _shore_area.position
	if sample.x < 0 or sample.y < 0 or sample.x >= _shore_area.size.x or sample.y >= _shore_area.size.y:
		return REACH + 1.0
	return _shore[sample.y * _shore_area.size.x + sample.x]


## Measures the distance to the water's edge, ring by ring out from it on both
## sides, around the owned sectors.
func _read_shore() -> void:
	var low := Vector2i(1 << 30, 1 << 30)
	var high := -low
	for cell in cells():
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x + 1), maxi(high.y, cell.y + 1))
	var size := int(SectorMap.SIZE)
	_shore_area = Rect2i(low * size - Vector2i.ONE * (REACH + 1), (high - low) * size + Vector2i.ONE * (2 * REACH + 3))
	var columns := _shore_area.size.x
	var wet := PackedByteArray()
	wet.resize(columns * _shore_area.size.y)
	var any_water := false
	for j in _shore_area.size.y:
		for i in columns:
			var xz := Vector2(_shore_area.position.x + i, -(_shore_area.position.y + j))
			if water_level_at(xz) > height_at(xz):
				wet[j * columns + i] = 1
				any_water = true
	_shore.resize(wet.size())
	_shore.fill(REACH + 1.0)
	if not any_water:
		return
	var seen := PackedByteArray()
	seen.resize(wet.size())
	var ring: Array[int] = []
	for k in wet.size():
		for side: int in [1, -1, columns, -columns]:
			var other := k + side
			if other >= 0 and other < wet.size() and wet[other] != wet[k]:
				ring.append(k)
				seen[k] = 1
				_shore[k] = 0.5 if wet[k] == 0 else -0.5
				break
	for distance in REACH:
		var next: Array[int] = []
		for k in ring:
			for side: int in [1, -1, columns, -columns, columns + 1, columns - 1, -columns + 1, -columns - 1]:
				var other := k + side
				if other < 0 or other >= wet.size() or seen[other] == 1:
					continue
				seen[other] = 1
				_shore[other] = (distance + 1.5) * (1.0 if wet[other] == 0 else -1.0)
				next.append(other)
		ring = next


## How steep the ground is at a point, in rise per metre.
func _slope(xz: Vector2) -> float:
	var east := height_at(xz + Vector2(0.5, 0.0)) - height_at(xz - Vector2(0.5, 0.0))
	var north := height_at(xz + Vector2(0.0, 0.5)) - height_at(xz - Vector2(0.0, 0.5))
	return Vector2(east, north).length()


## Which mass suits a point, or "" for none. `shore` is metres to the water.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	var bed := _beds.get_noise_2d(xz.x, xz.y)
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	var roll := rng.randf()
	if depth > 0.0:
		var flow := flow_at(xz).length()
		if flow < STILL and depth > 0.25 and depth < 3.2 and patch > -0.12 and roll < 0.55:
			var kind := rng.randf()
			return "lily_pads" if kind < 0.56 else ("lily_white" if kind < 0.8 else "lily_pink")
		if depth < 0.6 and bed > -0.1 and roll < 0.6:
			var kind := rng.randf()
			return "reeds_a" if kind < 0.42 else ("cattails" if kind < 0.72 else "reeds_b")
		# Where a river runs shallow, stones break the surface.
		if flow >= STILL and depth < 1.0 and roll < 0.22:
			return _any_stone()
		if depth < 0.5 and roll < 0.07:
			return _any_stone()
		return ""
	if shore < 1.6:
		if bed > 0.0 and roll < 0.62:
			var kind := rng.randf()
			return "reeds_b" if kind < 0.4 else ("cattails" if kind < 0.65 else ("sedge_b" if kind < 0.85 else "reeds_a"))
		if roll < 0.2:
			return _any_stone()
		if roll < 0.28:
			return "pebbles_patch"
		return "sedge_a" if roll < 0.48 else ""
	if shore < 4.5:
		if patch > 0.22 and roll < 0.2:
			return "blue_flag_iris"
		if patch < -0.2 and roll < 0.26:
			return "marsh_marigold"
		if roll < 0.3:
			return "sedge_a" if rng.randf() < 0.55 else "sedge_b"
		if roll < 0.38:
			return "waterside_fern"
		return "river_stone_b" if roll < 0.42 else ""
	# Thinning out up the bank.
	if roll > 0.13 * (1.0 - shore / REACH):
		return ""
	if patch < -0.12:
		return "waterside_fern"
	return "marsh_marigold" if patch > 0.28 else "sedge_a"


func _any_stone() -> String:
	var kind := rng.randf()
	return "river_stone_a" if kind < 0.45 else ("river_stone_b" if kind < 0.72 else "river_stone_c")


func _try_mass(xz: Vector2) -> void:
	if TerrainPaint.paving_at(xz) > 0.3:
		return
	var shore := _shore_at(xz)
	var ground := height_at(xz)
	var level := water_level_at(xz)
	var depth := level - ground if level != NO_WATER else -1.0
	var slug := _choose(xz, shore, depth)
	if slug.is_empty():
		return
	var room: float = ROOM[slug]
	if not fits(xz, room) or crowds_start(xz, room) or not is_clear(xz, room, 0.8):
		return
	var floats := slug.begins_with("lily")
	if not floats and _slope(xz) > STEEPEST:
		return
	var size := rng.randf_range(0.8, 1.25)
	var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.9, 1.15), size))
	var base := level + 0.015 if floats else ground - 0.03
	if not _copies.has(slug):
		_copies[slug] = []
		_copy_tints[slug] = PackedColorArray()
	(_copies[slug] as Array).append(Transform3D(basis, Vector3(xz.x, base, xz.y)))
	var shade := rng.randf_range(0.86, 1.1)
	var tints: PackedColorArray = _copy_tints[slug]
	tints.append(Color(shade, shade, shade))
	_copy_tints[slug] = tints
	claim(xz, room)


## Boulders where the shore is rocky, driftwood washed up at the waterline,
## stumps, shrubs and a few willows leaning over the banks.
func _place_props() -> void:
	var willows: Array[Vector2] = []
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed + 1, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for attempt in prop_tries:
			if placed >= 2:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			var shore := _shore_at(xz)
			if shore < -0.8 or shore > 7.5:
				continue
			var slug := _choose_prop(xz, shore, willows)
			if slug.is_empty():
				continue
			var room := PropLibrary.asset_room(PropLibrary.asset_scene(slug))
			# Turned and scaled up, a model reaches this much further.
			if not fits(xz, room * 1.7) or crowds_start(xz, room) or not is_clear(xz, room * 0.7, 0.9):
				continue
			if slug == "young_willow":
				willows.append(xz)
			var size := rng.randf_range(0.85, 1.2)
			var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, 0.5) - 0.05, xz.y))
			place_prop(PropLibrary.Kind.ASSET, 0, where, slug.begins_with("mossy") or slug == "driftwood_log" or slug == "young_willow", PropLibrary.asset_scene(slug))
			placed += 1


func _choose_prop(xz: Vector2, shore: float, willows: Array[Vector2]) -> String:
	if _slope(xz) > 0.8:
		return ""
	var patch := _patches.get_noise_2d(xz.x + 40.0, xz.y)
	var roll := rng.randf()
	if shore < 2.5 and patch < -0.15 and roll < 0.12:
		return "mossy_boulder_a" if rng.randf() < 0.6 else "mossy_boulder_b"
	if shore > -0.3 and shore < 2.0 and roll < 0.06:
		return "driftwood_log" if rng.randf() < 0.5 else "driftwood_branch"
	if shore > 1.5 and shore < 5.0 and roll < 0.05:
		for other in willows:
			if xz.distance_to(other) < willow_spacing:
				return "willow_shrub"
		return "young_willow"
	if shore > 2.0 and shore < 7.0 and roll < 0.07:
		return "willow_shrub" if patch > 0.0 else "mossy_stump"
	return ""
