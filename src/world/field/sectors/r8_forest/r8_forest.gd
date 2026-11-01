@tool
class_name R8Forest
extends "res://src/world/field/sectors/r1_roadside/r1_roadside.gd"
## R8's old forest, from the author's painted way west of the orchard up to the western
## cliff, and the half abandoned camp where the way ends in R2 and R3. The forest's body is
## masses worked out from the land, so it follows the land when it's sculpted again: stands
## of spruce, then hornbeam and ash, with young firs in the gaps and a dead pine here and
## there. Rocks, crags, fallen trunks, big trees beside the way and the camp are props to
## move by hand. A block of sectors per design, so they stream. The brief is in
## docs/DESIGN_DECISIONS.md; the layout is placeholder.

## Metres a tree's crown may reach past the block, over its neighbour.
const CROWN_REACH := 6.0
## For each tree of the body: its sway (metres aside at one metre up, growing with the
## square of the height, so very little), and its collider's radius.
const FOREST_TREES: Dictionary[String, Array] = {
	"forest_spruce_a": [0.0005, 0.42],
	"forest_spruce_b": [0.0003, 0.56],
	"young_fir": [0.003, 0.0],
	"forest_hornbeam": [0.0008, 0.42],
	"forest_ash": [0.0005, 0.44],
	"dead_pine": [0.0, 0.34],
	"tall_pine": [0.0004, 0.4],
	"tall_beech": [0.0006, 0.4],
	"white_birch": [0.001, 0.2],
	"field_maple": [0.0008, 0.36],
}
## From how far the body's trees show.
const TREE_DISTANCE := 230.0
## Metres between the places a tree is tried, and the most it's moved off them, as a share.
const TREE_STEP := 5.0
const TREE_JITTER := 0.44
## Metres a trunk keeps from the way, and ground lower than this is the cliff's.
const WAY_CLEAR := 2.6
const RIM_LEVEL := -2.5
## Rise per metre above which nothing tall stands.
const TREE_STEEPEST := 1.0
## x (east) where the forest starts thinning out toward the orchard, and where it's gone.
const THIN_EAST := -14.0
const GONE_EAST := 0.0
## Metres north where it starts thinning, and where it's gone.
const THIN_NORTH := 92.0
const GONE_NORTH := 120.0

## The middle of the camp's clearing, and the metres it keeps free of trees. The camp keeps
## to the flattest ground beside where the way ends.
const CAMP := Vector2(-25.6, 18.5)
const CAMP_CLEARING := 9.5
const FIRE := Vector2(-25.6, 16.0)
## The camp: a design, its place (x east, y north), and whether it turns to the fire. A
## number is a turn of its own, in radians.
const CAMP_THINGS: Array[Array] = [
	["campfire", FIRE, 0.4],
	["cook_tripod", FIRE, 1.1],
	["log_seat", Vector2(-25.7, 17.8), true],
	["log_seat", Vector2(-27.5, 16.5), true],
	["camp_tent", Vector2(-25.3, 24.4), true],
	["bedroll", Vector2(-23.2, 24.9), 0.5],
	["camp_tent_torn", Vector2(-21.5, 20.9), 2.2],
	["drying_rack", Vector2(-29.0, 20.7), true],
	["camp_crates", Vector2(-22.7, 19.3), 0.7],
	["camp_barrel", Vector2(-23.8, 19.5), 0.0],
	["firewood_pile", Vector2(-23.6, 18.1), 2.5],
]
## How often a sector gets each prop, and how many places it's tried at.
const ROCK_TRIES := 7
const WAY_TREE_CHANCE := 0.28
const FALLEN_CHANCE := 0.14
const CRAG_CHANCE := 0.45

var _stands: FastNoiseLite
var _gaps: FastNoiseLite


func _init() -> void:
	overhang = CROWN_REACH
	mass_tries = 380


func _setup() -> void:
	super()
	_stands = FastNoiseLite.new()
	_stands.seed = 83
	_stands.frequency = 0.022
	_gaps = FastNoiseLite.new()
	_gaps.seed = 84
	_gaps.frequency = 0.06


## Nobody starts in the forest, so its trees needn't leave each sector's start point open.
func crowds_start(_xz: Vector2, _radius: float) -> bool:
	return false


func _before_masses() -> void:
	_plant_forest()


func _tree_step() -> float:
	return TREE_STEP


## How much of the forest stands at a point, 0 to 1.
func _thickness(xz: Vector2) -> float:
	var east := 1.0 - smoothstep(THIN_EAST, GONE_EAST, xz.x)
	var north := 1.0 - smoothstep(THIN_NORTH, GONE_NORTH, -xz.y)
	return east * north


func _from_camp(xz: Vector2) -> float:
	return xz.distance_to(_world(CAMP))


## True where something tall can stand.
func _tree_ground(xz: Vector2) -> bool:
	return height_at(xz) > RIM_LEVEL and _slope(xz) < TREE_STEEPEST and _shore_at(xz) > 2.5 and _from_road(xz) > WAY_CLEAR and _from_camp(xz) > CAMP_CLEARING


## Which tree suits a place: spruces in the west and the high ground, broad trees in the
## east and the hollows, each kind in stands of its own.
func _tree_at(xz: Vector2) -> String:
	var stand := _stands.get_noise_2d(xz.x, xz.y) + (-xz.x - 40.0) * 0.012
	var roll := rng.randf()
	if roll < 0.035:
		return "dead_pine"
	if roll < 0.2:
		return "young_fir"
	if stand > 0.05:
		return "forest_spruce_b" if roll < 0.32 else ("tall_pine" if roll < 0.42 else "forest_spruce_a")
	if stand < -0.12:
		return "forest_ash" if roll < 0.55 else ("tall_beech" if roll < 0.68 else "forest_hornbeam")
	return "forest_hornbeam" if roll < 0.45 else ("forest_spruce_a" if roll < 0.8 else "forest_ash")


## The forest's body: a tree tried at each place of a loose grid, one MultiMesh per kind
## per sector, each with a collider at its foot.
func _plant_forest() -> void:
	var transforms: Dictionary[String, Array] = {}
	var tints: Dictionary[String, PackedColorArray] = {}
	var trunks := []
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		var step := _tree_step()
		var across := int(SectorMap.SIZE / step)
		for j in across:
			for i in across:
				rng.seed = hash(Vector4i(design_seed, cell.x * across + i, cell.y * across + j, 7))
				var xz := Vector2(corner.x + (i + 0.5) * step, corner.z - (j + 0.5) * step)
				var jitter := step * TREE_JITTER
				xz += Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
				var thick := _thickness(xz) * (0.84 if _gaps.get_noise_2d(xz.x, xz.y) > -0.18 else 0.28)
				if rng.randf() > thick or not _tree_ground(xz) or crowds_start(xz, 1.0) or not is_clear(xz, 1.0, 0.9):
					continue
				var slug := _tree_at(xz)
				var size := rng.randf_range(0.82, 1.18)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.92, 1.12), size))
				if not transforms.has(slug):
					transforms[slug] = []
					tints[slug] = PackedColorArray()
				var foot := Vector3(xz.x, lowest_ground(xz, TREE_FOOT) - 0.05, xz.y)
				(transforms[slug] as Array).append(Transform3D(basis, foot))
				var shade := rng.randf_range(0.82, 1.08)
				var tint: PackedColorArray = tints[slug]
				tint.append(Color(shade, shade, shade))
				tints[slug] = tint
				claim(xz, 1.0)
				var radius: float = FOREST_TREES[slug][1]
				if radius > 0.0:
					trunks.append([foot, radius * size])
	for slug: String in transforms:
		var placed: Array[Transform3D] = []
		placed.assign(transforms[slug])
		add_multimesh(slug.to_pascal_case(), PropLibrary.mass_mesh(slug, FOREST_TREES[slug][0], 0.0), null, placed, tints[slug], TREE_DISTANCE)
	for trunk: Array in trunks:
		var shape := CylinderShape3D.new()
		shape.radius = trunk[1]
		shape.height = 5.0
		add_collider(shape, Transform3D(Basis.IDENTITY, (trunk[0] as Vector3) + Vector3.UP * 2.5))


## What grows at a point: the waterside's by the water, verge grass along the way, bare
## trodden ground in the camp, and bracken, leaves, moss and stones under the trees.
func _choose(xz: Vector2, shore: float, depth: float) -> String:
	if depth > 0.0 or shore < WATER_PLANTS:
		return super(xz, shore, depth)
	var roll := rng.randf()
	if _from_camp(xz) < CAMP_CLEARING * 0.7:
		if roll < 0.02:
			return "fallen_twigs"
		return "meadow_grass_a" if roll < 0.05 else ""
	var away := _from_road(xz)
	var thick := _thickness(xz)
	if away < VERGE:
		if roll < 0.2:
			return "meadow_grass_a" if rng.randf() < 0.6 else "meadow_grass_b"
		return _any_stone() if roll < 0.24 else ""
	if rng.randf() > thick + 0.08:
		return "meadow_grass_a" if roll < 0.12 else ""
	var patch := _patches.get_noise_2d(xz.x, xz.y)
	if roll < 0.34:
		return "leaf_litter"
	if patch > 0.02:
		if roll < 0.56:
			return "bracken"
		return "waterside_fern" if roll < 0.62 else ("fallen_twigs" if roll < 0.68 else "")
	if patch < -0.18 and roll < 0.48:
		return "moss_patch"
	if roll < 0.52:
		return "fallen_twigs"
	if roll < 0.56:
		return "forest_mushrooms"
	if roll < 0.6:
		return _any_stone()
	return "meadow_grass_a" if roll < 0.66 else ""


func _place_props() -> void:
	for thing in CAMP_THINGS:
		_place_camp_thing(thing[0], thing[1], thing[2])
	for cell in cells():
		_place_wood_props(cell)


func _place_camp_thing(slug: String, at: Vector2, turn: Variant) -> void:
	var xz := _world(at)
	if not owns(xz):
		return
	var toward := _world(FIRE) - xz
	# A model's front is its +Z here.
	var angle: float = atan2(toward.x, toward.y) if turn is bool else turn
	# It lies with the slope, as something set down on it would.
	var east := height_at(xz + Vector2(0.6, 0.0)) - height_at(xz - Vector2(0.6, 0.0))
	var north := height_at(xz + Vector2(0.0, 0.6)) - height_at(xz - Vector2(0.0, 0.6))
	var up := Vector3(-east, 1.2, -north).normalized()
	var tilt := Basis(Quaternion(Vector3.UP, up))
	_place_forest(slug, Transform3D(tilt * Basis(Vector3.UP, angle), Vector3(xz.x, height_at(xz) - 0.02, xz.y)))


## Rocks, a crag near the cliff, a fallen trunk and a big tree beside the way, in a sector.
func _place_wood_props(cell: Vector2i) -> void:
	rng.seed = hash(Vector3i(design_seed + 5, cell.x, cell.y))
	var corner := SectorMap.corner_of(cell)
	for attempt in ROCK_TRIES:
		var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
		var slug := _wood_prop_at(xz)
		if slug.is_empty():
			continue
		if not _prop_ground(xz, slug):
			continue
		var size := rng.randf_range(0.85, 1.2)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
		_place_forest(slug, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.8) - 0.08, xz.y)))
		break


func _wood_prop_at(xz: Vector2) -> String:
	var away := _from_road(xz)
	var roll := rng.randf()
	if _near_rim(xz):
		if roll < CRAG_CHANCE:
			return "forest_crag"
		return "forest_rock_a" if roll < 0.55 else "forest_rock_b"
	if away > 3.0 and away < 8.0 and roll < WAY_TREE_CHANCE and _thickness(xz) > 0.2:
		var kind := rng.randf()
		return "big_oak" if kind < 0.3 else ("forest_spruce_b" if kind < 0.65 else "forest_ash")
	if _thickness(xz) < 0.2:
		return ""
	if roll < FALLEN_CHANCE:
		return "fallen_trunk"
	if roll < 0.32:
		return "forest_rock_a"
	if roll < 0.42:
		return "forest_rock_b"
	if roll < 0.5:
		return "mossy_boulder_a"
	return "mossy_stump" if roll < 0.56 else ""


## True within a few metres of the drop to the west.
func _near_rim(xz: Vector2) -> bool:
	return height_at(xz) > RIM_LEVEL and height_at(xz + Vector2(-9.0, 0.0)) < RIM_LEVEL - 1.0


func _prop_ground(xz: Vector2, slug: String) -> bool:
	var room := PropLibrary.asset_room(PropLibrary.asset_scene(slug))
	var foot: float = PropLibrary.FEET.get(slug, room)
	if height_at(xz) < RIM_LEVEL or _slope(xz) > 0.75 or _shore_at(xz) < 3.0 or _from_camp(xz) < CAMP_CLEARING + room:
		return false
	return _from_road(xz) > minf(room, 2.5) + 0.5 and not crowds_start(xz, foot) and is_clear(xz, foot, 0.9)


func _place_forest(slug: String, where: Transform3D) -> void:
	var solid := slug not in ["campfire", "cook_tripod", "bedroll"]
	place_prop(PropLibrary.Kind.ASSET, 0, where, solid, PropLibrary.asset_scene(slug))
