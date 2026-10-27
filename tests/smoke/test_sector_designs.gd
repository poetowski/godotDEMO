extends GutTest
## Every sector design in the field keeps to its own sectors: no sector is
## claimed twice, everything a design builds stays inside its sectors, its
## ground meets the flat field without a step, and the player starts on dry
## ground. New designs are covered without changes here.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node3D
var _terrain: FieldTerrain


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_terrain = _world.get_node("Terrain") as FieldTerrain
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()


func after_all() -> void:
	_world.free()


func test_there_are_designs() -> void:
	assert_gt(_terrain.designs().size(), 0)


func test_every_design_has_its_own_stable_id() -> void:
	var seen: Dictionary[String, String] = {}
	for design in _terrain.designs():
		assert_false(design.design_id.is_empty(), "%s has a design_id" % design.name)
		assert_eq(design.design_id, design.design_id.to_lower(), "lowercase")
		assert_false(seen.has(design.design_id), "%s and %s share %s" % [seen.get(design.design_id, ""), design.name, design.design_id])
		seen[design.design_id] = design.name


func test_saved_things_are_named_by_their_design_id() -> void:
	var count := 0
	for design in _terrain.designs():
		for node in design.content().find_children("*", "", true, false):
			var id: Variant = node.get("persist_id")
			if id is String and not (id as String).is_empty():
				assert_true((id as String).begins_with(design.design_id + "/"), id)
				count += 1
	assert_gt(count, 1, "the cornflower and the katana chest")


func test_no_sector_is_claimed_twice() -> void:
	var claimed: Dictionary[Vector2i, String] = {}
	for design in _terrain.designs():
		for cell in design.cells():
			assert_false(claimed.has(cell), "%s is claimed by %s and %s" % [SectorMap.name_of(cell), claimed.get(cell, ""), design.name])
			claimed[cell] = design.name


func test_designs_sit_at_the_world_origin() -> void:
	for design in _terrain.designs():
		assert_eq(design.global_transform, Transform3D.IDENTITY, design.name)


func test_everything_a_design_builds_stays_inside_its_sectors() -> void:
	for design in _terrain.designs():
		var checked := 0
		for node in _descendants(design):
			for box in _boxes(design, node):
				checked += 1
				assert_true(_inside(design, box), "%s pokes out of %s's sectors: %s" % [node.name, design.name, box])
		assert_gt(checked, 0, "%s builds something" % design.name)


func test_designs_meet_the_flat_field_without_a_step() -> void:
	for design in _terrain.designs():
		for cell in design.cells():
			var corner := SectorMap.corner_of(cell)
			for k in 41:
				var along := k * SectorMap.SIZE / 40.0
				var edges: Array[Vector2] = [
					Vector2(corner.x + 0.001, corner.z - along),
					Vector2(corner.x + SectorMap.SIZE - 0.001, corner.z - along),
					Vector2(corner.x + along, corner.z - 0.001),
					Vector2(corner.x + along, corner.z - SectorMap.SIZE + 0.001),
				]
				for point in edges:
					if _touches_foreign(design, point):
						assert_almost_eq(design.height_at(point), 0.0, 0.002, "%s at %s" % [design.name, point])


func test_the_ground_outside_designs_is_flat() -> void:
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var cell := Vector2i(column, row)
			var centre := SectorMap.center_of(cell)
			var xz := Vector2(centre.x, centre.z)
			if _terrain.design_at(xz) == null:
				assert_eq(_terrain.height_at(xz), 0.0, SectorMap.name_of(cell))
	assert_eq(_terrain.height_at(Vector2(-50.0, 50.0)), 0.0, "beyond the grid")


func test_the_player_starts_on_dry_ground_in_a1() -> void:
	var start := SectorMap.start_of(Vector2i.ZERO)
	assert_true(_terrain.is_dry(Vector2(start.x, start.z), 0.1), "A1's start point is dry")


## True if a point lies within 0.01 m of a sector the design doesn't own.
func _touches_foreign(design: SectorDesign, point: Vector2) -> bool:
	for offset: Vector2 in [Vector2(-0.01, 0.0), Vector2(0.01, 0.0), Vector2(0.0, -0.01), Vector2(0.0, 0.01)]:
		if not design.owns(point + offset):
			return true
	return false


func _descendants(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child in node.get_children():
		found.append(child)
		found.append_array(_descendants(child))
	return found


## World boxes of what a node draws or makes solid. MultiMesh copies come from
## the design, since headless runs can't read them back.
func _boxes(design: SectorDesign, node: Node) -> Array[AABB]:
	var boxes: Array[AABB] = []
	var mesh_instance := node as MeshInstance3D
	if mesh_instance and mesh_instance.mesh:
		boxes.append(mesh_instance.global_transform * mesh_instance.mesh.get_aabb())
	var multi := node as MultiMeshInstance3D
	if multi and multi.multimesh:
		var placed := design.instance_transforms(node.name)
		assert_eq(placed.size(), multi.multimesh.instance_count, "%s remembers its copies" % node.name)
		var mesh_box := multi.multimesh.mesh.get_aabb()
		for where in placed:
			boxes.append(multi.global_transform * where * mesh_box)
	var collision := node as CollisionShape3D
	if collision and collision.shape:
		boxes.append(collision.global_transform * collision.shape.get_debug_mesh().get_aabb())
	return boxes


func _inside(design: SectorDesign, box: AABB) -> bool:
	var inner := box.grow(-0.01)
	for corner: Vector2 in [Vector2(inner.position.x, inner.position.z), Vector2(inner.end.x, inner.position.z), Vector2(inner.position.x, inner.end.z), Vector2(inner.end.x, inner.end.z)]:
		if not design.owns(corner):
			return false
	return true
