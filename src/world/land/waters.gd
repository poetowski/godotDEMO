@tool
class_name Waters
extends Node3D
## Draws the water of every region design: its waterfalls
## (LandformSet.waterfalls), a sheet of streaming water draped over the
## ground from the top to the bottom, a pool where it lands, and spray; and
## its lakes (LandformSet.lakes), a still surface following each lake's
## wavering shore; and the water poured into the land as it lies (WaterField),
## with its flowing rivers. Built once when the world starts, from WorldShape's
## heights, so they show from any distance like the land, and again in the
## editor when the land is sculpted.

const WATER := Color(0.55, 0.75, 0.85)
## Metres between the sheet's rows down the slope.
const STEP := 0.75
## How far the sheet stands off the ground: up and toward the fall's front.
const LIFT := 0.9
const OUT := 1.2
## The look of water poured into the land.
const POURED_RIPPLE_SIZE := 2.2
const POURED_RIPPLE_STRENGTH := 0.022

var _sheet_material: ShaderMaterial
var _pool_material: StandardMaterial3D
var _lake_material: StandardMaterial3D
var _poured: MeshInstance3D


func _ready() -> void:
	add_to_group(&"waters")
	_sheet_material = ShaderMaterial.new()
	_sheet_material.shader = preload("res://src/world/land/waterfall.gdshader")
	_pool_material = StandardMaterial3D.new()
	_pool_material.albedo_color = Color(0.2, 0.45, 0.5, 0.82)
	_pool_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pool_material.roughness = 0.08
	_pool_material.metallic_specular = 0.8
	_lake_material = _pool_material.duplicate() as StandardMaterial3D
	_lake_material.albedo_color = Color(0.18, 0.38, 0.48, 0.88)
	for landform_set in Landforms.sets():
		for k in landform_set.waterfalls.size():
			_build(landform_set.waterfalls[k], "%s_%d" % [landform_set.id, k])
		for k in landform_set.lakes.size():
			_build_lake(landform_set.lakes[k], "%s_%d" % [landform_set.id, k])
	_show_poured_water()


## Pours the water again over the land as it is now.
func refresh() -> void:
	WaterField.rebuild()
	_show_poured_water()


## The surface of a lake or a waterfall's pool at a world x and z, or
## NO_WATER.
static func level_at(xz: Vector2) -> float:
	var poured := WaterField.level_at(xz)
	if poured != SectorDesign.NO_WATER:
		return poured
	var lake := Landforms.lake_level(xz)
	if lake != SectorDesign.NO_WATER:
		return lake
	for landform_set in Landforms.sets():
		for fall in landform_set.waterfalls:
			var bottom := Vector2(fall.bottom.x, -fall.bottom.y)
			if xz.distance_to(bottom) < fall.pool_radius:
				return WorldShape.height(bottom) + fall.pool_depth
	return SectorDesign.NO_WATER


## Waterfalls drawn.
func count() -> int:
	return find_children("Sheet_*", "", false, false).size()


## Lakes drawn.
func lake_count() -> int:
	return find_children("Lake_*", "", false, false).size()


func _show_poured_water() -> void:
	if _poured == null:
		_poured = MeshInstance3D.new()
		_poured.name = "PouredWater"
		var material := NatureKit.water_material()
		# Wide water: bigger, calmer ripples than the shader's small streams.
		material.set_shader_parameter("ripple_size", POURED_RIPPLE_SIZE)
		material.set_shader_parameter("ripple_strength", POURED_RIPPLE_STRENGTH)
		_poured.material_override = material
		_poured.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_poured)
	_poured.mesh = WaterField.mesh()


func _build_lake(lake: Lake, key: String) -> void:
	var segments := 96
	var vertices := PackedVector3Array()
	var middle := Vector3(lake.centre.x, lake.level, -lake.centre.y)
	for k in segments:
		var a := TAU * k / segments
		var b := TAU * (k + 1) / segments
		vertices.append(middle)
		vertices.append(_shore_point(lake, b))
		vertices.append(_shore_point(lake, a))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var water := MeshInstance3D.new()
	water.name = "Lake_" + key
	water.mesh = mesh
	water.material_override = _lake_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _shore_point(lake: Lake, angle: float) -> Vector3:
	var direction := Vector2(cos(angle), sin(angle))
	var north := lake.centre + direction * lake.shore(lake.centre + direction) * Lake.WATER
	return Vector3(north.x, lake.level, -north.y)


func _build(fall: Waterfall, key: String) -> void:
	var top := Vector2(fall.top.x, -fall.top.y)
	var bottom := Vector2(fall.bottom.x, -fall.bottom.y)
	var pool_level := WorldShape.height(bottom) + fall.pool_depth
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet_" + key
	sheet.mesh = _sheet(top, bottom, fall.width, pool_level)
	sheet.material_override = _sheet_material
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sheet)
	var pool := MeshInstance3D.new()
	pool.name = "Pool_" + key
	var disc := CylinderMesh.new()
	disc.top_radius = fall.pool_radius
	disc.bottom_radius = fall.pool_radius
	disc.height = 0.05
	disc.radial_segments = 20
	disc.rings = 1
	pool.mesh = disc
	pool.material_override = _pool_material
	pool.position = Vector3(bottom.x, pool_level, bottom.y)
	add_child(pool)
	add_child(_spray("Spray_" + key, Vector3(bottom.x, pool_level, bottom.y), fall.width))


## A strip down the ground from top to bottom: each row as high as the
## highest ground across it, lifted off it, and ending at the pool. UV.y
## counts metres down, for the shader's streaks.
func _sheet(top: Vector2, bottom: Vector2, width: float, pool_level: float) -> ArrayMesh:
	var along := bottom - top
	var down := along.normalized()
	var across := Vector2(-down.y, down.x)
	var rows := maxi(2, int(along.length() / STEP))
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var travelled := 0.0
	var previous := Vector3.ZERO
	for row in rows + 1:
		var centre := top + along * float(row) / rows
		var ground := -INF
		for k in 5:
			ground = maxf(ground, WorldShape.height(centre + across * width * (float(k) / 4.0 - 0.5)))
		var lifted := maxf(ground + LIFT, pool_level)
		var middle := Vector3(centre.x + down.x * OUT, lifted, centre.y + down.y * OUT)
		if row > 0:
			travelled += middle.distance_to(previous)
		previous = middle
		for side: float in [-0.5, 0.5]:
			var offset := across * width * side
			vertices.append(middle + Vector3(offset.x, 0.0, offset.y))
			uvs.append(Vector2(side + 0.5, travelled))
	var indices := PackedInt32Array()
	for row in rows:
		var a := row * 2
		indices.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## White spray rising where the water lands.
func _spray(node_name: String, at: Vector3, width: float) -> GPUParticles3D:
	var spray := GPUParticles3D.new()
	spray.name = node_name
	spray.position = at
	spray.amount = 90
	spray.lifetime = 2.4
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(width * 0.45, 0.3, 1.5)
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 40.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 2.6
	process.gravity = Vector3(0.0, -0.6, 0.0)
	process.scale_min = 1.5
	process.scale_max = 3.5
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.45))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	spray.process_material = process
	var puff := QuadMesh.new()
	puff.size = Vector2.ONE
	var look := StandardMaterial3D.new()
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.vertex_color_use_as_albedo = true
	look.albedo_color = Color(0.95, 0.97, 1.0)
	puff.material = look
	spray.draw_pass_1 = puff
	spray.visibility_aabb = AABB(Vector3(-width, -2, -width), Vector3(width * 2, 12, width * 2))
	return spray
