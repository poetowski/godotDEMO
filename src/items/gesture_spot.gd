@tool
class_name GestureSpot
extends Interactable
## A place where the player can choose how to act: pray, cry... Interacting
## turns the hero toward `face_toward` and asks which gesture to make; the
## hero then performs it for its time. The spot offers itself again once the
## gesture ends. Generated children have no owner, so the editor never saves
## them.

@export var prompt_text: String = "[E]  Stand here"
## The question above the choices.
@export var title: String = ""
## What each choice says, such as "Pray".
@export var labels: PackedStringArray = PackedStringArray()
## The gesture each choice makes; Player.perform knows them.
@export var gestures: Array[StringName] = []
## Seconds each gesture lasts.
@export var seconds: PackedFloat32Array = PackedFloat32Array()
## The world point the hero turns to face.
@export var face_toward: Vector3 = Vector3.ZERO
@export var reach: float = 1.3

var _area: Area3D


func _ready() -> void:
	_area = Area3D.new()
	_area.name = "SpotArea"
	_area.collision_layer = 0
	_area.collision_mask = 2
	_area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	shape.shape = sphere
	shape.position = Vector3.UP * 0.6
	_area.add_child(shape)
	add_child(_area)
	if not Engine.is_editor_hint():
		watch(_area)


func can_interact(player: Player) -> bool:
	return not player.is_performing()


func prompt() -> String:
	return prompt_text


func interact(player: Player) -> void:
	player.look_toward(Vector3(face_toward.x, player.global_position.y, face_toward.z))
	player.ask(title, labels, _on_chosen.bind(player))


## Performs the chosen gesture, or offers the spot again if none was chosen.
func choose(player: Player, choice: int) -> void:
	_on_chosen(choice, player)


func _on_chosen(choice: int, player: Player) -> void:
	if choice < 0 or choice >= gestures.size():
		_offer_again(player)
		return
	player.gesture_finished.connect(func(_gesture: StringName) -> void: _offer_again(player), CONNECT_ONE_SHOT)
	player.perform(gestures[choice], seconds[choice] if choice < seconds.size() else 4.0)


func _offer_again(player: Player) -> void:
	if is_instance_valid(player) and _area.overlaps_body(player):
		player.offer_pickup(self)
