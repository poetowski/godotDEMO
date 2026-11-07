@tool
class_name FieldWorld
extends RefCounted
## The field's size and the lay of its land, for the game and the editor alike:
## one region, R1, of 20 x 20 sectors, flat until regions or sectors are
## designed or the author sculpts it. Flat grass runs on past its edge
## (FieldTerrain's margin).


## R1 alone, or for testing a square of `regions` regions.
static func configure(regions: int = 0) -> void:
	RegionMap.configure(maxi(regions, 1), maxi(regions, 1))
	WorldShape.configure()
	var bounds := SectorMap.bounds()
	var ground := FieldTerrain.ground_material()
	ground.set_shader_parameter(&"grid_origin", Vector2(bounds.position.x, -bounds.position.y))
	ground.set_shader_parameter(&"grid_sectors", bounds.size / SectorMap.SIZE)
	WaterField.load_all()
	TerrainPaint.load_all()
	TerrainPaint.publish()
