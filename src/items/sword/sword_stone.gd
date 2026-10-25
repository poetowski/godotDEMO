class_name SwordStone
extends Node3D
## A sword stuck in a rock. Offers the sword to a player who walks up and
## hands it over through take_sword(). Placeholder for the castle PoC.

@onready var _sword: Node3D = $Sword
@onready var _glint: OmniLight3D = $Glint
@onready var _sparkles: GPUParticles3D = $Sparkles
@onready var _pickup_area: Area3D = $PickupArea


func _ready() -> void:
	_pickup_area.body_entered.connect(_on_body_entered)
	_pickup_area.body_exited.connect(_on_body_exited)


func has_sword() -> bool:
	return _sword != null


## Detaches the sword and returns it, or null once it has been taken.
func take_sword() -> Node3D:
	if _sword == null:
		return null
	var sword := _sword
	_sword = null
	remove_child(sword)
	_glint.visible = false
	_sparkles.emitting = false
	return sword


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player and has_sword():
		player.offer_pickup(self)


func _on_body_exited(body: Node3D) -> void:
	var player := body as Player
	if player:
		player.withdraw_pickup(self)
