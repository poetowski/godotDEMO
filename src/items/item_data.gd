class_name ItemData
extends Resource
## An item the player can carry: what it's called, what the inventory says
## about it, and the model shown in the world and when looking at it.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Short facts listed under the description, label to value.
@export var facts: Dictionary[String, String] = {}
## The item's look, with its base at the origin.
@export var model: PackedScene
## How many of this item share one inventory slot.
@export_range(1, 999) var stack_size: int = 1
