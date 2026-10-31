extends GutTest
## The field builds, the player starts on the ground in A1, sector names are
## painted where the grass is still flat, and the grass is solid well beyond
## the grid.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FieldScript := preload("res://src/world/field/field.gd")

var _world: Node3D


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)


func after_all() -> void:
	_world.free()


func test_player_starts_on_the_ground_in_a1() -> void:
	var player := _world.get_node("Player") as Player
	await wait_until(player.is_on_floor, 5.0)
	assert_true(player.is_on_floor())
	assert_eq(SectorMap.name_of(SectorMap.cell_at(player.global_position)), "R1:A1")


func test_hud_names_the_current_sector() -> void:
	await wait_process_frames(2)
	assert_eq((_world.get_node("Hud") as Hud).sector_text(), "Sector R1:A1")


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


func test_column_m_warns_and_going_on_returns_to_the_spawn_point() -> void:
	var player: Player = _world.call("player")
	var hud := _world.get_node("Hud") as Hud
	hud.notify("")
	player.global_position = Vector3(-60.0, 5.0, -100.0)
	await wait_process_frames(2)
	assert_eq(hud.toast_text(), "", "east of M, nothing")
	player.global_position = Vector3(-75.0, 5.0, -100.0)
	await wait_process_frames(2)
	assert_eq(hud.toast_text(), "I should not be here...")
	player.global_position = Vector3(-81.0, 5.0, -100.0)
	await wait_process_frames(2)
	assert_eq(SectorMap.cell_at(player.global_position), Vector2i.ZERO, "back at the spawn point")

