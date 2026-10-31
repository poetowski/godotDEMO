@tool
class_name SculptTile
extends Resource
## One saved tile of hand-sculpted ground: TerrainSculpt.TILE x TILE metres
## added to the land, row by row from the south-west, one sample a metre.

@export var heights: PackedFloat32Array = PackedFloat32Array()
