extends GutTest
## The C2 design follows its brief: a brick archer tower whose staircase
## the player can climb to the top, a big pine, and foliage around them.

const SCENE_PATH := "res://src/world/field/field.tscn"
const TowerDesign := preload("res://src/world/field/sectors/c2_archer_tower/c2_archer_tower.gd")

var _world: Node3D
var _design: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_design = _world.get_node("Sectors/C2ArcherTower") as SectorDesign


func after_all() -> void:
	_world.free()


func test_owns_c2() -> void:
	assert_eq(_design.cells(), [SectorMap.cell_named("C2")] as Array[Vector2i])


func test_tower_pine_and_foliage_exist() -> void:
	for node_name: String in ["TowerC2", "PineC2", "BushesC2", "GrassC2", "FernsC2"]:
		assert_not_null(_design.get_node_or_null(node_name), node_name)
	var tower := (_design.get_node("TowerC2") as MeshInstance3D).get_aabb()
	assert_gt(tower.size.y, 9.0, "the tower stands tall")
	var pine := (_design.get_node("PineC2") as MeshInstance3D).get_aabb()
	assert_gt(pine.size.y, 9.0, "the pine is big")


func test_the_player_can_climb_the_stairs_to_the_top() -> void:
	var design := _design as TowerDesign
	var player := _world.get_node("Player") as Player
	var middle := design.tower_radius + design.stair_width * 0.5 + 0.1
	var start := design._around(design._stair_angle(0.0) - 0.4, middle, 0.0)
	player.global_position = start + Vector3.UP * 0.1
	player.velocity = Vector3.ZERO
	await wait_physics_frames(10)
	Input.action_press("move_forward")
	var highest := 0.0
	for frame in 60 * 14:
		var flat := Vector2(player.global_position.x, player.global_position.z) - TowerDesign.TOWER
		var ahead := flat.angle() + 0.35
		player.look_toward(design._around(ahead, middle, player.global_position.y - design._base))
		await wait_physics_frames(1)
		highest = maxf(highest, player.global_position.y - design._base)
		if highest > design.tower_height:
			break
	Input.action_release("move_forward")
	assert_gt(highest, design.tower_height - 0.5, "reached the top, highest %.1f m" % highest)


func test_the_flame_katana_waits_in_the_chest_on_top_and_can_be_wielded() -> void:
	var chest := _design.get_node("Chest") as SwordChest
	assert_true(chest.has_sword())
	assert_gt(chest.global_position.y - _design.height_at(TowerDesign.TOWER), 9.0, "the chest is on top of the tower")
	var player := _world.get_node("Player") as Player
	watch_signals(player)
	player.global_position = chest.global_position + chest.global_basis.z * 0.9 + Vector3.UP * 0.1
	player.velocity = Vector3.ZERO
	await wait_physics_frames(6)
	assert_signal_emitted_with_parameters(player, "prompt_changed", ["[E]  Take the flame katana"])
	player.interact()
	assert_true(player.has_sword)
	assert_false(chest.has_sword())
	assert_eq(_find_katanas(player), 1, "the player holds the flame katana")
	assert_true(player.try_attack(), "and swings it")


func _find_katanas(node: Node) -> int:
	var found := 1 if node is FlameKatana else 0
	for child in node.get_children():
		found += _find_katanas(child)
	return found
