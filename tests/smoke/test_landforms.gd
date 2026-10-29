extends GutTest
## Region designs (data/world/landforms/) keep to their regions and off the
## designed sectors, and shape the land as briefed. New region designs are
## covered by the first tests without changes here.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _terrain: FieldTerrain


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_terrain = _world.call("terrain") as FieldTerrain


func after_all() -> void:
	_world.free()


func test_every_region_design_loads_and_fits_the_world() -> void:
	assert_gt(Landforms.sets().size(), 0)
	var ids: Dictionary[String, bool] = {}
	for landform_set in Landforms.sets():
		assert_false(landform_set.id.is_empty(), "every set has an id")
		assert_false(ids.has(landform_set.id), "ids are unique")
		ids[landform_set.id] = true
		assert_false(landform_set.brief.is_empty(), "%s keeps its brief" % landform_set.id)
		assert_gt(landform_set.landforms.size() + landform_set.lakes.size(), 0)


func test_landforms_stay_inside_their_regions() -> void:
	for landform_set in Landforms.sets():
		var area := landform_set.area()
		for landform in landform_set.landforms:
			assert_true(area.encloses(landform.bounds()), "%s: a landform reaches past %s" % [landform_set.id, ", ".join(landform_set.regions)])
		for lake in landform_set.lakes:
			assert_true(area.encloses(lake.bounds()), "%s: a lake reaches past %s" % [landform_set.id, ", ".join(landform_set.regions)])


func test_landforms_keep_off_designed_sectors() -> void:
	for design in _terrain.designs():
		for cell in design.cells():
			var corner := SectorMap.corner_of(cell)
			var sector := Rect2(Vector2(corner.x, -corner.z), Vector2.ONE * SectorMap.SIZE)
			for landform_set in Landforms.sets():
				for landform in landform_set.landforms:
					assert_false(landform.bounds().intersects(sector), "%s reaches %s's sector %s" % [landform_set.id, design.name, SectorMap.name_of(cell)])
				for lake in landform_set.lakes:
					assert_false(lake.bounds().intersects(sector), "%s's lake reaches %s's sector %s" % [landform_set.id, design.name, SectorMap.name_of(cell)])


func test_r1_stays_flat_where_the_world_is_built() -> void:
	for k in 30:
		assert_eq(WorldShape.height(Vector2(60.0 + k * 4.5, -10.0 - k * 6.0)), 0.0)


func test_the_r2_mountain_rises_snowy_above_wooded_slopes() -> void:
	var top := -INF
	var summit := Vector2.ZERO
	for i in 60:
		for j in 60:
			var xz := Vector2(205.0 + i * 3.2, -5.0 - j * 3.2)
			var height := _terrain.height_at(xz)
			if height > top:
				top = height
				summit = xz
	assert_gt(top, 70.0, "a big mountain")
	assert_eq(RegionMap.name_of(RegionMap.at(Vector3(summit.x, 0.0, summit.y))), "R2", "its summit in R2")
	var snow := Landforms.ground_tint(summit, top, 1.0)
	assert_lt(snow.a, 0.2, "snow on the summit")
	assert_gt(snow.r, 0.85)
	assert_lt(Landforms.ground_tint(summit, 20.0, 0.55).a, 0.2, "bare rock on steep slopes")
	assert_eq(Landforms.tree_factor(summit, top), 0.0, "no trees above the tree line")
	assert_gt(Landforms.tree_factor(Vector2(230.0, -30.0), 10.0), 0.5, "trees on its foot")


func test_r11_is_a_big_lake_with_an_island_and_woods_around() -> void:
	var middle := Vector2(100.0, -300.0)
	var lake := Landforms.lake_level(Vector2(100.0, -260.0))
	assert_ne(lake, SectorDesign.NO_WATER, "water across the lake")
	assert_lt(WorldShape.height(Vector2(100.0, -260.0)), lake - 1.0, "deep enough to swim")
	assert_gt(WorldShape.height(middle), lake + 3.0, "an island in the middle")
	assert_eq(Landforms.lake_level(Vector2(100.0, -150.0)), SectorDesign.NO_WATER, "R1 stays dry")
	var waters := _world.get_node("Waters") as Waters
	assert_eq(waters.lake_count(), 1)
	var vegetation := _world.call("vegetation") as Vegetation
	var on_water := 0
	var on_shore := 0
	for chunk: Vector2i in [Vegetation.chunk_at(Vector2(100.0, -260.0)), Vegetation.chunk_at(Vector2(20.0, -300.0))]:
		for spot: Array in vegetation.tree_spots(chunk):
			var at := (spot[1] as Transform3D).origin
			if Landforms.lake_level(Vector2(at.x, at.z)) != SectorDesign.NO_WATER and at.y < lake:
				on_water += 1
			else:
				on_shore += 1
	assert_eq(on_water, 0, "no trees in the water")
	assert_gt(on_shore, 10, "woods on the shore")


