extends GutTest
## The field streams its sector designs around the player: near designs load,
## far ones unload and leave a coarse stand-in of their ground, heights stay
## known everywhere, and things the player took stay taken. Uses a fixture
## design; the game has no designs yet.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FixtureDesign := preload("res://tests/fixtures/fixture_design.gd")

var _world: Node3D
var _streamer: SectorStreamer
var _terrain: FieldTerrain
var _player: Player
var _near: SectorDesign
var _far: SectorDesign


func before_all() -> void:
	WorldState.reset()
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	_near = FixtureDesign.add_to(_world, "NearPond", PackedStringArray(["A2"]))
	_far = FixtureDesign.add_to(_world, "FarPond", PackedStringArray(["A14"]))
	add_child(_world)
	_streamer = _world.get_node("Streamer") as SectorStreamer
	_terrain = _world.get_node("Terrain") as FieldTerrain
	_player = _world.get_node("Player") as Player


func after_all() -> void:
	_world.free()
	WorldState.reset()


func test_1_designs_near_the_start_are_loaded_and_far_ones_not() -> void:
	assert_true(_near.is_content_loaded(), "A2, next to the start")
	assert_false(_far.is_content_loaded(), "A14 is thirteen sectors away")
	assert_true(_terrain.shows_stand_in(SectorMap.cell_named("A14")), "its ground still shows, coarsely")
	assert_false(_terrain.shows_stand_in(SectorMap.cell_named("A2")))


func test_2_heights_are_known_while_unloaded() -> void:
	var pond: Vector2 = _far.call("pond", "A14")
	assert_lt(_terrain.height_at(pond), WorldShape.height(pond) - 2.0)
	assert_gt(_terrain.water_level_at(pond), _terrain.height_at(pond) + 1.0)


func test_3_taking_something_then_walking_away() -> void:
	var pebble := _near.part("Pebble") as ItemPickup
	_player.global_position = pebble.global_position + Vector3(0.0, 0.3, 0.8)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(8)
	_player.interact()
	assert_true(_player.inventory.has(&"pebble"))
	await _walk_to("A14")
	assert_true(_far.is_content_loaded(), "A14 loads around the player")
	assert_false(_near.is_content_loaded(), "A2 is far from the player now")
	assert_true(_terrain.shows_stand_in(SectorMap.cell_named("A2")))


func test_4_it_stays_taken_when_the_design_loads_again() -> void:
	await _walk_to("A1")
	assert_true(_near.is_content_loaded())
	assert_null(_near.part("Pebble"), "not back in the world")
	assert_true(_player.inventory.has(&"pebble"))


## Puts the player at a sector's start and waits for streaming to catch up.
func _walk_to(sector_name: String) -> void:
	var start := SectorMap.start_of(SectorMap.cell_named(sector_name))
	var spot := _terrain.find_dry_spot(Vector2(start.x, start.z))
	_player.global_position = Vector3(spot.x, _terrain.height_at(spot) + 0.3, spot.y)
	_player.velocity = Vector3.ZERO
	await wait_until(_streamer.is_settled, 10.0)
	await wait_physics_frames(40)
