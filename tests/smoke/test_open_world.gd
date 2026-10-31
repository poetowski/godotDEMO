extends GutTest
## The world: one region, R1, of 20 x 20 sectors, rolling with Perlin noise.
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
	WorldShape.configure(0.0)


func test_the_world_is_r1_alone_with_classic_sectors() -> void:
	assert_eq(RegionMap.count(), 1)
	assert_eq(SectorMap.COLUMNS, 20)
	assert_eq(SectorMap.ROWS, 20)
	assert_eq(SectorMap.extent(), Vector2(200.0, 200.0))
	assert_eq(SectorMap.name_of(SectorMap.cell_at(_player.global_position)), "A1", "the start")


func test_there_is_nothing_in_it_yet() -> void:
	for design in _terrain.designs():
		assert_true(design.decorates_land, "%s only decorates the land" % design.name)
	assert_eq((_world.get_node("Residents") as Node).get_child_count(), 0)


func test_the_land_rolls_inside_the_region() -> void:
	var lowest := INF
	var highest := -INF
	for i in 20:
		for j in 20:
			var height := _terrain.height_at(Vector2(15.0 + i * 8.5, -15.0 - j * 8.5))
			lowest = minf(lowest, height)
			highest = maxf(highest, height)
	assert_gt(highest - lowest, 0.5, "not flat")
	assert_lt(highest - lowest, FieldWorld.HILL_HEIGHT * 2.0 + 1.0)


func test_the_land_eases_flat_at_the_regions_edge() -> void:
	for k in 20:
		assert_almost_eq(_terrain.height_at(Vector2(k * 10.0 + 3.0, 0.0)), 0.0, 0.001)
		assert_almost_eq(_terrain.height_at(Vector2(200.0, -k * 10.0 - 3.0)), 0.0, 0.001)


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
	assert_lte(_terrain.chunks().tile_count(), 4, "the region's 100 m chunks")
