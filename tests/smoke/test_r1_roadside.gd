extends GutTest
## R1's painted roads and the farm, on the author's real land, water and paint: the
## farmhouse in D5 with its fences, matching lanterns at the crossroads, full-grown trees,
## and grass and flowers that keep off the roads.

const SCENE_PATH := "res://src/world/field/field.tscn"
const LANTERN_REACH := 7.0

var _world: Node
var _terrain: FieldTerrain
var _designs: Array[SectorDesign] = []


func before_all() -> void:
	TerrainSculpt.read_again()
	TerrainPaint.read_again()
	WaterField.use_only(WaterField.saved_plans())
	BakedSectors.forget()
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_terrain = _world.call("terrain") as FieldTerrain
	for design in _terrain.designs():
		if design.design_id.begins_with("r1_roadside_"):
			_designs.append(design)


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	TerrainPaint.start_empty()
	BakedSectors.forget()


## Every prop of a kind in the blocks, or of kinds starting with `slug`.
func _props(slug: String) -> Array[Prop]:
	var found: Array[Prop] = []
	for design in _designs:
		for prop in design.scene_props():
			if PropLibrary.slug_of(prop.asset).begins_with(slug):
				found.append(prop)
	return found


func _sector_of(prop: Prop) -> String:
	return SectorMap.name_of(SectorMap.cell_at(prop.position))


func _xz(prop: Prop) -> Vector2:
	return Vector2(prop.position.x, prop.position.z)


func test_the_paint_is_read() -> void:
	assert_gt(TerrainPaint.bare_at(Vector2(37.0, -33.0)), 0.5, "D4's crossroad is painted")
	assert_eq(TerrainPaint.bare_at(Vector2(120.0, -120.0)), 0.0, "and the field isn't")


func test_the_blocks_decorate_the_land_only() -> void:
	assert_eq(_designs.size(), 3)
	for design in _designs:
		assert_true(design.decorates_land)
		assert_true(design.props_frozen, "%s's props can be moved by hand" % design.name)
	assert_null(_terrain.design_at(Vector2(35.0, -45.0)), "the ground stays open")


func test_the_farmhouse_stands_in_d5_facing_its_yard() -> void:
	var houses := _props("farmhouse")
	assert_eq(houses.size(), 1)
	var house := houses[0]
	assert_eq(_sector_of(house), "R1:D5")
	# Its front is its model's -Y, which is the game's +Z: south.
	assert_gt((house.transform.basis * Vector3.BACK).z, 0.9, "faces south")
	assert_gt(TerrainPaint.bare_at(_xz(house) + Vector2(0.0, 6.0)), 0.5, "over the dirt of the yard")
	var roof_edge := _xz(house) + Vector2(3.0, 0.0)
	assert_lt(TerrainPaint.paving_at(roof_edge), 0.2, "not on the road")
	assert_lt(house.position.y - WorldShape.height(_xz(house)), 0.5, "on the ground")


func test_the_house_covers_the_ground_under_it() -> void:
	var house := _props("farmhouse")[0]
	# Its footing is 0.55 m tall: it must stand on the land at the corners too.
	for corner: Vector3 in [Vector3(-3.2, 0, -2.3), Vector3(3.2, 0, -2.3), Vector3(3.2, 0, 2.3), Vector3(-3.2, 0, 2.3)]:
		var at := house.transform * corner
		var ground := WorldShape.height(Vector2(at.x, at.z))
		assert_lt(house.position.y - ground, 0.15, "its footing reaches down at %s" % at)
		assert_lt(ground - house.position.y, 0.75, "and isn't buried at %s" % at)


func test_fences_run_round_the_farm_and_leave_it_open() -> void:
	var fences := _props("farm_fence")
	assert_gt(fences.size(), 10)
	var kinds := {}
	for fence in fences:
		kinds[PropLibrary.slug_of(fence.asset)] = true
		assert_lt(TerrainPaint.paving_at(_xz(fence)), 0.3, "%s is off the cobbles" % fence.name)
		assert_lt(absf(fence.position.y - WorldShape.height(_xz(fence))), 0.25, "%s follows the ground" % fence.name)
	assert_eq(kinds.size(), 3, "rails, hurdles and an old length")
	# The way in from the road, in the south-east.
	var gate := Vector2(39.5, -42.5)
	for fence in fences:
		assert_gt(_xz(fence).distance_to(gate), 2.0, "%s leaves the yard open to the road" % fence.name)


## The lanterns within reach of a crossroad.
func _lanterns_at(north: Vector2) -> Array[Prop]:
	var near: Array[Prop] = []
	for prop in _props("lantern"):
		if _xz(prop).distance_to(Vector2(north.x, -north.y)) < LANTERN_REACH:
			near.append(prop)
	return near


func test_crossroads_have_a_matching_pair_facing_each_other() -> void:
	for crossroad: Vector2 in [Vector2(37.9, 31.6), Vector2(47.0, 41.5), Vector2(61.0, 41.2)]:
		var pair := _lanterns_at(crossroad)
		var stood: Array[Prop] = []
		for prop in pair:
			if _sector_of(prop) != "R1:G5" or prop.position.distance_to(Vector3(61.0, prop.position.y, -41.2)) < 3.0:
				stood.append(prop)
		assert_eq(stood.size(), 2, "two at %s" % crossroad)
		assert_eq(stood[0].asset, stood[1].asset, "the same design at %s" % crossroad)
		var middle := Vector2(crossroad.x, -crossroad.y)
		var a := (_xz(stood[0]) - middle).normalized()
		var b := (_xz(stood[1]) - middle).normalized()
		assert_lt(a.dot(b), -0.7, "either side of %s" % crossroad)


func test_each_crossroad_has_its_own_design() -> void:
	var kinds := {}
	for crossroad: Vector2 in [Vector2(37.9, 31.6), Vector2(47.0, 41.5), Vector2(61.0, 41.2)]:
		kinds[PropLibrary.slug_of(_lanterns_at(crossroad)[0].asset)] = true
	assert_eq(kinds.size(), 3)


func test_single_lanterns_stand_where_asked() -> void:
	var sectors := {}
	for prop in _props("lantern"):
		sectors[_sector_of(prop)] = int(sectors.get(_sector_of(prop), 0)) + 1
	assert_eq(sectors.get("R1:E6", 0), 1, "E6")
	assert_eq(sectors.get("R1:E7", 0), 1, "E7")
	assert_eq(sectors.get("R1:D4", 0), 1, "one side of D4's crossroad; the other is across the road in E4")
	assert_eq(_props("lantern").size(), 9)


func test_lanterns_stand_beside_the_road_and_burn() -> void:
	for prop in _props("lantern"):
		var xz := _xz(prop)
		assert_lt(TerrainPaint.paving_at(xz), 0.3, "%s is off the cobbles" % prop.name)
		var near_road := false
		for k in 16:
			var angle := TAU * k / 16
			near_road = near_road or TerrainPaint.bare_at(xz + Vector2(cos(angle), sin(angle)) * 2.5) > 0.3
		assert_true(near_road, "%s is near the road" % prop.name)
	var flames := 0
	for design in _designs:
		flames += design.content().find_children("*", "NightLight", false, false).size()
	assert_eq(flames, 9)


func test_nothing_grows_on_the_roads() -> void:
	var total := 0
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			# What grows on the wet dirt is meant to, and that dirt isn't road.
			if R1Waterside.WET_PLANTS.any(func(slug: String) -> bool: return String(node.name).begins_with(slug.to_pascal_case())):
				continue
			for where in (node as BakedMultiMesh).transforms():
				total += 1
				assert_lt(TerrainPaint.bare_at(Vector2(where.origin.x, where.origin.z)), 0.31, "%s at %s" % [node.name, where.origin])
	assert_gt(total, 1500, "plenty grows beside them")


func test_painted_sectors_have_grass_flowers_and_stones() -> void:
	var kinds := {}
	var by_sector := {}
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			var kind := String(node.name)
			for where in (node as BakedMultiMesh).transforms():
				by_sector[SectorMap.name_of(SectorMap.unbounded_cell_at(Vector2(where.origin.x, where.origin.z)))] = true
			for prefix: String in ["MeadowGrass", "WildFlowers", "MossPatch", "RiverStone"]:
				if kind.begins_with(prefix):
					kinds[prefix] = true
	assert_eq(kinds.size(), 4, "grass, flowers, moss and stones")
	for sector: String in ["R1:D4", "R1:D5", "R1:C5", "R1:E5", "R1:E6", "R1:E7", "R1:F5", "R1:F6", "R1:G5", "R1:G6"]:
		assert_true(by_sector.has(sector), "%s is decorated" % sector)


func test_the_new_trees_and_boulders_are_placed() -> void:
	for slug: String in ["big_oak", "tall_beech", "tall_pine", "white_birch", "field_maple", "apple_tree", "hay_stack", "big_boulder"]:
		assert_gt(_props(slug).size(), 0, "%s is placed" % slug)


func test_big_trees_only_take_the_ground_at_their_feet() -> void:
	var oak := _props("big_oak")[0]
	assert_lt(PropLibrary.room(oak.kind, oak.transform, oak.asset), 2.0, "so grass grows under the crown")
	assert_gt(PropLibrary.asset_room(oak.asset), 5.0, "the crown is still wide")


func test_no_prop_stands_on_a_road_or_floats() -> void:
	for design in _terrain.designs():
		for prop in design.scene_props():
			if not prop.stands_on_ground():
				continue
			var xz := _xz(prop)
			assert_lt(prop.position.y - WorldShape.height(xz), 0.6, "%s/%s floats" % [design.name, prop.name])
			var fence := PropLibrary.slug_of(prop.asset).begins_with("farm_fence")
			if not fence and PropLibrary.slug_of(prop.asset) != "village_well" and not PropLibrary.slug_of(prop.asset).begins_with("lantern"):
				assert_lt(TerrainPaint.road_at(xz), 0.6, "%s/%s stands on a road" % [design.name, prop.name])


func test_boulders_and_stumps_keep_off_the_fences() -> void:
	var fences := _props("farm_fence")
	for slug: String in ["big_boulder", "mossy_boulder", "mossy_stump"]:
		for prop in _props(slug):
			var reach := PropLibrary.asset_room(prop.asset) * prop.transform.basis.get_scale().x
			for fence in fences:
				var a := fence.transform * Vector3(-1.2, 0.0, 0.0)
				var b := fence.transform * Vector3(1.2, 0.0, 0.0)
				var on_fence := Geometry2D.get_closest_point_to_segment(_xz(prop), Vector2(a.x, a.z), Vector2(b.x, b.z))
				assert_gt(_xz(prop).distance_to(on_fence), reach, "%s clears %s" % [prop.name, fence.name])

