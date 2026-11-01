extends GutTest
## R8's forest and camp, on the author's real land, water and paint: trees from the
## painted way up to the western cliff, rocks, and the camp with its campfire in R2 and R3.

const SCENE_PATH := "res://src/world/field/field.tscn"

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
		if design.design_id.begins_with("r8_forest_") or design.design_id == "r8_camp_r2":
			_designs.append(design)


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	TerrainPaint.start_empty()
	BakedSectors.forget()


func _props(slug: String) -> Array[Prop]:
	var found: Array[Prop] = []
	for design in _designs:
		for prop in design.scene_props():
			if PropLibrary.slug_of(prop.asset).begins_with(slug):
				found.append(prop)
	return found


func _trees() -> Array[Vector3]:
	var found: Array[Vector3] = []
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for slug: String in R8Forest.FOREST_TREES:
				if String(node.name).begins_with(slug.to_pascal_case()):
					for where in (node as BakedMultiMesh).transforms():
						found.append(where.origin)
	return found


func test_the_forest_is_thick_and_reaches_the_cliff() -> void:
	var trees := _trees()
	assert_gt(trees.size(), 100, "a forest, not a few trees")
	var west := 0.0
	for tree in trees:
		west = minf(west, tree.x)
		assert_gt(WorldShape.height(Vector2(tree.x, tree.z)), -3.0, "nothing stands below the rim at %s" % tree)
	assert_lt(west, -55.0, "it runs west up to the cliff")


func test_trees_keep_off_the_way_and_out_of_the_clearing() -> void:
	for tree in _trees():
		var xz := Vector2(tree.x, tree.z)
		assert_lt(TerrainPaint.bare_at(xz), 0.25, "a tree on the way at %s" % tree)
		assert_gt(xz.distance_to(Vector2(R8Forest.CAMP.x, -R8Forest.CAMP.y)), R8Forest.CAMP_CLEARING - 0.01, "a tree in the camp at %s" % tree)


func test_rocks_are_placed() -> void:
	assert_gt(_props("forest_rock").size(), 4)
	assert_gt(_props("forest_crag").size(), 1)


func test_the_camp_stands_in_r2_and_r3() -> void:
	var sectors := {}
	for slug: String in ["campfire", "cook_tripod", "log_seat", "camp_tent", "camp_tent_torn", "bedroll", "drying_rack", "camp_crates", "camp_barrel", "firewood_pile"]:
		var found := _props(slug)
		assert_gt(found.size(), 0, "%s is placed" % slug)
		for prop in found:
			var sector := SectorMap.name_of(SectorMap.cell_at(prop.position))
			sectors[sector] = true
			assert_true(sector in ["R8:R2", "R8:R3"], "%s stands in %s" % [slug, sector])
			assert_lt(absf(prop.position.y - WorldShape.height(Vector2(prop.position.x, prop.position.z))), 0.5, "%s is on the ground" % slug)
	assert_eq(sectors.size(), 2, "both sectors")


func test_the_campfire_burns_at_night() -> void:
	var flames := 0
	for design in _designs:
		flames += design.content().find_children("*", "NightLight", false, false).size()
	assert_eq(flames, 1)
