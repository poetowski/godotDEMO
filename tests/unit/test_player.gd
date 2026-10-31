extends GutTest

const PLAYER_SCENE := preload("res://src/player/player.tscn")


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


func test_holds_a_sword_in_the_hand() -> void:
	var player := _spawn_player()
	watch_signals(player)
	player.equip_sword(Node3D.new())
	assert_true(player.has_sword)
	assert_not_null(player.sword(), "in hand")
	assert_eq(player.sword().get_parent(), player.body().hand())
	assert_signal_emitted(player, "sword_equipped")


func test_the_hero_keeps_his_animations_without_praying_or_crying() -> void:
	var player := _spawn_player()
	var animations := player.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for animation: StringName in [&"idle", &"walk", &"run", &"fall", &"hold_sword", &"swing", &"swim"]:
		assert_true(animations.has_animation(animation), animation)
	assert_false(animations.has_animation(&"pray"))
	assert_false(animations.has_animation(&"cry"))


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
