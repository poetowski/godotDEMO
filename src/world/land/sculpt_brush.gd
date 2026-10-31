@tool
class_name SculptBrush
extends RefCounted
## A round brush that changes TerrainSculpt: raises, lowers, smooths, flattens
## to a height, or takes hand work away again. Strong in its middle and fading
## to nothing at its rim.

enum Tool { RAISE, LOWER, SMOOTH, FLATTEN, RESTORE }

const MIN_RADIUS := 1.0
const MAX_RADIUS := 40.0

var tool: Tool = Tool.RAISE
## Metres from the middle to the rim.
var radius: float = 8.0
## Metres a second at the brush's middle; for smoothing, how fast it evens out.
var strength: float = 4.0
## 0 is full strength out to the rim (hard edges, cliffs); 1 fades all the way
## from the middle.
var softness: float = 0.7
## The height Tool.FLATTEN brings the ground to.
var flatten_height: float = 0.0


## How much of its strength the brush has at a distance from its middle.
func weight(distance: float) -> float:
	return 1.0 - smoothstep(radius * (1.0 - softness), radius + 0.001, distance)


## The samples the brush covers at a world x and z, inside the world. Samples
## on the world's edge stay as they are, where the land meets the flat ring.
func area_at(xz: Vector2) -> Rect2i:
	var low := Vector2i(floori(xz.x - radius), floori(-xz.y - radius))
	var high := Vector2i(ceili(xz.x + radius), ceili(-xz.y + radius))
	var bounds := Rect2i(SectorMap.bounds())
	var world := Rect2i(bounds.position + Vector2i.ONE, bounds.size - Vector2i.ONE)
	return Rect2i(low, high - low + Vector2i.ONE).intersection(world)


## One step of the brush over `delta` seconds. `inverted` swaps raising and
## lowering. Returns the samples it covered.
func apply(xz: Vector2, delta: float, inverted: bool = false) -> Rect2i:
	var area := area_at(xz)
	if not area.has_area():
		return area
	var active := tool
	if inverted and active == Tool.RAISE:
		active = Tool.LOWER
	elif inverted and active == Tool.LOWER:
		active = Tool.RAISE
	# Smoothing looks farther with a bigger brush, or big bumps never even out.
	var reach := maxi(1, roundi(radius / 8.0))
	var reads_land := active == Tool.SMOOTH or active == Tool.FLATTEN
	var heights := _heights_around(area, reach) if reads_land else PackedFloat32Array()
	var row := area.size.x + 2 * reach
	var deltas := PackedFloat32Array()
	deltas.resize(area.size.x * area.size.y)
	var middle := Vector2(xz.x, -xz.y)
	var step := strength * delta
	for j in area.size.y:
		for i in area.size.x:
			var sample := area.position + Vector2i(i, j)
			var share := weight(middle.distance_to(Vector2(sample)))
			if share <= 0.0:
				continue
			var here := (j + reach) * row + i + reach
			var change := 0.0
			match active:
				Tool.RAISE:
					change = step * share
				Tool.LOWER:
					change = -step * share
				Tool.FLATTEN:
					change = move_toward(heights[here], flatten_height, step * share) - heights[here]
				Tool.RESTORE:
					var sculpted := TerrainSculpt.sample(sample.x, sample.y)
					change = move_toward(sculpted, 0.0, step * share) - sculpted
				Tool.SMOOTH:
					var around := (heights[here - reach] + heights[here + reach] + heights[here - reach * row] + heights[here + reach * row]) * 0.25
					change = (around - heights[here]) * minf(step * share, 1.0)
			deltas[j * area.size.x + i] = change
	TerrainSculpt.add_area(area, deltas)
	return area


## The land's height over an area and `reach` samples around it, row by row.
func _heights_around(area: Rect2i, reach: int) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize((area.size.x + 2 * reach) * (area.size.y + 2 * reach))
	var k := 0
	for j in range(area.position.y - reach, area.end.y + reach):
		for i in range(area.position.x - reach, area.end.x + reach):
			heights[k] = WorldShape.height(Vector2(i, -j))
			k += 1
	return heights
