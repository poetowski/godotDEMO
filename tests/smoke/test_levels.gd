extends GutTest
## More than one walkable height at the same x and z: floors over water, caves under
## it, pools of their own, named places and holes in the ground. The real bridge is
## walked in test_r1_waterside.gd.

const FixtureDesign := preload("res://tests/fixtures/fixture_design.gd")
const Settle := preload("res://tools/settle_props.gd")
## Dry land in the test world, away from everything.
const DRY := Vector2(120.0, -120.0)

var _world: Node
var _player: Player
var _terrain: FieldTerrain
var _hud: Hud
var _pond: SectorDesign
var _spot := Vector2.ZERO
var _level := 0.0
var _added: Array[Node] = []


func before_all() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	_pond = FixtureDesign.add_to(_world, "LevelsPond", PackedStringArray(["F6"]))
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_player = _world.call("player") as Player
	_terrain = _world.call("terrain") as FieldTerrain
	_hud = _world.get_node("Hud") as Hud
	_spot = _pond.call("pond", "F6")
	_level = _terrain.water_level_at(_spot)


func after_all() -> void:
	_world.free()


func after_each() -> void:
	for node in _added:
		node.free()
	_added.clear()
	_stand_at(DRY)
	await wait_physics_frames(3)


func _add(node: Node) -> Node:
	_world.add_child(node)
	_added.append(node)
	return node


## A solid slab at `spot`, its top at `height`.
func _slab(spot: Vector2, height: float, side: float = 8.0) -> StaticBody3D:
	var shape := BoxShape3D.new()
	shape.size = Vector3(side, 0.4, side)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.add_child(collision)
	body.position = Vector3(spot.x, height - 0.2, spot.y)
	return _add(body) as StaticBody3D


func _volume(spot: Vector2, height: float, size: Vector3) -> LevelVolume:
	var volume := LevelVolume.new()
	volume.size = size
	volume.position = Vector3(spot.x, height, spot.y)
	return _add(volume) as LevelVolume


func _put_hero(spot: Vector2, height: float) -> void:
	_player.global_position = Vector3(spot.x, height, spot.y)
	_player.velocity = Vector3.ZERO
	_player.revive()


func _stand_at(spot: Vector2) -> void:
	_put_hero(spot, _terrain.height_at(spot) + 0.1)


func test_on_a_floor_above_water_the_hero_walks() -> void:
	var deck := _level + 3.0
	_slab(_spot, deck)
	_put_hero(_spot, deck + 0.1)
	await wait_physics_frames(40)
	assert_false(_player.is_swimming, "not in the water below")
	assert_true(_player.is_on_floor())
	assert_almost_eq(_player.global_position.y, deck, 0.1, "stays up on the floor")
	assert_eq((_player.get_node("Footsteps") as Footsteps).surface_underfoot(), &"grass", "no splashing up here")
	var place := LevelMap.at(_terrain, _player.global_position)
	assert_almost_eq(place.water, _level, 0.001, "the water is known, below")
	assert_false(place.is_in_water())


func test_under_that_floor_the_hero_swims() -> void:
	_slab(_spot, _level + 3.0)
	_put_hero(_spot, _level - 0.5)
	await wait_physics_frames(60)
	assert_true(_player.is_swimming)
	assert_almost_eq(_player.global_position.y, _level - _player.float_depth, 0.15)


func test_a_floor_under_a_little_water_is_waded_on() -> void:
	var deck := _level - 0.4
	_slab(_spot, deck)
	_put_hero(_spot, deck + 0.05)
	await wait_physics_frames(40)
	assert_false(_player.is_swimming, "the water is deep below, but not above this floor")
	assert_almost_eq(_player.global_position.y, deck, 0.1)
	assert_eq((_player.get_node("Footsteps") as Footsteps).surface_underfoot(), &"water", "it splashes")


func test_falling_into_deep_water_is_caught_only_at_its_surface() -> void:
	watch_signals(_player)
	_put_hero(_spot, _level + 14.0)
	await wait_physics_frames(20)
	assert_gt(_player.global_position.y, _level, "still in the air")
	assert_false(_player.is_swimming, "and not swimming in it")
	await wait_seconds(2.0)
	assert_true(_player.is_swimming, "then in the water")
	assert_signal_not_emitted(_player, "died")


func test_falling_onto_a_floor_above_water_still_kills() -> void:
	_slab(_spot, _level + 1.0)
	watch_signals(_player)
	_put_hero(_spot, _level + 15.0)
	await wait_seconds(2.2)
	assert_signal_emitted(_player, "died")


func test_a_cave_under_the_water_is_dry() -> void:
	var bed := _terrain.height_at(_spot)
	var cave_floor := bed - 8.0
	_slab(_spot, cave_floor)
	_put_hero(_spot, cave_floor + 0.1)
	await wait_physics_frames(30)
	assert_false(_player.is_swimming, "the pond is overhead")
	assert_almost_eq(_player.global_position.y, cave_floor, 0.1)
	var place := LevelMap.at(_terrain, _player.global_position)
	assert_true(place.is_underground())
	assert_eq(place.water, SectorDesign.NO_WATER)
	assert_true(place.is_enclosed(), "underground counts as enclosed without any setting up")
	assert_eq((_player.get_node("Footsteps") as Footsteps).surface_underfoot(), &"grass")


func test_a_pool_in_a_cave_has_its_own_surface() -> void:
	var cave_floor := _terrain.height_at(DRY) - 20.0
	_slab(DRY, cave_floor)
	var chamber := _volume(DRY, cave_floor, Vector3(8.0, 5.0, 8.0))
	chamber.water_depth = 2.5
	_put_hero(DRY, cave_floor + 1.5)
	await wait_physics_frames(60)
	assert_true(_player.is_swimming, "swims down here, with no water above")
	assert_almost_eq(_player.global_position.y, chamber.water_surface() - _player.float_depth, 0.15)
	chamber.water_depth = 0.6
	await wait_physics_frames(45)
	assert_false(_player.is_swimming, "too shallow to swim now")
	assert_almost_eq(_player.global_position.y, cave_floor, 0.1, "wading on the floor")


func test_the_pool_is_only_in_its_volume() -> void:
	var chamber := _volume(DRY, _terrain.height_at(DRY) - 20.0, Vector3(8.0, 5.0, 8.0))
	chamber.water_depth = 2.5
	assert_eq(LevelMap.at(_terrain, Vector3(DRY.x, _terrain.height_at(DRY) + 1.0, DRY.y)).water, SectorDesign.NO_WATER, "none on the land above it")


func test_a_named_place_shows_and_hushes_the_ambience() -> void:
	var ambience := _world.get_node("Ambience") as Ambience
	var wind := ambience.get_node("Wind") as AudioStreamPlayer
	var open_wind := ambience.wind_db
	var fifth := _terrain.height_at(DRY) + 16.0
	_slab(DRY, fifth)
	var floor_five := _volume(DRY, fifth, Vector3(8.0, 3.0, 8.0))
	floor_five.place_name = "Bell tower, floor 5"
	_put_hero(DRY, fifth + 0.1)
	await wait_seconds(0.3)
	assert_string_contains(_hud.sector_text(), "Bell tower, floor 5")
	assert_string_contains(_hud.sector_text(), "Sector", "the sector still shows")
	assert_true(ambience.is_enclosed())
	await wait_seconds(1.6)
	assert_lt(wind.volume_db, open_wind - 10.0, "the wind has dropped")
	_stand_at(DRY)
	await wait_seconds(1.7)
	assert_false(_hud.sector_text().contains("Bell tower"), "gone on the ground below it")
	assert_false(ambience.is_enclosed())
	assert_almost_eq(wind.volume_db, open_wind, 0.5, "the wind is back")


func test_an_open_rooftop_is_not_enclosed() -> void:
	var roof := _volume(DRY, _terrain.height_at(DRY) + 20.0, Vector3(8.0, 3.0, 8.0))
	roof.enclosed = false
	assert_false(LevelMap.at(_terrain, roof.position + Vector3.UP).is_enclosed())
	roof.enclosed = true
	assert_true(LevelMap.at(_terrain, roof.position + Vector3.UP).is_enclosed())


func test_the_smallest_volume_around_a_point_wins() -> void:
	var height := _terrain.height_at(DRY) + 10.0
	var tower := _volume(DRY, height, Vector3(10.0, 20.0, 10.0))
	tower.place_name = "Tower"
	var room := _volume(DRY, height + 4.0, Vector3(3.0, 3.0, 3.0))
	room.place_name = "Room"
	assert_eq(LevelMap.at(_terrain, Vector3(DRY.x, height + 5.0, DRY.y)).place_name(), "Room")
	assert_eq(LevelMap.at(_terrain, Vector3(DRY.x, height + 1.0, DRY.y)).place_name(), "Tower")
	assert_eq(LevelMap.at(_terrain, Vector3(DRY.x, height + 30.0, DRY.y)).place_name(), "", "above them both")


func test_a_volume_follows_its_turn() -> void:
	var volume := _volume(DRY, 0.0, Vector3(10.0, 3.0, 2.0))
	volume.rotation.y = PI / 2.0
	assert_true(volume.contains(volume.position + Vector3(0.5, 1.0, 4.0)), "long along z when turned")
	assert_false(volume.contains(volume.position + Vector3(4.0, 1.0, 0.5)))


func test_an_opening_lets_the_hero_down_into_the_ground() -> void:
	var ground := _terrain.height_at(DRY)
	var opening := GroundOpening.new()
	opening.size = Vector2(6.0, 6.0)
	opening.position = Vector3(DRY.x, ground, DRY.y)
	_add(opening)
	var cellar := ground - 6.0
	_slab(DRY, cellar, 12.0)
	# Beside the hole first, so the ground around it is at its finest.
	var beside := DRY + Vector2(8.0, 0.0)
	_stand_at(beside)
	_terrain.refresh_openings(opening.samples_around())
	_terrain.prepare_around_focus()
	await wait_physics_frames(5)
	assert_true(_terrain.is_ground_open(DRY))
	assert_false(_terrain.is_dry(DRY), "nobody is put down over it")
	var safe := _terrain.find_dry_spot(DRY)
	assert_false(_terrain.is_ground_open(safe), "a teleport lands beside it")
	assert_true(_ground_stops_a_ray_at(beside), "the ground beside it is whole")
	assert_false(_ground_stops_a_ray_at(DRY), "no collision in the hole")
	assert_eq(_vertices_missing_from_the_tile_at(DRY), 36 * 6, "two triangles gone for each of the hole's 36 squares")
	watch_signals(_player)
	_put_hero(DRY, ground + 0.5)
	await wait_seconds(1.6)
	assert_almost_eq(_player.global_position.y, cellar, 0.1, "down on the floor below")
	assert_signal_not_emitted(_player, "died")
	assert_true(LevelMap.at(_terrain, _player.global_position).is_underground())
	# Closed again for the rest of the tests.
	_added.erase(opening)
	var area := opening.samples_around()
	opening.free()
	_terrain.refresh_openings(area)
	_stand_at(beside)
	_terrain.prepare_around_focus()
	await wait_physics_frames(5)
	assert_false(_terrain.is_ground_open(DRY))
	assert_true(_ground_stops_a_ray_at(DRY), "closed over again")


func test_a_moved_opening_moves_the_hole() -> void:
	var opening := GroundOpening.new()
	opening.size = Vector2(4.0, 2.0)
	opening.position = Vector3(DRY.x, 0.0, DRY.y)
	_add(opening)
	_terrain.refresh_openings(opening.samples_around())
	assert_true(_terrain.is_ground_open(DRY))
	assert_false(_terrain.is_ground_open(DRY + Vector2(0.0, 1.5)), "two metres along, so one either side")
	# It watches for this by itself in the editor.
	opening.set_process(true)
	opening.rotation.y = PI / 2.0
	await wait_seconds(GroundOpening.WATCH_INTERVAL + 0.2)
	assert_true(_terrain.is_ground_open(DRY + Vector2(0.0, 1.5)), "the hole turned with it")
	_added.erase(opening)
	var area := opening.samples_around()
	opening.free()
	_terrain.refresh_openings(area)


func test_falling_for_ever_counts_as_dying() -> void:
	watch_signals(_player)
	_put_hero(DRY, _terrain.height_at(DRY) + Player.LOST_FALL + 80.0)
	_player.velocity = Vector3.DOWN * 100.0
	await wait_seconds(2.0)
	assert_signal_emitted(_player, "died")
	assert_eq(_player.hp, _player.max_hp, "and back at the spawn point, alive")


func test_a_save_keeps_the_hero_on_their_floor() -> void:
	var deck := _level + 3.0
	_slab(_spot, deck)
	_put_hero(_spot, deck + 0.05)
	await wait_physics_frames(10)
	var saved: Dictionary = _world.call("capture")
	_stand_at(DRY)
	await wait_physics_frames(5)
	_world.call("apply", saved)
	await wait_physics_frames(30)
	assert_almost_eq(_player.global_position.y, deck, 0.1, "back up on the deck")
	assert_false(_player.is_swimming)


func test_settling_leaves_what_stands_on_a_floor_alone() -> void:
	var prop := Prop.new()
	prop.kind = PropLibrary.Kind.ASSET
	prop.asset = PropLibrary.asset_scene("lantern_post")
	prop.position = Vector3(DRY.x, 30.0, DRY.y)
	autofree(prop)
	assert_true(prop.stands_on_ground())
	assert_almost_eq(Settle.standing_height(prop), WorldShape.height(DRY) - Settle.SINK, 0.4, "pulled down to the land")
	prop.keep_height = true
	assert_false(prop.stands_on_ground())
	assert_eq(Settle.standing_height(prop), 30.0, "kept up on its floor")
	prop.keep_height = false
	prop.asset = PropLibrary.asset_scene("wooden_bridge")
	assert_false(prop.stands_on_ground(), "a bridge never settles")


func test_outlines_show_a_whole_box() -> void:
	var lines := autofree(LevelMap.outline(Vector3(4.0, 2.0, 6.0), Color.WHITE)) as MeshInstance3D
	var box := lines.mesh.get_aabb()
	assert_eq(box.size, Vector3(4.0, 2.0, 6.0))
	assert_eq(box.position.y, 0.0, "standing on its origin")


## True if a ray straight down at a spot stops within a metre of the ground there.
func _ground_stops_a_ray_at(spot: Vector2) -> bool:
	var ground := _terrain.height_at(spot)
	var space := (_world as Node3D).get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(spot.x, ground + 3.0, spot.y), Vector3(spot.x, ground - 1.0, spot.y))
	query.exclude = [_player.get_rid()]
	return not space.intersect_ray(query).is_empty()


## How many vertices a spot's finest tile is short of a whole one's: every square is
## two triangles, and a tile with none open has them all, and its skirts. Found by
## place, since a tile made over while the old one is freeing gets another name.
func _vertices_missing_from_the_tile_at(spot: Vector2) -> int:
	var whole := int(TerrainChunks.CHUNK * TerrainChunks.CHUNK) * 6
	var skirts := 4 * int(TerrainChunks.CHUNK) * 6
	for child in _terrain.get_children():
		var tile := child as MeshInstance3D
		if tile == null or not tile.mesh is ArrayMesh:
			continue
		var box := tile.mesh.get_aabb()
		if is_equal_approx(box.size.x, TerrainChunks.CHUNK) and box.has_point(Vector3(spot.x, box.get_center().y, spot.y)):
			return whole + skirts - (tile.mesh as ArrayMesh).surface_get_array_len(0)
	return -1
