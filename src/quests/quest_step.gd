@tool
class_name QuestStep
extends Resource
## One step of a quest, shown in the quest log. A step that names an `item`
## is done while the player carries `amount` of it; a step without one is
## done when the quest is (such as handing something over).

## What to do, in English.
@export_multiline var text: String = ""
## An item to carry, by id; empty for none.
@export var item: StringName = &""
@export var amount: int = 1
