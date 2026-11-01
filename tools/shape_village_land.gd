extends SceneTree
## One-off from the author's "you can also redesign hills and terrains around if you find it to
## be creative": shapes the land round R1's village. It smooths the lumps, lifts the church's
## hill, raises a long rise for the forest to climb east of the village, and levels a pad under
## each building and the square. Water's edges and low ground stay as they were. Run headless
## with the editor closed:
##   godot --headless --path . -s res://tools/shape_village_land.gd
## The tiles it saves are ordinary sculpt tiles, to go on sculpting by hand.

## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(76, 50, 94, 80)
const EDGE := 12.0
const BLUR_RADIUS := 3
const BLUR_PASSES := 3
## Added to the church's hill, and how wide that is.
const HILL_HEIGHT := 0.7
const HILL_REACH := 24.0
## The forest's rise: its crest's x, height and half width, and the folds along it.
const RISE_X := 145.0
const RISE_HEIGHT := 4.5
const RISE_REACH := 17.0
const RISE_NORTH_FROM := 58.0
const RISE_NORTH_TO := 122.0
## Ground lower than this stays as it is, fully changing from the upper height.
const KEEP_BELOW := -1.2
const CHANGE_ABOVE := 0.2
## A pad reaches this far past what it holds, fading out, and the church's fades long, so its
## hill rises gently.
const PAD_FADE := 6.0
const CHURCH_FADE := 16.0
const PAD_ROUNDS := 3
## Metres the church stands at, so the way up from the square is an easy climb.
const CHURCH_LEVEL := 3.0
## The farm stands on one wide gentle pad.
const FARM := Vector2(95.5, 70.0)
const FARM_RADIUS := 11.0


func _init() -> void:
	TerrainSculpt.read_again()
	var margin := BLUR_RADIUS * BLUR_PASSES + 1
	var wide := AREA.grow(margin)
	var land := PackedFloat32Array()
	land.resize(wide.size.x * wide.size.y)
	for j in wide.size.y:
		for i in wide.size.x:
			land[j * wide.size.x + i] = WorldShape.height(Vector2(wide.position.x + i, -(wide.position.y + j)))
	var smooth := land
	for pass_number in BLUR_PASSES:
		smooth = _blur(smooth, wide.size)
	var folds := FastNoiseLite.new()
	folds.seed = 11
	folds.frequency = 0.03
	folds.fractal_octaves = 2
	# First the shape, then the pads levelled on it.
	var shaped := smooth.duplicate()
	for j in wide.size.y:
		for i in wide.size.x:
			var at := Vector2(wide.position.x + i, wide.position.y + j)
			var along := smoothstep(RISE_NORTH_FROM, RISE_NORTH_FROM + 14.0, at.y) * (1.0 - smoothstep(RISE_NORTH_TO - 14.0, RISE_NORTH_TO, at.y))
			var rise := exp(-pow((at.x - RISE_X) / RISE_REACH, 2.0) * 2.0) * RISE_HEIGHT * along
			var hill := exp(-pow(at.distance_to(R1Village.CHURCH) / HILL_REACH, 2.0) * 2.0) * HILL_HEIGHT
			shaped[j * wide.size.x + i] += rise * (1.0 + folds.get_noise_2d(at.x, at.y)) + hill
	var pads: Array[Array] = [[R1Village.SQUARE, R1Village.SQUARE_RADIUS + 1.0, PAD_FADE], [FARM, FARM_RADIUS, PAD_FADE]]
	for building in R1Village.BUILDINGS:
		if String(building[0]) == "nordic_church":
			# First, so the terraces cut into its long slope have the last word.
			pads.push_front([building[1], 7.5, CHURCH_FADE])
		elif String(building[0]) not in ["farmhouse", "farm_shed"]:
			pads.append([building[1], building[3], PAD_FADE])
	# Pads whose fades would run into each other share a level, so they make one terrace.
	var levels: Array[float] = []
	for pad in pads:
		levels.append(_mean(shaped, wide, pad[0], pad[1]))
	var shared: Array[float] = []
	for a in pads.size():
		var total := 0.0
		var count := 0
		for b in pads.size():
			var apart := (pads[a][0] as Vector2).distance_to(pads[b][0])
			if pads[a][2] == PAD_FADE and pads[b][2] == PAD_FADE and pads[a][0] != FARM and pads[b][0] != FARM and apart < float(pads[a][1]) + float(pads[b][1]) + PAD_FADE:
				total += levels[b]
				count += 1
		shared.append(CHURCH_LEVEL if pads[a][2] == CHURCH_FADE else (total / count if count > 0 else levels[a]))
	# More than once, as a neighbour's fade reaches into a pad already levelled.
	for round_number in PAD_ROUNDS:
		for n in pads.size():
			var pad: Array = pads[n]
			var middle: Vector2 = pad[0]
			var radius: float = pad[1]
			var fade: float = pad[2]
			var level := shared[n]
			for j in wide.size.y:
				for i in wide.size.x:
					var distance := Vector2(wide.position.x + i, wide.position.y + j).distance_to(middle)
					if distance < radius + fade:
						var k := j * wide.size.x + i
						shaped[k] = lerpf(shaped[k], level, 1.0 - smoothstep(radius, radius + fade, distance))
	var deltas := PackedFloat32Array()
	deltas.resize(AREA.size.x * AREA.size.y)
	var biggest := 0.0
	for j in AREA.size.y:
		for i in AREA.size.x:
			var edge := minf(minf(i, AREA.size.x - 1 - i), minf(j, AREA.size.y - 1 - j)) / EDGE
			var k := (j + margin) * wide.size.x + i + margin
			var weight := smoothstep(0.0, 1.0, edge) * smoothstep(KEEP_BELOW, CHANGE_ABOVE, _lowest_near(land, wide, i + margin, j + margin))
			var delta := (shaped[k] - land[k]) * weight
			deltas[j * AREA.size.x + i] = delta
			biggest = maxf(biggest, absf(delta))
	TerrainSculpt.add_area(AREA, deltas)
	var error := TerrainSculpt.save(TerrainSculpt.tiles_in(AREA))
	print("[shape] largest change %.2f m, saved: %s" % [biggest, error_string(error)])
	quit(0 if error == OK else 1)


func _mean(values: PackedFloat32Array, area: Rect2i, middle: Vector2, radius: float) -> float:
	var total := 0.0
	var count := 0
	for j in area.size.y:
		for i in area.size.x:
			if Vector2(area.position.x + i, area.position.y + j).distance_to(middle) < radius:
				total += values[j * area.size.x + i]
				count += 1
	return total / maxi(count, 1)


## The lowest ground within a few metres, so banks keep their foot.
func _lowest_near(values: PackedFloat32Array, area: Rect2i, i: int, j: int) -> float:
	var lowest := INF
	for offset: Vector2i in [Vector2i.ZERO, Vector2i(5, 0), Vector2i(-5, 0), Vector2i(0, 5), Vector2i(0, -5)]:
		var at := Vector2i(i, j) + offset
		if at.x >= 0 and at.y >= 0 and at.x < area.size.x and at.y < area.size.y:
			lowest = minf(lowest, values[at.y * area.size.x + at.x])
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
