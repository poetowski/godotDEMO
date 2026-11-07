extends GutTest
## The field builds flat and empty, the player starts on the ground in A1,
## sector names are painted where the grass is still flat, and the grass is
## solid well beyond the grid.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FieldScript := preload("res://src/world/field/field.gd")

var _world: Node3D


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)


func after_all() -> void:
	_world.free()


func test_player_starts_on_the_ground_in_the_middle_of_a1() -> void:
	var player := _world.get_node("Player") as Player
	await wait_until(player.is_on_floor, 5.0)
	assert_true(player.is_on_floor())
	assert_eq(SectorMap.name_of(SectorMap.cell_at(player.global_position)), "A1")
	assert_almost_eq(Vector2(player.global_position.x, player.global_position.z), Vector2(5.0, -5.0), Vector2.ONE * 0.3, "in its middle")


func test_the_world_is_one_flat_empty_region() -> void:
	assert_eq(RegionMap.count(), 1, "R1 alone")
	assert_eq(SectorMap.bounds(), Rect2(0.0, 0.0, 200.0, 200.0), "20 x 20 sectors of 10 m")
	assert_eq(_world.get_node("Sectors").get_child_count(), 0, "no sector designs yet")
	assert_true(WorldShape.is_flat())
	var terrain: FieldTerrain = _world.call("terrain")
	for xz: Vector2 in [Vector2(5.0, -5.0), Vector2(100.0, -100.0), Vector2(195.0, -195.0), Vector2(-300.0, 300.0)]:
		assert_eq(terrain.height_at(xz), 0.0, "flat at %s" % xz)
		assert_eq(terrain.water_level_at(xz), SectorDesign.NO_WATER, "dry at %s" % xz)


func test_hud_names_the_current_sector() -> void:
	await wait_process_frames(2)
	assert_eq((_world.get_node("Hud") as Hud).sector_text(), "Sector A1")


func test_every_sector_has_a_painted_name() -> void:
	var grid := _world.get_node("SectorGrid")
	assert_not_null(grid.get_node_or_null("LabelA1"))
	assert_not_null(grid.get_node_or_null("LabelT20"))
	assert_eq(grid.get_children().filter(func(child: Node) -> bool: return child is Label3D).size(), SectorMap.COLUMNS * SectorMap.ROWS)


func test_names_show_in_sectors_without_a_design() -> void:
	var grid := _world.get_node("SectorGrid")
	assert_true((grid.get_node("LabelA1") as Label3D).visible)
	assert_true((grid.get_node("LabelT20") as Label3D).visible)


func test_grass_is_solid_far_beyond_the_grid() -> void:
	await wait_physics_frames(2)
	var from := Vector3(-400.0, 10.0, 400.0)
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 20.0))
	assert_false(hit.is_empty())


func test_sector_argument_picks_the_start() -> void:
	assert_eq(FieldScript.requested_sector(PackedStringArray(["--sector=C4"])), "C4")
	assert_eq(FieldScript.requested_sector(PackedStringArray()), "A1")
	assert_eq(FieldScript.requested_sector(PackedStringArray(), "J10"), "J10")


func _drop_from(metres: float) -> Player:
	var player: Player = _world.call("player")
	player.global_position = Vector3(35.0, WorldShape.height(Vector2(35.0, -45.0)) + metres, -45.0)
	player.velocity = Vector3.ZERO
	return player


func test_a_short_fall_does_nothing() -> void:
	var player := _drop_from(6.0)
	watch_signals(player)
	await wait_seconds(1.6)
	assert_signal_not_emitted(player, "died")
	assert_eq(player.hp, player.max_hp)


func test_a_long_fall_kills_and_respawns() -> void:
	var player := _drop_from(14.0)
	watch_signals(player)
	await wait_seconds(2.4)
	assert_signal_emitted(player, "died")
	assert_eq(player.hp, player.max_hp, "alive again")
	assert_eq(SectorMap.cell_at(player.global_position), SectorMap.cell_named("A1"), "at the spawn point")


func test_c_opens_the_character_panel() -> void:
	var hud := _world.get_node("Hud") as Hud
	var panel := hud.character_panel()
	assert_true(InputMap.has_action("character"))
	panel.open()
	panel.finish_slide()
	assert_true(panel.is_open())
	assert_string_contains(panel.text(), "Hero Level: 1")
	assert_string_contains(panel.text(), "HP: 100/100")
	var player: Player = _world.call("player")
	assert_false(player.input_enabled, "the hero stands still meanwhile")
	panel.close()
	assert_true(player.input_enabled)


func test_g_hides_and_shows_every_border() -> void:
	var grid := _world.get_node("SectorGrid") as Node3D
	assert_true(grid.visible, "shown to start with")
	var press := InputEventAction.new()
	press.action = "toggle_borders"
	press.pressed = true
	_world.call("_unhandled_input", press)
	assert_false(grid.visible, "curtains and names hidden")
	assert_false(FieldTerrain.ground_material().get_shader_parameter(&"show_lines"), "and the lines on the ground")
	_world.call("_unhandled_input", press)
	assert_true(grid.visible)
	assert_true(FieldTerrain.ground_material().get_shader_parameter(&"show_lines"))
