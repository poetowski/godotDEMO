class_name Vegetation
extends Node3D
## Woods that grow over a big world's open ground on their own, streamed in
## 100 m chunks around `focus` like the ground: trees out to `tree_chunks`
## chunks away, and close by (`detail_chunks`) bushes, grass and solid trunks
## too. Where a world-wide noise says forest the trees stand thick, elsewhere
## they thin out to clearings. Everything is placed the same every time from
## the chunk's position and `vegetation_seed`, built on worker threads and
## drawn as one MultiMesh per kind and chunk. Designed sectors and the flat
## home area being built by hand (WorldShape.home, R1) are left alone.

const CHUNK := TerrainChunks.CHUNK
## Metres between candidate tree spots (jittered).
const TREE_SPACING := 7.0
const ATTACH_PER_FRAME := 2

## Whose surroundings grow.
@export var focus: Node3D
## The ground the woods stand on.
@export var terrain: FieldTerrain
@export var vegetation_seed: int = 5
## Chunks away from the focus's chunk out to which trees show.
@export var tree_chunks: int = 3
## Chunks away within which bushes, grass and trunk collision come too.
@export var detail_chunks: int = 1
@export var grass_per_chunk: int = 2500
@export var bushes_per_chunk: int = 60
@export var tree_visible_distance: float = 380.0
@export var check_interval: float = 0.25

var _forest: FastNoiseLite
var _tree_meshes: Array[ArrayMesh] = []
var _bush_mesh: ArrayMesh
var _grass_mesh: ArrayMesh
var _tree_material: Material
var _grass_material: Material
## chunk -> {"trees": Array[Node], "detail": Array[Node], "detail_wanted": bool,
## "building": int, "token": int}
var _chunks: Dictionary[Vector2i, Dictionary] = {}
var _done: Array[Dictionary] = []
var _mutex := Mutex.new()
var _tasks: Array[int] = []
var _timer := 0.0
var _tokens := 0


func _ready() -> void:
	_forest = FastNoiseLite.new()
	_forest.seed = vegetation_seed
	_forest.frequency = 0.006
	_forest.fractal_octaves = 2
	var rng := RandomNumberGenerator.new()
	rng.seed = vegetation_seed
	for kind in 4:
		var batch := NatureKit.Batch.new()
		if kind < 2:
			NatureKit.add_round_tree(batch, rng, Vector3.ZERO, 4.5)
		else:
			NatureKit.add_pine(batch, rng, Vector3.ZERO, 7.0)
		_tree_meshes.append(batch.commit())
	var bush := NatureKit.Batch.new()
	NatureKit.add_bush(bush, rng, Transform3D())
	_bush_mesh = bush.commit()
	_grass_mesh = NatureKit.grass_tuft(rng)
	_tree_material = MeshKit.lowpoly_material(Color.WHITE, 0.95)
	_grass_material = NatureKit.grass_material()


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


## Starts growing the chunks now in reach and drops the ones out of it.
func update() -> void:
	var centre := _focus_chunk()
	for chunk: Vector2i in _chunks.keys():
		var apart := _apart(chunk, centre)
		if apart > tree_chunks:
			_drop(chunk)
		elif apart > detail_chunks and _chunks[chunk]["detail_wanted"]:
			_chunks[chunk]["detail_wanted"] = false
			_free(_chunks[chunk]["detail"])
			_chunks[chunk]["detail"] = []
	for dx in range(-tree_chunks, tree_chunks + 1):
		for dz in range(-tree_chunks, tree_chunks + 1):
			var chunk := centre + Vector2i(dx, dz)
			if not _in_world(chunk):
				continue
			if not _chunks.has(chunk):
				_chunks[chunk] = {"trees": [], "detail": [], "detail_wanted": false, "building": 0, "token": _next_token()}
				_start(chunk, false)
			var entry := _chunks[chunk]
			if _apart(chunk, centre) <= detail_chunks and not entry["detail_wanted"]:
				entry["detail_wanted"] = true
				_start(chunk, true)


## Grows everything in reach at once, for the start.
func build_now() -> void:
	update()
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()
	while not _done.is_empty():
		_attach_done(1000)


func chunk_count() -> int:
	return _chunks.size()


## How many trees stand in a chunk now (0 when it isn't grown).
func tree_count(chunk: Vector2i) -> int:
	if not _chunks.has(chunk):
		return 0
	var total := 0
	for node: Node in _chunks[chunk]["trees"]:
		total += (node as MultiMeshInstance3D).multimesh.instance_count
	return total


## True while the chunk has its bushes, grass and trunk collision.
func has_detail(chunk: Vector2i) -> bool:
	return _chunks.has(chunk) and not (_chunks[chunk]["detail"] as Array).is_empty()


func is_settled() -> bool:
	for chunk: Vector2i in _chunks:
		if int(_chunks[chunk]["building"]) > 0:
			return false
	return true


static func chunk_at(xz: Vector2) -> Vector2i:
	return Vector2i(floori(xz.x / CHUNK), floori(-xz.y / CHUNK))


func _focus_chunk() -> Vector2i:
	if focus and focus.is_inside_tree():
		return chunk_at(Vector2(focus.global_position.x, focus.global_position.z))
	return Vector2i.ZERO


func _apart(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _in_world(chunk: Vector2i) -> bool:
	var extent := SectorMap.extent()
	return chunk.x >= 0 and chunk.y >= 0 and chunk.x * CHUNK < extent.x and chunk.y * CHUNK < extent.y


func _start(chunk: Vector2i, detail: bool) -> void:
	_chunks[chunk]["building"] = int(_chunks[chunk]["building"]) + 1
	_tasks.append(WorkerThreadPool.add_task(_generate.bind(chunk, detail, int(_chunks[chunk]["token"]))))


## A new number for each time a chunk starts growing, so results meant for
## an earlier growth of the same chunk are thrown away.
func _next_token() -> int:
	_tokens += 1
	return _tokens


## Worker thread: where everything in a chunk stands.
func _generate(chunk: Vector2i, detail: bool, token: int) -> void:
	var corner := Vector2(chunk.x * CHUNK, -chunk.y * CHUNK)
	var result := {"chunk": chunk, "detail": detail, "token": token}
	var spots := _tree_spots(chunk)
	if not detail:
		var trees: Array[Array] = []
		for kind in _tree_meshes.size():
			trees.append([])
		for spot: Array in spots:
			trees[int(spot[0])].append(spot[1])
		result["trees"] = trees
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector3i(chunk.x, chunk.y, vegetation_seed + 7))
		var bushes: Array[Transform3D] = []
		for k in bushes_per_chunk:
			var xz := corner + Vector2(rng.randf() * CHUNK, -rng.randf() * CHUNK)
			if _open(xz):
				bushes.append(_stand(xz, rng.randf() * TAU, rng.randf_range(0.6, 1.1), 0.05))
		var grass: Array[Transform3D] = []
		for k in grass_per_chunk:
			var xz := corner + Vector2(rng.randf() * CHUNK, -rng.randf() * CHUNK)
			if _open(xz):
				grass.append(_stand(xz, rng.randf() * TAU, rng.randf_range(0.8, 1.2), 0.02))
		var trunks: Array[Vector3] = []
		for spot: Array in spots:
			trunks.append((spot[1] as Transform3D).origin)
		result["bushes"] = bushes
		result["grass"] = grass
		result["trunks"] = trunks
	_mutex.lock()
	_done.append(result)
	_mutex.unlock()


## Every tree in a chunk as [kind, transform]: candidates on a jittered grid,
## kept where the forest is thick enough. The same every time.
func _tree_spots(chunk: Vector2i) -> Array[Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(chunk.x, chunk.y, vegetation_seed))
	var corner := Vector2(chunk.x * CHUNK, -chunk.y * CHUNK)
	var spots: Array[Array] = []
	var steps := int(CHUNK / TREE_SPACING)
	for j in steps:
		for i in steps:
			var xz := corner + Vector2((i + rng.randf()) * TREE_SPACING, -(j + rng.randf()) * TREE_SPACING)
			var keep := rng.randf()
			var size := rng.randf_range(0.75, 1.3)
			var kind := rng.randi() % _tree_meshes.size()
			var turn := rng.randf() * TAU
			if keep <= forest_density(xz) and _open(xz):
				spots.append([kind, _stand(xz, turn, size, 0.1)])
	return spots


## How likely a tree is at a point, 0.05 in clearings to 0.9 in thick woods.
func forest_density(xz: Vector2) -> float:
	return clampf(0.5 + 1.1 * _forest.get_noise_2d(xz.x, xz.y), 0.05, 0.9)


func _open(xz: Vector2) -> bool:
	return not WorldShape.is_home(xz) and (terrain == null or terrain.design_at(xz) == null)


func _height(xz: Vector2) -> float:
	return WorldShape.height(xz)


func _stand(xz: Vector2, turn: float, size: float, sink: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * size), Vector3(xz.x, _height(xz) - sink, xz.y))


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
		var chunk: Vector2i = result["chunk"]
		if not _chunks.has(chunk) or int(_chunks[chunk]["token"]) != int(result["token"]):
			continue
		var entry := _chunks[chunk]
		entry["building"] = maxi(0, int(entry["building"]) - 1)
		if not result["detail"]:
			var trees: Array[Array] = []
			trees.assign(result["trees"])
			for kind in trees.size():
				var placed: Array[Transform3D] = []
				placed.assign(trees[kind])
				if not placed.is_empty():
					(entry["trees"] as Array).append(_multimesh("Trees%d_%d_%d" % [kind, chunk.x, chunk.y], _tree_meshes[kind], _tree_material, placed, tree_visible_distance, true))
		elif entry["detail_wanted"] and (entry["detail"] as Array).is_empty():
			var bushes: Array[Transform3D] = []
			bushes.assign(result["bushes"])
			var grass: Array[Transform3D] = []
			grass.assign(result["grass"])
			var detail: Array = entry["detail"]
			detail.append(_multimesh("Bushes_%d_%d" % [chunk.x, chunk.y], _bush_mesh, _tree_material, bushes, 120.0, true))
			detail.append(_multimesh("Grass_%d_%d" % [chunk.x, chunk.y], _grass_mesh, _grass_material, grass, 55.0, false))
			var trunks: Array[Vector3] = []
			trunks.assign(result["trunks"])
			detail.append(_trunk_body(chunk, trunks))


func _multimesh(node_name: String, mesh: Mesh, material: Material, placed: Array[Transform3D], visible_distance: float, shadows: bool) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = placed.size()
	for k in placed.size():
		multimesh.set_instance_transform(k, placed[k])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = visible_distance
	instance.visibility_range_end_margin = visible_distance * 0.1
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


func _trunk_body(chunk: Vector2i, trunks: Array[Vector3]) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Trunks_%d_%d" % [chunk.x, chunk.y]
	var shape := CylinderShape3D.new()
	shape.radius = 0.22
	shape.height = 4.0
	for foot in trunks:
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = foot + Vector3.UP * 2.0
		body.add_child(collision)
	add_child(body)
	return body


func _drop(chunk: Vector2i) -> void:
	_free(_chunks[chunk]["trees"])
	_free(_chunks[chunk]["detail"])
	_chunks.erase(chunk)


func _free(nodes: Array) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()
