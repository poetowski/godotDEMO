class_name Interactable
extends Node3D
## Something in the world the player can use with the interact key: take a
## sword, pick up an item. It offers itself to a player who comes within its
## area, with a prompt, and acts when the player interacts.


## True if this player can use it now.
func can_interact(_player: Player) -> bool:
	return true


## The line the HUD shows while it's on offer, such as "[E]  Take the sword".
func prompt() -> String:
	return ""


func interact(_player: Player) -> void:
	pass


## Offers itself to players entering `area` and withdraws when they leave.
func watch(area: Area3D) -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player and can_interact(player):
		player.offer_pickup(self)


func _on_body_exited(body: Node3D) -> void:
	var player := body as Player
	if player:
		player.withdraw_pickup(self)
