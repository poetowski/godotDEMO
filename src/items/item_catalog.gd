class_name ItemCatalog
extends RefCounted
## Every item in data/items, found by id, so saves can store ids and get the
## items back.

## Where items are read from. Tests point it at their own.
static var folder := "res://data/items"
static var _items: Dictionary[StringName, ItemData] = {}


## The item with this id, or null.
static func find(id: StringName) -> ItemData:
	_collect()
	return _items.get(id)


## Every item's id, sorted.
static func ids() -> Array[StringName]:
	_collect()
	var found: Array[StringName] = []
	found.assign(_items.keys())
	found.sort()
	return found


static func _collect() -> void:
	if _items.is_empty():
		if not DirAccess.dir_exists_absolute(folder):
			return
		for file in ResourceLoader.list_directory(folder):
			var item := load(folder.path_join(file)) as ItemData
			if item:
				_items[item.id] = item
