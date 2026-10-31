@tool
extends Node3D
## Draws the sector grid above the ground: a curtain of light rising from every
## grid line, and each sector's name painted flat in its centre. Both follow
## the terrain and any water. Names are hidden in sectors a design owns, where
## they would hover over its ground; the HUD still names them. The lines on
## the ground come from the grass shader. Generated children have no owner, so
## the editor never saves them.
##
## It covers one region (RegionMap) at a time: the one `focus` stands in,
## rebuilt when the focus walks into another. The main field is one region.
## The first region is built at once; later ones are worked out on a worker
## thread (the ground sampling is the slow part) and swapped in when ready.
##
## Every region's borders and name show at once, in gold (`_build_region_marks`):
## always in the game; in the editor the names wait until the view is too far out
## for the sectors' names.

const CURTAIN_SHADER := preload("res://src/world/field/light_curtain.gdshader")
## Metres between the points where a curtain meets a design's ground.
const CURTAIN_STEP := 0.5
## ...and where it meets the open hills, which are smoother.
const HILL_STEP := 2.0
## Half the size of a painted name, in metres east and north.
const LABEL_HALF_SIZE := Vector2(1.1, 0.9)
const REGION_COLOR := Color(1.0, 0.72, 0.28)
const REGION_CURTAIN_HEIGHT := 10.0
const BORDER_COLOR := Color(1.0, 0.12, 0.08)
const BORDER_CURTAIN_HEIGHT := 7.0
## A region's big name in its middle, and how far its small names stand inside
## each border, to read on crossing it.
const REGION_NAME_PIXEL := 0.4
const REGION_NEAR_NAME_PIXEL := 0.07
const REGION_NEAR_NAME_INSET := 14.0
## Worlds bigger than this are stress tests; they get no region marks.
const MOST_REGIONS_MARKED := 25

## The ground the grid stands on; flat at height 0 when unset.
@export var terrain: FieldTerrain
@export var curtain_height: float = 3.0
@export var label_color: Color = Color(0.75, 0.95, 1.0, 0.6)
@export var label_visible_distance: float = 70.0
## Paint names in designed sectors too.
@export var name_designed_sectors: bool = false
## Whose region the grid shows; R1 when unset.
@export var focus: Node3D

var _region := RegionMap.NONE
var _curtains: MeshInstance3D
## Every sector's painted name by its place in the region; the same names
## serve every region, moved over when the region changes.
var _labels: Array[Label3D] = []
## The region being worked out on a worker thread, its task, and the result.
var _pending := RegionMap.NONE
var _task := -1
var _result: Dictionary = {}
var _region_marks: Node3D


func _ready() -> void:
	add_to_group(&"sector_grids")
	_show_region(_focus_region())
	_build_region_marks()


func _process(_delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if _pending == _focus_region():
			_apply(_pending, _result)
		_pending = RegionMap.NONE
	var region := _focus_region()
	if region != _region and region != _pending and region != RegionMap.NONE and _task < 0:
		_pending = region
		_task = WorkerThreadPool.add_task(_work_out.bind(region))


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


## The region whose grid is shown.
func region() -> Vector2i:
	return _region


## Stands the grid on the ground again, once the ground changed.
func refresh() -> void:
	_region = RegionMap.NONE
	_build_region_marks()


func _focus_region() -> Vector2i:
	var follow := focus
	if terrain and terrain.view_focus():
		follow = terrain.view_focus()
	if follow == null or not follow.is_inside_tree():
		return Vector2i.ZERO
	return RegionMap.at(follow.global_position)


func _show_region(shown: Vector2i) -> void:
	_apply(shown, _work_out(shown))


## The region's curtain geometry and its names' places: reads the ground
## only, so it runs on a worker thread.
func _work_out(shown: Vector2i) -> Dictionary:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var origin := RegionMap.corner_of(shown)
	var side := RegionMap.SIZE
	for i in SectorMap.COLUMNS + 1:
		var x := origin.x + i * SectorMap.SIZE
		_add_curtain(vertices, colors, Vector3(x, 0.0, origin.z), Vector3(x, 0.0, origin.z - side))
	for j in SectorMap.ROWS + 1:
		var z := origin.z - j * SectorMap.SIZE
		_add_curtain(vertices, colors, Vector3(origin.x, 0.0, z), Vector3(origin.x + side, 0.0, z))
	var places := PackedVector3Array()
	var shown_names: Array[bool] = []
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var centre := SectorMap.center_of(RegionMap.first_cell(shown) + Vector2i(column, row))
			places.append(centre + Vector3.UP * _label_height(centre))
			shown_names.append(name_designed_sectors or terrain == null or terrain.design_at(Vector2(centre.x, centre.z)) == null)
	_result = {"vertices": vertices, "colors": colors, "places": places, "shown": shown_names}
	return _result


## Shows a worked-out region: the new curtains, the names moved over.
func _apply(shown: Vector2i, worked: Dictionary) -> void:
	_region = shown
	if _curtains:
		_curtains.queue_free()
	_build_curtains(worked["vertices"], worked["colors"])
	if _labels.is_empty():
		_build_labels()
	var places: PackedVector3Array = worked["places"]
	var shown_names: Array[bool] = []
	shown_names.assign(worked["shown"])
	for k in _labels.size():
		_labels[k].position = places[k]
		_labels[k].visible = shown_names[k]


func _build_curtains(vertices: PackedVector3Array, colors: PackedColorArray) -> void:
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
	_curtains = curtains


## Gold curtains on every region border and each region's name.
func _build_region_marks() -> void:
	if _region_marks:
		_region_marks.free()
	_region_marks = null
	if RegionMap.count() <= 1 or RegionMap.count() > MOST_REGIONS_MARKED:
		return
	_region_marks = Node3D.new()
	_region_marks.name = "RegionMarks"
	add_child(_region_marks)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var bounds := SectorMap.bounds()
	for i in RegionMap.columns + 1:
		var x := bounds.position.x + i * RegionMap.SIZE
		_add_curtain(vertices, colors, Vector3(x, 0.0, -bounds.position.y), Vector3(x, 0.0, -bounds.end.y), REGION_CURTAIN_HEIGHT)
	for j in RegionMap.rows + 1:
		var z := -bounds.position.y - j * RegionMap.SIZE
		_add_curtain(vertices, colors, Vector3(bounds.position.x, 0.0, z), Vector3(bounds.end.x, 0.0, z), REGION_CURTAIN_HEIGHT)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = CURTAIN_SHADER
	material.set_shader_parameter(&"color", REGION_COLOR)
	material.set_shader_parameter(&"intensity", 0.4)
	material.set_shader_parameter(&"far_fade_start", 500.0)
	material.set_shader_parameter(&"far_fade_end", 1600.0)
	var curtains := MeshInstance3D.new()
	curtains.name = "RegionCurtains"
	curtains.mesh = mesh
	curtains.material_override = material
	curtains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_region_marks.add_child(curtains)
	if ZoneBorder.applies():
		_add_border_lines()
	for j in RegionMap.rows:
		for i in RegionMap.columns:
			_add_region_names(RegionMap.south_west + Vector2i(i, j))


## Red curtains on the two lines of the player's border (ZoneBorder).
func _add_border_lines() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var bounds := SectorMap.bounds()
	for x: float in [ZoneBorder.WEST_WARN_X, ZoneBorder.WEST_RETURN_X]:
		_add_curtain(vertices, colors, Vector3(x, 0.0, -bounds.position.y), Vector3(x, 0.0, -bounds.end.y), BORDER_CURTAIN_HEIGHT)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = CURTAIN_SHADER
	material.set_shader_parameter(&"color", BORDER_COLOR)
	material.set_shader_parameter(&"intensity", 0.9)
	material.set_shader_parameter(&"falloff", 1.5)
	material.set_shader_parameter(&"near_fade_start", 0.5)
	material.set_shader_parameter(&"near_fade_end", 3.0)
	material.set_shader_parameter(&"far_fade_start", 500.0)
	material.set_shader_parameter(&"far_fade_end", 1600.0)
	var lines := MeshInstance3D.new()
	lines.name = "BorderLines"
	lines.mesh = mesh
	lines.material_override = material
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_region_marks.add_child(lines)


func _add_region_names(shown: Vector2i) -> void:
	var centre := RegionMap.center_of(shown)
	var region_name := RegionMap.name_of(shown)
	_add_region_name(region_name, centre, REGION_NAME_PIXEL, true)
	var reach := RegionMap.SIZE * 0.5 - REGION_NEAR_NAME_INSET
	for side: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		_add_region_name(region_name, centre + side * reach, REGION_NEAR_NAME_PIXEL, false)


func _add_region_name(region_name: String, place: Vector3, pixel: float, over_everything: bool) -> void:
	var label := Label3D.new()
	label.name = "%s_%d_%d" % [region_name, roundi(place.x), roundi(place.z)]
	label.text = region_name
	label.font_size = 96
	label.pixel_size = pixel
	label.outline_size = 0
	label.modulate = Color(REGION_COLOR, 0.55 if over_everything else 0.8)
	label.double_sided = true
	label.no_depth_test = over_everything
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if Engine.is_editor_hint():
		label.visibility_range_begin = label_visible_distance
		label.visibility_range_begin_margin = 10.0
		label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	label.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	label.position = place + Vector3.UP * (_surface(Vector2(place.x, place.z)) + 0.6)
	_region_marks.add_child(label)


## A curtain standing on the ground along the line from `a` to `b`, opaque at
## the ground and transparent at the top: a strip of quads that bends with
## shaped ground and stays one quad where the ground is flat. Only the
## sector-long spans beside a design are sampled.
func _add_curtain(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, height: float = -1.0) -> void:
	var spans := roundi(a.distance_to(b) / SectorMap.SIZE)
	var across := (b - a).normalized().cross(Vector3.UP) * 0.01
	var feet: Array[Vector3] = [a]
	for s in spans:
		var from := a.lerp(b, float(s) / spans)
		var to := a.lerp(b, float(s + 1) / spans)
		var middle := from.lerp(to, 0.5)
		var designed := _is_designed(middle + across) or _is_designed(middle - across)
		if not (designed or _is_shaped()):
			_add_foot(feet, to)
			continue
		var pieces := ceili(SectorMap.SIZE / (CURTAIN_STEP if designed else HILL_STEP))
		for k in range(1, pieces + 1):
			var point := from.lerp(to, float(k) / pieces)
			point.y = _surface(Vector2(point.x, point.z))
			_add_foot(feet, point)
	var up := Vector3.UP * (height if height > 0.0 else curtain_height)
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


## True when the land has hills everywhere, so every curtain follows it.
func _is_shaped() -> bool:
	return terrain != null and not WorldShape.is_flat()


func _is_designed(point: Vector3) -> bool:
	return terrain != null and terrain.design_at(Vector2(point.x, point.z)) != null


## Just above the highest ground or water under a painted name: sampled
## around it on a design's ground, at its middle on the smooth open hills.
func _label_height(centre: Vector3) -> float:
	if not _is_designed(centre):
		return _surface(Vector2(centre.x, centre.z)) + 0.25 if _is_shaped() else 0.03
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
			label.name = "Label" + SectorMap.local_name(cell)
			label.text = SectorMap.local_name(cell)
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
			add_child(label)
			_labels.append(label)
