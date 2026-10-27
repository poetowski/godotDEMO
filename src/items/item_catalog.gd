class_name ItemCatalog
extends RefCounted
## Every item in data/items, found by id, so saves can store ids and get the
## items back.

const FOLDER := "res://data/items"

static var _items: Dictionary[StringName, ItemData] = {}


## The item with this id, or null.
static func find(id: StringName) -> ItemData:
	if _items.is_empty():
		for file in ResourceLoader.list_directory(FOLDER):
			var item := load(FOLDER.path_join(file)) as ItemData
			if item:
				_items[item.id] = item
	return _items.get(id)
