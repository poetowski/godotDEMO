@tool
extends Node3D
## Builds the PoC fantasy castle from primitive meshes: curtain walls with
## merlons, an arched gate between two turrets, round corner towers, and a keep
## with three spired towers, flags and a small courtyard. Placeholder look.
##
## Local space: the origin is the courtyard floor at the castle's centre and
## +Z points out through the gate. Generated children have no owner, so the
## editor never saves them.

const STONE_SHADER := preload("res://src/world/poc_castle/castle_stone.gdshader")
const WALL_HALF := 16.0
const WALL_HEIGHT := 7.0
const WALL_THICKNESS := 2.0
const FOOTING := -1.0
const GATE_HALF_WIDTH := 2.0
const GATE_SPRING := 3.5
const TURRET_X := 4.3
const MERLON_STEP := 1.8

var _body: StaticBody3D
var _stone: ShaderMaterial
var _round_stone: ShaderMaterial
var _roof: ShaderMaterial
var _wood: ShaderMaterial
var _gold: StandardMaterial3D
var _dark: StandardMaterial3D
var _banner: StandardMaterial3D
var _water: StandardMaterial3D


func _ready() -> void:
	_make_materials()
	_body = StaticBody3D.new()
	_body.name = "Body"
	add_child(_body)
	_build_walls()
	_build_gate()
	var corner := WALL_HALF
	for x: float in [-corner, corner]:
		for z: float in [-corner, corner]:
			_tower(x, z, 3.2, 12.0, 6.0)
	_build_keep()
	_build_courtyard()


func _make_materials() -> void:
	_stone = ShaderMaterial.new()
	_stone.shader = STONE_SHADER
	_round_stone = _stone.duplicate() as ShaderMaterial
	_round_stone.set_shader_parameter("cylindrical", true)
	_roof = MeshKit.lowpoly_material(Color(0.22, 0.35, 0.7), 0.7)
	_wood = MeshKit.lowpoly_material(Color(0.42, 0.28, 0.16), 0.9)
	_gold = StandardMaterial3D.new()
	_gold.albedo_color = Color(0.92, 0.72, 0.32)
	_gold.metallic = 1.0
	_gold.roughness = 0.3
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color(0.07, 0.07, 0.09)
	_dark.roughness = 1.0
	_banner = StandardMaterial3D.new()
	_banner.albedo_color = Color(0.7, 0.1, 0.13)
	_banner.roughness = 0.8
	_banner.cull_mode = BaseMaterial3D.CULL_DISABLED
	_water = StandardMaterial3D.new()
	_water.albedo_color = Color(0.1, 0.2, 0.3)
	_water.roughness = 0.08


func _build_walls() -> void:
	var height := WALL_HEIGHT - FOOTING
	var middle := (WALL_HEIGHT + FOOTING) * 0.5
	var length := WALL_HALF * 2.0
	_block(Vector3(length, height, WALL_THICKNESS), Vector3(0.0, middle, -WALL_HALF))
	_block(Vector3(WALL_THICKNESS, height, length), Vector3(WALL_HALF, middle, 0.0))
	_block(Vector3(WALL_THICKNESS, height, length), Vector3(-WALL_HALF, middle, 0.0))

	var merlon := MeshKit.box(Vector3(0.9, 1.0, 0.5))
	var edge := WALL_HALF + WALL_THICKNESS * 0.5 - 0.25
	var y := WALL_HEIGHT + 0.5
	var t := -8.0 * MERLON_STEP
	while t <= 8.0 * MERLON_STEP + 0.01:
		if absf(t) < 12.6:
			_part(merlon, _stone, Vector3(t, y, -edge))
			_part(merlon, _stone, Vector3(edge, y, t), null, PI / 2.0)
			_part(merlon, _stone, Vector3(-edge, y, t), null, PI / 2.0)
			if absf(t) < TURRET_X - 1.9 or absf(t) > TURRET_X + 2.0:
				_part(merlon, _stone, Vector3(t, y, edge))
		t += MERLON_STEP


## The south wall, cut by an arched gateway, flanked by turrets with banners.
func _build_gate() -> void:
	var wall := CSGCombiner3D.new()
	wall.name = "GateWall"
	wall.use_collision = true
	add_child(wall)
	var block := CSGBox3D.new()
	block.size = Vector3(WALL_HALF * 2.0, WALL_HEIGHT - FOOTING, WALL_THICKNESS)
	block.position = Vector3(0.0, (WALL_HEIGHT + FOOTING) * 0.5, WALL_HALF)
	block.material = _stone
	wall.add_child(block)
	var opening := CSGBox3D.new()
	opening.operation = CSGShape3D.OPERATION_SUBTRACTION
	opening.size = Vector3(GATE_HALF_WIDTH * 2.0, GATE_SPRING - FOOTING + 0.2, WALL_THICKNESS + 1.0)
	opening.position = Vector3(0.0, (GATE_SPRING + FOOTING - 0.2) * 0.5, WALL_HALF)
	opening.material = _stone
	wall.add_child(opening)
	var arch := CSGCylinder3D.new()
	arch.operation = CSGShape3D.OPERATION_SUBTRACTION
	arch.radius = GATE_HALF_WIDTH
	arch.height = WALL_THICKNESS + 1.0
	arch.sides = 20
	arch.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	arch.position = Vector3(0.0, GATE_SPRING, WALL_HALF)
	arch.material = _stone
	wall.add_child(arch)

	var door_height := GATE_SPRING - FOOTING
	for side: float in [-1.0, 1.0]:
		_part(MeshKit.box(Vector3(0.15, door_height, 2.0)), _wood,
			Vector3(side * (GATE_HALF_WIDTH - 0.1), FOOTING + door_height * 0.5, WALL_HALF - WALL_THICKNESS * 0.5 - 1.0))
		var x := side * TURRET_X
		var front := WALL_HALF + 0.6 + 1.9
		_block(Vector3(3.6, 10.0, 3.8), Vector3(x, 4.0, WALL_HALF + 0.6))
		_part(MeshKit.cylinder(0.0, 2.75, 3.4, 4), _roof, Vector3(x, 10.7, WALL_HALF + 0.6), null, PI / 4.0)
		_part(MeshKit.sphere(0.16), _gold, Vector3(x, 12.5, WALL_HALF + 0.6))
		_part(MeshKit.box(Vector3(1.3, 3.2, 0.06)), _banner, Vector3(x, 5.0, front + 0.04))
		_part(MeshKit.box(Vector3(0.3, 1.2, 0.1)), _dark, Vector3(x, 7.9, front + 0.02))


func _build_keep() -> void:
	var front := -2.0
	_block(Vector3(14.0, 13.0, 10.0), Vector3(0.0, 5.5, front - 5.0))
	var merlon := MeshKit.box(Vector3(0.8, 0.9, 0.45))
	var x := -6.1
	while x <= 6.11:
		_part(merlon, _stone, Vector3(x, 12.45, front - 0.22))
		_part(merlon, _stone, Vector3(x, 12.45, front - 9.78))
		x += 1.75
	_part(MeshKit.box(Vector3(2.4, 3.6, 0.2)), _wood, Vector3(0.0, 1.8, front + 0.05))
	_part(MeshKit.box(Vector3(3.0, 0.35, 0.3)), _stone, Vector3(0.0, 3.75, front + 0.1))
	for y: float in [5.2, 8.8]:
		for wx: float in [-4.5, -1.5, 1.5, 4.5]:
			_part(MeshKit.box(Vector3(0.8, 1.6, 0.12)), _dark, Vector3(wx, y, front + 0.03))
	_tower(-7.0, front, 2.2, 17.0, 6.0, true)
	_tower(7.0, front, 2.2, 17.0, 6.0, true)
	_tower(0.0, -9.0, 3.2, 25.0, 9.0, true, Vector2(0.0, 1.0))


## A round tower from the footing up to `top`, with a corbel ring, a conical
## roof, a gold finial, arrow slits facing `facing` (outward by default) and an
## optional flag.
func _tower(x: float, z: float, radius: float, top: float, roof_height: float, flag: bool = false, facing: Vector2 = Vector2.ZERO) -> void:
	var height := top - FOOTING
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_part(MeshKit.cylinder(radius, radius, height, 18), _round_stone, Vector3(x, FOOTING + height * 0.5, z), shape)
	_part(MeshKit.cylinder(radius + 0.35, radius + 0.35, 0.7, 18), _round_stone, Vector3(x, top - 0.35, z))
	_part(MeshKit.cone(radius + 0.8, roof_height, 12), _roof, Vector3(x, top + roof_height * 0.5, z))
	var tip := top + roof_height
	_part(MeshKit.sphere(0.22), _gold, Vector3(x, tip + 0.1, z))
	if flag:
		_part(MeshKit.cylinder(0.05, 0.05, 2.6, 6), _dark, Vector3(x, tip + 1.3, z))
		_part(MeshKit.box(Vector3(1.5, 0.75, 0.04)), _banner, Vector3(x + 0.78, tip + 2.15, z))
	var out := facing if facing != Vector2.ZERO else Vector2(x, z).normalized()
	for y: float in [top * 0.4, top * 0.72]:
		var at := Vector3(x + out.x * (radius + 0.02), y, z + out.y * (radius + 0.02))
		_part(MeshKit.box(Vector3(0.28, 1.2, 0.12)), _dark, at, null, atan2(out.x, out.y))


func _build_courtyard() -> void:
	var well := Vector3(6.0, 0.0, 7.0)
	var ring := CylinderShape3D.new()
	ring.radius = 1.0
	ring.height = 0.9
	_part(MeshKit.cylinder(1.0, 1.05, 0.9, 14), _round_stone, well + Vector3(0.0, 0.45, 0.0), ring)
	_part(MeshKit.cylinder(0.85, 0.85, 0.05, 14), _water, well + Vector3(0.0, 0.78, 0.0))
	for side: float in [-1.0, 1.0]:
		_part(MeshKit.box(Vector3(0.14, 1.9, 0.14)), _wood, well + Vector3(side * 0.85, 1.4, 0.0))
	_part(MeshKit.cylinder(0.0, 1.35, 0.8, 4), _roof, well + Vector3(0.0, 2.7, 0.0), null, PI / 4.0)

	var barrel := MeshKit.cylinder(0.38, 0.38, 0.9, 10)
	for spot: Vector3 in [Vector3(-12.5, 0.45, 10.0), Vector3(-11.6, 0.45, 10.7), Vector3(-12.6, 0.45, 11.3)]:
		_part(barrel, _wood, spot)
	var crate := MeshKit.box(Vector3(0.9, 0.9, 0.9))
	for spot: Vector3 in [Vector3(12.0, 0.45, -11.5), Vector3(11.0, 0.45, -11.8), Vector3(11.6, 1.35, -11.6)]:
		_part(crate, _wood, spot, null, spot.x * 0.3)


## A stone block with matching collision.
func _block(size: Vector3, at: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_part(MeshKit.box(size), _stone, at, shape)


func _part(mesh: Mesh, material: Material, at: Vector3, shape: Shape3D = null, turn: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = Transform3D(Basis(Vector3.UP, turn), at)
	add_child(instance)
	if shape:
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = instance.transform
		_body.add_child(collision)
	return instance
