@tool
class_name MistBarrier
extends Node3D
## The edge of the playable land in the west: a bank of drifting fog over the
## abyss, thick enough to hide what lies past it, with a wall inside it the player
## can't cross. Sheets of fog stand one behind another along the border, lower
## and thinner on the player's side, and along the ravine's southern run too,
## where there's no wall: the ravine's south face stops the player there.
## Generated children have no owner, so the editor never saves them.
##
## The land under it was carved by tools/carve_western_abyss.gd.

const SHADER := preload("res://src/world/field/mist_wall.gdshader")
## The line of the wall, north to south (x east, y north).
const WEST_FROM := Vector2(-168.0, 400.0)
const WEST_TO := Vector2(-168.0, -200.0)
## The line of the fog along the ravine's southern run, west to east.
const SOUTH_FROM := Vector2(-168.0, -176.0)
const SOUTH_TO := Vector2(140.0, -182.0)
## Metres between points along the fog.
const STEP := 20.0
## How far the line wanders from straight, in metres, so it isn't a ruled edge.
const WANDER := 4.0
const BOTTOM := -230.0
const WALL_TOP := 80.0
const WALL_THICKNESS := 2.0
## Per sheet: metres towards the far side, height of its top, and its thickness.
## The first are on the player's side.
const SHEETS: Array[Vector3] = [
	Vector3(-16.0, -14.0, 0.3), Vector3(-8.0, 2.0, 0.4), Vector3(0.0, 12.0, 0.55),
	Vector3(6.0, 20.0, 0.7), Vector3(12.0, 26.0, 0.85), Vector3(18.0, 30.0, 1.0),
]


func _ready() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	_add_sheets(WEST_FROM, WEST_TO, 0, vertices, colors, uvs, indices)
	_add_sheets(SOUTH_FROM, SOUTH_TO, 1, vertices, colors, uvs, indices)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	var fog := MeshInstance3D.new()
	fog.name = "Fog"
	fog.mesh = mesh
	fog.material_override = material
	fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fog)
	_build_wall()


## Where the line runs `t` of the way along, wandering, `aside` metres off it.
static func _line_point(from: Vector2, to: Vector2, t: float, aside: float) -> Vector2:
	var along := to - from
	var side := along.orthogonal().normalized()
	var metres := along.length() * t
	var wander := sin(metres * 0.031 + from.x) * WANDER + sin(metres * 0.083) * WANDER * 0.4
	return from + along * t + side * (wander + aside)


## The sheets along one line. `far_side` picks which way the far side lies: the
## west of a line running south, the south of one running east.
func _add_sheets(from: Vector2, to: Vector2, far_side: int, vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, indices: PackedInt32Array) -> void:
	var length := from.distance_to(to)
	var points := ceili(length / STEP)
	var sign_to_far := -1.0 if far_side == 0 else 1.0
	# Which way a line's orthogonal points depends on the way it runs.
	for sheet in SHEETS:
		var start := vertices.size()
		for k in points + 1:
			var t := float(k) / points
			var at := _line_point(from, to, t, sheet.x * sign_to_far)
			var ends := 1.0 if far_side == 0 else minf(smoothstep(1.0, 0.8, t), 1.0)
			var shade := Color(ends, 0.0, 0.0, sheet.z)
			vertices.append(Vector3(at.x, BOTTOM, -at.y))
			vertices.append(Vector3(at.x, sheet.y, -at.y))
			colors.append(shade)
			colors.append(shade)
			uvs.append(Vector2(k * STEP, 0.0))
			uvs.append(Vector2(k * STEP, 1.0))
		for k in points:
			var a := start + k * 2
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))


## The wall, piece by piece along the wandering line, so the fog hides it.
func _build_wall() -> void:
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	add_child(wall)
	var points := ceili(WEST_FROM.distance_to(WEST_TO) / STEP)
	for k in points:
		var a := _line_point(WEST_FROM, WEST_TO, float(k) / points, 0.0)
		var b := _line_point(WEST_FROM, WEST_TO, float(k + 1) / points, 0.0)
		var shape := BoxShape3D.new()
		shape.size = Vector3(a.distance_to(b) + WALL_THICKNESS, WALL_TOP - BOTTOM, WALL_THICKNESS)
		var piece := CollisionShape3D.new()
		piece.shape = shape
		var middle := a.lerp(b, 0.5)
		piece.position = Vector3(middle.x, (WALL_TOP + BOTTOM) * 0.5, -middle.y)
		piece.rotation.y = atan2(b.y - a.y, b.x - a.x)
		wall.add_child(piece)
