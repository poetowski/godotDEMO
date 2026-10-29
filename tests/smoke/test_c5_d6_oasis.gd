extends GutTest
## Sectors C5, C6, D5, D6: an oasis with tents, and one resident living
## around it by a daily program.

var _world: Node
var _design: SectorDesign


func before_all() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_design = _world.get_node("Sectors/C5D6Oasis") as SectorDesign


func after_all() -> void:
	_world.free()


func test_there_is_a_pond_in_the_middle() -> void:
	assert_false(_design.is_dry(Vector2(30.0, -49.0)), "water at the pond")
	assert_true(_design.is_dry(Vector2(25.0, -52.5)), "C6's start is dry")


func test_the_camp_has_tents_palms_and_a_fire() -> void:
	assert_not_null(_design.part("Camp_0_0") if _design.part("Camp_0_0") else _design.content().find_child("Camp*", true, false), "camp meshes")
	assert_not_null(_design.content().find_child("Palms*", true, false), "palms")
	assert_not_null(_design.part("FireLight"), "a campfire")


func test_the_resident_follows_the_program() -> void:
	var samir := _world.get_node("Residents/Samir") as Villager
	assert_not_null(samir)
	assert_eq(samir.program.size(), 5)
	assert_eq(samir.clock, (_world.clock() as WorldClock))
	assert_eq(samir.step_at(8.0)["place"], &"work")
	assert_eq(samir.step_at(20.0)["place"], &"meet")
	assert_eq(samir.step_at(23.0)["place"], &"home")
