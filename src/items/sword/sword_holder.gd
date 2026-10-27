class_name SwordHolder
extends Interactable
## Something that holds a sword for the player to take: a sword in a stone, a
## chest with a blade on it. Hands the sword over through take_sword().

## What the prompt calls the blade: "[E]  Take <item_name>".
@export var item_name: String = "the sword"


func has_sword() -> bool:
	return false


## Detaches the sword and returns it, or null once it has been taken.
func take_sword() -> Node3D:
	return null


func can_interact(player: Player) -> bool:
	return has_sword() and not player.has_sword


func prompt() -> String:
	return "[E]  Take %s" % item_name


func interact(player: Player) -> void:
	var sword := take_sword()
	if sword:
		player.equip_sword(sword)
