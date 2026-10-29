class_name Talk
extends Interactable
## Lets the player talk to the villager it belongs to (its parent): offers
## "Talk to <name>" within reach, and while talking the villager stops and
## faces the player. The HUD runs the conversation (`Player.talk`).

## Metres within which the player can talk.
const REACH := 2.4

var dialogue: DialogueData
var _villager: Villager
var _area: Area3D


func _ready() -> void:
	_villager = get_parent() as Villager
	_area = Area3D.new()
	_area.name = "Reach"
	# Only the player (layer 2) comes within reach.
	_area.collision_layer = 0
	_area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = REACH
	shape.shape = sphere
	shape.position = Vector3.UP
	_area.add_child(shape)
	add_child(_area)
	watch(_area)


func speaker() -> String:
	return dialogue.speaker if dialogue else ""


func can_interact(player: Player) -> bool:
	return dialogue != null and dialogue.opening(player.inventory) != null


func prompt() -> String:
	return tr("[E]  Talk to %s") % tr(speaker())


func interact(player: Player) -> void:
	if _villager:
		_villager.listen_to(player)
	player.talk(self)


## Called when the conversation ends: the villager goes on with their day
## and the player can talk again.
func finish(player: Player) -> void:
	if _villager:
		_villager.listen_to(null)
	if _area.overlaps_body(player):
		player.offer_pickup(self)
