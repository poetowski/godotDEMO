extends GutTest
## The stress world: all 400 sectors are woodland designs on hills that run
## across sector borders without a step and ease to flat at the grid's
## edge; the area around the player streams in.

const SCENE_PATH := "res://src/world/stress/stress_field.tscn"

var _world: Node3D
var _terrain: FieldTerrain


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_terrain = _world.get_node("Terrain") as FieldTerrain


func after_all() -> void:
	_world.free()
	WorldShape.configure(0.0)


func test_every_sector_is_woodland() -> void:
	assert_eq(_terrain.designs().size(), SectorMap.COLUMNS * SectorMap.ROWS)


func test_the_land_is_hilly() -> void:
	var lowest := INF
	var highest := -INF
	for k in 50:
		var height := _terrain.height_at(Vector2(20.0 + k * 3.2, -20.0 - k * 3.2))
		lowest = minf(lowest, height)
		highest = maxf(highest, height)
	assert_gt(highest - lowest, 2.0)


func test_hills_cross_sector_borders_without_a_step() -> void:
	for k in 40:
		var border := Vector2(50.0, -12.0 - k * 4.0)
		var west := _terrain.design_at(border - Vector2(0.001, 0.0))
		var east := _terrain.design_at(border + Vector2(0.001, 0.0))
		assert_ne(west, east)
		assert_almost_eq(west.height_at(border - Vector2(0.001, 0.0)), east.height_at(border + Vector2(0.001, 0.0)), 0.01, "at %s" % border)


func test_hills_ease_to_flat_at_the_grid_edge() -> void:
	assert_almost_eq(_terrain.height_at(Vector2(0.001, -100.0)), 0.0, 0.01)
	assert_eq(_terrain.height_at(Vector2(-50.0, -100.0)), 0.0)


func test_the_player_starts_among_loaded_woods() -> void:
	var streamer := _world.get_node("Streamer") as SectorStreamer
	await wait_until(streamer.is_settled, 10.0)
	var loaded := streamer.loaded_designs().size()
	assert_between(loaded, 4, 49, "only the area around the start")
	var player := _world.get_node("Player") as Player
	await wait_until(player.is_on_floor, 5.0)
	assert_true(player.is_on_floor())
