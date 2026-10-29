@tool
class_name DialogueEntry
extends Resource
## One thing someone says in a dialogue, with the player's answers.

@export var id: StringName = &""
## An entry a conversation can open with: the first opening whose `when`
## holds is where talking starts.
@export var opening: bool = false
## For openings: when it applies (DialogueRules); empty for always.
@export var when: String = ""
## What they say, in English.
@export_multiline var line: String = ""
@export var choices: Array[DialogueChoice] = []
