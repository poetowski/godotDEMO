extends GutTest
## Saving and loading in the field: a save brings back where the player stood,
## what they carry and hold, and what they took from the world; the game menu
## pauses the game and saves through its slots.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node3D
var _player: Player
var _hud: Hud


func before_all() -> void:
	SaveGame.folder = "user://test_saves"
	for slot in SaveGame.SLOTS:
		SaveGame.delete(slot)
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
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
	# Take the cornflower and the katana, walk off, and save again.
	var meadow := _world.get_node("Sectors/B1Cornflower") as SectorDesign
	var flower := meadow.part("Cornflower") as ItemPickup
	_player.global_position = flower.global_position + Vector3(0.0, 0.3, 0.8)
	await wait_physics_frames(8)
	_player.interact()
	assert_true(_player.inventory.has(&"cornflower"))
	_player.equip_sword(FlameKatana.new())
	_player.global_position = Vector3(25.0, 0.3, -12.0)
	_player.face(1.0)
	await wait_physics_frames(2)
	assert_eq(field.call("save_to", "2"), OK)

	assert_true(field.call("load_from", "1"))
	await wait_process_frames(2)
	assert_false(_player.inventory.has(&"cornflower"), "the inventory is as it was")
	assert_false(_player.has_sword)
	assert_not_null(meadow.part("Cornflower"), "the cornflower grows again")
	assert_almost_eq(_player.global_position.x, 5.0, 0.5, "back at the start")

	assert_true(field.call("load_from", "2"))
	await wait_process_frames(2)
	assert_true(_player.inventory.has(&"cornflower"))
	assert_true(_player.sword() is FlameKatana, "holding the katana again")
	assert_null(meadow.part("Cornflower"), "picked, so gone")
	assert_almost_eq(_player.global_position, Vector3(25.0, 0.3, -12.0), Vector3.ONE * 0.2)
	assert_almost_eq(_player.facing(), 1.0, 0.001)
	assert_eq(_hud.toast_text(), "Loaded slot 2")


func test_1b_an_old_save_loads_with_what_was_taken() -> void:
	var field := _world as Node
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveGame.folder))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/saves/format_1.json"), ProjectSettings.globalize_path(SaveGame.path_of("3")))
	assert_true(field.call("load_from", "3"))
	await wait_process_frames(2)
	var meadow := _world.get_node("Sectors/B1Cornflower") as SectorDesign
	var tower := _world.get_node("Sectors/C2ArcherTower") as SectorDesign
	assert_null(meadow.part("Cornflower"), "picked in the old save, so gone")
	assert_false((tower.part("Chest") as SwordChest).has_sword(), "the chest stays empty")
	assert_true(_player.sword() is FlameKatana)
	assert_eq(_player.inventory.amount_at(1), 1)
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
