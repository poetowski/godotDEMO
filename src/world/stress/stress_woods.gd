@tool
extends SectorDesign
## Stress test: one sector of woodland on rolling hills. Trees, pines,
## bushes, rocks, grass and mushrooms to collect, thick where a world-wide noise says forest and
## thin in its clearings, so neighbouring sectors read as one wood. Every
## sector of the stress world is one of these, so streaming works exactly as
## it would in a fully built world. Not game content.

@export var max_trees: int = 9
@export var bushes: int = 6
@export var rocks: int = 4
@export var grass: int = 900
## At most this many mushrooms per sector, fewer in clearings.
@export var mushrooms: int = 3

const MUSHROOMS: Array[ItemData] = [
	preload("res://data/items/penny_bun.tres"),
	preload("res://data/items/fly_agaric.tres"),
	preload("res://data/items/chanterelle.tres"),
]

var _bumps: FastNoiseLite
var _forest: FastNoiseLite


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = 11
	_bumps.frequency = 0.15
	_forest = FastNoiseLite.new()
	_forest.seed = 23
	_forest.frequency = 0.025


## Small bumps on top of the world's hills.
func _ground(xz: Vector2) -> float:
	return 0.15 * _bumps.get_noise_2d(xz.x, xz.y)


func _populate() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 3:
		shapes.append(NatureKit.rock_shape(rng))
	var placed := 0
	for attempt in max_trees * 4:
		if placed >= max_trees:
			break
		var xz := random_point()
		if rng.randf() > _woodland(xz) or not fits(xz, 1.4) or crowds_start(xz, 1.2) or not is_clear(xz, 1.4):
			continue
		var foot := Vector3(xz.x, lowest_ground(xz, 0.3) - 0.1, xz.y)
		var height := rng.randf_range(3.0, 6.5)
		if rng.randf() < 0.45:
			NatureKit.add_pine(merged("Trees", xz), rng, foot, height * 1.5)
		else:
			NatureKit.add_round_tree(merged("Trees", xz), rng, foot, height)
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.2
		trunk.height = height
		add_collider(trunk, Transform3D(Basis(), foot + Vector3.UP * height * 0.5))
		claim(xz, 1.4)
		placed += 1
	commit_merged("Trees", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	for k in bushes + rocks:
		var xz := random_point()
		var size := rng.randf_range(0.45, 0.85)
		if not fits(xz, size) or crowds_start(xz, size) or not is_clear(xz, size * 0.75):
			continue
		var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), surface(xz) - Vector3.UP * 0.05)
		if k < bushes:
			NatureKit.add_bush(merged("Bushes", xz), rng, where)
		else:
			merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where.scaled_local(Vector3.ONE * 0.6), NatureKit.rock_color(rng))
		claim(xz, size * 0.75)
	commit_merged("Bushes", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_mushrooms()
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if not fits(xz, 0.25) or not is_clear(xz, 0.0, 0.6):
			continue
		var size := rng.randf_range(0.8, 1.2)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size, size)), surface(xz) - Vector3.UP * 0.02))
		var shade := rng.randf_range(0.88, 1.08)
		colors.append(Color(shade, shade, shade))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)


## Mushrooms the player can pick up, mostly where the wood is thick. Each
## is remembered in WorldState once taken.
func _place_mushrooms() -> void:
	var placed := 0
	for attempt in mushrooms * 6:
		if placed >= mushrooms:
			break
		var xz := random_point()
		if rng.randf() > _woodland(xz) * 0.8 or not fits(xz, 0.3) or not is_clear(xz, 0.3):
			continue
		var pickup := ItemPickup.new()
		pickup.name = "Mushroom%d" % placed
		pickup.item = MUSHROOMS[rng.randi() % MUSHROOMS.size()]
		pickup.reach = 1.2
		pickup.position = surface(xz) - Vector3.UP * 0.01
		pickup.rotation.y = rng.randf() * TAU
		pickup.persist_id = content_id(pickup.name)
		add_content(pickup)
		# Room in the grass so it can be spotted.
		claim(xz, 0.6)
		placed += 1


## How likely a tree is here: thick in the woods, sparse in clearings.
func _woodland(xz: Vector2) -> float:
	return clampf(0.2 + 1.2 * _forest.get_noise_2d(xz.x, xz.y) + 0.4, 0.1, 1.0)
