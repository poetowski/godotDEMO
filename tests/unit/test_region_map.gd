extends GutTest
## Regions: 20 x 20 sectors each, numbered R1, R2... from the south-west,
## east along a row and then on along the next row north; sectors in a
## multi-region world are named with their region.


func before_each() -> void:
	RegionMap.configure(10, 10)


func after_each() -> void:
	RegionMap.configure(1, 1)


func test_regions_are_numbered_from_the_south_west() -> void:
	assert_eq(RegionMap.name_of(Vector2i(0, 0)), "R1")
	assert_eq(RegionMap.name_of(Vector2i(9, 0)), "R10", "east along the first row")
	assert_eq(RegionMap.name_of(Vector2i(0, 1)), "R11", "then the next row north")
	assert_eq(RegionMap.name_of(Vector2i(9, 9)), "R100")
	assert_eq(RegionMap.name_of(Vector2i(10, 0)), "", "outside the world")


func test_names_turn_back_into_regions() -> void:
	assert_eq(RegionMap.named("r45"), Vector2i(4, 4))
	assert_eq(RegionMap.named("R101"), RegionMap.NONE)
	assert_eq(RegionMap.named("R0"), RegionMap.NONE)
	assert_eq(RegionMap.named("45"), RegionMap.NONE)


func test_a_region_is_200_metres_of_20_by_20_sectors() -> void:
	assert_eq(RegionMap.SIZE, RegionMap.SECTORS * SectorMap.SIZE)
	assert_eq(RegionMap.corner_of(Vector2i(1, 2)), Vector3(200.0, 0.0, -400.0))
	assert_eq(RegionMap.at(Vector3(205.0, 0.0, -405.0)), Vector2i(1, 2))
	assert_eq(RegionMap.at(Vector3(-5.0, 0.0, -5.0)), RegionMap.NONE)
	assert_eq(SectorMap.extent(), Vector2(2000.0, 2000.0))


func test_sectors_carry_their_region_in_a_big_world() -> void:
	var cell := SectorMap.cell_named("R45:J10")
	assert_eq(cell, Vector2i(4 * 20 + 9, 4 * 20 + 9))
	assert_eq(SectorMap.name_of(cell), "R45:J10")
	assert_eq(SectorMap.local_name(cell), "J10")
	assert_eq(SectorMap.cell_named("c4"), Vector2i(2, 3), "no region means R1")
	assert_eq(SectorMap.name_of(Vector2i(2, 3)), "R1:C4")
	assert_eq(SectorMap.cell_named("R45:Z1"), SectorMap.NONE)
	assert_eq(SectorMap.cell_named("R999:A1"), SectorMap.NONE)


func test_a_one_region_world_keeps_plain_names() -> void:
	RegionMap.configure(1, 1)
	assert_eq(SectorMap.name_of(Vector2i(2, 3)), "C4")
	assert_eq(SectorMap.cell_named("R1:C4"), Vector2i(2, 3))
	assert_eq(SectorMap.cell_named("R2:C4"), SectorMap.NONE)


func test_the_starting_zone_runs_clockwise_around_r1_from_the_north() -> void:
	RegionMap.configure_starting_zone()
	var expected := {
		"R1": Vector2i(0, 0), "R2": Vector2i(0, 1), "R3": Vector2i(1, 1), "R4": Vector2i(1, 0),
		"R5": Vector2i(1, -1), "R6": Vector2i(0, -1), "R7": Vector2i(-1, -1), "R8": Vector2i(-1, 0), "R9": Vector2i(-1, 1),
	}
	for region_name: String in expected:
		assert_eq(RegionMap.named(region_name), expected[region_name])
		assert_eq(RegionMap.name_of(expected[region_name]), region_name)
	assert_eq(RegionMap.named("R10"), RegionMap.NONE)
	assert_eq(RegionMap.at(Vector3(100.0, 0.0, -100.0)), Vector2i.ZERO)
	assert_eq(RegionMap.at(Vector3(-100.0, 0.0, 100.0)), Vector2i(-1, -1), "south-west of R1")
	assert_eq(RegionMap.at(Vector3(-201.0, 0.0, 0.0)), RegionMap.NONE, "outside the zone")
	assert_eq(SectorMap.bounds(), Rect2(-200.0, -200.0, 600.0, 600.0))
	assert_eq(SectorMap.cell_named("A1"), Vector2i.ZERO, "a plain name means R1")
	assert_eq(SectorMap.cell_named("R8:T20"), Vector2i(-1, 19), "west of R1")
	assert_eq(SectorMap.name_of(Vector2i(-1, 19)), "R8:T20")
	assert_eq(SectorMap.cell_at(Vector3(-5.0, 0.0, 5.0)), Vector2i(-1, -1), "a real cell, not nothing")


func test_r1s_land_is_the_same_with_neighbours_around_it() -> void:
	var points: Array[Vector2] = [Vector2(0.0, -5.0), Vector2(5.0, -100.0), Vector2(100.0, -100.0), Vector2(195.0, -199.0), Vector2(200.0, -60.0)]
	RegionMap.configure(1, 1)
	FieldWorld.configure(1)
	var alone: Array[float] = []
	for point in points:
		alone.append(WorldShape.base_height(point))
	FieldWorld.configure()
	for k in points.size():
		assert_almost_eq(WorldShape.base_height(points[k]), alone[k], 0.0001, "at %s" % points[k])
	assert_true(absf(WorldShape.base_height(Vector2(-100.0, 100.0))) > 0.0, "the neighbours have hills of their own")
	WorldShape.configure(0.0)


func test_painting_works_west_and_south_of_r1() -> void:
	RegionMap.configure_starting_zone()
	TerrainPaint.start_empty()
	var brush := PaintBrush.new()
	brush.apply(Vector2(-50.0, 50.0), 1.0)
	assert_gt(TerrainPaint.share(-50, -50, 0), 0.9)
	TerrainPaint.start_empty()
