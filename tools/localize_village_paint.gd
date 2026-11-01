extends SceneTree
## One-off from the author's "you can also adjust terrain painting, make pavement more
## realisticaly localized": repaints the middle of R1 so paving lies only where feet and wheels
## would have worn it. Cobbles on the square and the street's middle, dirt at the street's
## edges and before each door, flagstones up to the church, a wagon track where the author's
## ring road ran, and trodden dry grass where their plazas were. Run headless with the editor
## closed, after the buildings are laid out in R1Village:
##   godot --headless --path . -s res://tools/localize_village_paint.gd
## The author's own paint is in git at 50784c2. The road running in from the south-west is left
## as they painted it.

## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(88, 60, 52, 56)
## Half widths in metres.
const COBBLE_WIDTH := 1.1
const STREET_WIDTH := 2.2
const LANE_WIDTH := 1.2
const TRACK_WIDTH := 1.0
const CHURCH_WAY_WIDTH := 0.95
## Metres of dirt round a door, and of trodden grass round a building.
const DOOR_RADIUS := 2.8
const TRODDEN := 3.5
## Where along the street the cobbles start, by x: the village's end of it has only dirt.
const COBBLES_FROM_X := 104.0
const CHURCH_DOOR := Vector2(121.8, 101.2)

const DIRT := 0
const MUD := 1
const GRAVEL := 2
const DRY_GRASS := 4
const LUSH_GRASS := 5
const COBBLE := 6
const FLAGSTONE := 7

var _noise: FastNoiseLite


func _init() -> void:
	TerrainPaint.read_again()
	_noise = FastNoiseLite.new()
	_noise.seed = 21
	_noise.frequency = 0.28
	var layers: Dictionary[int, PackedFloat32Array] = {}
	for surface: int in [DIRT, MUD, GRAVEL, DRY_GRASS, LUSH_GRASS, COBBLE, FLAGSTONE]:
		var amounts := PackedFloat32Array()
		amounts.resize(AREA.size.x * AREA.size.y)
		layers[surface] = amounts
	var clear := PackedFloat32Array()
	clear.resize(AREA.size.x * AREA.size.y)
	clear.fill(1.0)
	for j in AREA.size.y:
		for i in AREA.size.x:
			var at := Vector2(AREA.position.x + i, AREA.position.y + j)
			var surface := _surface_at(at)
			if surface >= 0:
				layers[surface][j * AREA.size.x + i] = 1.0
	# What the author painted that's still wanted is written back from the plan.
	TerrainPaint.lay(AREA, clear, TerrainPaint.ERASE)
	for surface: int in layers:
		TerrainPaint.lay(AREA, layers[surface], surface)
	var error := TerrainPaint.save(TerrainSculpt.tiles_in(AREA))
	print("[paint] saved: %s" % error_string(error))
	quit(0 if error == OK else 1)


func _surface_at(at: Vector2) -> int:
	var rough := _noise.get_noise_2d(at.x, at.y)
	var plaza := _was_plaza(at)
	# The farm's barley, in strips with bare furrows between.
	if R1Village.CROPS.has_point(at):
		return DIRT if int(at.y) % 3 == 0 else DRY_GRASS
	if at.distance_to(R1Village.SQUARE) < R1Village.SQUARE_RADIUS + rough * 1.2:
		return COBBLE
	for door: Vector2 in [Vector2(98.8, 76.4)]:
		if at.distance_to(door) < 1.4 + rough:
			return MUD
	if at.distance_to(CHURCH_DOOR) < 2.3 + rough * 0.6 or _distance_to_line(at, [Vector2(118.0, 97.0), Vector2(120.6, 99.6), CHURCH_DOOR]) < CHURCH_WAY_WIDTH + rough * 0.25:
		return FLAGSTONE
	var street := _distance_to_line(at, R1Village.MAIN_STREET)
	if street < COBBLE_WIDTH + rough * 0.4 and at.x > COBBLES_FROM_X + rough * 3.0 and at.x < R1Village.SQUARE.x:
		return COBBLE
	if street < STREET_WIDTH + rough * 0.7:
		return DIRT
	for lane in R1Village.LANES:
		if _distance_to_line(at, lane) < LANE_WIDTH + rough * 0.45:
			return DIRT
	for building in R1Village.BUILDINGS:
		var from: Vector2 = building[1]
		var door := from + (Vector2(building[2]) - from).normalized() * (float(building[3]) * 0.72)
		if String(building[0]) != "nordic_church" and at.distance_to(door) < DOOR_RADIUS + rough:
			return DIRT
	var track := _distance_to_line(at, R1Village.RING)
	if track < 0.5 + rough * 0.3:
		return GRAVEL
	if track < TRACK_WIDTH + rough * 0.4:
		return DIRT
	if at.distance_to(R1Village.CHURCH) < R1Village.PINES_FROM + rough * 2.0:
		return LUSH_GRASS if rough > -0.2 else -1
	for building in R1Village.BUILDINGS:
		if String(building[0]) != "nordic_church" and at.distance_to(building[1]) < float(building[3]) + TRODDEN * (0.7 + rough):
			return DRY_GRASS if rough > -0.25 else -1
	if plaza:
		return DRY_GRASS if rough > 0.02 else -1
	return -1


## True where the author painted dirt. The middle of each plaza.
func _was_plaza(at: Vector2) -> bool:
	return TerrainPaint.share(int(at.x), int(at.y), DIRT) > 0.3


func _distance_to_line(at: Vector2, points: Array) -> float:
	var nearest := INF
	for k in points.size() - 1:
		var on: Vector2 = Geometry2D.get_closest_point_to_segment(at, points[k], points[k + 1])
		nearest = minf(nearest, at.distance_to(on))
	return nearest
