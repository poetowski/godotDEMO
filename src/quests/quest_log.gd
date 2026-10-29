class_name QuestLog
extends RefCounted
## The quests of this game: which the player has taken on and which are
## done, by quest id, and every quest in data/quests by id. Saves carry it
## (`snapshot`, `restore`); a new field starts a new game and clears it.
## Read `revision` to notice changes.

const FOLDER := "res://data/quests"
const NONE := &"none"
const ACTIVE := &"active"
const DONE := &"done"

## Goes up by one with every change.
static var revision := 0
## quest id -> ACTIVE or DONE, in the order they were taken on.
static var _states: Dictionary[StringName, StringName] = {}
static var _quests: Dictionary[StringName, QuestData] = {}


static func reset() -> void:
	_states.clear()
	revision += 1


## The quest with this id, or null.
static func find(id: StringName) -> QuestData:
	if _quests.is_empty():
		for file in ResourceLoader.list_directory(FOLDER):
			var quest := load(FOLDER.path_join(file)) as QuestData
			if quest:
				_quests[quest.id] = quest
	return _quests.get(id)


## NONE, ACTIVE or DONE.
static func state(id: StringName) -> StringName:
	return _states.get(id, NONE)


## Takes a quest on; false if it's unknown or already taken.
static func start(id: StringName) -> bool:
	if find(id) == null or state(id) != NONE:
		return false
	_states[id] = ACTIVE
	revision += 1
	return true


## Finishes a quest the player has taken on; false otherwise.
static func complete(id: StringName) -> bool:
	if state(id) != ACTIVE:
		return false
	_states[id] = DONE
	revision += 1
	return true


## The quests taken on, in that order, that are in this state.
static func quests_in(wanted: StringName) -> Array[QuestData]:
	var found: Array[QuestData] = []
	for id: StringName in _states:
		if _states[id] == wanted and find(id):
			found.append(find(id))
	return found


## Whether a step is done, given what the player carries.
static func is_step_done(quest: QuestData, step: QuestStep, inventory: Inventory) -> bool:
	if state(quest.id) == DONE:
		return true
	if step.item.is_empty():
		return false
	return inventory != null and inventory.total(step.item) >= step.amount


## Everything recorded, as plain data for saving.
static func snapshot() -> Dictionary:
	var result := {}
	for id: StringName in _states:
		result[String(id)] = String(_states[id])
	return result


## Replaces the record with a saved one; unknown quests are dropped.
static func restore(saved: Dictionary) -> void:
	_states.clear()
	for id: String in saved:
		var value := StringName(str(saved[id]))
		if find(StringName(id)) and value in [ACTIVE, DONE]:
			_states[StringName(id)] = value
	revision += 1
