extends GutTest
## The A5 design follows its brief: a medieval cottage with an open door the
## player can walk through and closed shutters, under a still cloud that
## rains.

const SCENE_PATH := "res://src/world/field/field.tscn"
const CottageDesign := preload("res://src/world/field/sectors/a5_rainy_cottage/a5_rainy_cottage.gd")

var _world: Node3D
var _design: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_design = _world.get_node("Sectors/A5RainyCottage") as SectorDesign


func after_all() -> void:
	_world.free()


func test_owns_a5() -> void:
	assert_eq(_design.cells(), [SectorMap.cell_named("A5")] as Array[Vector2i])


func test_the_cottage_and_its_rain_cloud_stand_in_a5() -> void:
	assert_not_null(_design.part("CottageA5"))
	var cloud := (_design.part("RainCloud") as MeshInstance3D).get_aabb()
	assert_gt(cloud.position.y, 10.0, "the cloud hangs high")
	var rain := _design.part("Rain") as GPUParticles3D
	assert_true(rain.emitting, "it rains")
	assert_gt(rain.amount, 500)
	assert_lt(rain.global_position.y, cloud.position.y + 1.0, "from under the cloud")
	assert_not_null(_design.part("RainCatcher"), "rain stops at the roof and ground")


func test_the_cloud_stays_put() -> void:
	var cloud := _design.part("RainCloud") as MeshInstance3D
	var before := cloud.global_position
	await wait_seconds(0.5)
	assert_eq(cloud.global_position, before)


func test_the_player_can_walk_in_through_the_open_door() -> void:
	var player := _world.get_node("Player") as Player
	var door := CottageDesign.COTTAGE + Vector2(CottageDesign.DOOR_X, CottageDesign.HALF.y)
	var outside := door + Vector2(0.0, 1.6)
	player.global_position = Vector3(outside.x, _design.height_at(outside) + 0.1, outside.y)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(10)
	player.look_toward(Vector3(door.x, player.global_position.y, door.y - 2.0))
	Input.action_press("move_forward")
	await wait_seconds(1.3)
	Input.action_release("move_forward")
	assert_lt(player.global_position.z, CottageDesign.COTTAGE.y + CottageDesign.HALF.y - 0.4, "inside the cottage, at %s" % player.global_position)
