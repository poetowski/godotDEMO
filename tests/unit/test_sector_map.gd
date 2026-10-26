extends GutTest


func test_a1_is_the_south_west_corner_sector() -> void:
	assert_eq(SectorMap.name_of(SectorMap.cell_at(Vector3(0.5, 0.0, -0.5))), "A1")
	assert_eq(SectorMap.center_of(Vector2i.ZERO), Vector3(5.0, 0.0, -5.0))


func test_letters_grow_east_and_numbers_grow_north() -> void:
	assert_eq(SectorMap.name_of(SectorMap.cell_at(Vector3(15.0, 0.0, -5.0))), "B1")
	assert_eq(SectorMap.name_of(SectorMap.cell_at(Vector3(5.0, 0.0, -15.0))), "A2")
	assert_eq(SectorMap.name_of(SectorMap.cell_at(Vector3(195.0, 0.0, -195.0))), "T20")


func test_points_off_the_grid_have_no_sector() -> void:
	for point: Vector3 in [Vector3(-1.0, 0.0, -5.0), Vector3(5.0, 0.0, 1.0), Vector3(201.0, 0.0, -5.0), Vector3(5.0, 0.0, -201.0)]:
		assert_eq(SectorMap.cell_at(point), SectorMap.NONE, "at %s" % point)
	assert_eq(SectorMap.name_of(SectorMap.NONE), "")


func test_names_turn_back_into_cells() -> void:
	assert_eq(SectorMap.cell_named("C4"), Vector2i(2, 3))
	assert_eq(SectorMap.cell_named(" t20 "), Vector2i(19, 19))
	for bad: String in ["", "C", "4C", "U1", "A0", "A21", "AA1"]:
		assert_eq(SectorMap.cell_named(bad), SectorMap.NONE, "'%s' is no sector" % bad)


func test_every_name_round_trips() -> void:
	for row in SectorMap.ROWS:
		for column in SectorMap.COLUMNS:
			var cell := Vector2i(column, row)
			assert_eq(SectorMap.cell_named(SectorMap.name_of(cell)), cell)
			assert_eq(SectorMap.cell_at(SectorMap.center_of(cell)), cell)


func test_corners_and_starts() -> void:
	assert_eq(SectorMap.corner_of(Vector2i.ZERO), Vector3.ZERO)
	assert_eq(SectorMap.corner_of(SectorMap.cell_named("B2")), Vector3(10.0, 0.0, -10.0))
	assert_eq(SectorMap.start_of(Vector2i.ZERO), Vector3(5.0, 0.0, -2.5))


func test_unbounded_cells_continue_past_the_grid() -> void:
	assert_eq(SectorMap.unbounded_cell_at(Vector2(15.0, -5.0)), Vector2i(1, 0))
	assert_eq(SectorMap.unbounded_cell_at(Vector2(-0.5, 0.5)), Vector2i(-1, -1))
	assert_eq(SectorMap.unbounded_cell_at(Vector2(10.0, -10.0)), Vector2i(1, 1))
