class_name Player
extends CharacterBody3D
## Third-person hero: camera-relative movement, sprinting and jumping, taking
## holding a sword and swinging it. The body is a skinned model with
## animations (HeroBody, built in Blender by tools/blender/build_hero.py).
## Look and tuning are placeholders.
##
## The mouse is captured on the first click in the window and released with
## Esc; a gamepad's right stick looks around without capturing anything.

signal prompt_changed(text: String)
signal sword_equipped
signal swung
## Something asks the player to choose; the HUD shows the choices and calls
## `on_chosen` with the pick's index, or -1 when cancelled.
signal choice_requested(title: String, labels: PackedStringArray, on_chosen: Callable, body: String)
## The player started talking to someone; the HUD runs the conversation.
signal talk_requested(talk: Talk)

## Share of a swing at which the blade strikes and the trail shows.
const SWING_STRIKE := 0.3

@export_group("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var acceleration: float = 14.0
@export var air_acceleration: float = 4.0
@export var jump_velocity: float = 5.2
@export var turn_speed: float = 10.0
@export_group("Swimming")
## Metres of water under the hero from which they swim.
@export var swim_depth: float = 1.0
@export var swim_speed: float = 2.4
@export var swim_sprint_speed: float = 3.6
## Metres the hero's feet (their origin) hang below the surface while
## swimming, so the back is just under it.
@export var float_depth: float = 0.9
@export_group("Camera")
@export var mouse_sensitivity: float = 0.0025
@export var stick_look_speed: float = 2.6
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 30.0
@export var min_distance: float = 2.0
@export var max_distance: float = 8.0
@export_group("Sword")
@export var swing_duration: float = 0.5

var has_sword: bool = false
## True while in water at least `swim_depth` deep.
var is_swimming: bool = false
var is_swinging: bool = false
## What the hero carries.
var inventory := Inventory.new()
## False while a menu such as the inventory is open: the hero stands still
## and ignores movement, look and action input.
var input_enabled: bool = true

var _offered: Interactable
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _yaw: float = 0.0
var _pitch: float = 0.0
var _hand: Node3D
var _swoosh_material: StandardMaterial3D

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _body: HeroBody = $Model/Body
@onready var _swoosh: MeshInstance3D = $Model/Swoosh


func _ready() -> void:
	_yaw = _camera_pivot.rotation.y
	_pitch = _camera_pivot.rotation.x
	_spring_arm.add_excluded_object(get_rid())
	_swoosh_material = StandardMaterial3D.new()
	_swoosh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_swoosh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_swoosh_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_swoosh_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_swoosh_material.vertex_color_use_as_albedo = true
	_swoosh_material.albedo_color = Color(0.85, 0.92, 1.0, 0.0)
	_swoosh.mesh = _build_swoosh_mesh()
	_swoosh.material_override = _swoosh_material
	_swoosh.visible = false
	_hand = _body.hand()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	var button := event as InputEventMouseButton
	if button and button.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and button.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_spring_arm.spring_length = maxf(_spring_arm.spring_length - 0.5, min_distance)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_spring_arm.spring_length = minf(_spring_arm.spring_length + 0.5, max_distance)
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn_camera(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("attack"):
		try_attack()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	var free := input_enabled
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down") if free else Vector2.ZERO
	if look != Vector2.ZERO:
		_turn_camera(-look.x * stick_look_speed * delta, -look.y * stick_look_speed * delta)

	var surface := _update_swimming()
	if is_swimming:
		# Float at the surface: ease toward it rather than fall.
		velocity.y = clampf((surface - float_depth - global_position.y) * 4.0, -3.0, 3.0)
	elif not is_on_floor():
		velocity.y -= _gravity * delta
	elif free and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if free else Vector2.ZERO
	var direction := Basis(Vector3.UP, _yaw) * Vector3(input.x, 0.0, input.y)
	var sprinting := Input.is_action_pressed("sprint")
	var speed := sprint_speed if sprinting else walk_speed
	var rate := acceleration if is_on_floor() else air_acceleration
	if is_swimming:
		speed = swim_sprint_speed if sprinting else swim_speed
		rate = acceleration * 0.4
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(Vector2(direction.x, direction.z) * speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	move_and_slide()

	if direction.length_squared() > 0.01:
		var facing := atan2(-direction.x, -direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, facing, 1.0 - exp(-turn_speed * delta))
	_animate(delta)


## Points the camera (and the hero) at a world position, e.g. when spawning.
func look_toward(target: Vector3) -> void:
	var to_target := target - global_position
	_yaw = atan2(-to_target.x, -to_target.z)
	_model.rotation.y = _yaw
	_turn_camera(0.0, 0.0)


## Asks the player to choose between `labels`; `on_chosen` gets the pick's
## index, or -1 when the player cancels.
func ask(title: String, labels: PackedStringArray, on_chosen: Callable, body: String = "") -> void:
	choice_requested.emit(title, labels, on_chosen, body)


## Starts a conversation with someone.
func talk(with: Talk) -> void:
	talk_requested.emit(with)


## Puts an interactable on offer: its prompt shows until the player uses it
## or walks away.
func offer_pickup(target: Interactable) -> void:
	if not target.can_interact(self):
		return
	_offered = target
	prompt_changed.emit(target.prompt())


func withdraw_pickup(target: Interactable) -> void:
	if _offered == target:
		_offered = null
		prompt_changed.emit("")


## Uses whatever is on offer.
func interact() -> void:
	if _offered == null:
		return
	var target := _offered
	_offered = null
	prompt_changed.emit("")
	target.interact(self)


## The animated body.
func body() -> HeroBody:
	return _body


## The sword in hand, or null.
func sword() -> Node3D:
	return _hand.get_child(0) as Node3D if _hand.get_child_count() > 0 else null


## Drops the sword in hand, if any; it's gone, not put in the world.
func unequip_sword() -> void:
	for child in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	has_sword = false


## The direction the hero and camera face, in radians around the vertical.
func facing() -> float:
	return _yaw


func face(yaw: float) -> void:
	_yaw = yaw
	_model.rotation.y = yaw
	_turn_camera(0.0, 0.0)


## Puts `sword` in the right hand, blade forward.
func equip_sword(sword: Node3D) -> void:
	_hand.add_child(sword)
	sword.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO)
	has_sword = true
	sword_equipped.emit()


## Starts a diagonal swing if the sword is in hand and no swing is running.
func try_attack() -> bool:
	if is_swimming:
		return false
	if not has_sword or is_swinging:
		return false
	is_swinging = true
	swung.emit()
	_body.swing()
	var tween := create_tween()
	tween.tween_interval(swing_duration * SWING_STRIKE)
	tween.tween_callback(_flash_swoosh)
	tween.tween_interval(swing_duration * (1.0 - SWING_STRIKE))
	tween.tween_callback(func() -> void: is_swinging = false)
	return true


func _turn_camera(yaw_delta: float, pitch_delta: float) -> void:
	_yaw = wrapf(_yaw + yaw_delta, -PI, PI)
	_pitch = clampf(_pitch + pitch_delta, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	_camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)


## Tells the body how the hero moves: idle, walk and run by ground speed,
## falling while airborne, the sword arm while holding the sword, swimming in
## deep water.
func _animate(delta: float) -> void:
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	_body.move(ground_speed, not is_on_floor() and not is_swimming, has_sword, delta)
	_body.swim(is_swimming, ground_speed, delta)


## Whether the hero swims here, from the water's depth under them (a little
## shallower to stop than to start, so they don't flicker at the edge).
## Returns the water's surface height, or -INF on dry land.
func _update_swimming() -> float:
	var terrain := get_tree().get_first_node_in_group(&"terrains") as FieldTerrain if is_inside_tree() else null
	if terrain == null:
		is_swimming = false
		return -INF
	var xz := Vector2(global_position.x, global_position.z)
	var level := terrain.water_level_at(xz)
	var depth := level - terrain.height_at(xz)
	is_swimming = depth >= (swim_depth - 0.15 if is_swimming else swim_depth)
	return level


func _flash_swoosh() -> void:
	_swoosh.visible = true
	_swoosh_material.albedo_color.a = 0.9
	var fade := create_tween()
	fade.tween_property(_swoosh_material, "albedo_color:a", 0.0, 0.3).set_delay(0.06)
	fade.tween_callback(_swoosh.hide)


## A fading arc for the swing: from behind the right shoulder, forward, down to
## the left. The newest end of the arc is brightest.
func _build_swoosh_mesh() -> ArrayMesh:
	var center := Vector3(0.28, 1.35, 0.0)
	var up_right := Vector3(1.0, 1.0, 0.0).normalized()
	var forward := Vector3(0.0, 0.0, -1.0)
	var steps := 24
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for i in steps + 1:
		var t := float(i) / steps
		var angle := deg_to_rad(lerpf(-20.0, 200.0, t))
		var direction := up_right * cos(angle) + forward * sin(angle)
		vertices.append(center + direction * 1.05)
		vertices.append(center + direction * 1.65)
		colors.append(Color(1.0, 1.0, 1.0, t * 0.1))
		colors.append(Color(1.0, 1.0, 1.0, t * 0.8))
	var indices := PackedInt32Array()
	for i in steps:
		var a := i * 2
		indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
