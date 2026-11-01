extends SceneTree
## One-off from the author's "you can also redesign terrain hills and slops to make it more
## realistic": turns the lumps of R8's forest and R1's west into long rolling slopes. Blurs
## what's sculpted, with broader folds added, over the area below; water's edges, low ground
## and the cliff stay exactly as they were. Run headless with the editor closed:
##   godot --headless --path . -s res://tools/relax_hills.gd
## The tiles it saves are ordinary sculpt tiles, to go on sculpting by hand.

## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(-85, 0, 130, 140)
## Metres over which the change fades in from the area's edge.
const EDGE := 12.0
## Passes of a blur this many metres wide, which is about a 12 m smoothing.
const BLUR_RADIUS := 3
const BLUR_PASSES := 4
## The metres of the broad folds, and how wide they are.
const FOLD_HEIGHT := 0.6
const FOLD_FREQUENCY := 0.018
## Ground lower than this stays as it is, fully changing from the upper height: cliffs,
## banks and the river.
const KEEP_BELOW := -1.2
const CHANGE_ABOVE := 0.2


func _init() -> void:
	TerrainSculpt.read_again()
	var margin := BLUR_RADIUS * BLUR_PASSES + 1
	var wide := AREA.grow(margin)
	var values := PackedFloat32Array()
	values.resize(wide.size.x * wide.size.y)
	for j in wide.size.y:
		for i in wide.size.x:
			values[j * wide.size.x + i] = TerrainSculpt.sample(wide.position.x + i, wide.position.y + j)
	var smooth := values
	for pass_number in BLUR_PASSES:
		smooth = _blur(smooth, wide.size)
	var folds := FastNoiseLite.new()
	folds.seed = 8
	folds.frequency = FOLD_FREQUENCY
	folds.fractal_octaves = 2
	var deltas := PackedFloat32Array()
	deltas.resize(AREA.size.x * AREA.size.y)
	var biggest := 0.0
	for j in AREA.size.y:
		for i in AREA.size.x:
			var x := AREA.position.x + i
			var north := AREA.position.y + j
			var edge := minf(minf(i, AREA.size.x - 1 - i), minf(j, AREA.size.y - 1 - j)) / EDGE
			var height := WorldShape.height(Vector2(x, -north))
			var low := minf(height, _lowest_near(x, north))
			var weight := smoothstep(0.0, 1.0, edge) * smoothstep(KEEP_BELOW, CHANGE_ABOVE, low)
			var k := (j + margin) * wide.size.x + i + margin
			var target := smooth[k] + folds.get_noise_2d(x, north) * FOLD_HEIGHT * 2.0
			var delta := (target - values[k]) * weight
			deltas[j * AREA.size.x + i] = delta
			biggest = maxf(biggest, absf(delta))
	TerrainSculpt.add_area(AREA, deltas)
	var error := TerrainSculpt.save(TerrainSculpt.tiles_in(AREA))
	print("[relax] largest change %.2f m, saved: %s" % [biggest, error_string(error)])
	quit(0 if error == OK else 1)


## The lowest ground within a few metres, so banks keep their foot.
func _lowest_near(x: int, north: int) -> float:
	var lowest := INF
	for offset: Vector2i in [Vector2i(5, 0), Vector2i(-5, 0), Vector2i(0, 5), Vector2i(0, -5), Vector2i(4, 4), Vector2i(-4, 4), Vector2i(4, -4), Vector2i(-4, -4)]:
		lowest = minf(lowest, WorldShape.height(Vector2(x + offset.x, -(north + offset.y))))
	return lowest


## One pass of a box blur, across and then along.
func _blur(from: PackedFloat32Array, size: Vector2i) -> PackedFloat32Array:
	var across := from.duplicate()
	for j in size.y:
		for i in range(BLUR_RADIUS, size.x - BLUR_RADIUS):
			var total := 0.0
			for k in range(-BLUR_RADIUS, BLUR_RADIUS + 1):
				total += from[j * size.x + i + k]
			across[j * size.x + i] = total / (BLUR_RADIUS * 2 + 1)
	var along := across.duplicate()
	for j in range(BLUR_RADIUS, size.y - BLUR_RADIUS):
		for i in size.x:
			var total := 0.0
			for k in range(-BLUR_RADIUS, BLUR_RADIUS + 1):
				total += across[(j + k) * size.x + i]
			along[j * size.x + i] = total / (BLUR_RADIUS * 2 + 1)
	return along
