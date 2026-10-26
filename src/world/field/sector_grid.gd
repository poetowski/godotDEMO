@tool
extends Node3D
## Draws the sector grid above the ground: a curtain of light rising from every
## grid line, and each sector's name painted flat in its centre. Both follow
## the terrain and any water. Names are hidden in sectors a design owns, where
## they would hover over its ground; the HUD still names them. The lines on
## the ground come from the grass shader. Generated children have no owner, so
## the editor never saves them.

const CURTAIN_SHADER := preload("res://src/world/field/light_curtain.gdshader")
## Metres between the points where a curtain meets shaped ground.
const CURTAIN_STEP := 0.5
## Half the size of a painted name, in metres east and north.
const LABEL_HALF_SIZE := Vector2(1.1, 0.9)

## The ground the grid stands on; flat at height 0 when unset.
@export var terrain: FieldTerrain
@export var curtain_height: float = 3.0
@export var label_color: Color = Color(0.75, 0.95, 1.0, 0.6)
@export var label_visible_distance: float = 70.0
## Paint names in designed sectors too.
@export var name_designed_sectors: bool = false


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


## A curtain standing on the ground along the line from `a` to `b`, opaque at
## the ground and transparent at the top: a strip of quads that bends with
## shaped ground and stays one quad where the ground is flat. Only the
## sector-long spans beside a design are sampled.
func _add_curtain(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3) -> void:
	var spans := roundi(a.distance_to(b) / SectorMap.SIZE)
	var across := (b - a).normalized().cross(Vector3.UP) * 0.01
	var feet: Array[Vector3] = [a]
	for s in spans:
		var from := a.lerp(b, float(s) / spans)
		var to := a.lerp(b, float(s + 1) / spans)
		var middle := from.lerp(to, 0.5)
		if not (_is_designed(middle + across) or _is_designed(middle - across)):
			_add_foot(feet, to)
			continue
		var pieces := ceili(SectorMap.SIZE / CURTAIN_STEP)
		for k in range(1, pieces + 1):
			var point := from.lerp(to, float(k) / pieces)
			point.y = _surface(Vector2(point.x, point.z))
			_add_foot(feet, point)
	var up := Vector3.UP * curtain_height
	var ground := Color(1.0, 1.0, 1.0, 1.0)
	var sky := Color(1.0, 1.0, 1.0, 0.0)
	for k in feet.size() - 1:
		var from := feet[k]
		var to := feet[k + 1]
		vertices.append_array(PackedVector3Array([from, to, from + up, to, to + up, from + up]))
		colors.append_array(PackedColorArray([ground, ground, sky, ground, sky, sky]))


## Adds a point where the curtain meets the ground, merging runs of flat
## ground into one quad.
func _add_foot(feet: Array[Vector3], point: Vector3) -> void:
	var count := feet.size()
	if count >= 2 and point.y == 0.0 and feet[count - 1].y == 0.0 and feet[count - 2].y == 0.0:
		feet[count - 1] = point
	else:
		feet.append(point)


## The height of the ground or water at a point.
func _surface(xz: Vector2) -> float:
	return terrain.surface_height_at(xz) if terrain else 0.0


func _is_designed(point: Vector3) -> bool:
	return terrain != null and terrain.design_at(Vector2(point.x, point.z)) != null


## Just above the highest ground or water under a painted name.
func _label_height(centre: Vector3) -> float:
	if not _is_designed(centre):
		return 0.03
	var highest := 0.0
	for dx: float in [-1.0, 0.0, 1.0]:
		for dz: float in [-1.0, 0.0, 1.0]:
			highest = maxf(highest, _surface(Vector2(centre.x, centre.z) + Vector2(dx, dz) * LABEL_HALF_SIZE))
	return highest + 0.03


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
			var centre := SectorMap.center_of(cell)
			label.position = centre + Vector3.UP * _label_height(centre)
			label.visible = name_designed_sectors or terrain == null or terrain.design_at(Vector2(centre.x, centre.z)) == null
			add_child(label)
