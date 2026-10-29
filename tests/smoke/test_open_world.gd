extends GutTest
## The open world: 10 x 10 regions whose ground and woods stream around the
## player, detailed near and coarse far, the same wherever the player goes.
## R1, where the world is built from, is flat and clear of woods.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _player: Player
var _terrain: FieldTerrain
var _vegetation: Vegetation


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_player = _world.call("player") as Player
	_terrain = _world.call("terrain") as FieldTerrain
	_vegetation = _world.call("vegetation") as Vegetation


func after_all() -> void:
	_world.free()
	RegionMap.configure(1, 1)
	WorldShape.configure(0.0)


func _xz() -> Vector2:
	return Vector2(_player.global_position.x, _player.global_position.z)


func before_each() -> void:
	if SectorMap.name_of(SectorMap.cell_at(_player.global_position)) != "R56:J10":
		_world.call("teleport", SectorMap.cell_named("R56:J10"))
	await wait_physics_frames(2)


func test_0_the_world_has_100_regions_and_starts_in_r1() -> void:
	assert_eq(RegionMap.count(), 100)
	assert_eq((_world as Node).get("start_sector"), "A1")
	assert_eq(SectorMap.cell_named("A1"), SectorMap.cell_named("R1:A1"))


func test_1_r1_is_flat_and_clear_and_the_hills_rise_beyond() -> void:
	for k in 20:
		assert_eq(_terrain.height_at(Vector2(10.0 + k * 9.0, -15.0 - k * 9.0)), 0.0, "flat in R1")
	assert_eq(_vegetation.tree_count(Vector2i(0, 0)), 0)
	var far := 0.0
	for k in 20:
		far = maxf(far, absf(_terrain.height_at(Vector2(700.0 + k * 31.0, -700.0 - k * 17.0))))
	assert_gt(far, 5.0, "hills well beyond R1")


func test_1b_standing_in_the_middle_of_the_world() -> void:
	assert_eq(SectorMap.name_of(SectorMap.cell_at(_player.global_position)), "R56:J10")
	await wait_physics_frames(10)
	assert_true(_player.is_on_floor(), "standing on the streamed ground")


func test_2_ground_is_detailed_near_and_coarse_far() -> void:
	var chunks := _terrain.chunks()
	assert_eq(chunks.step_at(_xz()), 1.0, "every metre underfoot")
	assert_eq(chunks.step_at(_xz() + Vector2(250.0, 0.0)), 4.0, "every 4 m in the next region")
	assert_eq(chunks.step_at(_xz() + Vector2(0.0, 700.0)), 20.0, "every 20 m far off")
	assert_lt(chunks.tile_count(), 200)


func test_3_the_land_rolls() -> void:
	var lowest := INF
	var highest := -INF
	for k in 40:
		var height := _terrain.height_at(_xz() + Vector2(k * 10.0, k * 7.0))
		lowest = minf(lowest, height)
		highest = maxf(highest, height)
	assert_gt(highest - lowest, 8.0)


func test_4_woods_grow_around_the_player() -> void:
	var here := Vegetation.chunk_at(_xz())
	var trees := 0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			trees += _vegetation.tree_count(here + Vector2i(dx, dz))
	assert_gt(trees, 50)
	assert_true(_vegetation.has_detail(here), "bushes, grass and trunks close by")
	assert_eq(_vegetation.tree_count(here + Vector2i(6, 0)), 0, "nothing far away")


func test_5_going_elsewhere_streams_it_in_and_lets_the_old_place_go() -> void:
	var before := _xz()
	var tiles := _terrain.chunks().tile_count()
	_world.call("teleport", SectorMap.cell_named("R1:A1"))
	await wait_physics_frames(10)
	assert_eq(SectorMap.name_of(SectorMap.cell_at(_player.global_position)), "R1:A1")
	assert_eq(_terrain.chunks().step_at(_xz()), 1.0)
	assert_eq(_terrain.chunks().step_at(before), 20.0, "the middle is far off now, coarse")
	assert_lt(_terrain.chunks().tile_count(), tiles + 20, "no more tiles than before")
	assert_true(_player.is_on_floor())
	await wait_until(func() -> bool: return (_world.get_node("SectorGrid") as Node).call("region") == Vector2i.ZERO, 5.0)
	assert_eq((_world.get_node("SectorGrid") as Node).call("region"), Vector2i.ZERO, "the grid follows into R1")
	_world.call("teleport", SectorMap.cell_named("R56:J10"))
	await wait_physics_frames(2)


func test_6_the_distant_forest_reaches_the_horizon() -> void:
	var far := _vegetation.far_forest
	far.update()
	await wait_until(far.is_settled, 30.0)
	assert_gt(far.block_count(), 4)
	assert_lt(far.block_count(), 50, "only blocks in view")
	var block := FarForest.block_at(_xz() + Vector2(700.0, -300.0))
	assert_gt(far.tree_count(block), 100, "woods far off")
	assert_eq(far.hide_within, _vegetation.tree_chunks * Vegetation.CHUNK, "the stand-ins give way where the real trees stand")
