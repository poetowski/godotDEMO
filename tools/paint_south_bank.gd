extends SceneTree
## One-off from the author's "use painting ground if needed, remember this one": paints R6 south
## of the bridge. Trodden dirt and dry grass in the tent's camp, a worn way from it to the author's
## road, leaf-dark dirt and lush grass under the poplars, and drifts of grass and stony patches the
## rocks are placed on. It adds to the author's paint and never paints over their strokes. Run
## headless with the editor closed, after R6SouthBank is laid out:
##   godot --headless --path . -s res://tools/paint_south_bank.gd
## The author's own paint before this is in git at 10bd197.

## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(18, -42, 56, 42)
## A sample holding more than this of the author's paint is theirs.
const THEIRS := 0.12
## The way from the tent's door to the author's road, and its half width.
const CAMP_WAY: Array[Vector2] = [Vector2(38.5, -15.2), Vector2(42.0, -14.0), Vector2(44.8, -13.4)]
const WAY_WIDTH := 0.9
const YARD := 6.2
const YARD_EDGE := 8.5
const RING_DIRT := 3.0
const STONY_FROM := 0.4
const STONY_MOST := 0.5
const DRY_FROM := 0.18
const LUSH_FROM := 0.12

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
	_edge = _noise(51, 0.2)
	_dry = _noise(52, 0.035)
	_lush = _noise(53, 0.045)
	_stony = _noise(54, 0.07)
	var layers: Dictionary[int, PackedFloat32Array] = {}
	for surface: int in [DIRT, MUD, GRAVEL, DRY_GRASS, LUSH_GRASS]:
		var amounts := PackedFloat32Array()
		amounts.resize(AREA.size.x * AREA.size.y)
		layers[surface] = amounts
	for j in AREA.size.y:
		for i in AREA.size.x:
			var x := AREA.position.x + i
			var y := AREA.position.y + j
			var theirs := 0.0
			for surface in TerrainPaint.LAYERS:
				theirs += TerrainPaint.share(x, y, surface)
			if theirs > THEIRS:
				continue
			var found := _surface_at(Vector2(x, y))
			if found[0] >= 0:
				layers[found[0]][j * AREA.size.x + i] = found[1]
	for surface: int in layers:
		TerrainPaint.lay(AREA, layers[surface], surface)
	var error := TerrainPaint.save(TerrainSculpt.tiles_in(AREA))
	print("[paint] saved: %s" % error_string(error))
	quit(0 if error == OK else 1)


func _noise(seed_number: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_number
	noise.frequency = frequency
	return noise


## The surface at a place and how much of it.
func _surface_at(at: Vector2) -> Array:
	var rough := _edge.get_noise_2d(at.x, at.y)
	var from_tent := at.distance_to(R6SouthBank.TENT) + rough * 2.5
	if from_tent < 3.9:
		return [MUD, 0.8]
	if from_tent < YARD:
		return [DIRT, clampf((YARD - from_tent) * 0.55 + 0.25, 0.3, 0.9)]
	var way := _distance_to_line(at, CAMP_WAY)
	if way < WAY_WIDTH + rough * 0.4:
		return [DIRT, 0.8]
	if at.distance_to(Vector2(41.8, -15.2)) < 2.6 + rough:
		return [DIRT, 0.85]
	if from_tent < YARD_EDGE:
		return [DRY_GRASS, 0.8]
	var from_ring := at.distance_to(R6SouthBank.RING) + rough * 1.4
	if from_ring < RING_DIRT:
		return [LUSH_GRASS, 0.9]
	if from_ring < RING_DIRT + 0.8:
		return [DIRT, 0.55]
	var lush := _lush.get_noise_2d(at.x, at.y)
	# Only grass under the stands: trees keep clear of bare ground, so bare patches would thin them.
	if R6SouthBank.POPLARS.has_point(at):
		return [DRY_GRASS, 0.5] if lush + rough * 0.3 < -0.16 else [LUSH_GRASS, 0.75]
	if R6SouthBank.WHITE_POPLARS.has_point(at):
		return [DRY_GRASS, 0.55] if lush + rough * 0.3 < -0.22 else [LUSH_GRASS, 0.6]
	var stony := _stony.get_noise_2d(at.x, at.y)
	if stony > STONY_FROM and rough > -0.25:
		return [GRAVEL, minf((stony - STONY_FROM) * 4.0, STONY_MOST)]
	var dry := _dry.get_noise_2d(at.x, at.y)
	if dry + rough * 0.15 > DRY_FROM:
		return [DRY_GRASS, minf((dry - DRY_FROM) * 3.5 + 0.2, 0.7)]
	if lush + rough * 0.15 > LUSH_FROM:
		return [LUSH_GRASS, minf((lush - LUSH_FROM) * 3.5 + 0.2, 0.7)]
	return [-1, 0.0]


func _distance_to_line(at: Vector2, points: Array) -> float:
	var nearest := INF
	for k in points.size() - 1:
		var on: Vector2 = Geometry2D.get_closest_point_to_segment(at, points[k], points[k + 1])
		nearest = minf(nearest, at.distance_to(on))
	return nearest
