@tool
class_name FieldWorld
extends RefCounted
## The field's size and the lay of its land, for the game and the editor alike.

## Regions east and north: R1 alone. `--regions=` makes more, for testing.
const REGIONS := 1
## Metres the land rises and falls at most.
const HILL_HEIGHT := 1.8
## How quickly the hills come and go: about one every 70 m.
const HILL_FREQUENCY := 0.014
## Metres inside the world's edge over which the land eases flat.
const BORDER := 12.0


static func configure(regions: int = REGIONS) -> void:
	RegionMap.configure(regions, regions)
	WorldShape.configure(HILL_HEIGHT, HILL_FREQUENCY, 3)
	WorldShape.border = BORDER
