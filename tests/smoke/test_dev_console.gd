extends GutTest
## The developer console's commands act on the field, and the streaming map
## tells loaded sectors from distant ones.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FixtureDesign := preload("res://tests/fixtures/fixture_design.gd")

var _world: Node3D
var _console: DevConsole
var _map: StreamingMap
var _player: Player


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	FixtureDesign.add_to(_world, "NearPond", PackedStringArray(["A5"]))
	add_child(_world)
	_player = _world.get_node("Player") as Player
	_console = DevConsole.new()
	_console.world = _world
	add_child(_console)
	_map = StreamingMap.new()
	_map.world = _world
	add_child(_map)


func after_all() -> void:
	_map.free()
	_console.free()
	_world.free()
	WorldState.reset()


func test_help_lists_every_command() -> void:
	var help := _console.execute("help")
	for command: String in ["goto", "time", "give", "radius", "reset", "save", "load", "map", "where"]:
		assert_string_contains(help, command)


func test_unknown_commands_say_so() -> void:
	assert_string_contains(_console.execute("fly away"), "Unknown command: fly")
	assert_eq(_console.execute("   "), "")


func test_goto_moves_the_hero_to_a_sector() -> void:
	assert_eq(_console.execute("goto c2"), "In C2.")
	assert_eq(SectorMap.name_of(SectorMap.cell_at(_player.global_position)), "C2")
	assert_string_contains(_console.execute("where"), "C2 at")
	assert_string_contains(_console.execute("goto Z99"), "No sector named")
	_console.execute("goto A1")


func test_time_shows_and_sets_the_clock() -> void:
	assert_eq(_console.execute("time 21:30"), "Day 1  21:30")
	assert_almost_eq((_world.get_node("Clock") as WorldClock).hour, 21.5, 0.001)
	assert_string_contains(_console.execute("time 25:00"), "Usage")


func test_give_fills_the_inventory() -> void:
	_player.inventory.clear()
	assert_eq(_console.execute("give berry 3"), "Gave 3 Berry.")
	assert_eq(_player.inventory.total(&"berry"), 3)
	assert_string_contains(_console.execute("give dragon"), "No item dragon")
	assert_string_contains(_console.execute("items"), "pebble")
	_player.inventory.clear()


func test_radius_changes_streaming() -> void:
	var streamer := _world.get_node("Streamer") as SectorStreamer
	var before := streamer.load_radius
	assert_eq(_console.execute("radius 2"), "Load radius 2, unload radius 3.")
	assert_eq(streamer.load_radius, 2)
	_console.execute("radius %d %d" % [before, before + 1])


func test_reset_brings_back_what_was_taken() -> void:
	WorldState.mark_taken("b1_cornflower/cornflower")
	assert_eq(_console.execute("reset"), "The world is as new.")
	assert_false(WorldState.is_taken("b1_cornflower/cornflower"))


func test_the_map_tells_loaded_sectors_from_distant_ones() -> void:
	_console.execute("goto A1")
	var streamer := _world.get_node("Streamer") as SectorStreamer
	await wait_until(streamer.is_settled, 10.0)
	assert_eq(_map.cell_state(SectorMap.cell_named("A5")), &"loaded", "the pond, next to the hero")
	assert_eq(_map.cell_state(SectorMap.cell_named("T20")), &"empty", "no design there")
	_console.execute("radius 0")
	assert_eq(_map.cell_state(SectorMap.cell_named("A5")), &"distant", "the pond, out of reach now")
	_console.execute("radius 4 5")
