@tool
class_name FieldTerrain
extends StaticBody3D
## The field's ground: flat grass everywhere, reshaped inside the sectors a
## SectorDesign owns. Builds one mesh and collision shape for the flat part
## (the undesigned sectors and a wide ring around the grid) and one of each per
## designed sector, all painted by the grass-and-grid shader. Answers height and
## water questions for the whole field. Generated children have no owner, so
## the editor never saves them.

const GRASS_SHADER := preload("res://src/world/field/grass_grid.gdshader")

## The node whose SectorDesign children shape the ground.
@export var designs_root: Node3D
## How far the flat grass reaches past the grid on every side, in metres.
@export var margin: float = 900.0

var _collected := false
var _designs: Array[SectorDesign] = []
var _owners: Dictionary[Vector2i, SectorDesign] = {}


func _ready() -> void:
	_collect()
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	_build_flat(material)
	for cell: Vector2i in _owners.keys():
		_build_shaped(cell, _owners[cell], material)


func designs() -> Array[SectorDesign]:
	_collect()
	return _designs


## The design owning the sector under a point, or null.
func design_at(xz: Vector2) -> SectorDesign:
	_collect()
	return _owners.get(SectorMap.unbounded_cell_at(xz))


func height_at(xz: Vector2) -> float:
	var design := design_at(xz)
	return design.height_at(xz) if design else 0.0


## Height of the water surface at a point, or SectorDesign.NO_WATER.
func water_level_at(xz: Vector2) -> float:
	var design := design_at(xz)
	return design.water_level_at(xz) if design else SectorDesign.NO_WATER


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


## Two triangles per undesigned sector, and four long strips around the grid.
func _build_flat(material: Material) -> void:
	var faces := PackedVector3Array()
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var cell := Vector2i(column, row)
			if not _owners.has(cell):
				var corner := SectorMap.corner_of(cell)
				_add_quad(faces, corner.x, corner.z, corner.x + SectorMap.SIZE, corner.z - SectorMap.SIZE)
	var west := SectorMap.ORIGIN.x
	var south := SectorMap.ORIGIN.z
	var east := west + SectorMap.extent().x
	var north := south - SectorMap.extent().y
	_add_quad(faces, west - margin, south + margin, east + margin, south)
	_add_quad(faces, west - margin, north, east + margin, north - margin)
	_add_quad(faces, west - margin, south, west, north)
	_add_quad(faces, east, south, east + margin, north)
	var normals := PackedVector3Array()
	normals.resize(faces.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	_add_ground("Flat", arrays, faces, material, false)


## A flat rectangle from its south-west to its north-east corner.
func _add_quad(faces: PackedVector3Array, x0: float, z0: float, x1: float, z1: float) -> void:
	var south_west := Vector3(x0, 0.0, z0)
	var south_east := Vector3(x1, 0.0, z0)
	var north_west := Vector3(x0, 0.0, z1)
	var north_east := Vector3(x1, 0.0, z1)
	faces.append_array(PackedVector3Array([south_west, north_west, south_east, south_east, north_west, north_east]))


## The ground of one designed sector, from its design's samples.
func _build_shaped(cell: Vector2i, design: SectorDesign, material: Material) -> void:
	var samples := SectorDesign.SAMPLES
	var step := SectorDesign.RESOLUTION
	var heights := design.heights_of(cell)
	var corner := SectorMap.corner_of(cell)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for j in samples:
		for i in samples:
			var k := j * samples + i
			var xz := Vector2(corner.x + i * step, corner.z - j * step)
			vertices.append(Vector3(xz.x, heights[k], xz.y))
			# Row j + 1 lies to the north. Border samples look into the
			# neighbouring sector, so normals match across the seam.
			var east_slope: float
			var south_slope: float
			if i > 0 and i < samples - 1 and j > 0 and j < samples - 1:
				east_slope = heights[k + 1] - heights[k - 1]
				south_slope = heights[k - samples] - heights[k + samples]
			else:
				east_slope = height_at(xz + Vector2(step, 0.0)) - height_at(xz - Vector2(step, 0.0))
				south_slope = height_at(xz + Vector2(0.0, step)) - height_at(xz - Vector2(0.0, step))
			normals.append(Vector3(-east_slope, 2.0 * step, -south_slope).normalized())
	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	for j in samples - 1:
		for i in samples - 1:
			var south_west := j * samples + i
			var north_west := south_west + samples
			for index: int in [south_west, north_west, south_west + 1, south_west + 1, north_west, north_west + 1]:
				indices.append(index)
				faces.append(vertices[index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = design.tints_of(cell)
	arrays[Mesh.ARRAY_INDEX] = indices
	_add_ground(SectorMap.name_of(cell), arrays, faces, material, true)


func _add_ground(node_name: String, arrays: Array, faces: PackedVector3Array, material: Material, shadows: bool) -> void:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	if not shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = node_name + "Collision"
	collision.shape = shape
	add_child(collision)
