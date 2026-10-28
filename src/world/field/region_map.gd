@tool
class_name RegionMap
extends RefCounted
## The world's regions: squares of 20 x 20 sectors (200 m), numbered R1, R2,
## R3... from the south-west corner, east along the southern row, then on
## along the next row north, the way sectors grow. A world is `columns`
## regions east by `rows` north; the main field is one region (R1). A sector
## anywhere is named with its region, such as "R45:J10" (SectorMap).

## Sectors along each side of a region.
const SECTORS := 20
## Metres along each side of a region: SECTORS sectors of SectorMap.SIZE.
const SIZE := 200.0
const NONE := Vector2i(-1, -1)

## Regions east and north in the current world. Set by the world's root.
static var columns := 1
static var rows := 1


static func configure(east: int, north: int) -> void:
	columns = maxi(1, east)
	rows = maxi(1, north)


static func count() -> int:
	return columns * rows


static func is_valid(region: Vector2i) -> bool:
	return region.x >= 0 and region.x < columns and region.y >= 0 and region.y < rows


## The region holding a sector cell (world cell coordinates).
static func of_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(cell.x / float(SECTORS)), floori(cell.y / float(SECTORS)))


## The region under a point, or NONE outside the world.
static func at(point: Vector3) -> Vector2i:
	var region := of_cell(SectorMap.unbounded_cell_at(Vector2(point.x, point.z)))
	return region if is_valid(region) else NONE


## "R1", "R45"..., or "" outside the world.
static func name_of(region: Vector2i) -> String:
	if not is_valid(region):
		return ""
	return "R%d" % (region.y * columns + region.x + 1)


## The region for a name such as "r45", or NONE.
static func named(region_name: String) -> Vector2i:
	var text := region_name.strip_edges().to_upper()
	if not text.begins_with("R") or not text.substr(1).is_valid_int():
		return NONE
	var index := text.substr(1).to_int() - 1
	if index < 0 or index >= count():
		return NONE
	return Vector2i(index % columns, index / columns)


## The region's south-west corner on the ground.
static func corner_of(region: Vector2i) -> Vector3:
	return SectorMap.corner_of(region * SECTORS)


static func center_of(region: Vector2i) -> Vector3:
	return corner_of(region) + Vector3(SIZE * 0.5, 0.0, -SIZE * 0.5)


## The first sector cell (A1) of a region.
static func first_cell(region: Vector2i) -> Vector2i:
	return region * SECTORS
