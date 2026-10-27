extends GutTest
## The D1-E2 design follows its brief: Bratislava Castle on a hill, which the
## player can reach by walking up the road to its gate.

const SCENE_PATH := "res://src/world/field/field.tscn"
const CastleDesign := preload("res://src/world/field/sectors/d1_e2_castle/d1_e2_castle.gd")

var _world: Node3D
var _design: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_design = _world.get_node("Sectors/D1E2Castle") as SectorDesign


func after_all() -> void:
	_world.free()


func test_owns_d1_to_e2() -> void:
	assert_eq(_design.cells().size(), 4)
	for sector_name: String in ["D1", "D2", "E1", "E2"]:
		assert_true(_design.owns_cell(SectorMap.cell_named(sector_name)), sector_name)


func test_the_castle_stands_on_a_hill() -> void:
	assert_gt(_design.height_at(CastleDesign.HILL), 2.5, "the hilltop is high")
	var castle := (_design.part("CastleE2") as MeshInstance3D).get_aabb()
	assert_gt(castle.position.y, 2.0, "the castle starts on the hilltop")
	assert_gt(castle.end.y, 10.0, "towers and roofs rise high")


func test_the_player_can_walk_up_the_road_to_the_gate() -> void:
	var player := _world.get_node("Player") as Player
	var foot := CastleDesign.ROAD_FOOT
	player.global_position = Vector3(foot.x, _design.height_at(foot) + 0.1, foot.y)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(10)
	var top := CastleDesign.ROAD_TOP
	player.look_toward(Vector3(top.x, player.global_position.y, top.y))
	Input.action_press("move_forward")
	await wait_seconds(3.0)
	Input.action_release("move_forward")
	assert_gt(player.global_position.y, 2.5, "climbed the hill, now at %s" % player.global_position)
