@tool
class_name RegionWater
extends Resource
## Water poured into the land as it lies, in data/world/water/: a lake and the
## rivers running into and out of it. It doesn't change the ground; WaterField
## fills whatever lies below the surface, so it follows the land when that's
## sculpted again.

## What this water is for, in a sentence.
@export var brief: String = ""
## A point in the lake (x east, y north), and its surface's height (absolute).
## A lake_level of -INF means no lake.
@export var lake_seed: Vector2 = Vector2.ZERO
@export var lake_level: float = -INF
@export var courses: Array[WaterCourse] = []
