class_name Hud
extends CanvasLayer
## On-screen text for the castle PoC: the interaction prompt, a line of
## controls, and a hint to click the window for mouse look. Placeholder style.

const CONTROLS := "WASD move    Shift sprint    Space jump    E interact    Left click swing    Wheel zoom    Esc free the mouse"

var _prompt: Label
var _mouse_hint: Label


func _ready() -> void:
	_prompt = _label(40, Color(1.0, 0.9, 0.6))
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -230.0
	_prompt.offset_bottom = -170.0
	var controls := _label(24, Color(1.0, 1.0, 1.0, 0.85))
	controls.text = CONTROLS
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.anchor_right = 1.0
	controls.offset_top = -56.0
	controls.offset_bottom = -20.0
	_mouse_hint = _label(26, Color(1.0, 1.0, 1.0, 0.9))
	_mouse_hint.text = "Click to look around with the mouse"
	_mouse_hint.anchor_right = 1.0
	_mouse_hint.offset_top = 24.0
	_mouse_hint.offset_bottom = 60.0


## Shows the player's prompts.
func track(player: Player) -> void:
	player.prompt_changed.connect(_on_prompt_changed)


func _process(_delta: float) -> void:
	_mouse_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED


func _on_prompt_changed(text: String) -> void:
	_prompt.text = text


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	return label
