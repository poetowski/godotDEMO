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


func test_mushrooms_grow_in_the_woods_and_can_be_collected() -> void:
	var streamer := _world.get_node("Streamer") as SectorStreamer
	await wait_until(streamer.is_settled, 10.0)
	var pickups: Array[ItemPickup] = []
	for design in streamer.loaded_designs():
		for node in design.content().find_children("Mushroom*", "ItemPickup", false, false):
			pickups.append(node as ItemPickup)
	assert_gt(pickups.size(), 3, "mushrooms among the loaded woods")
	var player := _world.get_node("Player") as Player
	player.inventory.clear()
	var first := pickups[0]
	var id := first.item.id
	var persist := first.persist_id
	first.interact(player)
	pickups[1].interact(player)
	assert_eq(player.inventory.count() + 0, 1 if pickups[1].item.id == id else 2)
	assert_true(player.inventory.has(id))
	assert_true(WorldState.is_taken(persist))
	player.inventory.clear()
	WorldState.reset()


func test_villagers_live_by_their_program() -> void:
	var clock: WorldClock = _world.call("clock")
	var villagers: Array[Villager] = []
	villagers.assign(_world.call("villagers"))
	assert_eq(villagers.size(), 10)
	clock.speed = 1.0
	clock.hour = 9.0
	for k in 40:
		for villager in villagers:
			villager.advance(1.0)
	for villager in villagers:
		assert_eq(villager.activity(), &"work", "%s works in the morning" % villager.display_name)
		assert_lt(villager.ground_position().distance_to(villager.work), 0.1)
	clock.hour = 12.5
	for k in 40:
		for villager in villagers:
			villager.advance(1.0)
	for villager in villagers:
		assert_eq(villager.activity(), &"talk", "%s is at lunch" % villager.display_name)
		assert_lt(villager.ground_position().distance_to(villager.meet), 2.0)
		assert_almost_eq(villager.global_position.y, _terrain.height_at(villager.ground_position()), 0.01, "on the ground")
