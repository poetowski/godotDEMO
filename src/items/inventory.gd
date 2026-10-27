class_name Inventory
extends RefCounted
## What the player carries: a grid of COLUMNS x ROWS slots, each empty or
## holding one item. Items fill the first empty slot.

signal changed

const COLUMNS := 4
const ROWS := 6

var _slots: Array[ItemData] = []


func _init() -> void:
	_slots.resize(capacity())


func capacity() -> int:
	return COLUMNS * ROWS


## The item in a slot (row by row from the top left), or null.
func item_at(slot: int) -> ItemData:
	return _slots[slot]


## Puts an item in the first empty slot; false when every slot is taken.
func add(item: ItemData) -> bool:
	var slot := _slots.find(null)
	if slot == -1:
		return false
	_slots[slot] = item
	changed.emit()
	return true


## Puts an item in a given slot, replacing what was there; null empties it.
func put(slot: int, item: ItemData) -> void:
	_slots[slot] = item
	changed.emit()


func clear() -> void:
	_slots.fill(null)
	changed.emit()


## Each slot's item id, "" for an empty slot, for saving.
func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for item in _slots:
		result.append(String(item.id) if item else "")
	return result


## Takes the item out of a slot and returns it, or null if it was empty.
func remove_at(slot: int) -> ItemData:
	var item := _slots[slot]
	if item:
		_slots[slot] = null
		changed.emit()
	return item


func count() -> int:
	return _slots.filter(func(item: ItemData) -> bool: return item != null).size()


func is_full() -> bool:
	return count() == capacity()


func has(id: StringName) -> bool:
	return _slots.any(func(item: ItemData) -> bool: return item != null and item.id == id)
