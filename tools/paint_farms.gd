extends SceneTree
## One-off from the author's "also use paint yourself on ground more often": paints the farms
## round Aiwyk and the fields between them. Worn ground at doors and gates, tracks, barley strips,
## and over the open land drifts of dry and lush grass and stony patches the rocks are placed on.
## It adds to the author's paint and never paints over their strokes. Run headless with the editor
## closed, after R1Farms is laid out:
##   godot --headless --path . -s res://tools/paint_farms.gd
## The author's own paint before this is in git at 32982f9.

## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(12, 80, 88, 56)
## The village's own ground, which keeps its paint.
const VILLAGE_WEST := 88.0
const VILLAGE_SOUTH := 58.0
## A sample holding more than this of the author's paint is theirs.
const THEIRS := 0.12
## Noise above which a drift starts, and how much of the surface it lays at most.
const DRY_FROM := 0.14
const DRY_MOST := 0.75
const LUSH_FROM := 0.2
const LUSH_MOST := 0.7
const STONY_FROM := 0.42
const STONY_MOST := 0.5

const DIRT := 0
const MUD := 1
const GRAVEL := 2
const DRY_GRASS := 4
const LUSH_GRASS := 5

var _edge: FastNoiseLite
var _dry: FastNoiseLite
var _lush: FastNoiseLite
var _stony: FastNoiseLite


func _initialize() -> void:
	FieldWorld.configure()
	TerrainPaint.read_again()
	_edge = _noise(31, 0.28)
	_dry = _noise(32, 0.035)
	_lush = _noise(33, 0.045)
	_stony = _noise(34, 0.07)
	var layers: Dictionary[int, PackedFloat32Array] = {}
	for surface: int in [DIRT, MUD, GRAVEL, DRY_GRASS, LUSH_GRASS]:
		var amounts := PackedFloat32Array()
		amounts.resize(AREA.size.x * AREA.size.y)
		layers[surface] = amounts
	# The yard south of row 8 lies outside the wide area, so it's a second pass.
	_paint(AREA, layers)
	var yard := Rect2i(58, 68, 24, 12)
	var yard_layers: Dictionary[int, PackedFloat32Array] = {}
	for surface: int in layers:
		var amounts := PackedFloat32Array()
		amounts.resize(yard.size.x * yard.size.y)
		yard_layers[surface] = amounts
	_paint(yard, yard_layers)
	for surface: int in layers:
		TerrainPaint.lay(AREA, layers[surface], surface)
		TerrainPaint.lay(yard, yard_layers[surface], surface)
	var keys := TerrainSculpt.tiles_in(AREA)
	for key in TerrainSculpt.tiles_in(yard):
		if key not in keys:
			keys.append(key)
	var error := TerrainPaint.save(keys)
	print("[paint] saved: %s" % error_string(error))
	quit(0 if error == OK else 1)


func _noise(seed_number: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_number
	noise.frequency = frequency
	return noise


func _paint(area: Rect2i, layers: Dictionary[int, PackedFloat32Array]) -> void:
	for j in area.size.y:
		for i in area.size.x:
			var at := Vector2(area.position.x + i, area.position.y + j)
			if at.x >= VILLAGE_WEST and at.y >= VILLAGE_SOUTH and not _on_track(at):
				continue
			if _theirs(int(at.x), int(at.y)) > THEIRS:
				continue
			var found := _surface_at(at)
			if found[0] >= 0:
				layers[found[0]][j * area.size.x + i] = found[1]


func _theirs(x: int, y: int) -> float:
	var total := 0.0
	for surface in TerrainPaint.LAYERS:
		total += TerrainPaint.share(x, y, surface)
	return total


func _on_track(at: Vector2) -> bool:
	for track in R1Farms.TRACKS:
		if _distance_to_line(at, track[0]) < float(track[1]) + 0.6:
			return true
	return false


## The surface at a place and how much of it.
func _surface_at(at: Vector2) -> Array:
	var rough := _edge.get_noise_2d(at.x, at.y)
	for crops: Rect2 in R1Farms.CROPS:
		if crops.has_point(at):
			return [DIRT, 0.9] if int(at.y) % 3 == 0 else [DRY_GRASS, 0.85]
	for worn in R1Farms.WORN:
		var reach := float(worn[2]) + rough * 0.7
		var distance := at.distance_to(worn[1])
		if distance < reach:
			return [worn[0], clampf((reach - distance) / 0.9, 0.25, 0.95)]
	for track in R1Farms.TRACKS:
		var distance := _distance_to_line(at, track[0])
		var wide: float = float(track[1]) + rough * 0.4
		if distance < wide:
			# A worn track comes and goes, more grass in it the less it's used.
			var worn: float = float(track[2])
			return [DIRT, clampf(worn + rough * 0.5 - distance / wide * 0.3, 0.0, 0.95)]
	var stony := _stony.get_noise_2d(at.x, at.y)
	if stony > STONY_FROM and rough > -0.25:
		return [GRAVEL, minf((stony - STONY_FROM) * 4.0, STONY_MOST)]
	var dry := _dry.get_noise_2d(at.x, at.y)
	if dry + rough * 0.15 > DRY_FROM:
		return [DRY_GRASS, minf((dry - DRY_FROM) * 3.5 + 0.2, DRY_MOST)]
	var lush := _lush.get_noise_2d(at.x, at.y)
	if lush + rough * 0.15 > LUSH_FROM:
		return [LUSH_GRASS, minf((lush - LUSH_FROM) * 3.5 + 0.2, LUSH_MOST)]
	return [-1, 0.0]


func _distance_to_line(at: Vector2, points: Array) -> float:
	var nearest := INF
	for k in points.size() - 1:
		var on: Vector2 = Geometry2D.get_closest_point_to_segment(at, points[k], points[k + 1])
		nearest = minf(nearest, at.distance_to(on))
	return nearest
