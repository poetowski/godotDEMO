@tool
class_name FieldWorld
extends RefCounted
## The field's size and the lay of its land, for the game and the editor alike.

## Metres the land rises and falls at most.
const HILL_HEIGHT := 1.8
## How quickly the hills come and go: about one every 70 m.
const HILL_FREQUENCY := 0.014
## Metres inside the world's edge over which the land eases flat.
const BORDER := 12.0


## The starting zone, or for testing a square of `regions` regions.
static func configure(regions: int = 0) -> void:
	if regions > 0:
		RegionMap.configure(regions, regions)
	else:
		RegionMap.configure_starting_zone()
	WorldShape.configure(HILL_HEIGHT, HILL_FREQUENCY, 3)
	WorldShape.border = BORDER
	# R1's rim stays where the author carved against it.
	if regions <= 0:
		WorldShape.rim = Rect2(Vector2.ZERO, Vector2.ONE * RegionMap.SIZE)
	var bounds := SectorMap.bounds()
	var ground := FieldTerrain.ground_material()
	ground.set_shader_parameter(&"grid_origin", Vector2(bounds.position.x, -bounds.position.y))
	ground.set_shader_parameter(&"grid_sectors", bounds.size / SectorMap.SIZE)
	WaterField.load_all()
	TerrainPaint.load_all()
	TerrainPaint.publish()
