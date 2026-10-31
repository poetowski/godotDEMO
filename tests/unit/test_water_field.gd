extends GutTest
## Water poured into the land as it lies: it fills only what lies below its
## level, connected to a lake or a river's middle, runs the way the river does,
## and leaves the ground as it was.

const LAKE := Vector2(150.0, -50.0)
const LAKE_LEVEL := -1.0

var _plan: RegionWater


func before_each() -> void:
	TerrainSculpt.start_empty()
	RegionMap.configure(1, 1)
	WorldShape.configure(0.0)
	# A basin, with a trench running in from the north and one out to the west.
	var brush := SculptBrush.new()
	brush.tool = SculptBrush.Tool.LOWER
	brush.softness = 0.2
	brush.radius = 15.0
	brush.strength = 3.0
	brush.apply(LAKE, 1.0)
	brush.radius = 4.0
	for k in 12:
		brush.apply(Vector2(150.0, -130.0 + k * 6.0), 1.0)
	for k in 12:
		brush.apply(Vector2(130.0 - k * 6.0, -50.0), 1.0)
	# A hole of the same depth nothing connects to.
	brush.apply(Vector2(30.0, -170.0), 1.0)
	var inflow := WaterCourse.new()
	inflow.points = PackedVector2Array([Vector2(150.0, 130.0), Vector2(150.0, 62.0)])
	inflow.levels = PackedFloat32Array([-0.6, LAKE_LEVEL])
	inflow.ease_out = 14.0
	var outflow := WaterCourse.new()
	outflow.points = PackedVector2Array([Vector2(130.0, 50.0), Vector2(64.0, 50.0)])
	outflow.levels = PackedFloat32Array([LAKE_LEVEL, -1.5])
	outflow.ease_in = 14.0
	_plan = RegionWater.new()
	_plan.lake_seed = Vector2(LAKE.x, -LAKE.y)
	_plan.lake_level = LAKE_LEVEL
	_plan.courses = [inflow, outflow] as Array[WaterCourse]
	WaterField.use_only([_plan] as Array[RegionWater])


func after_each() -> void:
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	WorldShape.configure(0.0)


func _is_wet(xz: Vector2) -> bool:
	return WaterField.level_at(xz) > WorldShape.height(xz)


func test_the_lake_is_flat_and_fills_the_basin() -> void:
	assert_true(_is_wet(LAKE))
	assert_almost_eq(WaterField.level_at(LAKE), LAKE_LEVEL, 0.001)
	assert_almost_eq(WaterField.level_at(LAKE + Vector2(6.0, 6.0)), LAKE_LEVEL, 0.001)


func test_dry_land_stays_dry() -> void:
	assert_false(_is_wet(Vector2(100.0, -150.0)))
	assert_false(_is_wet(LAKE + Vector2(20.0, 0.0)), "beyond the basin's rim")
	assert_eq(WaterField.level_at(Vector2(100.0, -150.0)), SectorDesign.NO_WATER)


func test_a_hole_nothing_connects_to_stays_empty() -> void:
	assert_lt(WorldShape.height(Vector2(30.0, -170.0)), -2.0)
	assert_eq(WaterField.level_at(Vector2(30.0, -170.0)), SectorDesign.NO_WATER)


func test_the_rivers_run_downhill_into_and_out_of_the_lake() -> void:
	var upstream := WaterField.level_at(Vector2(150.0, -125.0))
	var downstream := WaterField.level_at(Vector2(150.0, -75.0))
	assert_gt(upstream, downstream)
	assert_gt(downstream, LAKE_LEVEL)
	var out_near := WaterField.level_at(Vector2(125.0, -50.0))
	var out_far := WaterField.level_at(Vector2(70.0, -50.0))
	assert_lt(out_near, LAKE_LEVEL)
	assert_lt(out_far, out_near)


func test_the_inflow_flows_south_and_the_outflow_west() -> void:
	# South is +z.
	var south := WaterField.flow_at(Vector2(150.0, -105.0))
	assert_gt(south.y, 0.3)
	assert_almost_eq(south.x, 0.0, 0.05)
	var west := WaterField.flow_at(Vector2(100.0, -50.0))
	assert_lt(west.x, -0.3)
	assert_almost_eq(west.y, 0.0, 0.05)


func test_the_lake_lies_still() -> void:
	assert_eq(WaterField.flow_at(LAKE), Vector2.ZERO)


func test_pouring_leaves_the_ground_as_it_was() -> void:
	var before := WorldShape.height(LAKE)
	WaterField.rebuild()
	assert_eq(WorldShape.height(LAKE), before)


func test_water_follows_the_land_when_it_is_sculpted_again() -> void:
	var dry := LAKE + Vector2(20.0, 0.0)
	assert_false(_is_wet(dry))
	var brush := SculptBrush.new()
	brush.tool = SculptBrush.Tool.LOWER
	brush.radius = 8.0
	brush.strength = 3.0
	brush.apply(dry, 1.0)
	WaterField.rebuild()
	assert_true(_is_wet(dry), "the lake widens into the new ground")


func test_the_mesh_carries_the_flow_for_the_shader() -> void:
	var mesh := WaterField.mesh()
	assert_not_null(mesh)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var westward := false
	for k in vertices.size():
		if vertices[k].x == 100.0 and vertices[k].z == -50.0:
			westward = colors[k].r < 0.4
	assert_true(westward, "x flow below the middle means west")


func test_wet_sectors_are_named() -> void:
	var names := WaterField.wet_sectors()
	assert_has(names, "P5", "the lake")
	assert_has(names, "P10", "the inflow")
	assert_has(names, "J6", "the outflow")
	assert_does_not_have(names, "D18", "the hole nothing connects to")


## The water data the game ships must keep to the rules, whatever it holds.
func test_saved_water_runs_downhill_and_holds_together() -> void:
	for plan in WaterField.saved_plans():
		assert_false(plan.brief.is_empty())
		for course in plan.courses:
			assert_eq(course.points.size(), course.levels.size())
			assert_gt(course.points.size(), 1)
			assert_lte(course.speed, NatureKit.WATER_MAX_FLOW)
			for k in course.levels.size() - 1:
				assert_lte(course.levels[k + 1], course.levels[k], "levels must not rise downstream")
