@tool
class_name MistBarrier
extends Node3D
## The fog over the western drop: a volume filling the polygon on the far side of
## a line of points along the drop's rim, thin near the line and thickening with
## distance from it, so the first sectors can be seen through and then less and
## less. A wall inside the thick part stops the player.
##
## The line is the Marker3D children of `FogLine`, north to south and then east,
## with the fog on its right-hand side. Drag them in the editor and the fog
## follows; duplicate one to add a point, in order in the scene tree. Generated
## children have no owner, so the editor never saves them.

const SHADER := preload("res://src/world/field/mist_volume.gdshader")
## How far past the world the polygon reaches, in metres, so the fog also hides
## the flat land around it.
const BEYOND := 300.0
const TOP := 40.0
const BOTTOM := -240.0
## Metres per texel of the map of distances from the line.
const MAP_STEP := 4.0
## Metres into the fog at which the wall stands.
const WALL_DEPTH := 62.0
const WALL_TOP := 80.0
const WALL_THICKNESS := 2.0
## Seconds between looks at whether the points moved, in the editor.
const WATCH_INTERVAL := 0.3

var _material: ShaderMaterial
var _fog: MeshInstance3D
var _wall: StaticBody3D
var _guide: MeshInstance3D
var _built_line := PackedVector2Array()
var _watch := 0.0
var _map_rect := Rect2()
var _distances := PackedFloat32Array()
var _map_size := Vector2i.ZERO


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(delta: float) -> void:
	_watch -= delta
	if _watch > 0.0:
		return
	_watch = WATCH_INTERVAL
	if line() != _built_line:
		rebuild()


## The line of points (world x and z), in order.
func line() -> PackedVector2Array:
	var points := PackedVector2Array()
	var holder := get_node_or_null("FogLine")
	if holder:
		for child in holder.get_children():
			var marker := child as Node3D
			if marker:
				points.append(Vector2(marker.position.x, marker.position.z))
	return points


## Metres into the fog at a world x and z; 0 outside it.
func depth_at(xz: Vector2) -> float:
	if _distances.is_empty():
		return 0.0
	var at := Vector2i((xz - _map_rect.position) / MAP_STEP)
	if at.x < 0 or at.y < 0 or at.x >= _map_size.x or at.y >= _map_size.y:
		return 0.0
	return _distances[at.y * _map_size.x + at.x]


## Makes the fog and the wall again from the line as it is now.
func rebuild() -> void:
	var points := line()
	_built_line = points
	if points.size() < 2:
		return
	var polygon := _polygon(points)
	var triangles := Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		push_warning("MistBarrier: the fog's line crosses itself, so the fog stays as it was")
		return
	_read_distances(points, polygon)
	_show_fog(polygon, triangles)
	_show_wall(points)
	if Engine.is_editor_hint():
		_show_guide(points)


## The line, closed around the far side, past the world.
func _polygon(points: PackedVector2Array) -> PackedVector2Array:
	var bounds := SectorMap.bounds()
	var west := bounds.position.x - BEYOND
	# World z runs south, so a norths' end is a small z.
	var north_z := -bounds.end.y - BEYOND
	var south_z := -bounds.position.y + BEYOND
	var polygon := points.duplicate()
	polygon.append(Vector2(polygon[polygon.size() - 1].x, south_z))
	polygon.append(Vector2(west, south_z))
	polygon.append(Vector2(west, north_z))
	polygon.append(Vector2(points[0].x, north_z))
	return polygon


## Metres from the line, inside the polygon, by sweeping across the map twice; the
## closing sides past the world don't count as an edge.
func _read_distances(points: PackedVector2Array, polygon: PackedVector2Array) -> void:
	var low := polygon[0]
	var high := polygon[0]
	for point in polygon:
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	_map_rect = Rect2(low, high - low)
	_map_size = Vector2i(ceili(_map_rect.size.x / MAP_STEP) + 1, ceili(_map_rect.size.y / MAP_STEP) + 1)
	var columns := _map_size.x
	var field := PackedFloat32Array()
	field.resize(columns * _map_size.y)
	field.fill(1e6)
	for s in points.size() - 1:
		var steps := ceili(points[s].distance_to(points[s + 1]) / (MAP_STEP * 0.5))
		for k in steps + 1:
			var at := Vector2i((points[s].lerp(points[s + 1], float(k) / steps) - low) / MAP_STEP)
			field[at.y * columns + at.x] = 0.0
	var straight := MAP_STEP
	var diagonal := MAP_STEP * sqrt(2.0)
	for j in range(1, _map_size.y - 1):
		for i in range(1, columns - 1):
			var k := j * columns + i
			field[k] = minf(field[k], minf(minf(field[k - 1] + straight, field[k - columns] + straight), minf(field[k - columns - 1] + diagonal, field[k - columns + 1] + diagonal)))
	for j in range(_map_size.y - 2, 0, -1):
		for i in range(columns - 2, 0, -1):
			var k := j * columns + i
			field[k] = minf(field[k], minf(minf(field[k + 1] + straight, field[k + columns] + straight), minf(field[k + columns + 1] + diagonal, field[k + columns - 1] + diagonal)))
	for j in _map_size.y:
		for i in columns:
			if not Geometry2D.is_point_in_polygon(low + Vector2(i, j) * MAP_STEP, polygon):
				field[j * columns + i] = 0.0
	_distances = field


func _show_fog(polygon: PackedVector2Array, triangles: PackedInt32Array) -> void:
	var vertices := PackedVector3Array()
	for k in range(0, triangles.size(), 3):
		var a := polygon[triangles[k]]
		var b := polygon[triangles[k + 1]]
		var c := polygon[triangles[k + 2]]
		_add_triangle(vertices, Vector3(a.x, TOP, a.y), Vector3(b.x, TOP, b.y), Vector3(c.x, TOP, c.y), Vector3.UP)
		_add_triangle(vertices, Vector3(a.x, BOTTOM, a.y), Vector3(b.x, BOTTOM, b.y), Vector3(c.x, BOTTOM, c.y), Vector3.DOWN)
	# Which way is out of the polygon depends on which way it winds.
	var out := 1.0 if Geometry2D.is_polygon_clockwise(polygon) else -1.0
	for k in polygon.size():
		var a := polygon[k]
		var b := polygon[(k + 1) % polygon.size()]
		var along := (b - a).normalized()
		var outward := Vector3(-along.y, 0.0, along.x) * out
		_add_triangle(vertices, Vector3(a.x, BOTTOM, a.y), Vector3(b.x, BOTTOM, b.y), Vector3(a.x, TOP, a.y), outward)
		_add_triangle(vertices, Vector3(b.x, BOTTOM, b.y), Vector3(b.x, TOP, b.y), Vector3(a.x, TOP, a.y), outward)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if _fog == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		# After the water and everything else that's see-through.
		_material.render_priority = 10
		var billows := NoiseTexture2D.new()
		billows.seamless = true
		billows.width = 256
		billows.height = 256
		var noise := FastNoiseLite.new()
		noise.frequency = 0.012
		noise.fractal_octaves = 4
		billows.noise = noise
		_material.set_shader_parameter(&"billows", billows)
		_fog = MeshInstance3D.new()
		_fog.name = "Fog"
		_fog.material_override = _material
		_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_fog)
	_fog.mesh = mesh
	var map := Image.create_empty(_map_size.x, _map_size.y, false, Image.FORMAT_RF)
	map.set_data(_map_size.x, _map_size.y, false, Image.FORMAT_RF, _distances.to_byte_array())
	_material.set_shader_parameter(&"distance_map", ImageTexture.create_from_image(map))
	# The map's first texel's middle, and its size between first and last middles.
	var bounds := SectorMap.bounds()
	_material.set_shader_parameter(&"world_edges", Vector4(bounds.position.x, -bounds.end.y, bounds.end.x, -bounds.position.y))
	_material.set_shader_parameter(&"map_rect", Vector4(_map_rect.position.x - MAP_STEP * 0.5, _map_rect.position.y - MAP_STEP * 0.5, _map_size.x * MAP_STEP, _map_size.y * MAP_STEP))


## One triangle, wound to face `outward`.
func _add_triangle(vertices: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	if (c - a).cross(b - a).dot(outward) >= 0.0:
		vertices.append_array(PackedVector3Array([a, b, c]))
	else:
		vertices.append_array(PackedVector3Array([a, c, b]))


## The wall runs along the line, moved into the fog. Pieces that would land too
## near the line, in its tight bends, are left out: others stand behind them.
func _show_wall(points: PackedVector2Array) -> void:
	if _wall:
		_wall.free()
	_wall = StaticBody3D.new()
	_wall.name = "Wall"
	add_child(_wall)
	for k in points.size() - 1:
		var a := _into_fog(points, k, k)
		var b := _into_fog(points, k, k + 1)
		var middle := a.lerp(b, 0.5)
		if depth_at(middle) < WALL_DEPTH * 0.6:
			continue
		var shape := BoxShape3D.new()
		shape.size = Vector3(a.distance_to(b) + WALL_THICKNESS * 4.0, WALL_TOP - BOTTOM, WALL_THICKNESS)
		var piece := CollisionShape3D.new()
		piece.shape = shape
		piece.position = Vector3(middle.x, (WALL_TOP + BOTTOM) * 0.5, middle.y)
		piece.rotation.y = -atan2(b.y - a.y, b.x - a.x)
		_wall.add_child(piece)


## Point `at` of the line, moved into the fog along segment `segment`'s right side.
func _into_fog(points: PackedVector2Array, segment: int, at: int) -> Vector2:
	var along := (points[segment + 1] - points[segment]).normalized()
	# World z runs south, so on the ground the right-hand side is (-z, x).
	return points[at] + Vector2(-along.y, along.x) * WALL_DEPTH


## A bright line along the points, in the editor only, to see where they run.
func _show_guide(points: PackedVector2Array) -> void:
	if _guide == null:
		_guide = MeshInstance3D.new()
		_guide.name = "Guide"
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.albedo_color = Color(1.0, 0.25, 0.85)
		look.no_depth_test = true
		_guide.material_override = look
		_guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_guide)
	var vertices := PackedVector3Array()
	for point in points:
		vertices.append(Vector3(point.x, WorldShape.height(point) + 1.0, point.y))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	_guide.mesh = mesh
