class_name WorldState
extends RefCounted
## What the player has changed in the world during this game, kept per
## object by stable id (see SectorDesign.content_id and scatter_id), so
## streamed content comes back the way the player left it and saves carry it.
## Each object has a small Dictionary of plain values, such as
## {"taken": true}. A new field starts a new game and clears it.

static var _objects: Dictionary[String, Dictionary] = {}


static func reset() -> void:
	_objects.clear()


## A value recorded for an object, or `default` when there is none.
static func value(id: String, key: String, default: Variant = null) -> Variant:
	return _objects[id].get(key, default) if _objects.has(id) else default


## Records a plain value (bool, number, string, array or dictionary of
## those) for an object.
static func set_value(id: String, key: String, to: Variant) -> void:
	if not _objects.has(id):
		_objects[id] = {}
	_objects[id][key] = to


## Records that the thing with this id was taken from the world.
static func mark_taken(id: String) -> void:
	set_value(id, "taken", true)


static func is_taken(id: String) -> bool:
	return value(id, "taken", false) == true


static func ids() -> PackedStringArray:
	return PackedStringArray(_objects.keys())


## Everything recorded, as plain data for saving.
static func snapshot() -> Dictionary:
	var result := {}
	for id: String in _objects:
		result[id] = _objects[id].duplicate(true)
	return result


## Replaces the record with a saved one.
static func restore(objects: Dictionary) -> void:
	_objects.clear()
	for id: String in objects:
		if objects[id] is Dictionary:
			_objects[id] = (objects[id] as Dictionary).duplicate(true)
