class_name SectorGround
extends Resource
## A design's ground heights, water levels and water flow, baked so the field
## can answer questions about sectors whose content isn't loaded. Grids are
## SectorDesign.SAMPLES square per cell, row by row from the south-west.

@export var heights: Dictionary[Vector2i, PackedFloat32Array] = {}
@export var water: Dictionary[Vector2i, PackedFloat32Array] = {}
@export var flows: Dictionary[Vector2i, PackedVector2Array] = {}
