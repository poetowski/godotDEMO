extends SceneTree
## Carves the land along the world's west border into the author's sculpted tiles,
## once, at the author's request: the ravine carried north through R9, and
## everything west of the tarn sunk into an abyss far below the ravine's floor. It
## only ever lowers the ground, so it keeps what the author carved. Running it again
## changes nothing. Close the editor first.
##
## Run: godot --headless --path . --script res://tools/carve_western_abyss.gd

## x at which the abyss starts, and where it reaches full depth.
const ABYSS_FROM := -166.0
const ABYSS_FULL := -184.0
const ABYSS_DEPTH := -220.0
## The rim of the ravine carried north, in R9; its floor; and how wide its slope is.
const RIM_X := -128.0
const FLOOR := -58.0
const SLOPE := 36.0
## North of here the author's ravine ends, and this carve takes over.
const NORTH_FROM := 150.0
## Over these norths the rim closes in on the fog's line, to end the ravine at the
## world's north edge.
const CLOSE_FROM := 330.0
const CLOSE_TO := 396.0
const CLOSED_RIM_X := -168.0


func _initialize() -> void:
	FieldWorld.configure()
	var noise := FastNoiseLite.new()
	noise.seed = 88
	noise.frequency = 0.018
	var area := Rect2i(-199, -199, 110, 598)
	var deltas := PackedFloat32Array()
	deltas.resize(area.size.x * area.size.y)
	for j in area.size.y:
		for i in area.size.x:
			var x := area.position.x + i
			var north := area.position.y + j
			var here := WorldShape.height(Vector2(x, -north))
			deltas[j * area.size.x + i] = minf(_target(x, north, noise) - here, 0.0)
	TerrainSculpt.add_area(area, deltas)
	var error := TerrainSculpt.save(TerrainSculpt.tiles_in(area))
	print("carve: %s" % error_string(error))
	quit(0 if error == OK else 1)


## The height the ground should reach at most at a sample.
func _target(x: int, north: int, noise: FastNoiseLite) -> float:
	var target := INF
	if north >= NORTH_FROM:
		var rim := RIM_X + noise.get_noise_1d(north) * 22.0
		rim = lerpf(rim, CLOSED_RIM_X, smoothstep(CLOSE_FROM, CLOSE_TO, north))
		# Eases in, so it joins the author's rim instead of cutting across it.
		var from_rim := (rim - x) * smoothstep(NORTH_FROM, NORTH_FROM + 30.0, north)
		if from_rim > 0.0:
			var uneven := noise.get_noise_2d(x * 3.0, north * 3.0) * 4.0
			target = FLOOR * smoothstep(0.0, SLOPE, from_rim) + uneven * smoothstep(0.0, 12.0, from_rim)
	if x < ABYSS_FROM:
		target = minf(target, ABYSS_DEPTH * smoothstep(ABYSS_FROM, ABYSS_FULL, x))
	return target
