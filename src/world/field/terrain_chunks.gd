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
var material: Material
## Regions out to which tiles are shown.
var view_regions: int = 6
## Seconds between checks of what should be shown.
var check_interval: float = 0.25

## Tiles shown or being built: key -> {"step", "mesh", "collision", "building"}.
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
	var entry: Dictionary = _tiles.get(key, {"mesh": null, "collision": null})
	entry["step"] = step
	entry["building"] = true
	_tiles[key] = entry
	var side := CHUNK if key.z == 0 else RegionMap.SIZE
	var corner := Vector2(key.x * side, -key.y * side)
	var task := WorkerThreadPool.add_task(_generate.bind(key, step, corner, side))
	_tasks.append(task)


## Worker thread: the tile's triangles (flat-shaded, with skirts) and, for
## the detailed chunks, a height grid for collision.
func _generate(key: Vector3i, step: float, corner: Vector2, side: float) -> void:
	var samples := int(round(side / step)) + 1
	var heights := PackedFloat32Array()
	heights.resize(samples * samples)
	for j in samples:
		for i in samples:
			heights[j * samples + i] = float(height.call(corner + Vector2(i * step, -j * step)))
	var faces := PackedVector3Array()
	var open_everywhere := true
	for j in samples - 1:
		for i in samples - 1:
			var middle := corner + Vector2((i + 0.5) * step, -(j + 0.5) * step)
			if is_designed.is_valid() and bool(is_designed.call(middle)):
				open_everywhere = false
				continue
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
	for t in range(0, faces.size(), 3):
		var normal := (faces[t + 2] - faces[t]).cross(faces[t + 1] - faces[t]).normalized()
		normals[t] = normal
		normals[t + 1] = normal
		normals[t + 2] = normal
	var result := {"key": key, "step": step, "faces": faces, "normals": normals, "collide": key.z == 0}
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
		if not _tiles.has(key) or not is_equal_approx(float(_tiles[key]["step"]), float(result["step"])):
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
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
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


func _drop(key: Vector3i) -> void:
	_free_parts(_tiles[key])
	_tiles.erase(key)


func _free_parts(entry: Dictionary) -> void:
	for part: String in ["mesh", "collision"]:
		var node: Node = entry.get(part)
		if node and is_instance_valid(node):
			node.queue_free()
		entry[part] = null
