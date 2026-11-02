extends GutTest
## R6 south of the bridge on the author's real land and paint: poplars and bushes over F19 and F20,
## white poplars on C20 and D20, the tent in D19, and things through the sectors round them.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _design: SectorDesign


func before_all() -> void:
	TerrainSculpt.read_again()
	TerrainPaint.read_again()
	WaterField.use_only(WaterField.saved_plans())
	BakedSectors.forget()
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	for design: SectorDesign in (_world.call("terrain") as FieldTerrain).designs():
		if design.design_id == "r6_south_bank":
			_design = design


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	TerrainPaint.start_empty()
	BakedSectors.forget()


## How many copies of a mass stand in each sector.
func _masses(prefix: String) -> Dictionary:
	var found := {}
	for node in _design.content().find_children("*", "BakedMultiMesh", true, false):
		if String(node.name).begins_with(prefix):
			for where in (node as BakedMultiMesh).transforms():
				var sector := SectorMap.name_of(SectorMap.cell_at(where.origin))
				found[sector] = int(found.get(sector, 0)) + 1
	return found


func _prop_sectors(slug: String) -> Array:
	var found := []
	for prop in _design.scene_props():
		if PropLibrary.slug_of(prop.asset).begins_with(slug):
			found.append(SectorMap.name_of(SectorMap.cell_at(prop.position)))
	return found


func test_poplars_and_bushes_cover_f19_and_f20() -> void:
	var trees := _masses("TallPoplar")
	var bushes := _masses("HazelBush")
	var roses := _masses("DogRose")
	for sector: String in ["R6:F19", "R6:F20"]:
		assert_gt(int(trees.get(sector, 0)), 3, "poplars in %s" % sector)
		assert_gt(int(bushes.get(sector, 0)) + int(roses.get(sector, 0)), 5, "bushes in %s" % sector)


func test_white_poplars_stand_on_c20_and_d20() -> void:
	var trees := _masses("WhitePoplar")
	for sector: String in ["R6:C20", "R6:D20"]:
		assert_gt(int(trees.get(sector, 0)), 2, "white poplars in %s" % sector)


func test_the_tent_stands_in_d19() -> void:
	assert_eq(_prop_sectors("military_tent"), ["R6:D19"])


func test_the_sectors_round_them_have_rocks_and_finds() -> void:
	assert_eq(_prop_sectors("forest_idol"), ["R6:E18"])
	var things := 0
	for slug: String in ["field_rock", "mossy_boulder", "gnawed_stump", "bracket_log", "shed_antlers"]:
		things += _prop_sectors(slug).size()
	assert_gt(things, 15, "scattered about")


func test_it_keeps_the_authors_way_clear() -> void:
	for prop in _design.scene_props():
		assert_lt(TerrainPaint.road_at(Vector2(prop.position.x, prop.position.z)), 0.6, "%s stands off their road" % prop.name)
