@tool
class_name PaintTile
extends Resource
## One saved tile of hand-painted ground: TerrainSculpt.TILE x TILE samples, row
## by row from the south-west, each holding TerrainPaint.LAYERS bytes, one share
## per surface.

@export var layers: PackedByteArray = PackedByteArray()
