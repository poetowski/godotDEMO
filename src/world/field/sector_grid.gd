@tool
extends Node3D
## Draws the sector grid above the ground: a curtain of light rising from every
## grid line, and each sector's name painted flat in its centre. The lines on
## the ground come from the grass shader. Generated children have no owner, so
## the editor never saves them.

const CURTAIN_SHADER := preload("res://src/world/field/light_curtain.gdshader")

@export var curtain_height: float = 3.0
@export var label_color: Color = Color(0.75, 0.95, 1.0, 0.6)
@export var label_visible_distance: float = 70.0


func _ready() -> void:
	_build_curtains()
	_build_labels()


func _build_curtains() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var extent := SectorMap.extent()
	var origin := SectorMap.ORIGIN
	for i in SectorMap.COLUMNS + 1:
		var x := origin.x + i * SectorMap.SIZE
		_add_curtain(vertices, colors, Vector3(x, 0.0, origin.z), Vector3(x, 0.0, origin.z - extent.y))
	for j in SectorMap.ROWS + 1:
		var z := origin.z - j * SectorMap.SIZE
		_add_curtain(vertices, colors, Vector3(origin.x, 0.0, z), Vector3(origin.x + extent.x, 0.0, z))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = CURTAIN_SHADER
	var curtains := MeshInstance3D.new()
	curtains.name = "Curtains"
	curtains.mesh = mesh
	curtains.material_override = material
	curtains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(curtains)


## Two triangles standing on the line from `a` to `b`, opaque at the ground
## and transparent at the top.
func _add_curtain(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3) -> void:
	var up := Vector3.UP * curtain_height
	vertices.append_array(PackedVector3Array([a, b, a + up, b, b + up, a + up]))
	var ground := Color(1.0, 1.0, 1.0, 1.0)
	var sky := Color(1.0, 1.0, 1.0, 0.0)
	colors.append_array(PackedColorArray([ground, ground, sky, ground, sky, sky]))


func _build_labels() -> void:
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var cell := Vector2i(column, row)
			var label := Label3D.new()
			label.name = "Label" + SectorMap.name_of(cell)
			label.text = SectorMap.name_of(cell)
			label.font_size = 96
			label.pixel_size = 0.02
			label.outline_size = 0
			label.modulate = label_color
			label.double_sided = true
			label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			label.visibility_range_end = label_visible_distance
			label.visibility_range_end_margin = 10.0
			label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			# Lying flat, readable when facing north.
			label.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
			label.position = SectorMap.center_of(cell) + Vector3.UP * 0.03
			add_child(label)
