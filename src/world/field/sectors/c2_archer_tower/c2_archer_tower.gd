@tool
extends SectorDesign
## Sector C2: a round archer tower of stone bricks, with arrow slits, a
## doorway facing the start, and a staircase spiralling up its outside to an
## open battlement. A big pine stands in the north-west corner, and bushes,
## ferns and grass grow around. The brief is in docs/DESIGN_DECISIONS.md; the
## sizes, colours and layout are placeholders.

## The tower's centre on the ground (world x, z).
const TOWER := Vector2(24.0, -16.6)
## The pine's foot (world x, z).
const PINE := Vector2(21.9, -11.9)
## Angle (radians, from +x toward +z, south) of the doorway: toward the start.
const DOOR_ANGLE := PI * 0.5
const BRICK := Vector3(0.5, 0.28, 0.36)
const STONE_COLORS: Array[Color] = [Color(0.62, 0.58, 0.52), Color(0.55, 0.52, 0.48), Color(0.68, 0.63, 0.55), Color(0.5, 0.48, 0.46)]
const STEP_COLOR := Color(0.5, 0.47, 0.43)

@export var tower_radius: float = 1.8
@export var tower_height: float = 9.0
@export var stair_width: float = 1.0
## Turns the staircase makes from the ground to the top.
@export var stair_turns: float = 1.25
@export var step_rise: float = 0.25
@export var pine_height: float = 11.0
@export var bumpiness: float = 0.15
@export var bushes: int = 9
@export var grass: int = 1200

var _bumps: FastNoiseLite
var _base := 0.0


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.15
	_bumps.fractal_octaves = 3


## Gently bumpy ground that levels out into a pad under the tower.
func _ground(xz: Vector2) -> float:
	var land := 0.06 + bumpiness * _bumps.get_noise_2d(xz.x, xz.y)
	var pad := smoothstep(_outer_radius() + 1.2, _outer_radius() + 0.2, xz.distance_to(TOWER))
	return lerpf(land, 0.08, pad)


## Trodden earth around the tower's foot.
func _ground_tint(xz: Vector2) -> Color:
	var earth := Color(0.45, 0.38, 0.28)
	earth.a = smoothstep(tower_radius + 0.4, _outer_radius() + 1.0, xz.distance_to(TOWER))
	return earth


func _populate() -> void:
	_base = height_at(TOWER)
	var batch := merged("Tower", TOWER)
	_build_plinth(batch)
	_build_walls(batch)
	_build_battlement(batch)
	_build_stairs(batch)
	claim(TOWER, _outer_radius())
	commit_merged("Tower", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_build_pine()
	commit_merged("Pine", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_rocks()
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_bushes()
	commit_merged("Bushes", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_place_ground_cover()


func _outer_radius() -> float:
	return tower_radius + stair_width + 0.05


## A point on a circle around the tower at a height above its base.
func _around(angle: float, radius: float, height: float) -> Vector3:
	return Vector3(TOWER.x + cos(angle) * radius, _base + height, TOWER.y + sin(angle) * radius)


## A box standing tangent to the tower: its width runs around the circle.
func _ring_box(angle: float) -> Basis:
	return Basis(Vector3.UP, -angle - PI * 0.5)


func _stone() -> Color:
	return STONE_COLORS[rng.randi() % STONE_COLORS.size()] * rng.randf_range(0.92, 1.06)


## A ring of big blocks the walls stand on.
func _build_plinth(batch: NatureKit.Batch) -> void:
	var block := MeshKit.triangles(MeshKit.box(Vector3(0.8, 0.5, 0.5)))
	var count := 14
	for k in count:
		var angle := TAU * k / count
		if _angle_gap(angle, DOOR_ANGLE) < 0.3:
			continue
		var where := Transform3D(_ring_box(angle), _around(angle, tower_radius + 0.12, 0.05))
		batch.add(block, where, _stone() * 0.9)


## Courses of bricks, each course offset by half a brick, with a doorway
## and arrow slits left open. A dark core shows through the openings.
func _build_walls(batch: NatureKit.Batch) -> void:
	var per_course := floori(TAU * tower_radius / BRICK.x)
	var step := TAU / per_course
	var width := 2.0 * tower_radius * sin(step * 0.5) - 0.03
	var brick := MeshKit.triangles(MeshKit.box(Vector3(width, BRICK.y - 0.025, BRICK.z)))
	var courses := floori(tower_height / BRICK.y)
	for c in courses:
		var height := 0.3 + c * BRICK.y + BRICK.y * 0.5
		for k in per_course:
			var angle := (k + 0.5 * (c % 2)) * step
			if _is_opening(angle, height):
				continue
			var where := Transform3D(_ring_box(angle), _around(angle, tower_radius, height))
			batch.add(brick, where, _stone())
	var core := MeshKit.triangles(MeshKit.cylinder(tower_radius - 0.2, tower_radius - 0.2, tower_height, 16))
	batch.add(core, Transform3D(Basis(), _around(0.0, 0.0, tower_height * 0.5 + 0.2)), Color(0.08, 0.07, 0.06))
	var body := CylinderShape3D.new()
	body.radius = tower_radius + 0.1
	body.height = tower_height
	add_collider(body, Transform3D(Basis(), _around(0.0, 0.0, tower_height * 0.5 + 0.2)))


func _is_opening(angle: float, height: float) -> bool:
	if _angle_gap(angle, DOOR_ANGLE) < 0.22 and height < 2.1:
		return true
	for slit_height: float in [3.6, 6.0]:
		for k in 4:
			var slit := DOOR_ANGLE + PI * 0.25 + k * PI * 0.5 + slit_height * 0.4
			if _angle_gap(angle, slit) < 0.09 and absf(height - slit_height) < 0.45:
				return true
	return false


## A wider ring of corbels, the floor and merlons, open where the stairs
## arrive.
func _build_battlement(batch: NatureKit.Batch) -> void:
	var top := tower_height + 0.3
	var arrival := _stair_angle(1.0)
	var corbel := MeshKit.triangles(MeshKit.box(Vector3(0.62, 0.35, 0.6)))
	var merlon := MeshKit.triangles(MeshKit.box(Vector3(0.55, 0.7, 0.35)))
	var count := 20
	for k in count:
		var angle := TAU * k / count
		var open := _angle_gap(angle, arrival + 0.25) < 0.45
		if not open:
			batch.add(corbel, Transform3D(_ring_box(angle), _around(angle, tower_radius + 0.25, top - 0.15)), _stone())
			if k % 2 == 0:
				batch.add(merlon, Transform3D(_ring_box(angle), _around(angle, tower_radius + 0.38, top + 0.35)), _stone())
	var floor_mesh := MeshKit.triangles(MeshKit.cylinder(tower_radius + 0.2, tower_radius + 0.2, 0.2, 18))
	batch.add(floor_mesh, Transform3D(Basis(), _around(0.0, 0.0, top - 0.1)), Color(0.42, 0.33, 0.24))
	var deck := CylinderShape3D.new()
	deck.radius = tower_radius + 0.2
	deck.height = 0.2
	add_collider(deck, Transform3D(Basis(), _around(0.0, 0.0, top - 0.1)))
	# A pennant pole in the middle.
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.04, 0.05, 2.2, 6)), Transform3D(Basis(), _around(0.0, 0.0, top + 1.1)), Color(0.35, 0.25, 0.16))
	var flag := PackedVector3Array([Vector3(0.0, 0.0, 0.0), Vector3(0.0, -0.5, 0.0), Vector3(0.0, -0.25, 0.8)])
	var flag_place := Transform3D(Basis(), _around(0.0, 0.0, top + 2.15))
	batch.add(flag, flag_place, Color(0.7, 0.16, 0.14))
	flag.reverse()
	batch.add(flag, flag_place, Color(0.7, 0.16, 0.14))


## The stairs' angle a fraction of the way from the bottom to the top.
func _stair_angle(fraction: float) -> float:
	return DOOR_ANGLE + 0.7 + fraction * stair_turns * TAU


## Stone steps spiralling up the outside. Each step's collider is tilted
## along the climb, so together they make a ramp the player walks up.
func _build_stairs(batch: NatureKit.Batch) -> void:
	var steps := ceili((tower_height + 0.3) / step_rise)
	var middle := tower_radius + stair_width * 0.5 + 0.1
	var arc := stair_turns * TAU / steps
	var tread := arc * middle
	var stone := MeshKit.triangles(MeshKit.box(Vector3(tread + 0.04, step_rise, stair_width)))
	var pitch := atan2(step_rise, tread)
	for s in steps:
		var angle := _stair_angle(float(s) / steps)
		var height := (s + 1) * step_rise
		var facing := _ring_box(angle)
		batch.add(stone, Transform3D(facing, _around(angle, middle, height - step_rise * 0.5)), STEP_COLOR * rng.randf_range(0.9, 1.08))
		var ramp := BoxShape3D.new()
		ramp.size = Vector3(tread * 1.3, 0.1, stair_width)
		# The climb runs toward increasing angle, along the step's local +x.
		var tilt := facing * Basis(Vector3.BACK, pitch)
		add_collider(ramp, Transform3D(tilt, _around(angle, middle, height - 0.05 - step_rise * 0.5)))


## A tall pine: a tapering trunk under tiers of dark cones.
func _build_pine() -> void:
	var batch := merged("Pine", PINE)
	var foot := lowest_ground(PINE, 0.4) - 0.1
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.12, 0.3, pine_height * 0.85, 8)), Transform3D(Basis(), Vector3(PINE.x, foot + pine_height * 0.425, PINE.y)), Color(0.36, 0.25, 0.17))
	var tiers := 6
	for t in tiers:
		var f := float(t) / (tiers - 1)
		var radius := lerpf(1.75, 0.45, f)
		var height := lerpf(3.0, 1.6, f)
		var y := foot + lerpf(2.6, pine_height - 1.2, f)
		var cone := MeshKit.triangles(MeshKit.cone(radius, height, 9))
		var turn := Basis(Vector3.UP, rng.randf() * TAU)
		var green := Color(0.15, 0.3, 0.17).lerp(Color(0.2, 0.38, 0.2), f) * rng.randf_range(0.95, 1.05)
		batch.add(cone, Transform3D(turn, Vector3(PINE.x, y, PINE.y)), green)
	claim(PINE, 1.0)
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.3
	trunk.height = pine_height * 0.85
	add_collider(trunk, Transform3D(Basis(), Vector3(PINE.x, foot + pine_height * 0.425, PINE.y)))


func _place_rocks() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 4:
		shapes.append(NatureKit.rock_shape(rng))
	for k in 40:
		var angle := rng.randf() * TAU
		var xz := TOWER + Vector2(cos(angle), sin(angle)) * rng.randf_range(_outer_radius() + 0.3, _outer_radius() + 2.5)
		if k >= 14 or _angle_gap(angle, DOOR_ANGLE) < 0.5:
			xz = random_point()
		var size := lerpf(0.12, 0.45, pow(rng.randf(), 2.0))
		var radius := size * 0.62
		if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius):
			continue
		var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, radius * 0.7) - 0.05 * size, xz.y))
		merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where, NatureKit.rock_color(rng))
		claim(xz, radius)


## Bushes huddled around the pine and the tower's foot, a few elsewhere.
func _place_bushes() -> void:
	var placed := 0
	for attempt in bushes * 8:
		if placed >= bushes:
			return
		var near: Vector2 = [PINE, TOWER, random_point()][attempt % 3]
		var spread := 3.5 if near != TOWER else _outer_radius() + 2.0
		var xz := near + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
		var size := rng.randf_range(0.55, 0.95)
		var radius := size * 0.75
		if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius):
			continue
		NatureKit.add_bush(merged("Bushes", xz), rng, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, radius * 0.4) - 0.04, xz.y)))
		claim(xz, radius)
		placed += 1


## Grass over the open ground, and dark, broad ferns in the shade of the
## pine and against the tower.
func _place_ground_cover() -> void:
	var grass_places: Array[Transform3D] = []
	var grass_colors := PackedColorArray()
	var fern_places: Array[Transform3D] = []
	var fern_colors := PackedColorArray()
	var patches := FastNoiseLite.new()
	patches.seed = design_seed + 3
	patches.frequency = 0.25
	for k in int(grass * 1.5):
		var xz := random_point()
		if not fits(xz, 0.4) or not is_clear(xz, 0.0, 0.6):
			continue
		var shaded := xz.distance_to(PINE) < 2.6 or absf(xz.distance_to(TOWER) - _outer_radius() - 0.5) < 0.6
		var turn := Basis(Vector3.UP, rng.randf() * TAU)
		var shade := rng.randf_range(0.88, 1.08)
		if shaded and rng.randf() < 0.5:
			var size := rng.randf_range(1.6, 2.3)
			fern_places.append(Transform3D(turn.scaled(Vector3(size, size * 0.8, size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
			fern_colors.append(Color(0.55 * shade, 0.75 * shade, 0.5 * shade))
		elif rng.randf() < 0.2 + 0.8 * smoothstep(-0.3, 0.3, patches.get_noise_2d(xz.x, xz.y)) and fits(xz, 0.25):
			var size := rng.randf_range(0.8, 1.2)
			grass_places.append(Transform3D(turn.scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
			grass_colors.append(Color(shade, shade, shade))
	var material := NatureKit.grass_material()
	add_multimesh("Grass", NatureKit.grass_tuft(rng), material, grass_places, grass_colors, 45.0)
	add_multimesh("Ferns", NatureKit.grass_tuft(rng, 11), material, fern_places, fern_colors, 45.0)


func _angle_gap(a: float, b: float) -> float:
	return absf(angle_difference(a, b))
