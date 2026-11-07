@tool
class_name WorldShape
extends RefCounted
## The lay of the land under every sector, in layers that add up: the landforms
## of region designs (Landforms: mountains, ridges, valleys...), easing back to
## flat near the world's border, and last what was sculpted by hand in the
## editor (TerrainSculpt). With neither, the land is flat at height 0. Designs
## add their own shapes on top, and the ground between them follows it, so
## hills run across sector borders without a step.

## Metres inside the grid's border over which landforms ease to flat.
static var border := 12.0


## Loads the layers that come from data: landforms and hand sculpting.
static func configure() -> void:
	Landforms.load_all()
	TerrainSculpt.load_all()


static func is_flat() -> bool:
	return Landforms.sets().is_empty() and TerrainSculpt.is_empty()


## The height of the land at a world x and z.
static func height(xz: Vector2) -> float:
	return base_height(xz) + TerrainSculpt.height(xz)


## The height of the land before anything sculpted by hand.
static func base_height(xz: Vector2) -> float:
	if Landforms.sets().is_empty():
		return 0.0
	var grid := Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y)
	var edge := smoothstep(0.0, border, _inside(grid, SectorMap.bounds()))
	return Landforms.shape_lakes(xz, Landforms.height(xz) * edge)


## Metres inside a rectangle's nearest side; negative outside it.
static func _inside(point: Vector2, area: Rect2) -> float:
	return minf(minf(point.x - area.position.x, point.y - area.position.y), minf(area.end.x - point.x, area.end.y - point.y))
