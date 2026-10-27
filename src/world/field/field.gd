extends Node3D
## The sector-grid field: grass everywhere, the grid of 10 m sectors with their
## light curtains and names, the sector designs under `Sectors` shaping the
## sectors they own and streamed in around the player by `Streamer`, and the
## player starting in A1 facing north. Pass
## `--sector=C4` after `--` on the command line to start in another sector.

var _sector := Vector2i(-2, -2)

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _terrain: FieldTerrain = $Terrain
@onready var _streamer: SectorStreamer = $Streamer


## A new field is a new game.
func _init() -> void:
	WorldState.reset()


func _ready() -> void:
	var start := SectorMap.cell_named(requested_sector(OS.get_cmdline_user_args()))
	if start == SectorMap.NONE:
		start = Vector2i.ZERO
	var point := SectorMap.start_of(start)
	var spot := _terrain.find_dry_spot(Vector2(point.x, point.z))
	_player.global_position = Vector3(spot.x, _terrain.height_at(spot) + 0.05, spot.y)
	_player.look_toward(_player.global_position + Vector3.FORWARD)
	_streamer.load_around_now()
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
