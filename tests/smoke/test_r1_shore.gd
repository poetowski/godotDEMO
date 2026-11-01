extends GutTest
## The wet banks of R1's river on the author's real land: wet dirt in the sectors asked for, what
## grows on it, the ship on its boulders, the old wreck, and the fishing things and tools.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _terrain: FieldTerrain


func before_all() -> void:
	TerrainSculpt.read_again()
	TerrainPaint.read_again()
	WaterField.use_only(WaterField.saved_plans())
	BakedSectors.forget()
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_terrain = _world.call("terrain") as FieldTerrain


func after_all() -> void:
	_world.free()
	WaterField.use_only([] as Array[RegionWater])
	TerrainSculpt.start_empty()
	TerrainPaint.start_empty()
	BakedSectors.forget()


func _props(slug: String) -> Array[Prop]:
	var found: Array[Prop] = []
	for design in _terrain.designs():
		for prop in design.scene_props():
			if PropLibrary.slug_of(prop.asset).begins_with(slug):
				found.append(prop)
	return found


func _mud_share(sector: String) -> float:
	var cell := SectorMap.cell_named(sector)
	var corner := SectorMap.corner_of(cell)
	var muddy := 0
	for j in 10:
		for i in 10:
			if TerrainPaint.share(int(corner.x) + i, int(-corner.z) + j, 1) > 0.3:
				muddy += 1
	return muddy / 100.0


func test_every_sector_asked_for_has_wet_dirt() -> void:
	assert_eq(R1Waterside.WET_SECTORS.size(), 12)
	for sector: String in R1Waterside.WET_SECTORS:
		assert_gt(_mud_share(sector), 0.15, "wet dirt in %s" % sector)


func test_wet_dirt_keeps_to_those_sectors() -> void:
	# G8 wasn't asked for, and it lies well away from them all.
	assert_lt(_mud_share("G8"), 0.05)


func test_a_ship_lies_on_its_boulders_by_the_water() -> void:
	var ships := _props("ship_on_boulders")
	assert_eq(ships.size(), 1)
	assert_eq(SectorMap.name_of(SectorMap.cell_at(ships[0].position)), "R1:C2")
	assert_eq(_props("wreck_ribs").size(), 1)
	assert_eq(_props("wreck_stern").size(), 1)


func test_fishing_things_and_tools_are_there() -> void:
	for slug: String in ["fish_rack", "net_rack", "net_heap", "fish_creels", "fish_traps", "gutting_table", "smoke_hut", "rowboat_beached", "rowboat_upturned", "fishing_jetty"]:
		assert_gt(_props(slug).size(), 0, slug)
	assert_gt(_props("ground_knife").size(), 1, "knives on the ground")
	assert_gt(_props("ground_hammer").size(), 1, "hammers on the ground")


func test_plants_grow_on_the_wet_dirt() -> void:
	var grown := 0
	for design in _terrain.designs():
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for slug: String in R1Waterside.WET_PLANTS:
				if String(node.name).begins_with(slug.to_pascal_case()):
					grown += (node as BakedMultiMesh).transforms().size()
	assert_gt(grown, 200, "rushes, butterbur and stones")


func test_the_jetty_reaches_the_water() -> void:
	var jetty: Prop = _props("fishing_jetty")[0]
	var head := jetty.position + jetty.transform.basis.z.normalized() * 4.5
	var xz := Vector2(head.x, head.z)
	assert_gt(WaterField.level_at(xz), WorldShape.height(xz), "its head stands in water")
