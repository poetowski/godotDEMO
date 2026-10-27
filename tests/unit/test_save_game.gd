extends GutTest
## SaveGame writes plain JSON per slot, reads it back, describes slots for the
## menu and refuses files of another format.

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
	var data := {"version": SaveGame.FORMAT, "sector": "B1", "saved_at": "2026-10-27 10:42", "inventory": ["cornflower", ""], "taken": ["B1Cornflower/Cornflower"]}
	assert_eq(SaveGame.write("1", data), OK)
	assert_true(SaveGame.exists("1"))
	var read := SaveGame.read("1")
	assert_eq(read.get("sector"), "B1")
	assert_eq(read.get("taken"), ["B1Cornflower/Cornflower"])


func test_empty_slots_read_as_nothing() -> void:
	assert_false(SaveGame.exists("2"))
	assert_eq(SaveGame.read("2"), {})
	assert_eq(SaveGame.describe("2"), "Empty")


func test_describes_where_when_and_how_much() -> void:
	SaveGame.write("3", {"version": SaveGame.FORMAT, "sector": "C2", "saved_at": "2026-10-27 11:05", "inventory": ["cornflower", "", ""]})
	assert_eq(SaveGame.describe("3"), "C2   2026-10-27 11:05   1 item")


func test_refuses_other_formats() -> void:
	SaveGame.write(SaveGame.QUICK, {"version": SaveGame.FORMAT + 1})
	assert_eq(SaveGame.read(SaveGame.QUICK), {})


func test_inventory_and_world_state_give_their_ids() -> void:
	var inventory := Inventory.new()
	inventory.add(ItemCatalog.find(&"cornflower"))
	assert_eq(inventory.ids()[0], "cornflower")
	assert_eq(inventory.ids()[1], "")
	WorldState.restore(["A", "B"])
	assert_true(WorldState.is_taken("B"))
	WorldState.reset()
