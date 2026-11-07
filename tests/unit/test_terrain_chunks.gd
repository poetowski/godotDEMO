extends GutTest
## The ground streams in levels of detail around its focus: 100 m chunks every
## metre next to it and every 4 m in the 3 x 3 regions around it, single 200 m
## region tiles every 8 m out to 3 regions away and every 20 m beyond, out to
## `view_regions`, and nothing past the world's edge.


func before_each() -> void:
	RegionMap.configure(10, 10)


func after_each() -> void:
	RegionMap.configure(1, 1)


func _wanted_around(xz: Vector2) -> Dictionary[Vector3i, float]:
	var chunks := TerrainChunks.new()
	chunks.view_regions = 6
	var wanted := chunks.wanted_tiles(xz)
	chunks.free()
	return wanted


func test_detail_falls_off_with_distance() -> void:
	# Inside region (5, 5): x 1000 to 1200, north 1000 to 1200; chunk (11, 11).
	var wanted := _wanted_around(Vector2(1150.0, -1150.0))
	assert_eq(wanted[Vector3i(11, 11, 0)], 1.0, "the chunk underfoot, every metre")
	assert_eq(wanted[Vector3i(10, 12, 0)], 1.0, "and the chunks around it")
	assert_eq(wanted[Vector3i(8, 8, 0)], 4.0, "the rest of the 3 x 3 regions, every 4 m")
	assert_false(wanted.has(Vector3i(5, 5, 1)), "no region tile under the chunks")
	assert_eq(wanted[Vector3i(8, 5, 1)], 8.0, "3 regions away, one 200 m tile every 8 m")
	assert_eq(wanted[Vector3i(9, 9, 1)], 20.0, "4 regions away, every 20 m")
	assert_false(wanted.has(Vector3i(10, 5, 1)), "nothing past the world's edge")


func test_nothing_is_shown_beyond_the_view() -> void:
	var wanted := _wanted_around(Vector2(50.0, -50.0))
	assert_eq(wanted[Vector3i(6, 0, 1)], 20.0, "6 regions away")
	assert_false(wanted.has(Vector3i(7, 0, 1)), "7 regions away is past view_regions")


func test_a_one_region_world_is_four_detailed_chunks() -> void:
	RegionMap.configure(1, 1)
	var wanted := _wanted_around(Vector2(45.0, -5.0))
	assert_eq(wanted.size(), 4)
	for key: Vector3i in [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0)]:
		assert_eq(wanted[key], 1.0, "chunk %s every metre" % key)
