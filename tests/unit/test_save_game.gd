extends GutTest
## SaveGame writes plain JSON per slot, reads it back, describes slots for the
## menu, upgrades saves from older formats and refuses ones from newer
## versions of the game.

const FOLDER := "user://test_saves"


func before_each() -> void:
	SaveGame.folder = FOLDER
	for slot in SaveGame.SLOTS:
		SaveGame.delete(slot)


func after_all() -> void:
	for slot in SaveGame.SLOTS:
		SaveGame.delete(slot)
	SaveGame.folder = "user://saves"


func test_a_slot_round_trips() -> void:
	var data := {"version": SaveGame.FORMAT, "sector": "B1", "saved_at": "2026-10-27 10:42", "inventory": ["cornflower", ""], "amounts": [1, 0], "world": {"b1_cornflower/cornflower": {"taken": true}}}
	assert_eq(SaveGame.write("1", data), OK)
	assert_true(SaveGame.exists("1"))
	var read := SaveGame.read("1")
	assert_eq(read.get("sector"), "B1")
	assert_eq(read.get("world"), {"b1_cornflower/cornflower": {"taken": true}})


func test_empty_slots_read_as_nothing() -> void:
	assert_false(SaveGame.exists("2"))
	assert_eq(SaveGame.read("2"), {})
	assert_eq(SaveGame.describe("2"), "Empty")


func test_describes_where_when_and_how_much() -> void:
	SaveGame.write("3", {"version": SaveGame.FORMAT, "sector": "C2", "saved_at": "2026-10-27 11:05", "inventory": ["cornflower", "", ""]})
	assert_eq(SaveGame.describe("3"), "C2   2026-10-27 11:05   1 item")


func test_refuses_saves_from_newer_versions_and_non_saves() -> void:
	SaveGame.write(SaveGame.QUICK, {"version": SaveGame.FORMAT + 1})
	assert_eq(SaveGame.read(SaveGame.QUICK), {})
	SaveGame.write(SaveGame.QUICK, {"sector": "A1"})
	assert_eq(SaveGame.read(SaveGame.QUICK), {}, "no version")


func test_every_older_format_has_a_fixture_that_upgrades() -> void:
	for version in range(1, SaveGame.FORMAT):
		var path := "res://tests/fixtures/saves/format_%d.json" % version
		assert_true(FileAccess.file_exists(path), "a save written by format %d" % version)
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var upgraded := SaveMigration.upgrade(data)
		assert_eq(int(upgraded.get("version", 0)), SaveGame.FORMAT, "format %d upgrades" % version)
		assert_true(upgraded.has("world"))


func test_format_1_saves_keep_what_was_taken_under_the_stable_ids() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/saves/format_1.json"), ProjectSettings.globalize_path(SaveGame.path_of("1")))
	var read := SaveGame.read("1")
	assert_eq(int(read.get("version")), SaveGame.FORMAT)
	assert_eq(read.get("world"), {
		"b1_cornflower/cornflower": {"taken": true},
		"c2_archer_tower/sword_chest": {"taken": true},
	}, "renamed; stress mushrooms grow back")
	assert_false(read.has("taken"))
	assert_eq(read.get("amounts").slice(0, 4), [1, 1, 1, 0])
	assert_eq(read.get("player").get("sword"), "flame_katana")


func test_inventory_and_world_state_give_their_ids() -> void:
	var inventory := Inventory.new()
	inventory.add(ItemCatalog.find(&"cornflower"))
	assert_eq(inventory.ids()[0], "cornflower")
	assert_eq(inventory.ids()[1], "")
	WorldState.restore({"A": {"taken": true}, "B": {"open": 2}})
	assert_true(WorldState.is_taken("A"))
	assert_false(WorldState.is_taken("B"))
	assert_eq(WorldState.value("B", "open"), 2)
	WorldState.set_value("C", "seen", true)
	assert_eq(WorldState.snapshot().keys().size(), 3)
	WorldState.reset()
	assert_eq(WorldState.ids().size(), 0)
