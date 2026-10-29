class_name FarForest
extends Node3D
## The woods beyond the real trees, out to the horizon: simple stand-in
## trees standing exactly where Vegetation's trees would (every other one,
## a little bigger to make up for it), so the forest's outline and clearings
## match as the real trees take over. Grouped in 400 m blocks, one MultiMesh
## per kind and block, built on worker threads; each copy dissolves within
## `hide_within` metres of the camera, where the real trees stand
## (far_forest.gdshader).

const SHADER := preload("res://src/world/nature/far_forest.gdshader")
## Metres along a block's side: two regions.
const BLOCK := 400.0
const ATTACH_PER_FRAME := 1

## Whose surroundings are shown.
var focus: Node3D
## Where the trees stand (Vegetation.tree_spots).
var vegetation: Vegetation
## Metres out to which blocks are shown.
var view_distance: float = 1300.0
## Metres within which the real trees stand and the stand-ins dissolve.
var hide_within: float = 300.0
var check_interval: float = 0.5

var _meshes: Array[ArrayMesh] = []
var _material: ShaderMaterial
## block -> {"nodes": Array[Node], "building": bool}
var _blocks: Dictionary[Vector2i, Dictionary] = {}
var _done: Array[Dictionary] = []
var _mutex := Mutex.new()
var _tasks: Array[int] = []
var _timer := 0.0


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"hide_within", hide_within)
	_meshes = [_round_tree(), _pine()]


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


func update() -> void:
	var at := _focus_xz()
	var wanted: Dictionary[Vector2i, bool] = {}
	var reach := ceili(view_distance / BLOCK)
	var centre := Vector2i(floori(at.x / BLOCK), floori(-at.y / BLOCK))
	for bx in range(centre.x - reach, centre.x + reach + 1):
		for bz in range(centre.y - reach, centre.y + reach + 1):
			var block := Vector2i(bx, bz)
			if not _in_world(block):
				continue
			var middle := Vector2((bx + 0.5) * BLOCK, -(bz + 0.5) * BLOCK)
			if middle.distance_to(at) - BLOCK * 0.71 > view_distance:
				continue
			wanted[block] = true
	for block: Vector2i in _blocks.keys():
		if not wanted.has(block):
			_free(_blocks[block]["nodes"])
			_blocks.erase(block)
	for block: Vector2i in wanted:
		if not _blocks.has(block):
			_blocks[block] = {"nodes": [], "building": true}
			_tasks.append(WorkerThreadPool.add_task(_generate.bind(block)))


func block_count() -> int:
	return _blocks.size()


## How many stand-in trees a block holds (0 when it isn't built).
func tree_count(block: Vector2i) -> int:
	if not _blocks.has(block):
		return 0
	var total := 0
	for node: Node in _blocks[block]["nodes"]:
		total += (node as MultiMeshInstance3D).multimesh.instance_count
	return total


func is_settled() -> bool:
	for block: Vector2i in _blocks:
		if _blocks[block]["building"]:
			return false
	return true


static func block_at(xz: Vector2) -> Vector2i:
	return Vector2i(floori(xz.x / BLOCK), floori(-xz.y / BLOCK))


func _focus_xz() -> Vector2:
	if focus and focus.is_inside_tree():
		return Vector2(focus.global_position.x, focus.global_position.z)
	return Vector2.ZERO


func _in_world(block: Vector2i) -> bool:
	var extent := SectorMap.extent()
	return block.x >= 0 and block.y >= 0 and block.x * BLOCK < extent.x and block.y * BLOCK < extent.y


## Worker thread: every other tree of the block's chunks, by kind.
func _generate(block: Vector2i) -> void:
	var per_side := int(BLOCK / Vegetation.CHUNK)
	var placed: Array[Array] = [[], []]
	for cx in per_side:
		for cz in per_side:
			var spots := vegetation.tree_spots(block * per_side + Vector2i(cx, cz))
			for k in range(0, spots.size(), 2):
				var spot: Array = spots[k]
				var where: Transform3D = spot[1]
				var kind := 0 if int(spot[0]) < 2 else 1
				placed[kind].append(Transform3D(where.basis.scaled(Vector3.ONE * 1.25), where.origin))
	_mutex.lock()
	_done.append({"block": block, "placed": placed})
	_mutex.unlock()


func _attach_done() -> void:
	for k in range(_tasks.size() - 1, -1, -1):
		if WorkerThreadPool.is_task_completed(_tasks[k]):
			WorkerThreadPool.wait_for_task_completion(_tasks[k])
			_tasks.remove_at(k)
	_mutex.lock()
	var ready := _done.slice(0, ATTACH_PER_FRAME)
	_done = _done.slice(ATTACH_PER_FRAME)
	_mutex.unlock()
	for result: Dictionary in ready:
		var block: Vector2i = result["block"]
		if not _blocks.has(block) or not _blocks[block]["building"]:
			continue
		var placed: Array = result["placed"]
		for kind in placed.size():
			var transforms: Array = placed[kind]
			if transforms.is_empty():
				continue
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = _meshes[kind]
			multimesh.instance_count = transforms.size()
			for k in transforms.size():
				multimesh.set_instance_transform(k, transforms[k])
			var instance := MultiMeshInstance3D.new()
			instance.name = "FarTrees%d_%d_%d" % [kind, block.x, block.y]
			instance.multimesh = multimesh
			instance.material_override = _material
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(instance)
			(_blocks[block]["nodes"] as Array).append(instance)
		_blocks[block]["building"] = false


func _free(nodes: Array) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()


## A broadleaf seen from afar: a short trunk under a lumpy crown, 4.5 m to
## the top of the trunk like Vegetation's round trees.
func _round_tree() -> ArrayMesh:
	var batch := NatureKit.Batch.new()
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.12, 0.2, 4.5, 4)), Transform3D(Basis(), Vector3.UP * 2.25), Color(0.36, 0.26, 0.18))
	batch.add(MeshKit.triangles(MeshKit.sphere(1.6, 6, 4)), Transform3D(Basis().scaled(Vector3(1.0, 0.9, 1.0)), Vector3.UP * 4.8), NatureKit.LEAF_GREENS[1])
	return batch.commit()


## A pine seen from afar: one tall dark cone over a trunk, 7 m tall.
func _pine() -> ArrayMesh:
	var batch := NatureKit.Batch.new()
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.08, 0.18, 2.0, 4)), Transform3D(Basis(), Vector3.UP), Color(0.34, 0.24, 0.16))
	batch.add(MeshKit.triangles(MeshKit.cone(2.0, 5.8, 6)), Transform3D(Basis(), Vector3.UP * 4.0), Color(0.17, 0.33, 0.19))
	return batch.commit()
