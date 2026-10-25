extends Node3D
## The sector-grid field: flat grass everywhere, the grid of 10 m sectors with
## their light curtains and names, and the player starting in A1 facing north.
## Pass `--sector=C4` after `--` on the command line to start in another sector.

## Where the player stands in the starting sector: south of its centre, so
## the sector's name is painted just ahead.
const START_OFFSET := Vector3(0.0, 0.0, 2.5)

var _sector := Vector2i(-2, -2)

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud


func _ready() -> void:
	var start := SectorMap.cell_named(requested_sector(OS.get_cmdline_user_args()))
	if start == SectorMap.NONE:
		start = Vector2i.ZERO
	_player.global_position = SectorMap.center_of(start) + START_OFFSET
	_player.look_toward(_player.global_position + Vector3.FORWARD)
	_hud.track(_player)


func _process(_delta: float) -> void:
	var cell := SectorMap.cell_at(_player.global_position)
	if cell != _sector:
		_sector = cell
		_hud.show_sector(SectorMap.name_of(cell))


## The sector named by a `--sector=` argument, or "A1".
static func requested_sector(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--sector="):
			return arg.trim_prefix("--sector=")
	return "A1"
