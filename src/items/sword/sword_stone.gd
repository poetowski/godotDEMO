class_name SwordStone
extends SwordHolder
## A sword stuck in a rock. Placeholder from the castle PoC.

@onready var _sword: Node3D = $Sword
@onready var _glint: OmniLight3D = $Glint
@onready var _sparkles: GPUParticles3D = $Sparkles
@onready var _pickup_area: Area3D = $PickupArea


func _ready() -> void:
	watch(_pickup_area)


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

