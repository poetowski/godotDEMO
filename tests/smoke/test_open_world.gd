extends GutTest
## The world: one region, R1, of 20 x 20 flat sectors, with nothing in it yet.
## Its ground streams around the player, and it stays the same every run.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _player: Player
var _terrain: FieldTerrain


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_player = _world.call("player") as Player
	_terrain = _world.call("terrain") as FieldTerrain


func after_all() -> void:
	_world.free()
	RegionMap.configure(1, 1)
	WorldShape.configure()


func test_the_world_is_r1_alone_with_classic_sectors() -> void:
	assert_eq(RegionMap.count(), 1)
	assert_eq(SectorMap.COLUMNS, 20)
	assert_eq(SectorMap.ROWS, 20)
	assert_eq(SectorMap.extent(), Vector2(200.0, 200.0))
	assert_eq(SectorMap.name_of(SectorMap.cell_at(_player.global_position)), "A1", "the start")


func test_there_is_nothing_in_it_yet() -> void:
	assert_eq(_terrain.designs().size(), 0, "no sector designs")
	assert_eq((_world.get_node("Residents") as Node).get_child_count(), 0, "no villagers")


func test_the_land_is_flat() -> void:
	for i in 20:
		for j in 20:
			var xz := Vector2(5.0 + i * 10.0, -5.0 - j * 10.0)
			assert_eq(_terrain.height_at(xz), 0.0, "flat at %s" % xz)


func test_the_same_land_every_run() -> void:
	var at := Vector2(87.0, -113.0)
	var height := WorldShape.height(at)
	FieldWorld.configure()
	assert_eq(WorldShape.height(at), height)


func test_the_hero_stands_on_the_ground_and_it_is_detailed_underfoot() -> void:
	await wait_physics_frames(10)
	assert_true(_player.is_on_floor())
	var xz := Vector2(_player.global_position.x, _player.global_position.z)
	assert_eq(_terrain.chunks().step_at(xz), 1.0, "every metre underfoot")
	assert_eq(_terrain.chunks().tile_count(), 4, "R1's four 100 m chunks")
