class_name DialogueRules
extends RefCounted
## The small language dialogue data uses for conditions and actions.
##
## Conditions, joined by "&" (all must hold); empty always holds:
##   quest:<id>:none|active|done   where the player stands with a quest
##   has:<item>                    carries the item;  !has:<item>  doesn't
## Actions, joined by ";":
##   start:<quest>      take the quest on
##   complete:<quest>   finish it
##   take:<item>        the speaker takes one of the item from the player
##   give:<item>        the speaker gives one


## Whether a condition holds now.
static func holds(condition: String, inventory: Inventory) -> bool:
	for part in condition.split("&", false):
		if not _holds_one(part.strip_edges(), inventory):
			return false
	return true


## Carries out actions; returns the messages to show the player.
static func run(actions: String, inventory: Inventory) -> PackedStringArray:
	var messages := PackedStringArray()
	for part in actions.split(";", false):
		var action := part.strip_edges()
		var verb := action.get_slice(":", 0)
		var what := StringName(action.get_slice(":", 1))
		match verb:
			"start":
				if QuestLog.start(what):
					messages.append(TranslationServer.translate("New quest: %s") % TranslationServer.translate(QuestLog.find(what).title))
			"complete":
				if QuestLog.complete(what):
					messages.append(TranslationServer.translate("Quest complete: %s") % TranslationServer.translate(QuestLog.find(what).title))
			"take":
				if inventory and inventory.take(what):
					messages.append(TranslationServer.translate("Gave away: %s") % TranslationServer.translate(ItemCatalog.find(what).display_name))
			"give":
				var item := ItemCatalog.find(what)
				if inventory and item and inventory.add(item):
					messages.append(TranslationServer.translate("Received: %s") % TranslationServer.translate(item.display_name))
			_:
				push_warning("DialogueRules: unknown action '%s'" % action)
	return messages


## True when every quest, item and verb a condition or action names exists;
## for tests of dialogue data.
static func is_valid(text: String, separator: String) -> bool:
	for part in text.split(separator, false):
		var words := part.strip_edges().trim_prefix("!").split(":")
		match words[0]:
			"quest":
				if words.size() != 3 or QuestLog.find(StringName(words[1])) == null or not words[2] in ["none", "active", "done"]:
					return false
			"has", "take", "give":
				if words.size() != 2 or ItemCatalog.find(StringName(words[1])) == null:
					return false
			"start", "complete":
				if words.size() != 2 or QuestLog.find(StringName(words[1])) == null:
					return false
			_:
				return false
	return true


static func _holds_one(part: String, inventory: Inventory) -> bool:
	var negated := part.begins_with("!")
	var words := part.trim_prefix("!").split(":")
	var result := false
	match words[0]:
		"quest":
			result = words.size() == 3 and String(QuestLog.state(StringName(words[1]))) == words[2]
		"has":
			result = inventory != null and words.size() == 2 and inventory.has(StringName(words[1]))
		_:
			push_warning("DialogueRules: unknown condition '%s'" % part)
	return result != negated
