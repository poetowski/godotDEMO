extends GutTest
## The castle PoC builds, the player lands on the terrain at the spawn, and the
## sword waits in its stone where the layout says.

const SCENE_PATH := "res://src/world/poc_castle/castle_poc.tscn"

var _world: Node3D


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)


func after_all() -> void:
	_world.free()


func test_player_lands_on_the_terrain_at_the_spawn() -> void:
	var player := _world.get_node("Player") as Player
	await wait_until(player.is_on_floor, 5.0)
	assert_true(player.is_on_floor())
	var spawn := PocLayout.ground(PocLayout.SPAWN)
	assert_almost_eq(player.global_position.x, spawn.x, 0.5)
	assert_almost_eq(player.global_position.y, spawn.y, 0.3)


func test_sword_waits_in_its_stone() -> void:
	var stone := _world.get_node("SwordStone") as SwordStone
	assert_true(stone.has_sword())
	var where := Vector2(stone.global_position.x, stone.global_position.z)
	assert_almost_eq(where.distance_to(PocLayout.SWORD), 0.0, 0.01)


func test_castle_walls_are_solid() -> void:
	await wait_physics_frames(2)
	var from := PocLayout.ground(PocLayout.CASTLE_CENTER) + Vector3(-20.0, 3.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(10.0, 0.0, 0.0))
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "a ray from outside hits the west wall")
