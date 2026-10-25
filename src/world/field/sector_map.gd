@tool
class_name SectorMap
extends RefCounted
## The world's sector grid: square sectors named by column letter and row
## number. A1 is the south-west corner sector, where the player starts. Letters
## grow to the east (+X) and numbers to the north (-Z), the way the player
## faces at the start.

const SIZE := 10.0
const COLUMNS := 20
const ROWS := 20
## The south-west corner of A1.
const ORIGIN := Vector3.ZERO
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const NONE := Vector2i(-1, -1)


## The sector containing a point, or NONE outside the grid.
static func cell_at(point: Vector3) -> Vector2i:
	var cell := Vector2i(floori((point.x - ORIGIN.x) / SIZE), floori((ORIGIN.z - point.z) / SIZE))
	return cell if is_valid(cell) else NONE


## "A1", "T20"..., or "" for a cell outside the grid.
static func name_of(cell: Vector2i) -> String:
	if not is_valid(cell):
		return ""
	return LETTERS[cell.x] + str(cell.y + 1)


## The cell for a name such as "c4", or NONE if there is no such sector.
static func cell_named(sector_name: String) -> Vector2i:
	var text := sector_name.strip_edges().to_upper()
	if text.length() < 2 or not text.substr(1).is_valid_int():
		return NONE
	var cell := Vector2i(LETTERS.find(text[0]), text.substr(1).to_int() - 1)
	return cell if is_valid(cell) else NONE


static func is_valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS


## The sector's centre on the ground.
static func center_of(cell: Vector2i) -> Vector3:
	return ORIGIN + Vector3((cell.x + 0.5) * SIZE, 0.0, -(cell.y + 0.5) * SIZE)


## The grid's size in metres: x to the east, y to the north.
static func extent() -> Vector2:
	return Vector2(COLUMNS, ROWS) * SIZE
