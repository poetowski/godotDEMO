@tool
extends Node3D
## Scatters the PoC's low-poly nature: pine and oak groves, bushes, rocks and
## flower patches. Trees grow in noise-shaped groves and keep clear of the
## path, the castle, the spawn meadow and the sword's clearing. Tree trunks and
## large rocks are solid. Generated children have no owner, so the editor never
## saves them.

const MAX_TREES := 900
const TREE_ATTEMPTS := 9000
const TREE_SPACING := 2.6
const BUSHES := 260
const ROCKS := 140
const FLOWER_PATCHES := 70

var _rng := RandomNumberGenerator.new()
var _groves := FastNoiseLite.new()
var _body: StaticBody3D


func _ready() -> void:
	_rng.seed = PocLayout.SEED + 30
	_groves.seed = PocLayout.SEED + 31
	_groves.frequency = 0.03
	_body = StaticBody3D.new()
	_body.name = "Body"
	add_child(_body)
	_plant_trees()
	_scatter_bushes()
	_scatter_rocks()
	_scatter_flowers()


func _plant_trees() -> void:
	var pines: Array[Transform3D] = []
	var oaks: Array[Transform3D] = []
	var occupied := {}
	var half := PocLayout.SIZE * 0.5 - 2.0
	for attempt in TREE_ATTEMPTS:
		if pines.size() + oaks.size() >= MAX_TREES:
			break
		var spot := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		if _clearance(spot) < 4.0:
			continue
		var rim := smoothstep(0.7, 0.9, maxf(absf(spot.x), absf(spot.y)) / (PocLayout.SIZE * 0.5))
		var density := maxf(smoothstep(-0.15, 0.3, _groves.get_noise_2d(spot.x, spot.y)), rim)
		if _rng.randf() > density or _crowded(spot, occupied):
			continue
		occupied[Vector2i(floori(spot.x / TREE_SPACING), floori(spot.y / TREE_SPACING))] = spot
		var size_factor := _rng.randf_range(0.8, 1.35)
		var placed := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size_factor),
			PocLayout.ground(spot) - Vector3.UP * 0.15)
		if _groves.get_noise_2d(spot.x * 0.5 + 100.0, spot.y * 0.5) > -0.1:
			pines.append(placed)
		else:
			oaks.append(placed)
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.3 * size_factor
		trunk.height = 3.0 * size_factor
		var collision := CollisionShape3D.new()
		collision.shape = trunk
		collision.position = placed.origin + Vector3.UP * trunk.height * 0.5
		_body.add_child(collision)

	var pine_crown := MeshKit.merge(
		[MeshKit.cone(1.7, 2.6, 7), MeshKit.cone(1.3, 2.3, 7), MeshKit.cone(0.85, 2.0, 7)],
		[Transform3D(Basis(), Vector3(0.0, 2.6, 0.0)), Transform3D(Basis(), Vector3(0.0, 3.8, 0.0)),
			Transform3D(Basis(), Vector3(0.0, 4.9, 0.0))])
	var oak_crown := MeshKit.merge(
		[MeshKit.sphere(1.6, 7, 5), MeshKit.sphere(1.15, 7, 5), MeshKit.sphere(1.05, 7, 5), MeshKit.sphere(0.95, 7, 5)],
		[Transform3D(Basis(), Vector3(0.0, 3.6, 0.0)), Transform3D(Basis(), Vector3(1.0, 3.2, 0.3)),
			Transform3D(Basis(), Vector3(-0.9, 3.3, -0.4)), Transform3D(Basis(), Vector3(0.1, 4.5, -0.2))])
	_fill("PineTrunks", MeshKit.cylinder(0.16, 0.24, 2.0, 6), pines, Vector3(0.0, 1.0, 0.0), _bark)
	_fill("PineCrowns", pine_crown, pines, Vector3.ZERO, _pine_green)
	_fill("OakTrunks", MeshKit.cylinder(0.2, 0.3, 3.0, 6), oaks, Vector3(0.0, 1.5, 0.0), _bark)
	_fill("OakCrowns", oak_crown, oaks, Vector3.ZERO, _oak_green)


func _scatter_bushes() -> void:
	var placed: Array[Transform3D] = []
	var half := PocLayout.SIZE * 0.5 - 3.0
	while placed.size() < BUSHES:
		var spot := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		var clearance := _clearance(spot)
		if clearance < 2.6 or (clearance > 8.0 and _groves.get_noise_2d(spot.x, spot.y) < -0.1):
			continue
		var size_factor := _rng.randf_range(0.7, 1.3)
		placed.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(size_factor, size_factor * 0.8, size_factor)),
			PocLayout.ground(spot) - Vector3.UP * 0.05))
	var bush := MeshKit.merge(
		[MeshKit.sphere(0.55, 7, 4), MeshKit.sphere(0.42, 7, 4), MeshKit.sphere(0.38, 7, 4)],
		[Transform3D(Basis(), Vector3(0.0, 0.35, 0.0)), Transform3D(Basis(), Vector3(0.45, 0.28, 0.15)),
			Transform3D(Basis(), Vector3(-0.35, 0.25, -0.25))])
	_fill("Bushes", bush, placed, Vector3.ZERO, _bush_green)


func _scatter_rocks() -> void:
	var placed: Array[Transform3D] = []
	var half := PocLayout.SIZE * 0.5 - 2.0
	while placed.size() < ROCKS:
		var spot := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		if _clearance(spot) < 2.4:
			continue
		var size := Vector3(_rng.randf_range(0.5, 1.6), _rng.randf_range(0.35, 0.9), _rng.randf_range(0.5, 1.4))
		var tilt := Basis(Vector3(_rng.randf(), 0.0, _rng.randf()).normalized(), _rng.randf_range(-0.3, 0.3))
		var rock_basis := tilt * Basis(Vector3.UP, _rng.randf() * TAU) * Basis.from_scale(size)
		placed.append(Transform3D(rock_basis, PocLayout.ground(spot)))
		if size.x > 1.1 and size.z > 1.0:
			var shape := SphereShape3D.new()
			shape.radius = 0.5 * minf(size.x, size.z)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = PocLayout.ground(spot) + Vector3.UP * 0.1
			_body.add_child(collision)
	_fill("Rocks", MeshKit.sphere(0.6, 6, 4), placed, Vector3.ZERO, _rock_grey)


func _scatter_flowers() -> void:
	var placed: Array[Transform3D] = []
	var tints: Array[Color] = []
	var palette: Array[Color] = [Color(0.98, 0.95, 0.85), Color(0.98, 0.82, 0.25), Color(0.72, 0.55, 0.9), Color(0.92, 0.4, 0.45)]
	var half := PocLayout.SIZE * 0.5 - 15.0
	var patches := 0
	while patches < FLOWER_PATCHES:
		var center := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		if _clearance(center) < 2.5:
			continue
		patches += 1
		var tint := palette[_rng.randi() % palette.size()]
		for i in _rng.randi_range(8, 18):
			var spot := center + Vector2(_rng.randfn(0.0, 1.2), _rng.randfn(0.0, 1.2))
			if PocLayout.path_distance_at(spot.x, spot.y) < PocLayout.PATH_HALF_WIDTH + 0.4:
				continue
			placed.append(Transform3D(Basis(), PocLayout.ground(spot) + Vector3.UP * 0.12))
			tints.append(tint.lightened(_rng.randf_range(0.0, 0.15)))
	var flowers := _fill("Flowers", MeshKit.sphere(0.07, 6, 3), placed, Vector3.ZERO, func(i: int) -> Color: return tints[i])
	flowers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Distance to the nearest place that must stay open.
func _clearance(spot: Vector2) -> float:
	var clear := PocLayout.path_distance_at(spot.x, spot.y)
	clear = minf(clear, spot.distance_to(PocLayout.CASTLE_CENTER) - PocLayout.CASTLE_FLAT_RADIUS + 2.0)
	clear = minf(clear, spot.distance_to(PocLayout.SPAWN) - 6.0)
	clear = minf(clear, spot.distance_to(PocLayout.SWORD) - 4.0)
	return clear


func _crowded(spot: Vector2, occupied: Dictionary) -> bool:
	var cell := Vector2i(floori(spot.x / TREE_SPACING), floori(spot.y / TREE_SPACING))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var other: Variant = occupied.get(cell + Vector2i(dx, dz))
			if other != null and spot.distance_to(other as Vector2) < TREE_SPACING:
				return true
	return false


## One MultiMesh of `mesh` per transform, lifted by `offset`, coloured per instance.
func _fill(node_name: String, mesh: Mesh, transforms: Array[Transform3D], offset: Vector3, tint: Callable) -> MultiMeshInstance3D:
	var instance := MeshKit.multimesh_instance(mesh, MeshKit.lowpoly_material(), transforms.size())
	instance.name = node_name
	for i in transforms.size():
		var placed := transforms[i]
		instance.multimesh.set_instance_transform(i, placed.translated_local(offset))
		instance.multimesh.set_instance_color(i, tint.call(i) as Color)
	add_child(instance)
	return instance


func _bark(_i: int) -> Color:
	return Color(0.36, 0.25, 0.16).darkened(_rng.randf_range(0.0, 0.25))


func _pine_green(_i: int) -> Color:
	return Color(0.17, 0.4, 0.24).lightened(_rng.randf_range(-0.05, 0.12))


func _oak_green(_i: int) -> Color:
	var green := Color(0.36, 0.58, 0.22).lightened(_rng.randf_range(-0.08, 0.1))
	return green.lerp(Color(0.85, 0.62, 0.2), 0.6) if _rng.randf() < 0.06 else green


func _bush_green(_i: int) -> Color:
	return Color(0.27, 0.5, 0.2).lightened(_rng.randf_range(-0.06, 0.1))


func _rock_grey(_i: int) -> Color:
	return Color(0.55, 0.54, 0.52).darkened(_rng.randf_range(0.0, 0.2))
