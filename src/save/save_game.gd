class_name SaveGame
extends RefCounted
## Save files: one JSON file per slot in user://saves, holding plain data
## only (never Resources, which could run code when loaded). A save is a
## Dictionary:
##   version   format number, FORMAT
##   saved_at  local date and time, "2026-10-27 10:42"
##   sector    the sector the player stood in, "B1"
##   player    {position: [x, y, z], yaw, sword: "" | "sword" | "flame_katana"}
##   inventory item ids by slot ("" for an empty slot)
##   taken     WorldState ids of things taken from the world

const FORMAT := 1
const QUICK := "quick"
## The slots the menu offers, in order.
const SLOTS: Array[String] = [QUICK, "1", "2", "3"]

## Where saves live; tests point it elsewhere.
static var folder := "user://saves"


static func path_of(slot: String) -> String:
	return folder.path_join("slot_%s.json" % slot)


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(path_of(slot))


static func write(slot: String, data: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file := FileAccess.open(path_of(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return OK


## The save in a slot, or an empty Dictionary when there is none or it can't
## be read.
static func read(slot: String) -> Dictionary:
	if not exists(slot):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_of(slot)))
	if not parsed is Dictionary:
		push_warning("SaveGame: %s is not a save" % path_of(slot))
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != FORMAT:
		push_warning("SaveGame: %s has format %s, expected %d" % [path_of(slot), data.get("version"), FORMAT])
		return {}
	return data


static func delete(slot: String) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_of(slot)))


## A line describing a slot for menus, such as "B1   2026-10-27 10:42   1 item".
static func describe(slot: String) -> String:
	var data := read(slot)
	if data.is_empty():
		return "Empty"
	var items := 0
	for id: String in data.get("inventory", []):
		items += 0 if id.is_empty() else 1
	return "%s   %s   %d item%s" % [data.get("sector", "?"), data.get("saved_at", "?"), items, "" if items == 1 else "s"]


## The local date and time as saves record it.
static func now() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute]
