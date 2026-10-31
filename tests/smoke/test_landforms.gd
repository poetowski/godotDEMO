extends GutTest
## Region designs (data/world/landforms/) keep to their regions and off the
## designed sectors. There are none yet; new ones are covered without changes
## here.

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
