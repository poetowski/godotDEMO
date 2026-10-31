@tool
class_name FieldTerrain
extends StaticBody3D
## The field's ground: one mesh and collision shape for the flat grass (the
## undesigned sectors and a wide ring around the grid), and for each designed
## sector a coarse stand-in, 1 m between samples, shown while its design's
## content isn't loaded, so distant hills keep their shape and nothing is
## left open, and the design's far model (FarModel) out to `far_distance`, so
## its landmarks stay on the horizon. Loaded designs bring their own detailed
## ground and hide both. Answers height
## and water questions for the whole field. Generated children have no
## owner, so the editor never saves them.
##
## In a big world (`chunked`), the open ground isn't one mesh: TerrainChunks
## streams it around `focus`, detailed near and coarse far, and a flat ring
## lies around the world's edge.
##
## In the editor the streamed ground shows too, around a focus the sculpting
## plugin moves with the view (`move_view_focus`), and follows the brush
## (`reshape_ground`, `finish_reshaping`).

const GRASS_SHADER := preload("res://src/world/field/grass_grid.gdshader")
## Samples along each side of a sector's stand-in.
const FAR_SAMPLES := 11

## The node whose SectorDesign children shape the ground.
@export var designs_root: Node3D
## How far the flat grass reaches past the grid on every side, in metres.
@export var margin: float = 900.0
## Metres out to which far models show, fading out over the last tenth.
@export var far_distance: float = 150.0
## Stream the open ground in tiles around `focus` (big worlds).
@export var chunked: bool = false
## Whose surroundings the streamed ground details.
@export var focus: Node3D
## Regions out to which the streamed ground is shown.
@export var view_regions: int = 6

static var _material: ShaderMaterial

var _collected := false
var _designs: Array[SectorDesign] = []
var _owners: Dictionary[Vector2i, SectorDesign] = {}
## Each designed cell's stand-in mesh and its collision.
var _stand_ins: Dictionary[Vector2i, Array] = {}
var _far_models: Dictionary[SectorDesign, MeshInstance3D] = {}
var _chunks: TerrainChunks
## What the streamed ground and the grid follow in the editor.
var _view_focus: Node3D


## The grass-and-grid material every piece of ground shares.
static func ground_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = GRASS_SHADER
	return _material


## In the editor nothing else has set up the world, and designs ask about
## their ground from their own _ready.
func _enter_tree() -> void:
	if Engine.is_editor_hint() and chunked:
		TerrainSculpt.editing = true
		FieldWorld.configure()


func _ready() -> void:
	add_to_group(&"terrains")
	_collect()
	if chunked:
		_build_border()
		_start_chunks()
	else:
		_build_flat()
	for cell: Vector2i in _owners.keys():
		_build_stand_in(cell, _owners[cell])
	for design in _designs:
		_build_far_model(design)
		design.content_changed.connect(_show_stand_ins.bind(design))
		_show_stand_ins(design.is_content_loaded(), design)


func designs() -> Array[SectorDesign]:
	_collect()
	return _designs


## The design owning the sector under a point, or null.
func design_at(xz: Vector2) -> SectorDesign:
	_collect()
	return _owners.get(SectorMap.unbounded_cell_at(xz))


func height_at(xz: Vector2) -> float:
	var design := design_at(xz)
	return design.height_at(xz) if design else WorldShape.height(xz)


## Height of the water surface at a point, or SectorDesign.NO_WATER.
func water_level_at(xz: Vector2) -> float:
	var design := design_at(xz)
	return design.water_level_at(xz) if design else Waters.level_at(xz)


## The ground or the water, whichever is higher.
func surface_height_at(xz: Vector2) -> float:
	return maxf(height_at(xz), water_level_at(xz))


func is_dry(xz: Vector2, margin_above_water: float = 0.05) -> bool:
	return height_at(xz) > water_level_at(xz) + margin_above_water


## The dry ground nearest to a point, searched in widening rings up to
## `search_radius` metres; the point itself if nothing dry is found.
func find_dry_spot(xz: Vector2, search_radius: float = 8.0) -> Vector2:
	if is_dry(xz, 0.1):
		return xz
	var radius := 0.5
	while radius <= search_radius:
		var steps := ceili(TAU * radius / 0.5)
		for k in steps:
			var angle := TAU * k / steps
			var candidate := xz + Vector2(cos(angle), sin(angle)) * radius
			if is_dry(candidate, 0.1):
				return candidate
		radius += 0.5
	return xz


## Builds the streamed ground around the focus at once (big worlds), for the
## start or after jumping somewhere else.
func prepare_around_focus() -> void:
	if _chunks:
		_chunks.build_now()


## The streamed ground, or null when the field is one mesh.
func chunks() -> TerrainChunks:
	return _chunks


## Where the editor's view is, for the streamed ground and the grid; null in
## the game.
func view_focus() -> Node3D:
	return _view_focus


func move_view_focus(point: Vector3) -> void:
	if _view_focus:
		_view_focus.global_position = point


## Follows the brush at once: the 1 m open ground under an area of samples
## (x, north), and if `designs_too`, designed sectors, which cost more.
func reshape_ground(area: Rect2i, designs_too: bool) -> void:
	if _chunks:
		_chunks.reshape(area)
	if designs_too:
		_reshape_designs(area)


## After a stroke: makes everything under an area of samples whole again.
func finish_reshaping(area: Rect2i) -> void:
	if _chunks:
		_chunks.rebuild(area)
	_reshape_designs(area)
	for node in get_tree().get_nodes_in_group(&"waters"):
		node.call(&"refresh")
	for node in get_tree().get_nodes_in_group(&"sector_grids"):
		node.call(&"refresh")


## The first place a ray meets the ground, or Vector3.INF. Walks in steps as
## long as a part of the height above the ground, then closes in.
func ground_hit(from: Vector3, direction: Vector3, reach: float = 4000.0) -> Vector3:
	var travelled := 0.0
	var previous := 0.0
	while travelled <= reach:
		var point := from + direction * travelled
		var gap := point.y - height_at(Vector2(point.x, point.z))
		if gap <= 0.0:
			if travelled == 0.0:
				return Vector3.INF
			var low := previous
			var high := travelled
			for k in 12:
				var middle := (low + high) * 0.5
				var probe := from + direction * middle
				if probe.y > height_at(Vector2(probe.x, probe.z)):
					low = middle
				else:
					high = middle
			return from + direction * high
		previous = travelled
		travelled += clampf(gap * 0.5, 0.25, 50.0)
	return Vector3.INF


## The far model shown for a design while its content is away, or null.
func far_model(design: SectorDesign) -> MeshInstance3D:
	return _far_models.get(design)


## True if a designed cell is showing its coarse stand-in.
func shows_stand_in(cell: Vector2i) -> bool:
	return _stand_ins.has(cell) and (_stand_ins[cell][0] as MeshInstance3D).visible


func _collect() -> void:
	if _collected:
		return
	_collected = true
	if designs_root == null:
		return
	for child in designs_root.get_children():
		var design := child as SectorDesign
		if design == null:
			continue
		design.bake()
		_designs.append(design)
		for cell in design.cells():
			if _owners.has(cell):
				push_error("Sector %s is claimed by both %s and %s" % [SectorMap.name_of(cell), _owners[cell].name, design.name])
				continue
			_owners[cell] = design


func _reshape_designs(area: Rect2i) -> void:
	for design in _designs:
		design.reshape_ground(area)


func _start_chunks() -> void:
	_chunks = TerrainChunks.new()
	_chunks.name = "Chunks"
	_chunks.body = self
	_chunks.focus = focus
	if Engine.is_editor_hint():
		_view_focus = Node3D.new()
		_view_focus.name = "ViewFocus"
		add_child(_view_focus)
		_chunks.focus = _view_focus
		_chunks.editable = true
	_chunks.height = WorldShape.height
	_chunks.is_designed = func(xz: Vector2) -> bool: return _owners.has(SectorMap.unbounded_cell_at(xz))
	_chunks.tint = Landforms.ground_tint
	_chunks.material = ground_material()
	_chunks.view_regions = view_regions
	add_child(_chunks)


## Four long flat strips around the world, where the land has eased flat.
func _build_border() -> void:
	var faces := PackedVector3Array()
	_add_border(faces)
	var normals := PackedVector3Array()
	for t in range(0, faces.size(), 3):
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	_add_ground("Border", arrays, faces, false)


func _add_border(faces: PackedVector3Array) -> void:
	var west := SectorMap.ORIGIN.x
	var south := SectorMap.ORIGIN.z
	var east := west + SectorMap.extent().x
	var north := south - SectorMap.extent().y
	_add_quad(faces, west - margin, south + margin, east + margin, south)
	_add_quad(faces, west - margin, north, east + margin, north - margin)
	_add_quad(faces, west - margin, south, west, north)
	_add_quad(faces, east, south, east + margin, north)


## Two triangles per undesigned sector, and four long strips around the grid.
func _build_flat() -> void:
	var faces := PackedVector3Array()
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var cell := Vector2i(column, row)
			if _owners.has(cell):
				continue
			var corner := SectorMap.corner_of(cell)
			if WorldShape.is_flat():
				_add_quad(faces, corner.x, corner.z, corner.x + SectorMap.SIZE, corner.z - SectorMap.SIZE)
			else:
				_add_shaped(faces, corner, func(xz: Vector2) -> float: return WorldShape.height(xz))
	_add_border(faces)
	var normals := PackedVector3Array()
	for t in range(0, faces.size(), 3):
		var normal := (faces[t + 2] - faces[t]).cross(faces[t + 1] - faces[t]).normalized()
		normals.append_array(PackedVector3Array([normal, normal, normal]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	_add_ground("Flat", arrays, faces, false)


## A flat rectangle from its south-west to its north-east corner.
func _add_quad(faces: PackedVector3Array, x0: float, z0: float, x1: float, z1: float) -> void:
	var south_west := Vector3(x0, 0.0, z0)
	var south_east := Vector3(x1, 0.0, z0)
	var north_west := Vector3(x0, 0.0, z1)
	var north_east := Vector3(x1, 0.0, z1)
	faces.append_array(PackedVector3Array([south_west, north_west, south_east, south_east, north_west, north_east]))


## A sector's ground at 1 m between samples, heights from `height`.
func _add_shaped(faces: PackedVector3Array, corner: Vector3, height: Callable) -> void:
	var step := SectorMap.SIZE / (FAR_SAMPLES - 1)
	var points := PackedVector3Array()
	for j in FAR_SAMPLES:
		for i in FAR_SAMPLES:
			var xz := Vector2(corner.x + i * step, corner.z - j * step)
			points.append(Vector3(xz.x, float(height.call(xz)), xz.y))
	for j in FAR_SAMPLES - 1:
		for i in FAR_SAMPLES - 1:
			var south_west := j * FAR_SAMPLES + i
			var north_west := south_west + FAR_SAMPLES
			for index: int in [south_west, north_west, south_west + 1, south_west + 1, north_west, north_west + 1]:
				faces.append(points[index])


## A designed sector's ground at 1 m, following its surface (water lies flat).
func _build_stand_in(cell: Vector2i, design: SectorDesign) -> void:
	var faces := PackedVector3Array()
	_add_shaped(faces, SectorMap.corner_of(cell), func(xz: Vector2) -> float: return maxf(design.height_at(xz), design.water_level_at(xz)))
	var normals := PackedVector3Array()
	for t in range(0, faces.size(), 3):
		var normal := (faces[t + 2] - faces[t]).cross(faces[t + 1] - faces[t]).normalized()
		normals.append_array(PackedVector3Array([normal, normal, normal]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	_stand_ins[cell] = _add_ground("Far" + SectorMap.node_name(cell), arrays, faces, false)


func _add_ground(node_name: String, arrays: Array, faces: PackedVector3Array, shadows: bool) -> Array:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = ground_material()
	if not shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = node_name + "Collision"
	collision.shape = shape
	add_child(collision)
	return [instance, collision]


func _build_far_model(design: SectorDesign) -> void:
	var mesh: Mesh = null if Engine.is_editor_hint() else BakedSectors.load_far(design.name)
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = "Far" + design.name
	instance.mesh = mesh
	instance.material_override = MeshKit.lowpoly_material(Color.WHITE, 0.9)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = far_distance
	instance.visibility_range_end_margin = far_distance * 0.1
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	_far_models[design] = instance


## Shows a design's stand-ins and far model while its content is away, and
## hides them (and the stand-ins' collision) while it's loaded.
func _show_stand_ins(loaded: bool, design: SectorDesign) -> void:
	if _far_models.has(design):
		_far_models[design].visible = not loaded
	for cell in design.cells():
		if not _stand_ins.has(cell):
			continue
		(_stand_ins[cell][0] as MeshInstance3D).visible = not loaded
		(_stand_ins[cell][1] as CollisionShape3D).set_deferred(&"disabled", loaded)
