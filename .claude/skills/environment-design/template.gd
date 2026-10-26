@tool
extends SectorDesign
## Sectors <list>: <one or two sentences on what the place is>. The brief is
## in docs/DESIGN_DECISIONS.md; <what is placeholder>.
##
## Template for /environment-design. Copy to
## src/world/field/sectors/<slug>/<slug>.gd, rename nothing in the hooks, and
## delete what the brief doesn't need.

## How far the ground rises and dips, in metres.
@export var bumpiness: float = 0.3
@export var rocks_per_sector: int = 8
@export var grass_per_sector: int = 900

var _bumps: FastNoiseLite


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.15
	_bumps.fractal_octaves = 3


## Height before the base eases it to 0 at edges with sectors not owned.
func _ground(xz: Vector2) -> float:
	return 0.08 + bumpiness * _bumps.get_noise_2d(xz.x, xz.y)


## Water surface height where there is water, otherwise NO_WATER.
func _water_level(_xz: Vector2) -> float:
	return NO_WATER


## Metres per second along world x and z, for the water shader.
func _flow(_xz: Vector2) -> Vector2:
	return Vector2.ZERO


## GRASS, or a colour (sRGB) whose alpha says how much grass still shows.
func _ground_tint(_xz: Vector2) -> Color:
	return GRASS


func _populate() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 5:
		shapes.append(NatureKit.rock_shape(rng))
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for attempt in rocks_per_sector * 3:
			if placed >= rocks_per_sector:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if _try_rock(shapes, xz, lerpf(0.15, 0.6, pow(rng.randf(), 2.0))):
				placed += 1
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_grass()


func _try_rock(shapes: Array[PackedVector3Array], xz: Vector2, size: float) -> bool:
	var radius := size * 0.62
	if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius) or not is_dry(xz, 0.05):
		return false
	var base := lowest_ground(xz, radius * 0.7) - 0.08 * size
	var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, base, xz.y))
	merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where, NatureKit.rock_color(rng))
	claim(xz, radius)
	if size >= 0.45:
		var shape := SphereShape3D.new()
		shape.radius = size * 0.38
		add_collider(shape, Transform3D(Basis(), Vector3(xz.x, base + size * 0.12, xz.y)))
	return true


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		for k in grass_per_sector:
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if not is_clear(xz, 0.0, 0.6) or not fits(xz, 0.25) or not is_dry(xz, 0.08):
				continue
			var size := rng.randf_range(0.8, 1.2)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size))
			transforms.append(Transform3D(basis, Vector3(xz.x, height_at(xz) - 0.02, xz.y)))
			var shade := rng.randf_range(0.88, 1.08)
			colors.append(Color(shade, shade, shade))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
