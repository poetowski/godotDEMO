@tool
class_name TerrainChunks
extends Node
## Streams the open ground of a big world in tiles, detailed near `focus`
## and coarser with distance, so the whole world's ground is never in memory
## at once:
##   the 3 x 3 regions around the focus are cut into 100 m chunks, with
##   collision, sampled every metre next to the focus and every 4 m beyond;
##   farther regions are single 200 m tiles, sampled every 8 m and then
##   every 20 m, out to `view_regions` regions.
## Each tile hangs a skirt down from its edges, hiding the cracks where tiles
## of different detail meet. Tiles are built on worker threads and attached a
## few per frame. Designed sectors are left open: their designs bring their
## own ground. Heights come from `height` (the world's shape).
##
## In the editor (`editable`) the tiles keep their triangles, so sculpting can
## change the few under the brush at once (`reshape`); `rebuild` then makes
## the touched tiles over, skirts and collision included.

## Metres along a near chunk's side.
const CHUNK := 100.0
## How far the skirts reach below the edges, in metres.
const SKIRT := 4.0
## Tiles attached per frame at most.
const ATTACH_PER_FRAME := 2

## The body that gets the tiles' meshes and collision shapes.
var body: StaticBody3D
## Whose surroundings are detailed.
var focus: Node3D
## Height of the open ground at a world x and z. Must be safe to call from
## worker threads.
var height: Callable
## True for a cell a design owns (left open). Safe on worker threads.
var is_designed: Callable
## The ground's colour for the grass shader at (xz, height, up), such as
## rock on steep slopes; plain grass when unset. Safe on worker threads.
var tint: Callable
var material: Material
## Regions out to which tiles are shown.
var view_regions: int = 6
## Seconds between checks of what should be shown.
var check_interval: float = 0.25
## Keep each 1 m tile's triangles for `reshape`, which costs memory.
var editable: bool = false

## Tiles shown or being built: key -> {"step", "mesh", "collision", "building",
## "build"}, and when `editable`, {"faces", "normals", "colors", "quads"}.
var _tiles: Dictionary[Vector3i, Dictionary] = {}
var _done: Array[Dictionary] = []
var _mutex := Mutex.new()
var _tasks: Array[int] = []
var _timer := 0.0


func _process(delta: float) -> void:
	_attach_done()
	_timer -= delta
	if _timer <= 0.0:
		_timer = check_interval
		update()


func _exit_tree() -> void:
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()


## Works out which tiles should be shown at which detail, starts building
## the missing ones and drops the ones no longer wanted.
func update() -> void:
	var wanted := wanted_tiles(_focus_xz())
	for key: Vector3i in _tiles.keys():
		if not wanted.has(key):
			_drop(key)
	for key: Vector3i in wanted:
		var step: float = wanted[key]
		if _tiles.has(key) and is_equal_approx(float(_tiles[key]["step"]), step):
			continue
		_build(key, step)


## Builds everything wanted around the focus at once, for the start.
func build_now() -> void:
	update()
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()
	while not _done.is_empty():
		_attach_done(1000)


## Changes the 1 m tiles under an area of samples (x, north) at once, for
## sculpting. Their skirts stay behind until `rebuild`.
func reshape(area: Rect2i) -> void:
	for key in _chunks_in(area):
		var entry: Dictionary = _tiles.get(key, {})
		if entry.has("quads") and is_equal_approx(float(entry["step"]), 1.0):
			_reshape_tile(key, entry, area.grow(1))


## Makes every tile under an area of samples (x, north) over from the current
## heights, on worker threads.
func rebuild(area: Rect2i) -> void:
	var keys := _chunks_in(area)
	var low := Vector2(area.position) / RegionMap.SIZE
	var high := Vector2(area.end) / RegionMap.SIZE
	for z in range(floori(low.y), floori(high.y) + 1):
		for x in range(floori(low.x), floori(high.x) + 1):
			keys.append(Vector3i(x, z, 1))
	for key in keys:
		if _tiles.has(key):
			_build(key, float(_tiles[key]["step"]))


## The tiles wanted around a point and their sample spacing. A key is
## (x, z, size): size 0 is a 100 m chunk at chunk coordinates, size 1 a
## 200 m region tile at region coordinates.
func wanted_tiles(xz: Vector2) -> Dictionary[Vector3i, float]:
	var wanted: Dictionary[Vector3i, float] = {}
	var focus_region := RegionMap.of_cell(SectorMap.unbounded_cell_at(xz))
	var focus_chunk := Vector2i(floori(xz.x / CHUNK), floori(-xz.y / CHUNK))
	var per_region := int(RegionMap.SIZE / CHUNK)
	for rx in range(focus_region.x - view_regions, focus_region.x + view_regions + 1):
		for rz in range(focus_region.y - view_regions, focus_region.y + view_regions + 1):
			var region := Vector2i(rx, rz)
			if not RegionMap.is_valid(region):
				continue
			var apart := maxi(absi(rx - focus_region.x), absi(rz - focus_region.y))
			if apart <= 1:
				for cx in per_region:
					for cz in per_region:
						var chunk := region * per_region + Vector2i(cx, cz)
						var near := maxi(absi(chunk.x - focus_chunk.x), absi(chunk.y - focus_chunk.y)) <= 1
						wanted[Vector3i(chunk.x, chunk.y, 0)] = 1.0 if near else 4.0
			else:
				wanted[Vector3i(rx, rz, 1)] = 8.0 if apart <= 3 else 20.0
	return wanted


func tile_count() -> int:
	return _tiles.size()


## The sample spacing of the tile covering a point, or 0 if none is shown.
func step_at(xz: Vector2) -> float:
	var chunk := Vector2i(floori(xz.x / CHUNK), floori(-xz.y / CHUNK))
	var chunk_key := Vector3i(chunk.x, chunk.y, 0)
	if _tiles.has(chunk_key) and _tiles[chunk_key]["mesh"] != null:
		return float(_tiles[chunk_key]["step"])
	var region := RegionMap.of_cell(SectorMap.unbounded_cell_at(xz))
	var region_key := Vector3i(region.x, region.y, 1)
	if _tiles.has(region_key) and _tiles[region_key]["mesh"] != null:
		return float(_tiles[region_key]["step"])
	return 0.0


## True once nothing is waiting to be built or attached.
func is_settled() -> bool:
	for key: Vector3i in _tiles:
		if _tiles[key]["building"]:
			return false
	return true


func _focus_xz() -> Vector2:
	if focus and focus.is_inside_tree():
		return Vector2(focus.global_position.x, focus.global_position.z)
	return Vector2.ZERO


func _build(key: Vector3i, step: float) -> void:
	var entry: Dictionary = _tiles.get(key, {"mesh": null, "collision": null, "build": 0})
	entry["step"] = step
	entry["building"] = true
	# Only the newest build counts: an older one read older heights.
	entry["build"] = int(entry["build"]) + 1
	_tiles[key] = entry
	var side := CHUNK if key.z == 0 else RegionMap.SIZE
	var corner := Vector2(key.x * side, -key.y * side)
	var task := WorkerThreadPool.add_task(_generate.bind(key, step, corner, side, int(entry["build"])))
	_tasks.append(task)


## Worker thread: the tile's triangles (flat-shaded, with skirts) and, for
## the detailed chunks, a height grid for collision.
func _generate(key: Vector3i, step: float, corner: Vector2, side: float, build: int) -> void:
	var samples := int(round(side / step)) + 1
	var heights := PackedFloat32Array()
	heights.resize(samples * samples)
	for j in samples:
		for i in samples:
			heights[j * samples + i] = float(height.call(corner + Vector2(i * step, -j * step)))
	var faces := PackedVector3Array()
	var open_everywhere := true
	# Where each square's triangles start in `faces`; -1 for an open one.
	var quads := PackedInt32Array()
	for j in samples - 1:
		for i in samples - 1:
			var middle := corner + Vector2((i + 0.5) * step, -(j + 0.5) * step)
			if is_designed.is_valid() and bool(is_designed.call(middle)):
				open_everywhere = false
				quads.append(-1)
				continue
			quads.append(faces.size())
			var sw := Vector3(corner.x + i * step, heights[j * samples + i], corner.y - j * step)
			var se := Vector3(sw.x + step, heights[j * samples + i + 1], sw.z)
			var nw := Vector3(sw.x, heights[(j + 1) * samples + i], sw.z - step)
			var ne := Vector3(sw.x + step, heights[(j + 1) * samples + i + 1], sw.z - step)
			faces.append_array(PackedVector3Array([sw, nw, se, se, nw, ne]))
	var edges: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	for k in samples:
		edges[0].append(Vector3(corner.x + k * step, heights[k], corner.y))
		edges[1].append(Vector3(corner.x + side, heights[k * samples + samples - 1], corner.y - k * step))
		edges[2].append(Vector3(corner.x + side - k * step, heights[(samples - 1) * samples + samples - 1 - k], corner.y - side))
		edges[3].append(Vector3(corner.x, heights[(samples - 1 - k) * samples], corner.y - side + k * step))
	for edge in edges:
		for k in edge.size() - 1:
			var a := edge[k]
			var b := edge[k + 1]
			var down := Vector3.DOWN * SKIRT
			faces.append_array(PackedVector3Array([a, b, a + down, b, b + down, a + down]))
	var normals := PackedVector3Array()
	normals.resize(faces.size())
	var colors := PackedColorArray()
	if tint.is_valid():
		colors.resize(faces.size())
	for t in range(0, faces.size(), 3):
		var normal := (faces[t + 2] - faces[t]).cross(faces[t + 1] - faces[t]).normalized()
		normals[t] = normal
		normals[t + 1] = normal
		normals[t + 2] = normal
		if tint.is_valid():
			var middle := (faces[t] + faces[t + 1] + faces[t + 2]) / 3.0
			var color: Color = tint.call(Vector2(middle.x, middle.z), middle.y, normal.y)
			colors[t] = color
			colors[t + 1] = color
			colors[t + 2] = color
	var result := {"key": key, "step": step, "build": build, "faces": faces, "normals": normals, "colors": colors, "collide": key.z == 0}
	if editable and step <= 1.0:
		result["quads"] = quads
	if step <= 1.0:
		result["heights"] = heights
		result["samples"] = samples
		result["open"] = open_everywhere
		result["centre"] = corner + Vector2(side * 0.5, -side * 0.5)
	_mutex.lock()
	_done.append(result)
	_mutex.unlock()


func _attach_done(limit: int = ATTACH_PER_FRAME) -> void:
	for k in range(_tasks.size() - 1, -1, -1):
		if WorkerThreadPool.is_task_completed(_tasks[k]):
			WorkerThreadPool.wait_for_task_completion(_tasks[k])
			_tasks.remove_at(k)
	_mutex.lock()
	var ready := _done.slice(0, limit)
	_done = _done.slice(limit)
	_mutex.unlock()
	for result: Dictionary in ready:
		var key: Vector3i = result["key"]
		if not _tiles.has(key) or int(_tiles[key]["build"]) != int(result["build"]):
			continue
		_replace(key, result)


func _replace(key: Vector3i, result: Dictionary) -> void:
	var entry := _tiles[key]
	_free_parts(entry)
	var faces: PackedVector3Array = result["faces"]
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = result["normals"]
	if not (result["colors"] as PackedColorArray).is_empty():
		arrays[Mesh.ARRAY_COLOR] = result["colors"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	entry.erase("quads")
	if result.has("quads"):
		for part: String in ["faces", "normals", "colors", "quads"]:
			entry[part] = result[part]
	var instance := MeshInstance3D.new()
	instance.name = "Tile_%d_%d_%d" % [key.x, key.y, key.z]
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if key.z == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(instance)
	entry["mesh"] = instance
	if result["collide"]:
		entry["collision"] = _collision(key, result)
	entry["building"] = false


## A height grid for an all-open chunk sampled every metre, else its
## triangles.
func _collision(key: Vector3i, result: Dictionary) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	collision.name = "TileCollision_%d_%d" % [key.x, key.y]
	if result.get("open", false):
		var samples: int = result["samples"]
		var shape := HeightMapShape3D.new()
		shape.map_width = samples
		shape.map_depth = samples
		# The height map runs +X and +Z from its centre; the chunk's rows run
		# north (-Z), so they go in reversed.
		var heights: PackedFloat32Array = result["heights"]
		var data := PackedFloat32Array()
		data.resize(samples * samples)
		for j in samples:
			for i in samples:
				data[(samples - 1 - j) * samples + i] = heights[j * samples + i]
		shape.map_data = data
		collision.shape = shape
		var centre: Vector2 = result["centre"]
		collision.position = Vector3(centre.x, 0.0, centre.y)
	else:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(result["faces"])
		collision.shape = shape
	body.add_child(collision)
	return collision


## The 100 m chunks around an area of samples, the squares just past it too.
func _chunks_in(area: Rect2i) -> Array[Vector3i]:
	var keys: Array[Vector3i] = []
	var side := int(CHUNK)
	for z in range(floori(float(area.position.y - 1) / side), floori(float(area.end.y) / side) + 1):
		for x in range(floori(float(area.position.x - 1) / side), floori(float(area.end.x) / side) + 1):
			keys.append(Vector3i(x, z, 0))
	return keys


## Moves the squares of a 1 m tile inside an area of samples to the current
## heights, with their normals and colours.
func _reshape_tile(key: Vector3i, entry: Dictionary, area: Rect2i) -> void:
	var side := int(CHUNK)
	var origin := Vector2i(key.x, key.y) * side
	var squares := Rect2i(origin, Vector2i.ONE * side).intersection(area)
	var mesh_node: MeshInstance3D = entry["mesh"]
	if not squares.has_area() or mesh_node == null:
		return
	var faces: PackedVector3Array = entry["faces"]
	var normals: PackedVector3Array = entry["normals"]
	var colors: PackedColorArray = entry["colors"]
	var quads: PackedInt32Array = entry["quads"]
	var columns := squares.size.x + 1
	var heights := PackedFloat32Array()
	heights.resize(columns * (squares.size.y + 1))
	for j in squares.size.y + 1:
		for i in columns:
			heights[j * columns + i] = float(height.call(Vector2(squares.position.x + i, -squares.position.y - j)))
	for j in squares.size.y:
		for i in squares.size.x:
			var square := squares.position + Vector2i(i, j) - origin
			var start := quads[square.y * side + square.x]
			if start < 0:
				continue
			var south_west := heights[j * columns + i]
			var south_east := heights[j * columns + i + 1]
			var north_west := heights[(j + 1) * columns + i]
			var north_east := heights[(j + 1) * columns + i + 1]
			var corners: Array[float] = [south_west, north_west, south_east, south_east, north_west, north_east]
			for k in 6:
				var point := faces[start + k]
				point.y = corners[k]
				faces[start + k] = point
			for t: int in [start, start + 3]:
				var normal := (faces[t + 2] - faces[t]).cross(faces[t + 1] - faces[t]).normalized()
				normals[t] = normal
				normals[t + 1] = normal
				normals[t + 2] = normal
				if tint.is_valid():
					var middle := (faces[t] + faces[t + 1] + faces[t + 2]) / 3.0
					var color: Color = tint.call(Vector2(middle.x, middle.z), middle.y, normal.y)
					colors[t] = color
					colors[t + 1] = color
					colors[t + 2] = color
	entry["faces"] = faces
	entry["normals"] = normals
	entry["colors"] = colors
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = faces
	arrays[Mesh.ARRAY_NORMAL] = normals
	if not colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := mesh_node.mesh as ArrayMesh
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _drop(key: Vector3i) -> void:
	_free_parts(_tiles[key])
	_tiles.erase(key)


func _free_parts(entry: Dictionary) -> void:
	for part: String in ["mesh", "collision"]:
		var node: Node = entry.get(part)
		if node and is_instance_valid(node):
			node.queue_free()
		entry[part] = null
