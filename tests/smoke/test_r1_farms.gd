extends GutTest
## The farms round Aiwyk on the author's real land and paint: the farmhouse in H9 with its open
## doors to the south, the fenced yard in H8, G8 and G9, a farm behind a broken fence, one with no
## fence at all, the sign on the road in, and the fields filled between them.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _designs: Array[SectorDesign] = []
var _village: Array[SectorDesign] = []


func before_all() -> void:
	TerrainSculpt.read_again()
	TerrainPaint.read_again()
	WaterField.use_only(WaterField.saved_plans())
	BakedSectors.forget()
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	for design: SectorDesign in (_world.call("terrain") as FieldTerrain).designs():
		if design.design_id.begins_with("r1_farm"):
			_designs.append(design)
		elif design.design_id.begins_with("r1_village"):
			_village.append(design)


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	TerrainPaint.start_empty()
	BakedSectors.forget()


func _props(slug: String, designs: Array[SectorDesign] = _designs) -> Array[Prop]:
	var found: Array[Prop] = []
	for design in designs:
		for prop in design.scene_props():
			if PropLibrary.slug_of(prop.asset).begins_with(slug):
				found.append(prop)
	return found


func _sector(prop: Prop) -> String:
	return SectorMap.name_of(SectorMap.cell_at(prop.position))


func _sectors_of(slug: String) -> Dictionary:
	var sectors := {}
	for prop in _props(slug):
		sectors[_sector(prop)] = true
	return sectors


func test_the_farmhouse_stands_in_h9_with_its_doors_to_the_south() -> void:
	var houses := _props("farmhouse_open")
	assert_eq(houses.size(), 1)
	assert_eq(_sector(houses[0]), "R1:H9")
	# A model's front is its +Z, and south is +Z.
	assert_almost_eq(houses[0].transform.basis.z.normalized().dot(Vector3(0.0, 0.0, 1.0)), 1.0, 0.001)


func test_the_yards_fence_runs_through_h8_g8_and_g9_with_gates() -> void:
	var sectors := _sectors_of("farm_fence_a")
	for sector: String in ["R1:H8", "R1:G8", "R1:G9"]:
		assert_true(sectors.has(sector), "fence in %s" % sector)
	assert_eq(_props("farm_fence_gate").size(), 2)


func test_a_farm_has_a_broken_fence_and_one_has_none() -> void:
	assert_gt(_props("farm_fence_down").size() + _props("farm_fence_stubs").size(), 3, "broken lengths")
	var crofts := _props("croft_cottage")
	assert_eq(crofts.size(), 1)
	var at: Vector3 = crofts[0].position
	for prop in _props("farm_fence"):
		assert_gt(prop.position.distance_to(at), 12.0, "no fence near the croft")


func test_the_sign_stands_by_the_road_before_the_village() -> void:
	var signs := _props("aiwyk_sign", _village)
	assert_eq(signs.size(), 1)
	var at: Vector2 = Vector2(signs[0].position.x, -signs[0].position.z)
	assert_lt(at.x, R1Village.MAIN_STREET[0].x, "before the street starts")
	var road := INF
	for j in range(-5, 6):
		for i in range(-5, 6):
			if TerrainPaint.road_at(Vector2(at.x + i, -(at.y + j))) > 0.3:
				road = minf(road, Vector2(i, j).length())
	assert_lt(road, 4.0, "beside the road")


func test_the_fields_between_are_filled() -> void:
	var things := 0
	for slug: String in ["field_rock", "elder_bush", "bramble_thicket", "field_cairn"]:
		things += _props(slug).size()
	assert_gt(things, 30, "rocks and bushes between the farms")


func test_their_paint_keeps_their_gravel() -> void:
	# Where the author's way runs along row 8's north edge, as they painted it at 32982f9.
	assert_gt(TerrainPaint.share(65, 80, 2), 0.3)


func test_buildings_are_not_left_on_steep_ground() -> void:
	for building in R1Farms.BUILDINGS:
		var at: Vector2 = building[1]
		var lowest := INF
		var highest := -INF
		for k in 12:
			var angle := TAU * k / 12
			var height := WorldShape.height(Vector2(at.x + cos(angle) * 2.5, -(at.y + sin(angle) * 2.5)))
			lowest = minf(lowest, height)
			highest = maxf(highest, height)
		assert_lt(highest - lowest, 0.9, "%s" % building[0])
