@tool
extends SectorDesign
## Sector B1: a small sunny meadow of white and yellow wildflowers, and in it
## one cornflower the player can pick up, glinting so it can be found. The
## brief is in docs/DESIGN_DECISIONS.md; the meadow and the flower's place
## are placeholders.

const CORNFLOWER := preload("res://data/items/cornflower.tres")
## Where the cornflower grows (world x, z): a few steps ahead of the start.
const FLOWER_AT := Vector2(16.2, -6.2)
const PETAL_COLORS: Array[Color] = [Color(0.98, 0.97, 0.94), Color(0.98, 0.86, 0.3), Color(0.96, 0.92, 0.98)]

@export var wildflowers: int = 160
@export var grass: int = 1100

var _bumps: FastNoiseLite


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.17
	_bumps.fractal_octaves = 2


func _ground(xz: Vector2) -> float:
	return 0.06 + 0.12 * _bumps.get_noise_2d(xz.x, xz.y)


func _populate() -> void:
	var pickup := ItemPickup.new()
	pickup.name = "Cornflower"
	pickup.item = CORNFLOWER
	pickup.position = surface(FLOWER_AT) - Vector3.UP * 0.02
	pickup.persist_id = content_id(pickup.name)
	add_content(pickup)
	claim(FLOWER_AT, 0.5)
	_place_wildflowers()
	_place_grass()


## Daisies and buttercups dotted over the meadow, leaving room around the
## cornflower so it stands out.
func _place_wildflowers() -> void:
	var meshes: Array[ArrayMesh] = []
	for color in PETAL_COLORS:
		meshes.append(_wildflower_mesh(color))
	var places: Array[Array] = [[], [], []]
	var colors: Array[PackedColorArray] = [PackedColorArray(), PackedColorArray(), PackedColorArray()]
	for k in wildflowers * 2:
		var xz := random_point()
		if xz.distance_to(FLOWER_AT) < 1.2 or not fits(xz, 0.15):
			continue
		var kind := rng.randi() % meshes.size()
		var size := rng.randf_range(0.8, 1.2)
		places[kind].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), surface(xz) - Vector3.UP * 0.02))
		colors[kind].append(Color.WHITE)
		if places[0].size() + places[1].size() + places[2].size() >= wildflowers:
			break
	var material := MeshKit.lowpoly_material(Color.WHITE, 0.8)
	for kind in meshes.size():
		var placed: Array[Transform3D] = []
		placed.assign(places[kind])
		add_multimesh("Wildflowers%d" % kind, meshes[kind], material, placed, colors[kind], 40.0)


## A small flower on a short stem: a ring of petals around a golden eye.
func _wildflower_mesh(petal: Color) -> ArrayMesh:
	var batch := NatureKit.Batch.new()
	var height := 0.22
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.004, 0.005, height, 4)), Transform3D(Basis(), Vector3.UP * height * 0.5), Color(0.32, 0.5, 0.24))
	var top := Vector3.UP * height
	var petals := 8
	for p in petals:
		var angle := TAU * p / petals
		var out := Vector3(cos(angle), 0.12, sin(angle)) * 0.04
		var across := Vector3(-sin(angle), 0.0, cos(angle)) * 0.011
		var triangle := PackedVector3Array([top, top + out * 0.6 + across, top + out, top, top + out, top + out * 0.6 - across])
		batch.add(triangle, Transform3D(), petal)
		triangle.reverse()
		batch.add(triangle, Transform3D(), petal * 0.85)
	batch.add(MeshKit.triangles(MeshKit.sphere(0.011, 6, 4)), Transform3D(Basis(), top + Vector3.UP * 0.006), Color(0.95, 0.72, 0.15))
	return batch.commit()


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if xz.distance_to(FLOWER_AT) < 0.9 or not fits(xz, 0.25) or not is_clear(xz, 0.0, 0.6):
			continue
		var size := rng.randf_range(0.7, 1.1)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
		var shade := rng.randf_range(0.9, 1.1)
		colors.append(Color(shade, shade, shade * 0.95))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
