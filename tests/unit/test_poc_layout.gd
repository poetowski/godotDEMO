extends GutTest

const CASTLE_OFFSETS: Array[Vector2] = [Vector2.ZERO, Vector2(12.0, 0.0), Vector2(-15.0, 14.0), Vector2(0.0, -20.0)]


func test_castle_stands_on_flat_ground() -> void:
	var center := PocLayout.CASTLE_CENTER
	for offset in CASTLE_OFFSETS:
		var spot := center + offset
		assert_almost_eq(PocLayout.height_at(spot.x, spot.y), PocLayout.CASTLE_GROUND, 0.01, "at %s" % spot)


func test_path_starts_at_the_spawn_and_runs_through_the_gate() -> void:
	assert_lt(PocLayout.path_distance_at(PocLayout.SPAWN.x, PocLayout.SPAWN.y), 1.0)
	var gate_z := PocLayout.CASTLE_CENTER.y + 16.0
	assert_lt(PocLayout.path_distance_at(PocLayout.CASTLE_CENTER.x, gate_z), 0.5)


func test_sword_sits_beside_the_path() -> void:
	var distance := PocLayout.path_distance_at(PocLayout.SWORD.x, PocLayout.SWORD.y)
	assert_between(distance, 3.0, 10.0)


func test_height_between_samples_is_interpolated() -> void:
	var a := PocLayout.height_at(10.0, 10.0)
	var b := PocLayout.height_at(11.0, 10.0)
	var middle := PocLayout.height_at(10.5, 10.0)
	assert_almost_eq(middle, (a + b) * 0.5, 0.001)
