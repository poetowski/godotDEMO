class_name SwordHolder
extends Node3D
## Something that holds a sword for the player to take: a sword in a stone, a
## chest with a blade on it. It offers the sword to a player who comes within
## its pickup area and hands it over through take_sword().

## What the prompt calls the blade: "[E]  Take <item_name>".
@export var item_name: String = "the sword"


func has_sword() -> bool:
	return false


## Detaches the sword and returns it, or null once it has been taken.
func take_sword() -> Node3D:
	return null


func prompt() -> String:
	return "[E]  Take %s" % item_name


## Offers the sword to players entering `area` and withdraws it when they
## leave.
func watch(area: Area3D) -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player and has_sword():
		player.offer_pickup(self)


func _on_body_exited(body: Node3D) -> void:
	var player := body as Player
	if player:
		player.withdraw_pickup(self)
