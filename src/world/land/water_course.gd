@tool
class_name WaterCourse
extends Resource
## A river poured along ground already carved for it (see RegionWater): where
## its middle runs, downstream, and how high its surface stands there. Metres,
## x east and y north. The levels must not rise downstream.

## The middle of the river, from its source downstream.
@export var points: PackedVector2Array = PackedVector2Array()
## The surface's height (absolute) at each point.
@export var levels: PackedFloat32Array = PackedFloat32Array()
## Metres a second, at most NatureKit.WATER_MAX_FLOW.
@export var speed: float = 0.5
## Metres at each end over which the flow eases from or to still water, where
## it leaves or joins a lake.
@export var ease_in: float = 0.0
@export var ease_out: float = 0.0
## Metres of water at most under this river's surface; 0 for no limit. Rapids
## running down a slope set it, so their sloping surface stops where the ground
## falls away instead of hanging in the air.
@export var max_depth: float = 0.0
