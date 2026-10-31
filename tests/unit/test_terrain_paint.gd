extends GutTest
## Painting by hand: the shares, the brush, saving, and that the land stays put.

const FOLDER := "user://test_paint"
const PROJECT_FOLDER := "res://data/world/paint"
const DIRT := 0
const COBBLE := 6
const AT := Vector2(150.0, -150.0)
const SAMPLE := Vector2i(150, 150)


func before_each() -> void:
	TerrainPaint.folder = FOLDER
	_empty_folder()
	TerrainPaint.start_empty()


func after_each() -> void:
	_empty_folder()
	TerrainPaint.folder = PROJECT_FOLDER
	TerrainPaint.start_empty()


func _empty_folder() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	for file in DirAccess.get_files_at(FOLDER):
		DirAccess.remove_absolute(FOLDER.path_join(file))


func _brush(surface: int) -> PaintBrush:
	var brush := PaintBrush.new()
	brush.surface = surface
	brush.radius = 5.0
	brush.softness = 0.5
	brush.strength = 2.0
	return brush


func _share(surface: int, sample: Vector2i = SAMPLE) -> float:
	return TerrainPaint.share(sample.x, sample.y, surface)


func test_painting_covers_the_middle_and_leaves_the_rim_alone() -> void:
	_brush(DIRT).apply(AT, 1.0)
	assert_almost_eq(_share(DIRT), 1.0, 0.001)
	assert_eq(_share(DIRT, SAMPLE + Vector2i(6, 0)), 0.0, "past the rim")
	assert_gt(_share(DIRT, SAMPLE + Vector2i(4, 0)), 0.0, "towards the rim")
	assert_lt(_share(DIRT, SAMPLE + Vector2i(4, 0)), 1.0, "towards the rim")


func test_one_surface_gives_way_to_another() -> void:
	_brush(DIRT).apply(AT, 1.0)
	_brush(COBBLE).apply(AT, 0.25)
	assert_almost_eq(_share(COBBLE), 0.5, 0.01)
	assert_lte(_share(DIRT) + _share(COBBLE), 1.0, "never more than everything")
	assert_gt(_share(DIRT), 0.4)
	_brush(COBBLE).apply(AT, 1.0)
	assert_eq(_share(DIRT), 0.0, "gone once fully covered")


func test_erasing_brings_the_land_back_and_empties_the_tile() -> void:
	_brush(DIRT).apply(AT, 1.0)
	assert_false(TerrainPaint.is_empty())
	var erasing := _brush(DIRT)
	erasing.radius = 12.0
	erasing.apply(AT, 2.0, true)
	assert_eq(_share(DIRT), 0.0)
	assert_true(TerrainPaint.is_empty())


func test_painting_stays_inside_the_world() -> void:
	var area := _brush(DIRT).apply(Vector2(1.0, -1.0), 1.0)
	assert_eq(area.position, Vector2i.ZERO)
	assert_false(_brush(DIRT).area_at(Vector2(-100.0, 100.0)).has_area())


func test_a_stroke_across_tiles_paints_both() -> void:
	_brush(DIRT).apply(Vector2(100.0, -50.0), 1.0)
	assert_almost_eq(_share(DIRT, Vector2i(99, 50)), 1.0, 0.05)
	assert_almost_eq(_share(DIRT, Vector2i(100, 50)), 1.0, 0.05)


func test_saved_tiles_come_back_and_empty_ones_lose_their_file() -> void:
	_brush(COBBLE).apply(AT, 1.0)
	var key := Vector2i(1, 1)
	var keys: Array[Vector2i] = [key]
	assert_eq(TerrainPaint.save(keys), OK)
	assert_true(FileAccess.file_exists(TerrainPaint.tile_path(key)))
	TerrainPaint.read_again()
	assert_almost_eq(_share(COBBLE), 1.0, 0.001)
	assert_gt(TerrainPaint.paving_at(AT), 0.9)
	_brush(COBBLE).apply(AT, 1.0, true)
	assert_eq(TerrainPaint.save(keys), OK)
	assert_false(FileAccess.file_exists(TerrainPaint.tile_path(key)))


func test_a_snapshot_undoes_a_stroke() -> void:
	var keys: Array[Vector2i] = [Vector2i(1, 1)]
	var before := TerrainPaint.snapshot(keys)
	_brush(DIRT).apply(AT, 1.0)
	var after := TerrainPaint.snapshot(keys)
	TerrainPaint.restore(before)
	assert_true(TerrainPaint.is_empty())
	TerrainPaint.restore(after)
	assert_almost_eq(_share(DIRT), 1.0, 0.001)


func test_painting_leaves_the_land_alone() -> void:
	var height := WorldShape.height(AT)
	_brush(DIRT).apply(AT, 1.0)
	assert_eq(WorldShape.height(AT), height)
