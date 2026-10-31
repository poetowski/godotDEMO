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
		if design.design_id.begins_with("r1_waterside_") or design.design_id.begins_with("r8_river") or design.design_id.begins_with("r4_lakeside"):
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


func test_the_lake_runs_on_into_r4_and_its_tips() -> void:
	for at: Vector2 in [Vector2(215.0, -10.0), Vector2(225.0, 0.0), Vector2(210.0, 20.0), Vector2(190.0, 10.0)]:
		assert_almost_eq(WaterField.level_at(at), -1.4, 0.001, "the lake at %s" % at)
	assert_eq(WaterField.level_at(Vector2(260.0, -10.0)), SectorDesign.NO_WATER, "dry beyond its shore")


func test_the_lake_has_its_alders_slabs_and_fallen_trees() -> void:
	var kinds: Dictionary[String, int] = {}
	for design in _designs:
		if not design.design_id.begins_with("r4_lakeside"):
			continue
		for prop in design.scene_props():
			var slug := prop.asset.resource_path.get_file().get_basename()
			kinds[slug] = kinds.get(slug, 0) + 1
	for slug: String in ["lake_alder", "fallen_alder", "shore_slab"]:
		assert_gt(kinds.get(slug, 0), 0, "%s is placed" % slug)


func test_the_border_runs_just_inside_the_ravine() -> void:
	var line := (_world.get_node("ZoneBorder") as ZoneBorder).line()
	for k in range(1, line.size() - 1):
		var ground := WorldShape.height(line[k])
		assert_lt(ground, -3.0, "point %d is below the rim" % k)
		assert_gt(ground, -12.0, "point %d is only a few metres down" % k)


func test_the_river_runs_on_through_its_delta_to_the_fall() -> void:
	for at: Vector2 in [Vector2(-5.0, -2.0), Vector2(-20.0, 1.0), Vector2(-35.0, 7.0), Vector2(-50.0, 10.0), Vector2(-60.0, 10.0)]:
		assert_ne(WaterField.level_at(at), SectorDesign.NO_WATER, "water at %s" % at)
	assert_lt(WaterField.flow_at(Vector2(-50.0, 10.0)).x, -0.6, "the rapids run west, fast")
	assert_eq(WaterField.falls().size(), 1)
	var fall := WaterField.falls()[0]
	assert_gt(WorldShape.height(Vector2(fall.top.x, -fall.top.y)) - WorldShape.height(Vector2(fall.bottom.x, -fall.bottom.y)), 40.0, "a huge drop")


func test_no_water_hangs_over_the_ravine() -> void:
	for x in range(-120, -64, 2):
		for n in range(-40, 40, 2):
			var xz := Vector2(x, -n)
			var level := WaterField.level_at(xz)
			# The tarn, far below, is deep on purpose.
			if level != SectorDesign.NO_WATER and level > -50.0:
				assert_lt(level - WorldShape.height(xz), 5.0, "at most a lip at the rim, at %s" % xz)


func test_nothing_lies_at_the_bottom_of_the_fall() -> void:
	assert_eq(WaterField.level_at(Vector2(-120.0, 0.0)), SectorDesign.NO_WATER, "no water hanging in the ravine")
	for design in _designs:
		for prop in design.scene_props():
			assert_gt(prop.position.y, -15.0, "%s/%s is above the mist" % [design.name, prop.name])
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for where in (node as BakedMultiMesh).transforms():
				assert_gt(where.origin.y, -15.0, "%s is above the mist" % node.name)


func test_the_new_assets_are_placed_along_the_fall() -> void:
	var kinds: Dictionary[String, int] = {}
	for design in _designs:
		for prop in design.scene_props():
			var slug := prop.asset.resource_path.get_file().get_basename()
			kinds[slug] = kinds.get(slug, 0) + 1
	for slug: String in ["cliff_outcrop_a", "wind_snag"]:
		assert_gt(kinds.get(slug, 0), 0, "%s is placed" % slug)
	assert_gt(_copies(["RapidStoneA", "RapidStoneB"] as Array[String]).size(), 0, "rapid stones")
	assert_gt(_copies(["SprayMoss"] as Array[String]).size(), 0, "spray moss")


func test_the_fog_follows_its_line_and_thickens_away_from_it() -> void:
	var barrier := _world.get_node("MistBarrier") as MistBarrier
	assert_not_null(barrier.get_node("Fog"))
	assert_gt((barrier.get_node("Wall") as StaticBody3D).get_child_count(), 15)
	var line := barrier.line()
	assert_gt(line.size(), 20)
	var r8_rim := Vector2(-73.0, -20.0)
	assert_eq(barrier.depth_at(r8_rim + Vector2(10.0, 0.0)), 0.0, "clear on the near side")
	assert_gt(barrier.depth_at(r8_rim + Vector2(-30.0, 0.0)), 20.0, "three sectors in")
	assert_gt(barrier.depth_at(r8_rim + Vector2(-80.0, 0.0)), barrier.depth_at(r8_rim + Vector2(-30.0, 0.0)), "further in")


func test_the_wall_stops_the_player_inside_the_fog() -> void:
	await wait_physics_frames(2)
	var space := (_world as Node3D).get_world_3d().direct_space_state
	# Above the ground, from the rim in R6 towards the world's south edge.
	var query := PhysicsRayQueryParameters3D.create(Vector3(40.0, 20.0, 148.0), Vector3(40.0, 20.0, 199.0) + Vector3(0.0, 0.0, 60.0))
	var hit := space.intersect_ray(query)
	assert_false(hit.is_empty(), "the wall is there")
	assert_gt((hit.get("position", Vector3.ZERO) as Vector3).z, 148.0)


func test_moving_a_point_moves_the_fog() -> void:
	var barrier := _world.get_node("MistBarrier") as MistBarrier
	var marker := barrier.get_node("FogLine").get_child(22) as Node3D
	var was := marker.position
	var spot := Vector2(was.x + 15.0, was.z)
	assert_eq(barrier.depth_at(spot), 0.0, "before")
	marker.position.x += 40.0
	barrier.rebuild()
	assert_gt(barrier.depth_at(spot), 0.0, "after")
	marker.position = was
	barrier.rebuild()


func test_no_prop_floats() -> void:
	for design in _designs:
		for prop in design.scene_props():
			if not prop.stands_on_ground():
				continue
			var xz := Vector2(prop.position.x, prop.position.z)
			assert_lt(prop.position.y - WorldShape.height(xz), 0.6, "%s/%s" % [design.name, prop.name])


func _bridge() -> Prop:
	for design in _designs:
		for prop in design.scene_props():
			if PropLibrary.slug_of(prop.asset) == "wooden_bridge":
				return prop
	return null


func test_the_bridge_crosses_the_river_and_can_be_walked() -> void:
	var bridge := _bridge()
	assert_not_null(bridge)
	assert_almost_eq(bridge.rotation.y, 0.2235, 0.01, "turned a little")
	var middle := bridge.position * Vector3(1.0, 0.0, 1.0)
	assert_ne(WaterField.level_at(Vector2(middle.x, middle.z)), SectorDesign.NO_WATER, "over the water")
	await wait_physics_frames(2)
	var space := (_world as Node3D).get_world_3d().direct_space_state
	for along: float in [-9.5, -5.0, 0.0, 5.0, 9.5]:
		var at := bridge.transform * Vector3(0.0, 0.0, along)
		var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 12.0, at.z), Vector3(at.x, -12.0, at.z))
		var hit := space.intersect_ray(query)
		assert_false(hit.is_empty(), "a deck %.1f m along" % along)
		var height := (hit.get("position", Vector3.ZERO) as Vector3).y
		assert_gt(height, -0.5, "not the river bed, %.1f m along" % along)
		assert_lt(height, 2.6, "%.1f m along" % along)


func test_nothing_grows_up_through_the_bridge() -> void:
	var inverse := _bridge().transform.affine_inverse()
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for where in (node as BakedMultiMesh).transforms():
				var local := inverse * Vector3(where.origin.x, _bridge().position.y, where.origin.z)
				assert_false(absf(local.x) < 1.4 and absf(local.z) < 10.9, "%s under the bridge at %s" % [node.name, where.origin])


func test_lanterns_stand_by_the_bridge_and_light_only_at_night() -> void:
	var flames := 0
	for design in _designs:
		flames += design.content().find_children("*", "NightLight", false, false).size()
	assert_eq(flames, 6, "one flame per lantern")
	assert_eq(NightLight.amount_at(12.0), 0.0, "noon")
	assert_eq(NightLight.amount_at(23.0), 1.0, "midnight")
	assert_eq(NightLight.amount_at(3.0), 1.0, "before dawn")
	assert_eq(NightLight.amount_at(7.0), 0.0, "morning")


func test_the_hero_crosses_the_bridge_on_foot() -> void:
	var bridge := _bridge()
	var player: Player = _world.call("player")
	# In the model's own metres: its deck's top is about 6.4 up, near each end.
	var south := bridge.transform * Vector3(0.0, 6.6, 9.5)
	var north := bridge.transform * Vector3(0.0, 6.6, -9.5)
	player.global_position = south
	player.velocity = Vector3.ZERO
	player.look_toward(north)
	await wait_physics_frames(20)
	var swam := 0
	var highest := player.global_position.y
	var frames := 0
	Input.action_press(&"move_forward")
	# Faster than this, at 4.5 m/s over 19 m, and it wouldn't be walking.
	while player.global_position.z > north.z and frames < 300:
		await wait_physics_frames(1)
		frames += 1
		swam += 1 if player.is_swimming else 0
		highest = maxf(highest, player.global_position.y)
	Input.action_release(&"move_forward")
	assert_eq(swam, 0, "never swims up on the deck")
	assert_gt(highest, 1.9, "goes over the arch")
	assert_lt(frames, 300, "gets across at walking pace")
	assert_gt(player.global_position.y, -1.0, "and comes off on the bank, not in the river")
	assert_false(player.is_swimming)

