@tool
class_name LandformSet
extends Resource
## One region design: the landforms shaping some regions, made by
## /region-design and kept in data/world/landforms/. `regions` names the
## regions it may touch; a test holds every landform inside them.

## Names the set, such as "r2_mountain".
@export var id: String = ""
## The regions it shapes, such as ["R2"] or ["R12", "R13"].
@export var regions: PackedStringArray = PackedStringArray()
## The brief it was made from, in the author's words.
@export_multiline var brief: String = ""
@export var landforms: Array[Landform] = []


## True when every region it names is in the current world.
func fits_world() -> bool:
	for region_name in regions:
		if RegionMap.named(region_name) == RegionMap.NONE:
			return false
	return not regions.is_empty()


## The area of its regions, x east and y north, in metres.
func area() -> Rect2:
	var box := Rect2()
	for k in regions.size():
		var corner := RegionMap.corner_of(RegionMap.named(regions[k]))
		var region := Rect2(Vector2(corner.x, -corner.z), Vector2.ONE * RegionMap.SIZE)
		box = region if k == 0 else box.merge(region)
	return box
