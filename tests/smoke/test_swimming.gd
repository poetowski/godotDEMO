extends GutTest
## The hero swims in water at least a metre deep (the oasis pond, the
## R11 lake), floating at the surface with the swim animation, and
## walks again on the shore.

var _world: Node
var _player: Player


func before_all() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_player = _world.call("player") as Player


func after_all() -> void:
	_world.free()


func test_the_hero_has_a_swim_animation() -> void:
	var animations := _player.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	assert_true(animations.has_animation(&"swim"))
	assert_eq(animations.get_animation(&"swim").loop_mode, Animation.LOOP_LINEAR)


func test_swims_in_the_oasis_pond_and_floats_at_the_surface() -> void:
	var terrain := _world.call("terrain") as FieldTerrain
	var spot := Vector2(30.0, -49.0)
	assert_gt(terrain.water_level_at(spot) - terrain.height_at(spot), 1.0, "the pond is over a metre deep")
	_player.global_position = Vector3(spot.x, terrain.water_level_at(spot) - 0.5, spot.y)
	await wait_physics_frames(60)
	assert_true(_player.is_swimming)
	assert_almost_eq(_player.global_position.y, terrain.water_level_at(spot) - _player.float_depth, 0.15)
	assert_gt(float(_player.body().get_node("AnimationTree").get("parameters/water/blend_amount")), 0.5, "the swim animation plays")


func test_walks_on_dry_land_and_in_shallow_water() -> void:
	var terrain := _world.call("terrain") as FieldTerrain
	_player.global_position = Vector3(25.0, terrain.height_at(Vector2(25.0, -42.5)) + 0.1, -42.5)
	await wait_physics_frames(30)
	assert_false(_player.is_swimming)


func test_the_r11_lake_is_water_to_swim_in() -> void:
	var terrain := _world.call("terrain") as FieldTerrain
	var spot := Vector2(100.0, -260.0)
	assert_gt(terrain.water_level_at(spot) - terrain.height_at(spot), 1.0)
