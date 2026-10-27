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


const SWORD_SCENE := preload("res://src/items/sword/sword.tscn")


## A new field is a new game.
func _init() -> void:
	WorldState.reset()
	WorldShape.configure(0.0)


func _ready() -> void:
	var start := SectorMap.cell_named(requested_sector(OS.get_cmdline_user_args()))
	if start == SectorMap.NONE:
		start = Vector2i.ZERO
	var point := SectorMap.start_of(start)
	var spot := _terrain.find_dry_spot(Vector2(point.x, point.z))
	_player.global_position = Vector3(spot.x, _terrain.height_at(spot) + 0.05, spot.y)
	_player.look_toward(_player.global_position + Vector3.FORWARD)
	_streamer.load_around_now()
	_hud.save_requested.connect(save_to)
	_hud.load_requested.connect(load_from)
	_hud.track(_player)


func _process(_delta: float) -> void:
	var cell := SectorMap.cell_at(_player.global_position)
	if cell != _sector:
		_sector = cell
		_hud.show_sector(SectorMap.name_of(cell))


## Everything a save keeps, as plain data (see SaveGame).
func capture() -> Dictionary:
	var at := _player.global_position
	var sword := _player.sword()
	return {
		"version": SaveGame.FORMAT,
		"saved_at": SaveGame.now(),
		"sector": SectorMap.name_of(SectorMap.cell_at(at)),
		"player": {
			"position": [at.x, at.y, at.z],
			"yaw": _player.facing(),
			"sword": "" if sword == null else ("flame_katana" if sword is FlameKatana else "sword"),
		},
		"inventory": Array(_player.inventory.ids()),
		"taken": Array(WorldState.taken_ids()),
	}


func save_to(slot: String) -> Error:
	var error := SaveGame.write(slot, capture())
	_hud.notify(("Saved to %s" % _slot_name(slot)) if error == OK else ("Could not save: %s" % error_string(error)))
	return error


## Loads a slot; false, with a message, when there's nothing to load.
func load_from(slot: String) -> bool:
	var data := SaveGame.read(slot)
	if data.is_empty():
		_hud.notify("No save in %s" % _slot_name(slot))
		return false
	apply(data)
	_hud.close_menus()
	_hud.notify("Loaded %s" % _slot_name(slot))
	return true


## Puts the world and the player back as a save describes them, then reloads
## the sectors around the player so taken things stay gone and the rest
## come back.
func apply(data: Dictionary) -> void:
	WorldState.restore(data.get("taken", []))
	var inventory: Array = data.get("inventory", [])
	_player.inventory.clear()
	for slot in mini(inventory.size(), _player.inventory.capacity()):
		var id: String = inventory[slot]
		if not id.is_empty():
			_player.inventory.put(slot, ItemCatalog.find(StringName(id)))
	var player: Dictionary = data.get("player", {})
	_player.unequip_sword()
	match String(player.get("sword", "")):
		"flame_katana":
			_player.equip_sword(FlameKatana.new())
		"sword":
			_player.equip_sword(SWORD_SCENE.instantiate() as Node3D)
	var at: Array = player.get("position", [0.0, 0.0, 0.0])
	_player.global_position = Vector3(at[0], at[1], at[2])
	_player.velocity = Vector3.ZERO
	_player.face(float(player.get("yaw", 0.0)))
	_streamer.unload_all()
	_streamer.load_around_now()


func _slot_name(slot: String) -> String:
	return "quicksave" if slot == SaveGame.QUICK else "slot " + slot


## The sector named by a `--sector=` argument, or "A1".
static func requested_sector(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--sector="):
			return arg.trim_prefix("--sector=")
	return "A1"
