class_name Player
extends CharacterBody3D
## Third-person hero for the castle proof of concept: camera-relative movement,
## sprinting and jumping, taking the sword and swinging it. The body is made of
## primitive parts animated in code. Look and tuning are placeholders.
##
## The mouse is captured on the first click in the window and released with
## Esc; a gamepad's right stick looks around without capturing anything.

signal prompt_changed(text: String)
signal sword_equipped
signal swung

const TAKE_PROMPT := "[E]  Take the sword"
const SWORD_REST := Vector3(0.45, 0.0, 0.0)
const SWING_RAISED := Vector3(2.6, 0.0, 0.7)
const SWING_STRUCK := Vector3(0.55, 0.0, -1.1)

@export_group("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var acceleration: float = 14.0
@export var air_acceleration: float = 4.0
@export var jump_velocity: float = 5.2
@export var turn_speed: float = 10.0
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
var is_swinging: bool = false

var _offered: SwordStone
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _yaw: float = 0.0
var _pitch: float = 0.0
var _walk_phase: float = 0.0
var _stride: float = 0.0
var _swoosh_material: StandardMaterial3D

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _left_arm: Node3D = $Model/LeftArm
@onready var _right_arm: Node3D = $Model/RightArm
@onready var _left_leg: Node3D = $Model/LeftLeg
@onready var _right_leg: Node3D = $Model/RightLeg
@onready var _hand: Node3D = $Model/RightArm/Hand
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


func _unhandled_input(event: InputEvent) -> void:
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
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look != Vector2.ZERO:
		_turn_camera(-look.x * stick_look_speed * delta, -look.y * stick_look_speed * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Basis(Vector3.UP, _yaw) * Vector3(input.x, 0.0, input.y)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var rate := acceleration if is_on_floor() else air_acceleration
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


func offer_pickup(stone: SwordStone) -> void:
	if has_sword:
		return
	_offered = stone
	prompt_changed.emit(TAKE_PROMPT)


func withdraw_pickup(stone: SwordStone) -> void:
	if _offered == stone:
		_offered = null
		prompt_changed.emit("")


## Takes whatever is on offer; today that's only the sword.
func interact() -> void:
	if _offered == null or has_sword:
		return
	var sword := _offered.take_sword()
	_offered = null
	prompt_changed.emit("")
	if sword:
		equip_sword(sword)


## Puts `sword` in the right hand, blade forward.
func equip_sword(sword: Node3D) -> void:
	_hand.add_child(sword)
	sword.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO)
	has_sword = true
	_right_arm.rotation = SWORD_REST
	sword_equipped.emit()


## Starts a diagonal swing if the sword is in hand and no swing is running.
func try_attack() -> bool:
	if not has_sword or is_swinging:
		return false
	is_swinging = true
	swung.emit()
	var tween := create_tween()
	tween.tween_property(_right_arm, "rotation", SWING_RAISED, swing_duration * 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_flash_swoosh)
	tween.tween_property(_right_arm, "rotation", SWING_STRUCK, swing_duration * 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_right_arm, "rotation", SWORD_REST, swing_duration * 0.48) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: is_swinging = false)
	return true


func _turn_camera(yaw_delta: float, pitch_delta: float) -> void:
	_yaw = wrapf(_yaw + yaw_delta, -PI, PI)
	_pitch = clampf(_pitch + pitch_delta, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	_camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)


## Walk cycle: legs and arms swing with ground speed, the body bobs a little,
## legs tuck while airborne. The sword arm stays still while holding the sword.
func _animate(delta: float) -> void:
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	_stride = lerpf(_stride, clampf(ground_speed / walk_speed, 0.0, 1.4), 1.0 - exp(-8.0 * delta))
	_walk_phase = fmod(_walk_phase + delta * (3.0 + ground_speed * 1.5), TAU)
	var swing := sin(_walk_phase) * 0.65 * _stride
	if is_on_floor():
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
	else:
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.6, 1.0 - exp(-10.0 * delta))
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -0.25, 1.0 - exp(-10.0 * delta))
	_left_arm.rotation.x = -swing * 0.8
	if not is_swinging:
		var rest := SWORD_REST.x + swing * 0.25 if has_sword else swing * 0.8
		_right_arm.rotation = Vector3(rest, 0.0, 0.0)
	_model.position.y = absf(sin(_walk_phase)) * 0.05 * _stride


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
