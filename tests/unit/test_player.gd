extends GutTest

const PLAYER_SCENE := preload("res://src/player/player.tscn")
const STONE_SCENE := preload("res://src/items/sword/sword_stone.tscn")


func after_each() -> void:
	Input.action_release(&"move_forward")


func _spawn_player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


func test_cannot_swing_without_a_sword() -> void:
	var player := _spawn_player()
	assert_false(player.try_attack())
	assert_false(player.is_swinging)


func test_takes_the_sword_from_the_stone() -> void:
	var player := _spawn_player()
	var stone := STONE_SCENE.instantiate() as SwordStone
	add_child_autofree(stone)
	watch_signals(player)
	player.offer_pickup(stone)
	assert_signal_emitted_with_parameters(player, "prompt_changed", [stone.prompt()])
	player.interact()
	assert_true(player.has_sword)
	assert_false(stone.has_sword())
	assert_not_null(player.get_node_or_null("Model/RightArm/Hand/Sword"))
	assert_signal_emitted(player, "sword_equipped")


func test_interact_does_nothing_with_nothing_on_offer() -> void:
	var player := _spawn_player()
	player.interact()
	assert_false(player.has_sword)


func test_swings_one_at_a_time() -> void:
	var player := _spawn_player()
	player.equip_sword(Node3D.new())
	assert_true(player.try_attack())
	assert_true(player.is_swinging)
	assert_false(player.try_attack(), "no second swing mid-swing")
	await wait_seconds(player.swing_duration + 0.2)
	assert_false(player.is_swinging)
	assert_true(player.try_attack(), "can swing again afterwards")


func test_walks_where_the_camera_faces() -> void:
	var player := _spawn_player()
	Input.action_press(&"move_forward")
	await wait_physics_frames(20)
	assert_lt(player.velocity.z, -0.5)
	assert_almost_eq(player.velocity.x, 0.0, 0.01)


func test_praying_kneels_for_its_time_then_stands() -> void:
	var player := _spawn_player()
	watch_signals(player)
	player.perform(&"pray", 1.5)
	assert_true(player.is_performing())
	assert_eq(player.gesture(), &"pray")
	await wait_seconds(0.8)
	assert_lt((player.get_node("Model") as Node3D).position.y, -0.2, "kneeling")
	await wait_seconds(1.0)
	assert_false(player.is_performing())
	assert_signal_emitted_with_parameters(player, "gesture_finished", [&"pray"])
	assert_eq((player.get_node("Model") as Node3D).position.y, 0.0, "standing again")


func test_crying_sheds_tears_then_stops() -> void:
	var player := _spawn_player()
	player.perform(&"cry", 1.5)
	var tears := player.get_node("Model/LeftEye/Tears") as GPUParticles3D
	assert_true(tears.emitting)
	await wait_seconds(1.8)
	assert_false(player.is_performing())
	assert_false(tears.emitting)


func test_the_hero_stands_still_while_performing() -> void:
	var player := _spawn_player()
	player.perform(&"pray", 1.0)
	Input.action_press("move_forward")
	await wait_physics_frames(20)
	Input.action_release("move_forward")
	assert_almost_eq(Vector2(player.velocity.x, player.velocity.z).length(), 0.0, 0.01)
