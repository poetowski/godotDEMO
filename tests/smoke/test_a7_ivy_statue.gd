extends GutTest
## The A7 design follows its brief: a big statue standing in A7, overgrown
## with ivy.

const SCENE_PATH := "res://src/world/field/field.tscn"
const StatueDesign := preload("res://src/world/field/sectors/a7_ivy_statue/a7_ivy_statue.gd")

var _world: Node3D
var _design: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_design = _world.get_node("Sectors/A7IvyStatue") as SectorDesign


func after_all() -> void:
	_world.free()


func test_owns_a7() -> void:
	assert_eq(_design.cells(), [SectorMap.cell_named("A7")] as Array[Vector2i])


func test_the_statue_is_big() -> void:
	var statue := (_design.part("StatueA7") as MeshInstance3D).get_aabb()
	assert_gt(statue.size.y, 4.5, "taller than two people")


func test_ivy_covers_the_statue_thickest_at_its_foot() -> void:
	var leaves := _design.instance_transforms(&"IvyA7")
	assert_gt(leaves.size(), 4000)
	var floor_height := _design.height_at(StatueDesign.STATUE)
	var low := 0
	var high := 0
	for leaf in leaves:
		var height := leaf.origin.y - floor_height
		if height > StatueDesign.PLINTH_TOP and height < 2.2:
			low += 1
		elif height > 3.2:
			high += 1
	assert_gt(high, 100, "ivy reaches the top")
	assert_gt(low, high, "and grows thicker below")


func test_the_statue_is_solid() -> void:
	await wait_physics_frames(2)
	var from := Vector3(StatueDesign.STATUE.x, 10.0, StatueDesign.STATUE.y)
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 20.0))
	assert_gt((hit.position as Vector3).y, 3.5, "a ray from above stops on its head")


func test_before_the_statue_the_player_can_pray_or_cry() -> void:
	var spot := _design.part("ShrineSpot") as GestureSpot
	assert_eq(spot.labels, PackedStringArray(["Pray", "Cry"]))
	var player := _world.get_node("Player") as Player
	watch_signals(player)
	player.global_position = spot.global_position + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO
	await wait_physics_frames(8)
	assert_signal_emitted_with_parameters(player, "prompt_changed", ["[E]  Stand before the statue"])
	player.interact()
	assert_signal_emitted(player, "choice_requested")
	var menu := (_world.get_node("Hud") as Hud).choice_menu()
	assert_true(menu.is_open())
	menu.pick(0)
	assert_false(menu.is_open())
	assert_eq(player.gesture(), &"pray", "kneels to pray")
	await wait_until(func() -> bool: return not player.is_performing(), 8.0)
	assert_signal_emitted_with_parameters(player, "gesture_finished", [&"pray"])
	await wait_physics_frames(2)
	assert_signal_emit_count(player, "prompt_changed", 3, "offered again afterwards")
