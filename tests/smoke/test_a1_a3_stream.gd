extends GutTest
## The A1-A3 design follows its brief: a small stream with flowing water runs
## through all three sectors, lilies float on it, the ground is bumpy, and
## bushes, rocks and grass grow around.

const SCENE_PATH := "res://src/world/field/field.tscn"
const StreamDesign := preload("res://src/world/field/sectors/a1_a3_stream/a1_a3_stream.gd")

var _world: Node3D
var _design: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_design = _world.get_node("Sectors/A1A3Stream") as SectorDesign


func after_all() -> void:
	_world.free()


func test_owns_a1_to_a3() -> void:
	assert_eq(_design.cells(), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)] as Array[Vector2i])


func test_water_runs_through_all_three_sectors() -> void:
	for sector_name: String in ["A1", "A2", "A3"]:
		assert_gt(_wet_points(SectorMap.cell_named(sector_name)), 20, "water in %s" % sector_name)


func test_water_flows_from_the_spring_to_the_pond() -> void:
	var stream := StreamDesign.STREAM
	for k in range(1, stream.size() - 2):
		var here := Vector2(stream[k].x, stream[k].y)
		var downstream := Vector2(stream[k + 1].x, stream[k + 1].y) - here
		assert_gt(_design.flow_at(here).dot(downstream.normalized()), 0.2, "flowing at control point %d" % k)
	var pond := stream[stream.size() - 1]
	assert_lt(_design.flow_at(Vector2(pond.x, pond.y)).length(), 0.15, "the pond is nearly still")


func test_lilies_float_on_the_water() -> void:
	var pads := 0
	for node in _design.get_children():
		var multi := node as MultiMeshInstance3D
		if multi == null or not (node.name.begins_with("LilyPads") or node.name.begins_with("WaterLilies")):
			continue
		for where in _design.instance_transforms(node.name):
			var origin := where.origin
			var xz := Vector2(origin.x, origin.z)
			assert_gt(_design.water_level_at(xz), _design.height_at(xz), "pad %s is over water" % origin)
			assert_almost_eq(origin.y, _design.water_level_at(xz), 0.05)
			pads += 1
	assert_gt(pads, 10)


func test_the_ground_is_bumpy() -> void:
	var lowest := INF
	var highest := -INF
	var corner := SectorMap.corner_of(SectorMap.cell_named("A2"))
	for k in 200:
		var xz := Vector2(corner.x + 2.0 + (k % 20) * 0.3, corner.z - 1.0 - (k / 20) * 0.8)
		if _design.is_dry(xz, 0.3):
			lowest = minf(lowest, _design.height_at(xz))
			highest = maxf(highest, _design.height_at(xz))
	assert_gt(highest - lowest, 0.2)


func test_rocks_bushes_and_grass_grow_in_every_sector() -> void:
	for sector_name: String in ["A1", "A2", "A3"]:
		assert_not_null(_design.get_node_or_null("Rocks" + sector_name), "rocks in %s" % sector_name)
		assert_not_null(_design.get_node_or_null("Bushes" + sector_name), "bushes in %s" % sector_name)
		var tufts := 0
		for variant in 2:
			var grass := _design.get_node_or_null("Grass%d%s" % [variant, sector_name]) as MultiMeshInstance3D
			tufts += grass.multimesh.instance_count if grass else 0
		assert_gt(tufts, 300, "grass in %s" % sector_name)


func test_the_stream_bed_is_solid_below_the_water() -> void:
	await wait_physics_frames(2)
	var point := StreamDesign.STREAM[4]
	var from := Vector3(point.x, 5.0, point.y)
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 10.0))
	assert_false(hit.is_empty())
	assert_lt((hit.position as Vector3).y, point.w - 0.1, "the bed lies under the water surface")


func test_the_player_can_wade_across_the_stream() -> void:
	var player := _world.get_node("Player") as Player
	var west := Vector2(1.8, -15.6)
	var east := Vector2(5.8, -15.6)
	assert_true(_design.is_dry(west, 0.05) and _design.is_dry(east, 0.05), "both banks are dry")
	player.global_position = Vector3(west.x, _design.height_at(west) + 0.05, west.y)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(10)
	player.look_toward(Vector3(east.x, player.global_position.y, east.y))
	Input.action_press("move_forward")
	await wait_seconds(2.0)
	Input.action_release("move_forward")
	var reached := Vector2(player.global_position.x, player.global_position.z)
	assert_gt(reached.x, east.x - 1.0, "crossed to the east bank, now at %s" % reached)
	assert_true(_design.is_dry(reached, 0.0), "standing on dry ground")


## Ground samples in a sector, half a metre apart, with water above them.
func _wet_points(cell: Vector2i) -> int:
	var corner := SectorMap.corner_of(cell)
	var wet := 0
	for j in 20:
		for i in 20:
			var xz := Vector2(corner.x + 0.25 + i * 0.5, corner.z - 0.25 - j * 0.5)
			if _design.water_level_at(xz) > _design.height_at(xz) + 0.05:
				wet += 1
	return wet
