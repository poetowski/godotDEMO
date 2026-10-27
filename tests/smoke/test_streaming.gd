extends GutTest
## The field streams its sector designs around the player: near designs load,
## far ones unload and leave a coarse stand-in of their ground, heights stay
## known everywhere, things the player took stay taken, and baked content is
## what the designs would generate.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node3D
var _streamer: SectorStreamer
var _terrain: FieldTerrain
var _player: Player


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_streamer = _world.get_node("Streamer") as SectorStreamer
	_terrain = _world.get_node("Terrain") as FieldTerrain
	_player = _world.get_node("Player") as Player


func after_all() -> void:
	_world.free()


func test_1_designs_near_the_start_are_loaded_and_far_ones_not() -> void:
	assert_true(_design("A1A3Stream").is_content_loaded(), "A1 to A3, where the player starts")
	assert_true(_design("B1Cornflower").is_content_loaded())
	assert_false(_design("A7IvyStatue").is_content_loaded(), "A7 is six sectors away")
	assert_true(_terrain.shows_stand_in(SectorMap.cell_named("A7")), "its ground still shows, coarsely")
	assert_false(_terrain.shows_stand_in(SectorMap.cell_named("A1")))


func test_2_heights_are_known_while_unloaded() -> void:
	var castle := _design("D1E2Castle")
	var hilltop := Vector2(40.0, -10.8)
	assert_gt(castle.height_at(hilltop), 2.5)
	assert_gt(_terrain.height_at(Vector2(5.0, -66.2)), 0.0, "around the A7 statue")


func test_3_picking_the_cornflower_then_walking_away() -> void:
	var flower := _design("B1Cornflower").part("Cornflower") as ItemPickup
	_player.global_position = flower.global_position + Vector3(0.0, 0.3, 0.8)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(8)
	_player.interact()
	assert_true(_player.inventory.has(&"cornflower"))
	# In A8 the camera, behind the player, is in A7.
	await _walk_to("A8")
	assert_true(_design("A7IvyStatue").is_content_loaded(), "A7 loads around the player")
	assert_false(_design("B1Cornflower").is_content_loaded(), "B1 is six sectors from the camera now")
	assert_true(_design("C2ArcherTower").is_content_loaded(), "C2 is five away: inside the unload radius, so it stays")
	assert_true(_terrain.shows_stand_in(SectorMap.cell_named("B1")))
	assert_true(_player.is_on_floor(), "standing on the ground")


func test_4_the_cornflower_stays_picked_when_b1_loads_again() -> void:
	await _walk_to("B1")
	var meadow := _design("B1Cornflower")
	assert_true(meadow.is_content_loaded())
	assert_null(meadow.part("Cornflower"), "not back in the meadow")
	assert_true(_player.inventory.has(&"cornflower"))


func test_5_baked_content_matches_what_the_designs_generate() -> void:
	for design in _terrain.designs():
		var path := BakedSectors.scene_for(design.name)
		assert_false(path.is_empty(), "%s is baked and fresh" % design.name)
		if path.is_empty():
			continue
		var baked := (load(path) as PackedScene).instantiate()
		var generated := design.generate_content()
		assert_eq(_names(baked), _names(generated), design.name)
		baked.free()
		generated.free()


func _design(design_name: String) -> SectorDesign:
	return _world.get_node("Sectors/" + design_name) as SectorDesign


## Puts the player at a sector's start and waits for streaming to catch up.
func _walk_to(sector_name: String) -> void:
	var start := SectorMap.start_of(SectorMap.cell_named(sector_name))
	var spot := _terrain.find_dry_spot(Vector2(start.x, start.z))
	_player.global_position = Vector3(spot.x, _terrain.height_at(spot) + 0.3, spot.y)
	_player.velocity = Vector3.ZERO
	await wait_until(_streamer.is_settled, 10.0)
	await wait_physics_frames(40)


func _names(root: Node) -> PackedStringArray:
	var names := PackedStringArray()
	for child in root.get_children():
		names.append(child.name)
	names.sort()
	return names
