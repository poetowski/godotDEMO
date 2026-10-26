extends GutTest
## StreamPath measures distances from a stream in metres and half-widths, and
## gives the water level and downstream direction along it.


func _straight() -> StreamPath:
	var control: Array[Vector4] = [Vector4(0.0, 0.0, 1.0, 0.0), Vector4(10.0, 0.0, 1.0, -1.0)]
	return StreamPath.new(control, 2.0)


func test_measures_distance_from_the_centre_line() -> void:
	var hit := _straight().nearest(Vector2(5.0, 0.5))
	assert_almost_eq(hit.distance, 0.5, 0.01)
	assert_almost_eq(hit.reach(), 0.5, 0.01)
	assert_almost_eq(hit.edge(), -0.5, 0.01)


func test_level_and_direction_follow_the_stream() -> void:
	var hit := _straight().nearest(Vector2(5.0, -0.2))
	assert_almost_eq(hit.level, -0.5, 0.02)
	assert_almost_eq(hit.direction, Vector2.RIGHT, Vector2(0.001, 0.001))
	assert_almost_eq(hit.along, 5.0, 0.05)


func test_points_beyond_the_reach_have_no_stream() -> void:
	assert_not_null(_straight().nearest(Vector2(5.0, 2.9)))
	assert_null(_straight().nearest(Vector2(5.0, 3.1)))
	assert_null(_straight().nearest(Vector2(50.0, 50.0)))


func test_a_wide_last_point_makes_a_pond() -> void:
	var control: Array[Vector4] = [Vector4(0.0, 0.0, 0.5, 0.0), Vector4(6.0, 0.0, 0.5, 0.0), Vector4(8.0, 0.0, 2.0, 0.0)]
	var path := StreamPath.new(control, 2.0)
	assert_lt(path.nearest(Vector2(8.0, 1.5)).reach(), 1.0, "inside the pond")
	assert_gt(path.nearest(Vector2(3.0, 1.5)).reach(), 1.0, "beside the narrow stream")
	assert_almost_eq(path.length(), 8.0, 0.05)
