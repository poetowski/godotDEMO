extends GutTest
## R1's waterside, decorated: reads the author's real land and water, which the
## suite otherwise leaves out, and checks that things grow where they belong and
## that the land and water are left alone.

const SCENE_PATH := "res://src/world/field/field.tscn"
const LILIES: Array[String] = ["LilyPads", "LilyWhite", "LilyPink"]
const WETLAND: Array[String] = ["ReedsA", "ReedsB", "Cattails"]
const BANK: Array[String] = ["SedgeA", "SedgeB", "WatersideFern", "BlueFlagIris", "MarshMarigold"]
const STONES: Array[String] = ["RiverStoneA", "RiverStoneB", "RiverStoneC", "PebblesPatch"]

var _world: Node
var _terrain: FieldTerrain
var _designs: Array[SectorDesign] = []


func before_all() -> void:
	TerrainSculpt.read_again()
	WaterField.use_only(WaterField.saved_plans())
	BakedSectors.forget()
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_terrain = _world.call("terrain") as FieldTerrain
	for design in _terrain.designs():
		if design.design_id.begins_with("r1_waterside_") or design.design_id.begins_with("r8_river"):
			_designs.append(design)


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	BakedSectors.forget()


func _copies(kinds: Array[String]) -> Array[Transform3D]:
	var found: Array[Transform3D] = []
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for kind in kinds:
				if String(node.name).begins_with(kind):
					found.append_array((node as BakedMultiMesh).transforms())
	return found


func test_the_waterside_is_decorated_from_blocks_of_sectors() -> void:
	assert_gt(_designs.size(), 8)
	for design in _designs:
		assert_true(design.decorates_land)
	assert_gt(_copies(LILIES).size(), 30, "lilies")
	assert_gt(_copies(WETLAND).size(), 200, "reeds and cattails")
	assert_gt(_copies(BANK).size(), 300, "plants on the banks")
	assert_gt(_copies(STONES).size(), 100, "stones")


func test_every_sector_with_shallows_has_something_in_it() -> void:
	var covered: Dictionary[Vector2i, bool] = {}
	var everything: Array[String] = []
	everything.append_array(LILIES)
	everything.append_array(WETLAND)
	everything.append_array(BANK)
	everything.append_array(STONES)
	for where in _copies(everything):
		covered[SectorMap.unbounded_cell_at(Vector2(where.origin.x, where.origin.z))] = true
	for sector in WaterField.wet_sectors():
		# Deep open water is left open.
		if _shallow_samples(SectorMap.cell_named(sector)) < 25:
			continue
		assert_true(covered.has(SectorMap.cell_named(sector)), "%s is decorated" % sector)


func _shallow_samples(cell: Vector2i) -> int:
	var corner := SectorMap.corner_of(cell)
	var count := 0
	for i in 10:
		for j in 10:
			var xz := Vector2(corner.x + i + 0.5, corner.z - j - 0.5)
			var depth := WaterField.level_at(xz) - WorldShape.height(xz)
			if depth > 0.0 and depth < 0.6:
				count += 1
	return count


func test_decorating_owns_no_ground() -> void:
	assert_null(_terrain.design_at(Vector2(161.0, -24.0)))
	assert_false(_terrain.shows_stand_in(SectorMap.cell_named("Q3")))
	assert_almost_eq(_terrain.water_level_at(Vector2(161.0, -24.0)), -1.4, 0.001, "the lake is as it was")
	assert_almost_eq(_terrain.height_at(Vector2(161.0, -24.0)), WorldShape.height(Vector2(161.0, -24.0)), 0.001)


func test_lilies_float_on_still_water() -> void:
	for where in _copies(LILIES):
		var xz := Vector2(where.origin.x, where.origin.z)
		var level := WaterField.level_at(xz)
		assert_gt(level, WorldShape.height(xz), "in the water at %s" % xz)
		assert_almost_eq(where.origin.y, level, 0.03, "on the surface at %s" % xz)
		assert_lt(WaterField.flow_at(xz).length(), 0.2, "no lilies in the current at %s" % xz)


func test_nothing_grows_out_of_deep_water() -> void:
	var rooted: Array[String] = []
	rooted.append_array(WETLAND)
	rooted.append_array(BANK)
	for where in _copies(rooted):
		var xz := Vector2(where.origin.x, where.origin.z)
		var level := WaterField.level_at(xz)
		assert_lt(level - WorldShape.height(xz), 0.7, "standing in shallows at most, at %s" % xz)
		assert_almost_eq(where.origin.y, WorldShape.height(xz), 0.1, "on the ground at %s" % xz)


func test_flowers_and_ferns_stay_on_dry_banks() -> void:
	var dry: Array[String] = ["WatersideFern", "BlueFlagIris", "MarshMarigold"]
	for where in _copies(dry):
		var xz := Vector2(where.origin.x, where.origin.z)
		assert_gt(WorldShape.height(xz), WaterField.level_at(xz), "dry at %s" % xz)


func test_the_landmarks_are_placed_and_near_the_water() -> void:
	var kinds: Dictionary[String, int] = {}
	for design in _designs:
		for prop in design.scene_props():
			assert_eq(prop.kind, PropLibrary.Kind.ASSET)
			var slug := prop.asset.resource_path.get_file().get_basename()
			kinds[slug] = kinds.get(slug, 0) + 1
	for slug: String in ["mossy_boulder_a", "driftwood_log", "young_willow", "willow_shrub", "mossy_stump"]:
		assert_gt(kinds.get(slug, 0), 0, "%s is placed" % slug)


func test_the_start_stays_clear_and_dry() -> void:
	var start := SectorMap.start_of(SectorMap.cell_named("A1"))
	var spot := _terrain.find_dry_spot(Vector2(start.x, start.z))
	assert_true(_terrain.is_dry(spot))


func test_the_river_runs_on_through_its_delta_to_the_fall() -> void:
	for at: Vector2 in [Vector2(-5.0, -2.0), Vector2(-20.0, 1.0), Vector2(-35.0, 7.0), Vector2(-50.0, 10.0), Vector2(-60.0, 10.0)]:
		assert_ne(WaterField.level_at(at), SectorDesign.NO_WATER, "water at %s" % at)
	assert_lt(WaterField.flow_at(Vector2(-50.0, 10.0)).x, -0.6, "the rapids run west, fast")
	assert_eq(WaterField.falls().size(), 1)
	var fall := WaterField.falls()[0]
	assert_gt(WorldShape.height(Vector2(fall.top.x, -fall.top.y)) - fall.pool_level, 40.0, "a huge drop")


func test_no_water_hangs_over_the_ravine() -> void:
	for x in range(-120, -64, 2):
		for n in range(-40, 40, 2):
			var xz := Vector2(x, -n)
			var level := WaterField.level_at(xz)
			if level != SectorDesign.NO_WATER:
				assert_lt(level - WorldShape.height(xz), 5.0, "at most a lip at the rim, at %s" % xz)


func test_the_tarn_stays_in_its_hollow_above_the_abyss() -> void:
	assert_eq(WaterField.level_at(Vector2(-141.0, -11.0)), -57.0, "the tarn")
	assert_eq(WaterField.level_at(Vector2(-180.0, -11.0)), SectorDesign.NO_WATER, "not poured into the abyss")
	assert_eq(WaterField.level_at(Vector2(-140.0, 80.0)), SectorDesign.NO_WATER, "the ravine's not full")
	assert_lt(WorldShape.height(Vector2(-190.0, -100.0)), -200.0, "the abyss")
	assert_lt(WorldShape.height(Vector2(-150.0, -300.0)), -40.0, "the ravine runs north through R9")


func test_the_new_assets_are_placed_along_the_fall() -> void:
	var kinds: Dictionary[String, int] = {}
	for design in _designs:
		for prop in design.scene_props():
			var slug := prop.asset.resource_path.get_file().get_basename()
			kinds[slug] = kinds.get(slug, 0) + 1
	for slug: String in ["cliff_outcrop_a", "cliff_outcrop_b", "wind_snag"]:
		assert_gt(kinds.get(slug, 0), 0, "%s is placed" % slug)
	assert_gt(_copies(["RapidStoneA", "RapidStoneB"] as Array[String]).size(), 0, "rapid stones")
	assert_gt(_copies(["SprayMoss"] as Array[String]).size(), 0, "spray moss")


func test_the_fog_has_a_wall_the_player_cannot_cross() -> void:
	var barrier := _world.get_node("MistBarrier")
	assert_not_null(barrier.get_node("Fog"))
	var wall := barrier.get_node("Wall") as StaticBody3D
	assert_gt(wall.get_child_count(), 20)
	var north_end := MistBarrier.WEST_FROM
	var south_end := MistBarrier.WEST_TO
	assert_eq(north_end.y, SectorMap.bounds().end.y, "reaches the world's north edge")
	assert_eq(south_end.y, SectorMap.bounds().position.y, "reaches the world's south edge")

