@tool
class_name DialogueChoice
extends Resource
## One answer the player can give in a dialogue entry.

## What the player says, in English.
@export var text: String = ""
## Shown only when this holds (DialogueRules); empty for always.
@export var when: String = ""
## What happens when chosen (DialogueRules actions, joined by ";").
@export var then: String = ""
## The entry to go on to; empty ends the conversation.
@export var goto: StringName = &""
