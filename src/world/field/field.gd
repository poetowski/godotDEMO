extends Node3D
## The sector-grid field: grass everywhere, the grid of 10 m sectors with their
## light curtains and names, the sector designs under `Sectors` shaping the
## sectors they own and streamed in around the player by `Streamer`, and the
## player starting in A1 facing north, and the time of day (Clock, with
## DayNight lighting the world by it), and the villagers living in it
## (`Residents`, none yet). Pass `--sector=C4` after `--` on the
## command line to start in another sector, `--hour=21.5` to start at
## another time. Sector M of the regions to the west (R7, R8, R9) is the limit of
## where the player may go: walking in gives a warning, and walking on past it
## takes them back to the spawn point.

## World x of column M's eastern and western edges in the western regions.
const LIMIT_WARN_X := -70.0
const LIMIT_RETURN_X := -80.0

## The sector the player starts in unless `--sector=` names another.
var start_sector: String = "A1"

var _sector := Vector2i(-2, -2)
var _spawn := Vector2i.ZERO
var _warned := false

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _terrain: FieldTerrain = $Terrain
@onready var _streamer: SectorStreamer = $Streamer
@onready var _clock: WorldClock = $Clock


## A new field is a new game.
func _init() -> void:
	WorldState.reset()
	QuestLog.reset()
	# `--regions=20` after `--` makes 4 km, for testing.
	var regions := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--regions="):
			regions = clampi(arg.trim_prefix("--regions=").to_int(), 1, 50)
	FieldWorld.configure(regions)


func _ready() -> void:
	var start := SectorMap.cell_named(requested_sector(OS.get_cmdline_user_args(), start_sector))
	if start == SectorMap.NONE:
		start = Vector2i.ZERO
	_spawn = start
	teleport(start)
	var hour := requested_hour(OS.get_cmdline_user_args())
	if hour >= 0.0:
		_clock.hour = hour
	_hud.save_requested.connect(save_to)
	_hud.load_requested.connect(load_from)
	_hud.track(_player)
	_wake_residents()


## The villagers living in the field (under `Residents`): they follow their
## programs on the field's clock and show near the player.
func _wake_residents() -> void:
	var residents := get_node_or_null("Residents")
	if residents == null:
		return
	for node in residents.get_children():
		var villager := node as Villager
		if villager == null:
			continue
		villager.clock = _clock
		villager.terrain = _terrain
		villager.viewer = _player
		villager.add_to_group(&"villagers")


func _process(_delta: float) -> void:
	var cell := SectorMap.cell_at(_player.global_position)
	if cell != _sector:
		_sector = cell
		_hud.show_sector(SectorMap.name_of(cell))
	_hud.show_clock(_clock.text())
	_keep_to_the_limit()


## The warning, and the way back to the spawn point. Only where there are regions
## to the west of R1, not in test worlds.
func _keep_to_the_limit() -> void:
	if RegionMap.south_west.x >= 0:
		return
	var x := _player.global_position.x
	if x < LIMIT_RETURN_X:
		teleport(_spawn)
		_warned = false
	elif x < LIMIT_WARN_X:
		if not _warned:
			_warned = true
			_hud.notify(tr("I should not be here..."))
	else:
		_warned = false


func clock() -> WorldClock:
	return _clock


func player() -> Player:
	return _player


func streamer() -> SectorStreamer:
	return _streamer


func terrain() -> FieldTerrain:
	return _terrain


## Puts the player on dry ground in a sector, facing north, and loads the
## sectors around it.
func teleport(cell: Vector2i) -> void:
	var point := SectorMap.start_of(cell)
	var spot := _terrain.find_dry_spot(Vector2(point.x, point.z))
	_player.global_position = Vector3(spot.x, _terrain.height_at(spot) + 0.05, spot.y)
	_player.velocity = Vector3.ZERO
	_player.face(0.0)
	_terrain.prepare_around_focus()
	_streamer.load_around_now()


## Everything a save keeps, as plain data (see SaveGame).
func capture() -> Dictionary:
	var at := _player.global_position
	return {
		"version": SaveGame.FORMAT,
		"saved_at": SaveGame.now(),
		"sector": SectorMap.name_of(SectorMap.cell_at(at)),
		"player": {
			"position": [at.x, at.y, at.z],
			"yaw": _player.facing(),
			# No swords exist right now; a save's field stays for when they do.
			"sword": "",
		},
		"inventory": Array(_player.inventory.ids()),
		"amounts": Array(_player.inventory.amounts()),
		"world": WorldState.snapshot(),
		"quests": QuestLog.snapshot(),
		"time": {"day": _clock.day, "hour": _clock.hour},
	}


func save_to(slot: String) -> Error:
	var error := SaveGame.write(slot, capture())
	_hud.notify((tr("Saved to %s") % _slot_name(slot)) if error == OK else (tr("Could not save: %s") % error_string(error)))
	return error


## Loads a slot; false, with a message, when there's nothing to load.
func load_from(slot: String) -> bool:
	var data := SaveGame.read(slot)
	if data.is_empty():
		_hud.notify(tr("Nothing to load in %s") % _slot_name(slot))
		return false
	apply(data)
	_hud.close_menus()
	_hud.notify(tr("Loaded %s") % _slot_name(slot))
	return true


## Puts the world and the player back as a save describes them, then reloads
## the sectors around the player so taken things stay gone and the rest
## come back.
func apply(data: Dictionary) -> void:
	WorldState.restore(data.get("world", {}))
	QuestLog.restore(data.get("quests", {}))
	var time: Dictionary = data.get("time", {})
	_clock.day = int(time.get("day", 1))
	_clock.hour = float(time.get("hour", _clock.start_hour))
	var inventory: Array = data.get("inventory", [])
	var amounts: Array = data.get("amounts", [])
	_player.inventory.clear()
	for slot in mini(inventory.size(), _player.inventory.capacity()):
		var id: String = inventory[slot]
		if not id.is_empty():
			var item := ItemCatalog.find(StringName(id))
			# An old save can hold items that no longer exist.
			if item:
				_player.inventory.put(slot, item, int(amounts[slot]) if slot < amounts.size() else 1)
	var player: Dictionary = data.get("player", {})
	_player.unequip_sword()
	var at: Array = player.get("position", [0.0, 0.0, 0.0])
	_player.global_position = Vector3(at[0], at[1], at[2])
	_player.velocity = Vector3.ZERO
	_player.face(float(player.get("yaw", 0.0)))
	_terrain.prepare_around_focus()
	_streamer.unload_all()
	_streamer.load_around_now()


func _slot_name(slot: String) -> String:
	return tr("quicksave") if slot == SaveGame.QUICK else tr("slot %s") % slot


## The hour given by an `--hour=` argument, or -1.
static func requested_hour(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--hour="):
			return clampf(arg.trim_prefix("--hour=").to_float(), 0.0, 23.99)
	return -1.0


## The sector named by a `--sector=` argument, or `fallback`.
static func requested_sector(args: PackedStringArray, fallback: String = "A1") -> String:
	for arg in args:
		if arg.begins_with("--sector="):
			return arg.trim_prefix("--sector=")
	return fallback
