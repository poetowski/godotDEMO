extends GutTest
## Sculpting by hand: the saved layer, the brushes, and the land following them.

const FOLDER := "user://test_sculpt"
const PROJECT_FOLDER := "res://data/world/sculpt"


func before_each() -> void:
	TerrainSculpt.start_empty()
	TerrainSculpt.folder = FOLDER
	_empty_folder()
	RegionMap.configure(10, 10)
	WorldShape.configure(0.0)


func after_each() -> void:
	_empty_folder()
	TerrainSculpt.folder = PROJECT_FOLDER
	TerrainSculpt.start_empty()
	RegionMap.configure(1, 1)


func _empty_folder() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	for file in DirAccess.get_files_at(FOLDER):
		DirAccess.remove_absolute(FOLDER.path_join(file))


func _brush(tool: SculptBrush.Tool) -> SculptBrush:
	var brush := SculptBrush.new()
	brush.tool = tool
	brush.radius = 6.0
	brush.strength = 2.0
	brush.softness = 0.5
	return brush


func test_raising_lifts_the_middle_and_leaves_the_rim_alone() -> void:
	var at := Vector2(150.0, -150.0)
	_brush(SculptBrush.Tool.RAISE).apply(at, 1.0)
	assert_almost_eq(WorldShape.height(at), 2.0, 0.001)
	assert_almost_eq(WorldShape.height(at + Vector2(7.0, 0.0)), 0.0, 0.001)
	assert_between(WorldShape.height(at + Vector2(4.5, 0.0)), 0.1, 1.9, "it fades towards the rim")


func test_lowering_and_inverting_dig_down() -> void:
	var at := Vector2(150.0, -150.0)
	_brush(SculptBrush.Tool.LOWER).apply(at, 1.0)
	assert_almost_eq(WorldShape.height(at), -2.0, 0.001)
	_brush(SculptBrush.Tool.RAISE).apply(at, 1.0, true)
	assert_almost_eq(WorldShape.height(at), -4.0, 0.001)


func test_a_stroke_across_tiles_has_no_step() -> void:
	var at := Vector2(100.0, -100.0)
	_brush(SculptBrush.Tool.RAISE).apply(at, 1.0)
	assert_eq(TerrainSculpt.tile_count(), 4, "the corner of four tiles")
	for k in 40:
		var north := -96.0 - k * 0.2
		assert_almost_eq(WorldShape.height(Vector2(99.9, north)), WorldShape.height(Vector2(100.1, north)), 0.15)


func test_heights_between_samples_lie_on_the_triangles() -> void:
	_brush(SculptBrush.Tool.RAISE).apply(Vector2(50.0, -50.0), 1.0)
	var south_west := TerrainSculpt.sample(51, 50)
	var south_east := TerrainSculpt.sample(52, 50)
	var north_west := TerrainSculpt.sample(51, 51)
	assert_almost_eq(TerrainSculpt.height(Vector2(51.5, -50.0)), (south_west + south_east) * 0.5, 0.0001)
	assert_almost_eq(TerrainSculpt.height(Vector2(51.0, -50.5)), (south_west + north_west) * 0.5, 0.0001)


func test_flatten_brings_the_ground_to_a_height() -> void:
	var at := Vector2(150.0, -150.0)
	var raise := _brush(SculptBrush.Tool.RAISE)
	raise.strength = 5.0
	raise.apply(at, 1.0)
	var flatten := _brush(SculptBrush.Tool.FLATTEN)
	flatten.flatten_height = 1.5
	flatten.strength = 100.0
	flatten.apply(at, 1.0)
	assert_almost_eq(WorldShape.height(at), 1.5, 0.001)
	assert_almost_eq(WorldShape.height(at + Vector2(1.0, 1.0)), 1.5, 0.001)


func test_smoothing_evens_out_a_spike() -> void:
	var at := Vector2(150.0, -150.0)
	var spike := _brush(SculptBrush.Tool.RAISE)
	spike.radius = 2.0
	spike.softness = 0.0
	spike.apply(at, 1.0)
	var rim := at + Vector2(3.0, 0.0)
	var before := WorldShape.height(at) - WorldShape.height(rim)
	var smooth := _brush(SculptBrush.Tool.SMOOTH)
	for k in 20:
		smooth.apply(at, 0.05)
	assert_lt(WorldShape.height(at) - WorldShape.height(rim), before * 0.8)


func test_restore_takes_hand_work_away_and_only_that() -> void:
	var at := Vector2(150.0, -150.0)
	var base := WorldShape.base_height(at)
	_brush(SculptBrush.Tool.RAISE).apply(at, 1.0)
	var restore := _brush(SculptBrush.Tool.RESTORE)
	restore.softness = 0.0
	restore.strength = 100.0
	restore.apply(at, 1.0)
	assert_almost_eq(WorldShape.height(at), base, 0.001)


func test_the_brush_stays_inside_the_world() -> void:
	var brush := _brush(SculptBrush.Tool.RAISE)
	brush.apply(Vector2(1.0, -1.0), 1.0)
	assert_eq(TerrainSculpt.sample(0, 0), 0.0, "the world's edge meets the flat ring")
	assert_eq(TerrainSculpt.sample(-1, 3), 0.0)
	assert_gt(TerrainSculpt.sample(2, 2), 0.0)
	assert_false(brush.apply(Vector2(-50.0, 50.0), 1.0).has_area())


func test_tiles_are_saved_read_back_and_removed_when_empty() -> void:
	var at := Vector2(150.0, -150.0)
	var area := _brush(SculptBrush.Tool.RAISE).apply(at, 1.0)
	var keys := TerrainSculpt.tiles_in(area)
	assert_eq(TerrainSculpt.save(keys), OK)
	assert_true(FileAccess.file_exists(TerrainSculpt.tile_path(Vector2i(1, 1))))
	var height := TerrainSculpt.height(at)
	TerrainSculpt.read_again()
	assert_almost_eq(TerrainSculpt.height(at), height, 0.0001)
	var empty: Dictionary[Vector2i, PackedFloat32Array] = {}
	for key in keys:
		empty[key] = PackedFloat32Array()
	TerrainSculpt.restore(empty)
	assert_eq(TerrainSculpt.save(keys), OK)
	assert_false(FileAccess.file_exists(TerrainSculpt.tile_path(Vector2i(1, 1))))


func test_snapshots_put_the_ground_back() -> void:
	var at := Vector2(150.0, -150.0)
	var brush := _brush(SculptBrush.Tool.RAISE)
	var keys := TerrainSculpt.tiles_in(brush.area_at(at))
	var nothing := TerrainSculpt.snapshot(keys)
	brush.apply(at, 1.0)
	var once := TerrainSculpt.snapshot(keys)
	brush.apply(at, 1.0)
	TerrainSculpt.restore(once)
	assert_almost_eq(WorldShape.height(at), 2.0, 0.001)
	TerrainSculpt.restore(nothing)
	assert_true(TerrainSculpt.is_empty())
