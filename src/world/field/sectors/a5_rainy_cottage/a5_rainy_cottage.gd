@tool
extends SectorDesign
## Sector A5: a medieval cottage under a rain cloud. A half-timbered cottage
## with a thatched gable roof and a stone chimney; its door stands open
## toward the sector's start, its windows are shut with wooden shutters. A
## dark cloud hangs still above the sector and rains moderately; the rain
## stops on the roof and the ground, and the grass beneath is darker with
## wet. The brief is in docs/DESIGN_DECISIONS.md; sizes, colours and the
## rain's look are placeholders.

## The cottage's centre on the ground (world x, z); its long side runs
## east-west and its door faces south.
const COTTAGE := Vector2(5.0, -46.8)
## Half the cottage's size, east-west and north-south.
const HALF := Vector2(2.3, 1.7)
const DOOR_X := -0.6
const DOOR_SIZE := Vector2(0.9, 1.9)
const PLASTER := Color(0.88, 0.84, 0.74)
const TIMBER := Color(0.27, 0.18, 0.12)
const PLANKS := Color(0.46, 0.31, 0.19)
const THATCH := Color(0.66, 0.54, 0.32)
const STONE := Color(0.52, 0.5, 0.47)
const CLOUD_CENTRE := Vector3(5.0, 14.0, -45.0)

@export var wall_height: float = 2.4
@export var roof_rise: float = 1.9
## How far the door is swung open, in degrees.
@export var door_open_degrees: float = 75.0
## Raindrops falling at any moment.
@export var rain_amount: int = 1400
@export var rain_speed: float = 9.0
@export var grass: int = 1000

var _bumps: FastNoiseLite
var _floor := 0.0


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.2


## Gently uneven ground, levelled under the cottage.
func _ground(xz: Vector2) -> float:
	var land := 0.05 + 0.1 * _bumps.get_noise_2d(xz.x, xz.y)
	var pad := 1.0 - smoothstep(0.3, 1.5, _outside_cottage(xz))
	return lerpf(land, 0.08, pad)


## Rain-darkened grass under the cloud, and a trodden path to the door.
func _ground_tint(xz: Vector2) -> Color:
	var door := COTTAGE + Vector2(DOOR_X, HALF.y)
	var path_start := Vector2(5.0, -42.0)
	var along := clampf((xz - path_start).dot(door - path_start) / path_start.distance_squared_to(door), 0.0, 1.0)
	var path := xz.distance_to(path_start.lerp(door, along))
	if path < 0.8:
		return Color(0.5, 0.42, 0.31, smoothstep(0.35, 0.8, path))
	var wet := 1.0 - smoothstep(2.5, 4.2, xz.distance_to(Vector2(CLOUD_CENTRE.x, CLOUD_CENTRE.z)))
	return Color(0.2, 0.33, 0.15, 1.0 - 0.55 * wet)


func _populate() -> void:
	_floor = height_at(COTTAGE) + 0.05
	var batch := merged("Cottage", COTTAGE)
	_build_foundation(batch)
	_build_walls(batch)
	_build_timbers(batch)
	_build_shutters(batch)
	_build_door(batch)
	_build_roof(batch)
	_build_chimney(batch)
	claim(COTTAGE, HALF.x + 0.6)
	commit_merged("Cottage", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_build_cloud()
	_build_rain()
	_place_bushes()
	commit_merged("Bushes", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_place_grass()


## Signed distance from the cottage's footprint: negative inside.
func _outside_cottage(xz: Vector2) -> float:
	var q := (xz - COTTAGE).abs() - HALF
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


## A point relative to the cottage's centre, `y` above its floor.
func _local(x: float, y: float, z: float) -> Vector3:
	return Vector3(COTTAGE.x + x, _floor + y, COTTAGE.y + z)


func _box(batch: NatureKit.Batch, centre: Vector3, size: Vector3, color: Color, basis: Basis = Basis()) -> void:
	batch.add(MeshKit.triangles(MeshKit.box(size)), Transform3D(basis, centre), color)


func _solid(centre: Vector3, size: Vector3, basis: Basis = Basis()) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	add_collider(shape, Transform3D(basis, centre))


func _build_foundation(batch: NatureKit.Batch) -> void:
	_box(batch, _local(0.0, -0.15, 0.0), Vector3(HALF.x * 2.0 + 0.2, 0.4, HALF.y * 2.0 + 0.2), STONE)
	_box(batch, _local(0.0, 0.06, 0.0), Vector3(HALF.x * 2.0 - 0.3, 0.04, HALF.y * 2.0 - 0.3), PLANKS * 0.8)
	_solid(_local(0.0, -0.15, 0.0), Vector3(HALF.x * 2.0 + 0.2, 0.4, HALF.y * 2.0 + 0.2))


## Plastered walls 0.2 m thick, the south one split around the doorway, and
## gables up to the ridge at the east and west ends.
func _build_walls(batch: NatureKit.Batch) -> void:
	var t := 0.2
	var h := wall_height
	var length := HALF.x * 2.0
	var pieces: Array[Array] = [
		[_local(0.0, h * 0.5, -HALF.y + t * 0.5), Vector3(length, h, t)],
		[_local(-HALF.x + t * 0.5, h * 0.5, 0.0), Vector3(t, h, HALF.y * 2.0 - 2.0 * t)],
		[_local(HALF.x - t * 0.5, h * 0.5, 0.0), Vector3(t, h, HALF.y * 2.0 - 2.0 * t)],
	]
	var door_left := DOOR_X - DOOR_SIZE.x * 0.5
	var door_right := DOOR_X + DOOR_SIZE.x * 0.5
	var west_width := door_left + HALF.x
	var east_width := HALF.x - door_right
	pieces.append([_local(-HALF.x + west_width * 0.5, h * 0.5, HALF.y - t * 0.5), Vector3(west_width, h, t)])
	pieces.append([_local(door_right + east_width * 0.5, h * 0.5, HALF.y - t * 0.5), Vector3(east_width, h, t)])
	pieces.append([_local(DOOR_X, (h + DOOR_SIZE.y) * 0.5, HALF.y - t * 0.5), Vector3(DOOR_SIZE.x, h - DOOR_SIZE.y, t)])
	for piece in pieces:
		var centre: Vector3 = piece[0]
		var size: Vector3 = piece[1]
		_box(batch, centre, size, PLASTER)
		_solid(centre, size)
	# A dim interior seen through the open door, under a plank ceiling.
	_box(batch, _local(0.0, h * 0.5, -HALF.y + t + 0.01), Vector3(length - 2.0 * t, h, 0.02), PLASTER * 0.45)
	_box(batch, _local(0.0, h - 0.06, 0.0), Vector3(length - 2.0 * t, 0.12, HALF.y * 2.0 - 2.0 * t), PLANKS * 0.45)
	for side: float in [-1.0, 1.0]:
		var gable := PackedVector3Array([
			_local(side * HALF.x, h, -HALF.y), _local(side * HALF.x, h, HALF.y), _local(side * HALF.x, h + roof_rise, 0.0),
		])
		batch.add(gable, Transform3D(), PLASTER)
		gable.reverse()
		batch.add(gable, Transform3D(), PLASTER * 0.5)


## Dark oak framing on the outside: corner posts, sill and top beams, and
## braces on the long walls.
func _build_timbers(batch: NatureKit.Batch) -> void:
	var w := 0.14
	var h := wall_height
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(batch, _local(sx * (HALF.x + 0.01), h * 0.5, sz * (HALF.y + 0.01)), Vector3(w + 0.04, h, w + 0.04), TIMBER)
	for sz: float in [-1.0, 1.0]:
		for y: float in [0.12, h - 0.08]:
			_box(batch, _local(0.0, y, sz * (HALF.y + 0.03)), Vector3(HALF.x * 2.0, w, 0.06), TIMBER)
	for sx: float in [-1.0, 1.0]:
		for y: float in [0.12, h - 0.08]:
			_box(batch, _local(sx * (HALF.x + 0.03), y, 0.0), Vector3(0.06, w, HALF.y * 2.0), TIMBER)
	# Braces on the north wall and beside the door.
	var brace := Vector3(0.1, 1.9, 0.06)
	for x: float in [-1.4, 1.4]:
		var tilt := Basis(Vector3.BACK, 0.55 if x < 0.0 else -0.55)
		_box(batch, _local(x, h * 0.5, -HALF.y - 0.03), brace, TIMBER, tilt)
	_box(batch, _local(1.75, h * 0.5, HALF.y + 0.03), brace, TIMBER, Basis(Vector3.BACK, -0.45))
	# The door frame.
	for x: float in [DOOR_X - DOOR_SIZE.x * 0.5 - 0.05, DOOR_X + DOOR_SIZE.x * 0.5 + 0.05]:
		_box(batch, _local(x, DOOR_SIZE.y * 0.5, HALF.y + 0.03), Vector3(0.1, DOOR_SIZE.y, 0.08), TIMBER)
	_box(batch, _local(DOOR_X, DOOR_SIZE.y + 0.05, HALF.y + 0.03), Vector3(DOOR_SIZE.x + 0.2, 0.12, 0.08), TIMBER)


## Windows closed with two plank shutters each, in a timber frame, with iron
## strap hinges.
func _build_shutters(batch: NatureKit.Batch) -> void:
	var windows: Array[Array] = [
		[Vector3(0.9, 1.35, HALF.y + 0.05), 0.0],
		[Vector3(-1.0, 1.35, -HALF.y - 0.05), PI],
		[Vector3(1.0, 1.35, -HALF.y - 0.05), PI],
		[Vector3(HALF.x + 0.05, 1.35, 0.0), PI * 0.5],
		[Vector3(-HALF.x - 0.05, 1.35, 0.0), -PI * 0.5],
	]
	for window in windows:
		var spot: Vector3 = window[0]
		var facing := Basis(Vector3.UP, float(window[1]))
		var centre := _local(spot.x, spot.y, spot.z)
		_box(batch, centre, Vector3(0.86, 0.8, 0.05), TIMBER, facing)
		for side: float in [-1.0, 1.0]:
			var leaf_centre := centre + facing * Vector3(side * 0.18, 0.0, 0.03)
			_box(batch, leaf_centre, Vector3(0.34, 0.68, 0.04), PLANKS * rng.randf_range(0.9, 1.08), facing)
			for y: float in [-0.2, 0.2]:
				_box(batch, leaf_centre + facing * Vector3(side * 0.04, y, 0.025), Vector3(0.26, 0.04, 0.01), Color(0.18, 0.18, 0.19), facing)
		_box(batch, centre + facing * Vector3(0.0, 0.0, 0.055), Vector3(0.02, 0.68, 0.01), TIMBER * 0.7, facing)


## A plank door hung on its west post, swung open outward.
func _build_door(batch: NatureKit.Batch) -> void:
	var hinge := _local(DOOR_X - DOOR_SIZE.x * 0.5, 0.0, HALF.y + 0.04)
	var swing := Basis(Vector3.UP, -deg_to_rad(door_open_degrees))
	var leaf := Vector3(DOOR_SIZE.x - 0.04, DOOR_SIZE.y - 0.04, 0.06)
	var centre := hinge + swing * Vector3(leaf.x * 0.5, leaf.y * 0.5 + 0.02, 0.0)
	_box(batch, centre, leaf, PLANKS * 0.92, swing)
	for y: float in [0.35, 1.5]:
		_box(batch, centre + swing * Vector3(0.0, y - leaf.y * 0.5, 0.04), Vector3(leaf.x - 0.1, 0.06, 0.015), Color(0.18, 0.18, 0.19), swing)
	_box(batch, centre + swing * Vector3(leaf.x * 0.3, 0.0, 0.05), Vector3(0.05, 0.05, 0.04), Color(0.2, 0.2, 0.2), swing)
	_solid(centre, leaf, swing)


## A steep thatched gable roof overhanging the walls, with a ridge cap.
func _build_roof(batch: NatureKit.Batch) -> void:
	var overhang := 0.35
	var run := HALF.y + overhang
	var slope := atan2(roof_rise, HALF.y)
	var length := run / cos(slope)
	var thickness := 0.28
	for side: float in [-1.0, 1.0]:
		var tilt := Basis(Vector3.RIGHT, side * slope)
		var centre := _local(0.0, wall_height + roof_rise - (run * 0.5) * tan(slope) + thickness * 0.4, side * run * 0.5)
		_box(batch, centre, Vector3(HALF.x * 2.0 + overhang * 2.0, thickness, length), THATCH * (0.95 if side > 0.0 else 1.04), tilt)
	_box(batch, _local(0.0, wall_height + roof_rise + 0.12, 0.0), Vector3(HALF.x * 2.0 + overhang * 2.0 + 0.05, 0.22, 0.4), THATCH * 0.8, Basis(Vector3.RIGHT, PI * 0.25))


## A stone chimney rising through the east end of the roof.
func _build_chimney(batch: NatureKit.Batch) -> void:
	var height := wall_height + roof_rise + 0.7
	_box(batch, _local(HALF.x - 0.55, height * 0.5, -0.45), Vector3(0.6, height, 0.6), STONE)
	_box(batch, _local(HALF.x - 0.55, height + 0.06, -0.45), Vector3(0.7, 0.12, 0.7), STONE * 0.85)


## A heavy grey cloud of lumps hanging still above the sector.
func _build_cloud() -> void:
	var batch := NatureKit.Batch.new()
	for k in 9:
		var radius := rng.randf_range(1.4, 2.3)
		var offset := Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(-0.4, 0.6), rng.randf_range(-1.8, 1.8))
		var grey := rng.randf_range(0.42, 0.55)
		batch.add(NatureKit.lumpy_sphere(rng, radius, 0.2, 8, 5), Transform3D(Basis().scaled(Vector3(1.0, 0.6, 1.0)), CLOUD_CENTRE + offset), Color(grey, grey, grey * 1.04))
	add_mesh("RainCloud", batch.commit(), MeshKit.lowpoly_material(Color.WHITE, 1.0))


## Streaks of rain falling from under the cloud. They stop where they meet
## the roof or the ground, which a heightfield over the sector records.
func _build_rain() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(3.6, 0.2, 3.2)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 2.0
	process.initial_velocity_min = rain_speed * 0.9
	process.initial_velocity_max = rain_speed * 1.1
	process.gravity = Vector3.ZERO
	process.particle_flag_align_y = true
	process.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.78, 0.84, 0.92, 0.45)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale = true
	material.use_particle_trails = false
	var streak := QuadMesh.new()
	streak.size = Vector2(0.015, 0.45)
	streak.material = material
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = rain_amount
	rain.lifetime = (CLOUD_CENTRE.y - 1.0) / rain_speed
	rain.preprocess = rain.lifetime
	rain.process_material = process
	rain.draw_pass_1 = streak
	rain.position = CLOUD_CENTRE - Vector3(0.0, 1.0, 0.0)
	rain.visibility_aabb = AABB(Vector3(-4.0, -CLOUD_CENTRE.y, -4.0), Vector3(8.0, CLOUD_CENTRE.y + 1.0, 8.0))
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)
	var catcher := GPUParticlesCollisionHeightField3D.new()
	catcher.name = "RainCatcher"
	catcher.size = Vector3(9.0, 12.0, 9.0)
	catcher.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_256
	catcher.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_WHEN_MOVED
	catcher.position = Vector3(CLOUD_CENTRE.x, 5.0, CLOUD_CENTRE.z)
	add_child(catcher)


func _place_bushes() -> void:
	var placed := 0
	for attempt in 60:
		if placed >= 6:
			return
		var xz := random_point()
		var size := rng.randf_range(0.5, 0.85)
		var radius := size * 0.75
		if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius) or _outside_cottage(xz) < 0.6:
			continue
		NatureKit.add_bush(merged("Bushes", xz), rng, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), surface(xz) - Vector3(0.0, 0.04, 0.0)))
		claim(xz, radius)
		placed += 1


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if _outside_cottage(xz) < 0.3 or _ground_tint(xz).a < 0.4 or not fits(xz, 0.25) or not is_clear(xz, 0.0, 0.6):
			continue
		var size := rng.randf_range(0.8, 1.2)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
		var shade := rng.randf_range(0.8, 1.0)
		colors.append(Color(shade * 0.9, shade, shade * 0.9))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
