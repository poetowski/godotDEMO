class_name SwordHolder
extends Interactable
## Something that holds a sword for the player to take: a sword in a stone, a
## chest with a blade on it. Hands the sword over through take_sword().

## What the prompt calls the blade, in English (it's translated when
## shown): "[E]  Take <item_name>". Empty for "the sword".
@export var item_name: String = ""


func has_sword() -> bool:
	return false


## Detaches the sword and returns it, or null once it has been taken.
func take_sword() -> Node3D:
	return null


func can_interact(player: Player) -> bool:
	return has_sword() and not player.has_sword


func prompt() -> String:
	return tr("[E]  Take %s") % (tr("the sword") if item_name.is_empty() else tr(item_name))


func interact(player: Player) -> void:
	var sword := take_sword()
	if sword:
		player.equip_sword(sword)
