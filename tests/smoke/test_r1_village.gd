extends GutTest
## R1's village on the author's real land and paint: houses in the sectors asked for, the church
## in M11 among pines, the farm in J8 with fences into J7, and the forest in N and O.

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
		if design.design_id.begins_with("r1_village_") or design.design_id == "r1_forest_n7":
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


func _sector(prop: Prop) -> String:
	return SectorMap.name_of(SectorMap.cell_at(prop.position))


func _xz(prop: Prop) -> Vector2:
	return Vector2(prop.position.x, prop.position.z)


func _trees(pines_only: bool) -> Array[Vector3]:
	var found: Array[Vector3] = []
	for design in _designs:
		for node in design.content().find_children("*", "BakedMultiMesh", false, false):
			for slug: String in R8Forest.FOREST_TREES:
				var is_pine := slug == "tall_pine" or slug.begins_with("forest_spruce")
				if String(node.name).begins_with(slug.to_pascal_case()) and (is_pine or not pines_only):
					for where in (node as BakedMultiMesh).transforms():
						found.append(where.origin)
	return found


func test_houses_stand_in_the_sectors_asked_for() -> void:
	var sectors := {}
	for slug: String in ["village_house", "village_loft", "village_smithy"]:
		for prop in _props(slug):
			sectors[_sector(prop)] = true
	for sector: String in ["R1:K10", "R1:K11", "R1:L9", "R1:M9"]:
		assert_true(sectors.has(sector), "a building in %s" % sector)


func test_the_church_stands_in_m11_among_pines() -> void:
	var churches := _props("nordic_church")
	assert_eq(churches.size(), 1)
	assert_eq(_sector(churches[0]), "R1:M11")
	var around := 0
	for tree in _trees(true):
		if Vector2(tree.x, tree.z).distance_to(_xz(churches[0])) < 19.0:
			around += 1
	for slug: String in ["tall_pine", "forest_spruce"]:
		for prop in _props(slug):
			if _xz(prop).distance_to(_xz(churches[0])) < 19.0:
				around += 1
	assert_gt(around, 10, "pines round it")


func test_the_farm_is_in_j8_with_fences_into_j7() -> void:
	var sheds := _props("farm_shed")
	assert_eq(sheds.size(), 1)
	var sectors := {}
	for prop in _props("farm_fence"):
		sectors[_sector(prop)] = true
	assert_true(sectors.has("R1:J8"), "fences in J8")
	assert_true(sectors.has("R1:J7"), "fences in J7")
	var houses := 0
	for prop in _props("farmhouse"):
		if _sector(prop) in ["R1:J8", "R1:J7"]:
			houses += 1
	assert_eq(houses, 1, "a house on the farm")


func test_the_forest_fills_n_and_o() -> void:
	var by_sector := {}
	for tree in _trees(false):
		by_sector[SectorMap.name_of(SectorMap.cell_at(tree))] = true
	var filled := 0
	for column: String in ["N", "O"]:
		for row in range(7, 13):
			if by_sector.has("R1:%s%d" % [column, row]):
				filled += 1
	assert_gt(filled, 8, "trees through most of its 12 sectors")


func test_nothing_tall_stands_on_a_house() -> void:
	for tree in _trees(false):
		for building in R1Village.BUILDINGS:
			var at: Vector2 = building[1]
			assert_gt(Vector2(tree.x, -tree.z).distance_to(at), float(building[3]), "a tree in %s" % building[0])


func test_paving_keeps_to_the_square_and_the_streets() -> void:
	var paved := 0
	var far := 0
	for j in range(60, 116):
		for i in range(88, 140):
			if TerrainPaint.paving_at(Vector2(i, -j)) > 0.5:
				paved += 1
				var at := Vector2(i, j)
				var near := at.distance_to(R1Village.SQUARE) < R1Village.SQUARE_RADIUS + 2.0
				for k in R1Village.MAIN_STREET.size() - 1:
					near = near or at.distance_to(Geometry2D.get_closest_point_to_segment(at, R1Village.MAIN_STREET[k], R1Village.MAIN_STREET[k + 1])) < 3.0
				near = near or at.distance_to(R1Village.CHURCH) < 9.0
				if not near:
					far += 1
	assert_gt(paved, 50, "the square and the street are paved")
	assert_eq(far, 0, "and nothing else is")


func test_buildings_stand_on_level_ground() -> void:
	for building in R1Village.BUILDINGS:
		var at: Vector2 = building[1]
		var lowest := INF
		var highest := -INF
		for k in 12:
			var angle := TAU * k / 12
			var height := WorldShape.height(Vector2(at.x + cos(angle) * 2.5, -(at.y + sin(angle) * 2.5)))
			lowest = minf(lowest, height)
			highest = maxf(highest, height)
		assert_lt(highest - lowest, 0.7, "%s's pad" % building[0])
