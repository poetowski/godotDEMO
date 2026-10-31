@tool
class_name PaintBrush
extends RefCounted
## A round brush that changes TerrainPaint: lays a surface, or takes paint away.
## Strong in its middle and fading to nothing at its rim.

const MIN_RADIUS := 1.0
const MAX_RADIUS := 40.0

## One of TerrainPaint's surfaces, or TerrainPaint.ERASE.
var surface: int = 0
## Metres from the middle to the rim.
var radius: float = 3.0
## Full coverages laid a second at the brush's middle.
var strength: float = 4.0
## 0 is full strength out to the rim (hard edges); 1 fades all the way from the
## middle.
var softness: float = 0.35


## How much of its strength the brush has at a distance from its middle.
func weight(distance: float) -> float:
	return 1.0 - smoothstep(radius * (1.0 - softness), radius + 0.001, distance)


## The samples the brush covers at a world x and z, inside the world.
func area_at(xz: Vector2) -> Rect2i:
	var low := Vector2i(floori(xz.x - radius), floori(-xz.y - radius))
	var high := Vector2i(ceili(xz.x + radius), ceili(-xz.y + radius))
	var world := Rect2i(SectorMap.bounds())
	return Rect2i(low, high - low + Vector2i.ONE).intersection(world)


## One step of the brush over `delta` seconds. `erasing` takes paint away
## whichever surface is picked. Returns the samples it covered.
func apply(xz: Vector2, delta: float, erasing: bool = false) -> Rect2i:
	var area := area_at(xz)
	if not area.has_area():
		return area
	var amounts := PackedFloat32Array()
	amounts.resize(area.size.x * area.size.y)
	var middle := Vector2(xz.x, -xz.y)
	var step := strength * delta
	for j in area.size.y:
		for i in area.size.x:
			amounts[j * area.size.x + i] = step * weight(middle.distance_to(Vector2(area.position + Vector2i(i, j))))
	TerrainPaint.lay(area, amounts, TerrainPaint.ERASE if erasing else surface)
	return area
