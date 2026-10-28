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
