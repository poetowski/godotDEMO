@tool
class_name QuestData
extends Resource
## A quest, kept as data in data/quests/: its title, who gives it, what it's
## about and its steps. Dialogue starts and completes it (DialogueRules);
## QuestLog remembers where the player stands with it.

## Names it in saves and dialogue for good: lowercase, never changed once
## shipped.
@export var id: StringName = &""
@export var title: String = ""
## Who gives it, as the player knows them.
@export var giver: String = ""
@export_multiline var description: String = ""
@export var steps: Array[QuestStep] = []
