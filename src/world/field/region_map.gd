@tool
class_name RegionMap
extends RefCounted
## The world's regions: squares of 20 x 20 sectors (200 m). The game's world is
## the starting zone: R1 in the middle, at region (0, 0), and R2 to R9 clockwise
## around it from the north, so the regions around it have negative coordinates.
## A test world (`configure`) is `columns` east by `rows` north, numbered from the
## south-west, east along each row and then north. A sector anywhere is named
## with its region, such as "R4:J10" (SectorMap).

## Sectors along each side of a region.
const SECTORS := 20
## Metres along each side of a region: SECTORS sectors of SectorMap.SIZE.
const SIZE := 200.0
const NONE := Vector2i(-1048576, -1048576)
## Where R1 to R9 lie.
const STARTING_ZONE: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1),
	Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
]

## Regions east and north in the current world. Set by the world's root.
static var columns := 1
static var rows := 1
## The world's south-west region.
static var south_west := Vector2i.ZERO
## Where each region lies by its number, or empty when numbered by rows.
static var _layout: Array[Vector2i] = []


static func configure(east: int, north: int) -> void:
	columns = maxi(1, east)
	rows = maxi(1, north)
	south_west = Vector2i.ZERO
	_layout = []


static func configure_starting_zone() -> void:
	columns = 3
	rows = 3
	south_west = Vector2i(-1, -1)
	_layout = STARTING_ZONE


static func count() -> int:
	return columns * rows


static func is_valid(region: Vector2i) -> bool:
	var local := region - south_west
	return local.x >= 0 and local.x < columns and local.y >= 0 and local.y < rows


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
	if not _layout.is_empty():
		return "R%d" % (_layout.find(region) + 1)
	return "R%d" % (region.y * columns + region.x + 1)


## The region for a name such as "r45", or NONE.
static func named(region_name: String) -> Vector2i:
	var text := region_name.strip_edges().to_upper()
	if not text.begins_with("R") or not text.substr(1).is_valid_int():
		return NONE
	var index := text.substr(1).to_int() - 1
	if index < 0 or index >= count():
		return NONE
	if not _layout.is_empty():
		return _layout[index]
	return Vector2i(index % columns, index / columns)


## The region's south-west corner on the ground.
static func corner_of(region: Vector2i) -> Vector3:
	return SectorMap.corner_of(region * SECTORS)


static func center_of(region: Vector2i) -> Vector3:
	return corner_of(region) + Vector3(SIZE * 0.5, 0.0, -SIZE * 0.5)


## The first sector cell (A1) of a region.
static func first_cell(region: Vector2i) -> Vector2i:
	return region * SECTORS
