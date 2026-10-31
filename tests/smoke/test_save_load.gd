extends GutTest
## Saving and loading in the field: a save brings back where the player stood,
## what they carry, and what they took from the world; the game menu
## pauses the game and saves through its slots.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FixtureDesign := preload("res://tests/fixtures/fixture_design.gd")

var _world: Node3D
var _player: Player
var _hud: Hud
var _pond: SectorDesign


func before_all() -> void:
	SaveGame.folder = "user://test_saves"
	for slot in SaveGame.SLOTS:
		SaveGame.delete(slot)
	WorldState.reset()
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	_pond = FixtureDesign.add_to(_world, "SavePond", PackedStringArray(["A3"]))
	add_child(_world)
	_player = _world.get_node("Player") as Player
	_hud = _world.get_node("Hud") as Hud


func after_all() -> void:
	get_tree().paused = false
	_world.free()
	for slot in SaveGame.SLOTS:
		SaveGame.delete(slot)
	SaveGame.folder = "user://saves"


func test_1_loading_brings_back_the_world_and_the_hero() -> void:
	var field := _world as Node
	assert_eq(field.call("save_to", "1"), OK, "saved at the start")
	# Take the pebble, walk off, and save again.
	var pebble := _pond.part("Pebble") as ItemPickup
	var start_x := _player.global_position.x
	_player.global_position = pebble.global_position + Vector3(0.0, 0.3, 0.8)
	await wait_physics_frames(8)
	_player.interact()
	assert_true(_player.inventory.has(&"pebble"))
	var away := Vector3(25.0, (_world.get_node("Terrain") as FieldTerrain).height_at(Vector2(25.0, -12.0)) + 0.3, -12.0)
	_player.global_position = away
	_player.face(1.0)
	await wait_physics_frames(2)
	assert_eq(field.call("save_to", "2"), OK)

	assert_true(field.call("load_from", "1"))
	await wait_process_frames(2)
	assert_false(_player.inventory.has(&"pebble"), "the inventory is as it was")
	assert_not_null(_pond.part("Pebble"), "the pebble is back")
	assert_almost_eq(_player.global_position.x, start_x, 0.5, "back at the start")

	assert_true(field.call("load_from", "2"))
	await wait_process_frames(2)
	assert_true(_player.inventory.has(&"pebble"))
	assert_null(_pond.part("Pebble"), "taken, so gone")
	assert_almost_eq(_player.global_position, away, Vector3.ONE * 0.3)
	assert_almost_eq(_player.facing(), 1.0, 0.001)
	assert_eq(_hud.toast_text(), "Loaded slot 2")


func test_1b_an_old_save_holding_things_gone_from_the_game_still_loads() -> void:
	var field := _world as Node
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveGame.folder))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/saves/format_1.json"), ProjectSettings.globalize_path(SaveGame.folder.path_join("slot_3.json")))
	assert_true(field.call("load_from", "3"))
	await wait_process_frames(2)
	assert_true(WorldState.is_taken("b1_cornflower/cornflower"), "its record is kept")
	assert_eq(_player.inventory.count(), 0, "items no longer in the game are skipped")
	assert_false(_player.has_sword)
	SaveGame.delete("3")


func test_1c_the_time_of_day_is_saved() -> void:
	var field := _world as Node
	var clock := _world.get_node("Clock") as WorldClock
	clock.day = 3
	clock.hour = 21.25
	assert_eq(field.call("save_to", "2"), OK)
	clock.day = 1
	clock.hour = 9.0
	assert_true(field.call("load_from", "2"))
	assert_eq(clock.day, 3)
	assert_almost_eq(clock.hour, 21.25, 0.01)


func test_2_esc_opens_the_menu_and_pauses() -> void:
	var menu := _hud.game_menu()
	_press("ui_cancel")
	await wait_process_frames(2)
	assert_true(menu.is_open())
	assert_true(get_tree().paused, "the game pauses")
	menu.show_page("save")
	assert_eq(menu.page(), "save")
	menu.close()
	assert_false(get_tree().paused)


func test_3_f5_quicksaves_and_the_menu_saves_to_a_slot() -> void:
	_press("quick_save")
	await wait_process_frames(2)
	assert_true(SaveGame.exists(SaveGame.QUICK))
	assert_eq(_hud.toast_text(), "Saved to quicksave")
	var menu := _hud.game_menu()
	menu.open()
	menu.show_page("save")
	SaveGame.delete("3")
	menu.call("_pick_slot", "3")
	assert_true(SaveGame.exists("3"), "saved from the menu")
	menu.close()


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
