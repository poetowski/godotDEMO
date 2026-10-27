@tool
extends SectorDesign
## Sector A7: a big, weathered phallic statue in the manner of ancient
## fertility stones, on a stepped plinth, overgrown with ivy: leaves thick
## at its foot and thinning toward the top, vines spiralling up the shaft,
## and ivy creeping over the ground around it. Rubble and grass around. In
## front of it the player can choose to pray (kneeling) or cry. The
## brief is in docs/DESIGN_DECISIONS.md; the shape, size and colours are
## placeholders.

## The statue's centre on the ground (world x, z); it faces south, toward
## the sector's start.
const STATUE := Vector2(5.0, -66.2)
const PLINTH_TOP := 1.1
const SHAFT_RADIUS := 0.55
const SHAFT_TOP := 3.9
const HEAD_RADIUS := Vector2(0.68, 0.58)
const BALL_RADIUS := 0.58
const STONE := Color(0.6, 0.58, 0.53)
const MOSSY := Color(0.46, 0.5, 0.38)
const VINE := Color(0.3, 0.24, 0.15)
## Where the player stands to pray or cry: in front of the plinth, facing it.
const SHRINE_SPOT := Vector2(5.0, -63.6)
const IVY_GREENS: Array[Color] = [Color(0.16, 0.34, 0.14), Color(0.22, 0.42, 0.16), Color(0.28, 0.48, 0.2), Color(0.19, 0.38, 0.18)]

## Leaves on the statue and the plinth.
@export var ivy_leaves: int = 5000
## Leaves creeping over the ground around the plinth.
@export var ground_leaves: int = 900
@export var vines: int = 6
@export var grass: int = 900

var _floor := 0.0


func _ground(xz: Vector2) -> float:
	var t := xz.distance_to(STATUE) / 3.5
	return 0.12 * maxf(0.0, 1.0 - t * t)


## Darker, leaf-littered earth where the ivy creeps.
func _ground_tint(xz: Vector2) -> Color:
	var earth := Color(0.33, 0.3, 0.2)
	earth.a = smoothstep(1.4, 2.8, xz.distance_to(STATUE))
	return earth


func _populate() -> void:
	_floor = height_at(STATUE)
	var batch := merged("Statue", STATUE)
	_build_plinth(batch)
	_build_statue(batch)
	_build_vines(batch)
	claim(STATUE, 1.8)
	commit_merged("Statue", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_ivy()
	_place_shrine_spot()
	_place_rubble()
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_grass()


func _at(x: float, y: float, z: float) -> Vector3:
	return Vector3(STATUE.x + x, _floor + y, STATUE.y + z)


## Two worn stone steps.
func _build_plinth(batch: NatureKit.Batch) -> void:
	for step: Array in [[Vector3(2.8, 0.55, 2.8), 0.12], [Vector3(2.1, 0.6, 2.1), 0.8]]:
		var size: Vector3 = step[0]
		var centre := _at(0.0, float(step[1]), 0.0)
		batch.add(MeshKit.triangles(MeshKit.box(size)), Transform3D(Basis(), centre), STONE.lerp(MOSSY, 0.35) * rng.randf_range(0.92, 1.0))
		var shape := BoxShape3D.new()
		shape.size = size
		add_collider(shape, Transform3D(Basis(), centre))


## The shaft, its rounded head with a carved rim, and the two stones at its
## foot, weathered and greening near the bottom.
func _build_statue(batch: NatureKit.Batch) -> void:
	var length := SHAFT_TOP - PLINTH_TOP
	var shaft := MeshKit.triangles(MeshKit.cylinder(SHAFT_RADIUS, SHAFT_RADIUS * 1.05, length, 14))
	batch.add(shaft, Transform3D(Basis(), _at(0.0, PLINTH_TOP + length * 0.5, 0.0)), STONE.lerp(MOSSY, 0.2))
	var head := MeshKit.triangles(MeshKit.sphere(1.0, 14, 8))
	var head_shape := Basis().scaled(Vector3(HEAD_RADIUS.x, HEAD_RADIUS.y, HEAD_RADIUS.x))
	batch.add(head, Transform3D(head_shape, _at(0.0, SHAFT_TOP + 0.2, 0.0)), STONE * 1.03)
	var rim := MeshKit.triangles(MeshKit.cylinder(HEAD_RADIUS.x * 1.02, SHAFT_RADIUS, 0.22, 14))
	batch.add(rim, Transform3D(Basis(), _at(0.0, SHAFT_TOP - 0.05, 0.0)), STONE * 0.94)
	for side: float in [-1.0, 1.0]:
		var ball := MeshKit.triangles(MeshKit.sphere(BALL_RADIUS, 12, 7))
		batch.add(ball, Transform3D(Basis().scaled(Vector3(1.0, 0.95, 1.0)), _ball_centre(side)), STONE.lerp(MOSSY, 0.45))
		var ball_shape := SphereShape3D.new()
		ball_shape.radius = BALL_RADIUS
		add_collider(ball_shape, Transform3D(Basis(), _ball_centre(side)))
	var body := CylinderShape3D.new()
	body.radius = SHAFT_RADIUS
	body.height = SHAFT_TOP + 0.8 - PLINTH_TOP
	add_collider(body, Transform3D(Basis(), _at(0.0, PLINTH_TOP + body.height * 0.5, 0.0)))


func _ball_centre(side: float) -> Vector3:
	return _at(side * 0.5, PLINTH_TOP + BALL_RADIUS * 0.85, 0.42)


## Woody vines spiralling up the shaft from the plinth.
func _build_vines(batch: NatureKit.Batch) -> void:
	for v in vines:
		var turn := TAU * v / vines + rng.randf_range(-0.3, 0.3)
		var top := rng.randf_range(2.6, SHAFT_TOP - 0.1)
		var spin := rng.randf_range(2.6, 3.6) * (1.0 if v % 2 == 0 else -1.0)
		var previous := Vector3.ZERO
		var steps := 26
		for s in steps + 1:
			var f := float(s) / steps
			var height := lerpf(PLINTH_TOP - 0.05, top, f)
			var angle := turn + f * spin
			var radius := SHAFT_RADIUS + 0.035 + (0.25 if height < PLINTH_TOP + 0.9 else 0.0) * (1.0 - f * 3.0)
			var point := _at(cos(angle) * maxf(radius, SHAFT_RADIUS + 0.035), height, sin(angle) * maxf(radius, SHAFT_RADIUS + 0.035))
			if s > 0:
				_add_twig(batch, previous, point, lerpf(0.035, 0.015, f))
			previous = point


## A thin cylinder from `a` to `b`.
func _add_twig(batch: NatureKit.Batch, a: Vector3, b: Vector3, radius: float) -> void:
	var direction := b - a
	var up := direction.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up)).orthonormalized()
	var twig := MeshKit.triangles(MeshKit.cylinder(radius, radius, direction.length() + 0.02, 5))
	batch.add(twig, Transform3D(basis, (a + b) * 0.5), VINE)


## The place in front of the statue where the player can pray or cry.
func _place_shrine_spot() -> void:
	var spot := GestureSpot.new()
	spot.name = "ShrineSpot"
	spot.prompt_text = Text.mark("[E]  Stand before the statue")
	spot.title = Text.mark("Before the statue")
	spot.labels = Text.marks(PackedStringArray(["Pray", "Cry"]))
	spot.gestures = [&"pray", &"cry"] as Array[StringName]
	spot.seconds = PackedFloat32Array([5.0, 4.0])
	spot.face_toward = _at(0.0, 2.0, 0.0)
	spot.position = surface(SHRINE_SPOT)
	add_content(spot)
	claim(SHRINE_SPOT, 0.8)


## Ivy leaves lying on the statue's surface, thick at the foot and thinning
## toward the head, and more creeping over the ground around the plinth.
func _place_ivy() -> void:
	var leaf := _leaf_mesh()
	var places: Array[Transform3D] = []
	var colors := PackedColorArray()
	var made := 0
	for attempt in ivy_leaves * 4:
		if made >= ivy_leaves:
			break
		var spot := _statue_surface_point()
		var point: Vector3 = spot[0]
		var normal: Vector3 = spot[1]
		var climb := clampf((point.y - _floor - PLINTH_TOP) / (SHAFT_TOP + 0.7 - PLINTH_TOP), 0.0, 1.0)
		if rng.randf() > 1.0 - 0.7 * smoothstep(0.3, 1.0, climb):
			continue
		places.append(_leaf_transform(point + normal * rng.randf_range(0.02, 0.06), normal, rng.randf_range(1.1, 1.8)))
		colors.append(IVY_GREENS[rng.randi() % IVY_GREENS.size()] * rng.randf_range(0.9, 1.1))
		made += 1
	for k in ground_leaves:
		var angle := rng.randf() * TAU
		var distance := 1.3 + 1.6 * pow(rng.randf(), 1.6)
		var xz := STATUE + Vector2(cos(angle), sin(angle)) * distance
		if not fits(xz, 0.15):
			continue
		var tilt := Vector3(rng.randf_range(-0.3, 0.3), 1.0, rng.randf_range(-0.3, 0.3)).normalized()
		places.append(_leaf_transform(surface(xz) + Vector3.UP * 0.03, tilt, rng.randf_range(1.1, 1.6)))
		colors.append(IVY_GREENS[rng.randi() % IVY_GREENS.size()] * rng.randf_range(0.85, 1.05))
	add_multimesh("Ivy", leaf, MeshKit.lowpoly_material(Color.WHITE, 0.7), places, colors, 60.0)


## A random point on the plinth's top and sides or the statue, with the
## surface's outward normal, chosen roughly by area.
func _statue_surface_point() -> Array:
	var pick := rng.randf()
	if pick < 0.45:
		var angle := rng.randf() * TAU
		var height := rng.randf_range(PLINTH_TOP, SHAFT_TOP)
		var out := Vector3(cos(angle), 0.0, sin(angle))
		return [_at(0.0, height, 0.0) + out * SHAFT_RADIUS, out]
	if pick < 0.6:
		var out := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.2, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var centre := _at(0.0, SHAFT_TOP + 0.2, 0.0)
		return [centre + Vector3(out.x * HEAD_RADIUS.x, out.y * HEAD_RADIUS.y, out.z * HEAD_RADIUS.x), out]
	if pick < 0.8:
		var out := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		return [_ball_centre(-1.0 if rng.randf() < 0.5 else 1.0) + out * BALL_RADIUS, out]
	# The plinth's steps: tops and sides.
	var step := 1.4 if rng.randf() < 0.6 else 1.05
	var top := 0.395 if step > 1.2 else PLINTH_TOP
	var side := rng.randi() % 5
	if side == 4:
		return [_at(rng.randf_range(-step, step), top, rng.randf_range(-step, step)), Vector3.UP]
	var out := Vector3(cos(side * PI * 0.5), 0.0, sin(side * PI * 0.5))
	var along := Vector3(-out.z, 0.0, out.x) * rng.randf_range(-step, step)
	return [_at(0.0, rng.randf_range(top - 0.5, top), 0.0) + out * step + along, out]


## A leaf lying on a surface: its face along `normal`, turned at random.
func _leaf_transform(at: Vector3, normal: Vector3, size: float) -> Transform3D:
	var side := normal.cross(Vector3.UP if absf(normal.y) < 0.95 else Vector3.RIGHT).normalized()
	var basis := Basis(side, normal, side.cross(normal)).orthonormalized()
	basis = basis * Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
	return Transform3D(basis.scaled(Vector3.ONE * size), at)


## An ivy leaf about 12 cm across: three pointed lobes around a centre,
## lying in the xz plane, two-faced.
func _leaf_mesh() -> ArrayMesh:
	var batch := NatureKit.Batch.new()
	var centre := Vector3(0.0, 0.004, 0.0)
	var outline: Array[Vector3] = [
		Vector3(0.0, 0.0, -0.02), Vector3(-0.05, 0.0, -0.03), Vector3(-0.065, 0.0, 0.01), Vector3(-0.025, 0.0, 0.02),
		Vector3(0.0, 0.0, 0.075), Vector3(0.025, 0.0, 0.02), Vector3(0.065, 0.0, 0.01), Vector3(0.05, 0.0, -0.03),
	]
	for k in outline.size():
		var triangle := PackedVector3Array([centre, outline[k], outline[(k + 1) % outline.size()]])
		batch.add(triangle, Transform3D(), Color.WHITE)
		triangle.reverse()
		batch.add(triangle, Transform3D(), Color.WHITE * 0.8)
	return batch.commit()


## Broken stone and fallen pieces around the statue.
func _place_rubble() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 4:
		shapes.append(NatureKit.rock_shape(rng))
	var placed := 0
	for attempt in 60:
		if placed >= 14:
			return
		var xz := STATUE + Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0)) if attempt % 2 == 0 else random_point()
		var size := lerpf(0.12, 0.45, pow(rng.randf(), 2.0))
		var radius := size * 0.62
		if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius):
			continue
		var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, radius * 0.7) - 0.05 * size, xz.y))
		merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where, STONE.lerp(MOSSY, rng.randf() * 0.5))
		claim(xz, radius)
		placed += 1


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if xz.distance_to(STATUE) < 1.8 or not fits(xz, 0.25) or not is_clear(xz, 0.0, 0.6):
			continue
		var size := rng.randf_range(0.8, 1.25)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
		var shade := rng.randf_range(0.88, 1.08)
		colors.append(Color(shade, shade, shade))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
