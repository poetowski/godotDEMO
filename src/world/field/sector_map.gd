@tool
class_name SectorMap
extends RefCounted
## The world's sector grid: square sectors named by column letter and row
## number within their region (RegionMap). A1 is the south-west corner sector
## of a region; R1's A1 is the world's south-west corner. Letters grow to
## the east (+X) and numbers to the north (-Z), the way the player faces at
## the start.
##
## Cells are world cell coordinates: (0, 0) is R1's A1, and they run across
## every region. In a one-region world names are plain ("C4"); with several
## regions they carry the region ("R45:C4"). A name without a region means R1.

const SIZE := 10.0
## Sectors along each side of a region.
const COLUMNS := 20
const ROWS := 20
## The south-west corner of R1's A1.
const ORIGIN := Vector3.ZERO
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const NONE := Vector2i(-1, -1)
## Where a player starting in a sector stands, from its centre: to the south,
## so the sector's painted name lies just ahead.
const START_OFFSET := Vector3(0.0, 0.0, 2.5)


## The sector containing a point, or NONE outside the world.
static func cell_at(point: Vector3) -> Vector2i:
	var cell := Vector2i(floori((point.x - ORIGIN.x) / SIZE), floori((ORIGIN.z - point.z) / SIZE))
	return cell if is_valid(cell) else NONE


## The cell under a ground point given as world x and z, even outside the
## world, where `is_valid` is false.
static func unbounded_cell_at(xz: Vector2) -> Vector2i:
	return Vector2i(floori((xz.x - ORIGIN.x) / SIZE), floori((ORIGIN.z - xz.y) / SIZE))


## "A1", "T20"... in a one-region world, "R45:J10" in a bigger one, or "" for
## a cell outside the world.
static func name_of(cell: Vector2i) -> String:
	if not is_valid(cell):
		return ""
	if RegionMap.count() == 1:
		return local_name(cell)
	return RegionMap.name_of(RegionMap.of_cell(cell)) + ":" + local_name(cell)


## A sector's name fit for a node (no ":"): "A1" in R1, "R45J10" elsewhere,
## or "" outside the world. R1's parts keep the names they had before the
## world had regions.
static func node_name(cell: Vector2i) -> String:
	if not is_valid(cell):
		return ""
	var region := RegionMap.of_cell(cell)
	return local_name(cell) if region == Vector2i.ZERO else RegionMap.name_of(region) + local_name(cell)


## The sector's name within its region, such as "J10".
static func local_name(cell: Vector2i) -> String:
	var local := Vector2i(posmod(cell.x, COLUMNS), posmod(cell.y, ROWS))
	return LETTERS[local.x] + str(local.y + 1)


## The cell for a name such as "c4" (in R1) or "R45:J10", or NONE if there is
## no such sector.
static func cell_named(sector_name: String) -> Vector2i:
	var text := sector_name.strip_edges().to_upper()
	var region := Vector2i.ZERO
	if ":" in text:
		region = RegionMap.named(text.get_slice(":", 0))
		if region == RegionMap.NONE:
			return NONE
		text = text.get_slice(":", 1)
	if text.length() < 2 or not text.substr(1).is_valid_int():
		return NONE
	var local := Vector2i(LETTERS.find(text[0]), text.substr(1).to_int() - 1)
	if local.x < 0 or local.x >= COLUMNS or local.y < 0 or local.y >= ROWS:
		return NONE
	var cell := RegionMap.first_cell(region) + local
	return cell if is_valid(cell) else NONE


## True for a cell inside the world (every region).
static func is_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < RegionMap.columns * COLUMNS and cell.y >= 0 and cell.y < RegionMap.rows * ROWS


## The sector's centre on the ground.
static func center_of(cell: Vector2i) -> Vector3:
	return ORIGIN + Vector3((cell.x + 0.5) * SIZE, 0.0, -(cell.y + 0.5) * SIZE)


## The world's size in metres: x to the east, y to the north.
static func extent() -> Vector2:
	return Vector2(RegionMap.columns * COLUMNS, RegionMap.rows * ROWS) * SIZE


## The sector's south-west corner on the ground.
static func corner_of(cell: Vector2i) -> Vector3:
	return ORIGIN + Vector3(cell.x * SIZE, 0.0, -cell.y * SIZE)


## Where a player starting in this sector stands.
static func start_of(cell: Vector2i) -> Vector3:
	return center_of(cell) + START_OFFSET
