class_name SaveMigration
extends RefCounted
## Upgrades saves written in older formats, one step at a time, so a save
## from any earlier version of the game still loads. Each step takes a save
## in format N and returns it in format N + 1; `upgrade` chains them.
##
## When the save format changes: bump SaveGame.FORMAT, add a `_from_<N>`
## step and its line in `upgrade`, and add tests/fixtures/saves/format_<N>.json
## written by the old version. Never edit an old fixture or an old step.


## The save in the current format, or an empty Dictionary when it can't be
## upgraded (not a save, or from a newer version of the game).
static func upgrade(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	var version := int(result.get("version", 0))
	while version != SaveGame.FORMAT:
		match version:
			1:
				result = _from_1(result)
			2:
				result = _from_2(result)
			3:
				result = _from_3(result)
			_:
				return {}
		version = int(result.get("version", 0))
	return result


## Format 1 (2026-10-27) to 2: world-state ids named nodes ("B1Cornflower/
## Cornflower") and became stable design ids ("b1_cornflower/cornflower");
## the list of taken ids became a record per object; inventory slots gained
## amounts. Mushrooms in the stress woods were ids by placing order, which
## can't be matched to a place, so they grow back.
static func _from_1(data: Dictionary) -> Dictionary:
	const RENAMED := {
		"B1Cornflower/Cornflower": "b1_cornflower/cornflower",
		"C2ArcherTower/Chest": "c2_archer_tower/sword_chest",
	}
	var world := {}
	for id: String in data.get("taken", []):
		if RENAMED.has(id):
			world[RENAMED[id]] = {"taken": true}
		elif not id.begins_with("Stress"):
			world[id] = {"taken": true}
	data.erase("taken")
	data["world"] = world
	if not data.has("amounts"):
		var amounts: Array = []
		for id: String in data.get("inventory", []):
			amounts.append(0 if id.is_empty() else 1)
		data["amounts"] = amounts
	data["version"] = 2
	return data


## Format 2 to 3 (2026-10-28): saves gained the time of day. Older games
## carry on from the clock's starting time on day 1.
static func _from_2(data: Dictionary) -> Dictionary:
	data["time"] = {"day": 1, "hour": 8.0}
	data["version"] = 3
	return data


## Format 3 to 4 (2026-10-29): saves gained the quest log. Older games had
## no quests.
static func _from_3(data: Dictionary) -> Dictionary:
	data["quests"] = {}
	data["version"] = 4
	return data
