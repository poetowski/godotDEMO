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
##   amounts   how many of the item each slot holds
##   world     WorldState's record: {stable id: {"taken": true, ...}}
##   time      the world clock: {day, hour}
## Saves in older formats are upgraded on reading (SaveMigration).

const FORMAT := 3
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
	var version := int(data.get("version", 0))
	if version > FORMAT:
		push_warning("SaveGame: %s is from a newer version of the game (format %d, this one reads up to %d)" % [path_of(slot), version, FORMAT])
		return {}
	var upgraded := SaveMigration.upgrade(data)
	if upgraded.is_empty():
		push_warning("SaveGame: %s has format %s, which can't be upgraded" % [path_of(slot), data.get("version")])
	return upgraded


static func delete(slot: String) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_of(slot)))


## A line describing a slot for menus, such as "B1   2026-10-27 10:42   1 item".
static func describe(slot: String) -> String:
	if not exists(slot):
		return TranslationServer.translate("Empty")
	var data := read(slot)
	if data.is_empty():
		return TranslationServer.translate("Can't be loaded")
	var items := 0
	var amounts: Array = data.get("amounts", [])
	var inventory: Array = data.get("inventory", [])
	for index in inventory.size():
		if not (inventory[index] as String).is_empty():
			items += int(amounts[index]) if index < amounts.size() else 1
	var carried := TranslationServer.translate_plural("%d item", "%d items", items) % items
	return "%s   %s   %s" % [data.get("sector", "?"), data.get("saved_at", "?"), carried]


## The local date and time as saves record it.
static func now() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute]
