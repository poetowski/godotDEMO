@tool
class_name ZoneBorder
extends RefCounted
## A border the player may not cross, for the world's edge or between zones. In
## the band between its two lines the player is warned; past the far line they
## are returned to the spawn point. Field applies it and SectorGrid draws it in
## red. See "Borders" in docs/world/README.md.

## Sector M of the western regions (R7, R8, R9): the player comes from the east.
const WEST_WARN_X := -70.0
const WEST_RETURN_X := -80.0


## True in a world with regions to the west, not in test worlds.
static func applies() -> bool:
	return RegionMap.south_west.x < 0
