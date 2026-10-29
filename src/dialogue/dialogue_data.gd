@tool
class_name DialogueData
extends Resource
## What someone can say, kept as data in data/dialogue/: entries of lines
## and answers, opened by the first opening entry whose condition holds, so
## the conversation follows the game (a quest taken on, an item carried).

## Who speaks, as the player knows them.
@export var speaker: String = ""
@export var entries: Array[DialogueEntry] = []


## Where a conversation starts now, or null when nothing applies.
func opening(inventory: Inventory) -> DialogueEntry:
	for entry in entries:
		if entry.opening and DialogueRules.holds(entry.when, inventory):
			return entry
	return null


func entry(id: StringName) -> DialogueEntry:
	for found in entries:
		if found.id == id:
			return found
	return null


## The answers to an entry the player can give now.
func choices_of(at: DialogueEntry, inventory: Inventory) -> Array[DialogueChoice]:
	var found: Array[DialogueChoice] = []
	for choice in at.choices:
		if DialogueRules.holds(choice.when, inventory):
			found.append(choice)
	return found
