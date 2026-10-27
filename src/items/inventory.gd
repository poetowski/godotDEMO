class_name Inventory
extends RefCounted
## What the player carries: a grid of COLUMNS x ROWS slots, each empty or
## holding a stack of one kind of item, up to the item's `stack_size`. Items
## join the first stack of their kind with room, or fill the first empty slot.

signal changed

const COLUMNS := 4
const ROWS := 6

var _slots: Array[ItemData] = []
var _amounts := PackedInt32Array()


func _init() -> void:
	_slots.resize(capacity())
	_amounts.resize(capacity())


func capacity() -> int:
	return COLUMNS * ROWS


## The item in a slot (row by row from the top left), or null.
func item_at(slot: int) -> ItemData:
	return _slots[slot]


## How many of the item a slot holds; 0 when it's empty.
func amount_at(slot: int) -> int:
	return _amounts[slot]


## Whether the item would fit: a stack of its kind with room or an empty slot.
func can_add(item: ItemData) -> bool:
	return _slot_for(item) != -1


## Adds one of an item; false when it doesn't fit.
func add(item: ItemData) -> bool:
	var slot := _slot_for(item)
	if slot == -1:
		return false
	_slots[slot] = item
	_amounts[slot] += 1
	changed.emit()
	return true


## Puts a stack in a given slot, replacing what was there; null empties it.
func put(slot: int, item: ItemData, amount: int = 1) -> void:
	_slots[slot] = item
	_amounts[slot] = clampi(amount, 1, item.stack_size) if item else 0
	changed.emit()


func clear() -> void:
	_slots.fill(null)
	_amounts.fill(0)
	changed.emit()


## Each slot's item id, "" for an empty slot, for saving.
func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for item in _slots:
		result.append(String(item.id) if item else "")
	return result


## Each slot's amount, for saving.
func amounts() -> PackedInt32Array:
	return _amounts.duplicate()


## Takes the whole stack out of a slot and returns its item, or null if the
## slot was empty.
func remove_at(slot: int) -> ItemData:
	var item := _slots[slot]
	if item:
		_slots[slot] = null
		_amounts[slot] = 0
		changed.emit()
	return item


## How many slots are taken.
func count() -> int:
	return _slots.filter(func(item: ItemData) -> bool: return item != null).size()


## How many of an item the player carries, over all its stacks.
func total(id: StringName) -> int:
	var sum := 0
	for slot in _slots.size():
		if _slots[slot] and _slots[slot].id == id:
			sum += _amounts[slot]
	return sum


func is_full() -> bool:
	return count() == capacity()


func has(id: StringName) -> bool:
	return _slots.any(func(item: ItemData) -> bool: return item != null and item.id == id)


func _slot_for(item: ItemData) -> int:
	for slot in _slots.size():
		if _slots[slot] and _slots[slot].id == item.id and _amounts[slot] < item.stack_size:
			return slot
	return _slots.find(null)
