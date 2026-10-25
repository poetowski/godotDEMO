class_name FlyCamera
extends Camera3D
## Free-flying debug camera. WASD or the left stick moves, E/Q rise and sink,
## Shift speeds up, holding the right mouse button (or the right stick) looks
## around, and the mouse wheel changes the base speed.

const MAX_PITCH := deg_to_rad(89.0)

@export var speed: float = 8.0
@export var fast_multiplier: float = 4.0
@export var mouse_sensitivity: float = 0.003
@export var stick_look_speed: float = 2.5

var _yaw: float
var _pitch: float


func _ready() -> void:
	_yaw = rotation.y
	_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		match button.button_index:
			MOUSE_BUTTON_RIGHT:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if button.pressed else Input.MOUSE_MODE_VISIBLE
			MOUSE_BUTTON_WHEEL_UP when button.pressed:
				speed = minf(speed * 1.25, 1000.0)
			MOUSE_BUTTON_WHEEL_DOWN when button.pressed:
				speed = maxf(speed / 1.25, 0.25)
		return
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look != Vector2.ZERO:
		_turn(-look.x * stick_look_speed * delta, -look.y * stick_look_speed * delta)
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var rise := Input.get_axis("dev_fly_down", "dev_fly_up")
	var direction := global_basis * Vector3(move.x, 0.0, move.y) + Vector3.UP * rise
	var current_speed := speed * (fast_multiplier if Input.is_action_pressed("dev_fly_fast") else 1.0)
	global_position += direction.limit_length(1.0) * current_speed * delta


func _turn(yaw_delta: float, pitch_delta: float) -> void:
	_yaw = wrapf(_yaw + yaw_delta, -PI, PI)
	_pitch = clampf(_pitch + pitch_delta, -MAX_PITCH, MAX_PITCH)
	rotation = Vector3(_pitch, _yaw, 0.0)
