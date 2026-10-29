class_name ChoiceMenu
extends Control
## A small menu in the middle of the screen asking the player to choose:
## a title, an optional body of text (what someone says), and a numbered
## button per choice. Number keys or clicks choose;
## Esc cancels, which reports choice -1. Built in code; placeholder style.

signal chosen(choice: int)

const BACKGROUND := Color(0.08, 0.09, 0.12, 0.9)
const BUTTON := Color(0.16, 0.18, 0.23, 0.95)
const BUTTON_HOVER := Color(0.24, 0.28, 0.36, 0.95)
const ACCENT := Color(0.75, 0.95, 1.0)

var _panel: PanelContainer
var _title: Label
var _body: Label
var _buttons: VBoxContainer
var _count := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = BACKGROUND
	box.set_corner_radius_all(14)
	box.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", box)
	centre.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", ACCENT)
	column.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(760.0, 0.0)
	_body.add_theme_font_size_override("font_size", 30)
	_body.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95))
	column.add_child(_body)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 10)
	column.add_child(_buttons)
	var hint := Label.new()
	hint.text = tr("Esc  cancel")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74))
	column.add_child(hint)
	visible = false


func is_open() -> bool:
	return visible


## Shows the choices; `chosen` reports the pick.
func ask(title: String, labels: PackedStringArray, body: String = "") -> void:
	_title.text = tr(title)
	_body.text = tr(body)
	_body.visible = not body.is_empty()
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	_count = labels.size()
	for k in labels.size():
		var button := Button.new()
		button.text = "%d   %s" % [k + 1, tr(labels[k])]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(420.0, 64.0)
		button.add_theme_font_size_override("font_size", 32)
		button.add_theme_stylebox_override("normal", _box(BUTTON))
		button.add_theme_stylebox_override("hover", _box(BUTTON_HOVER))
		button.add_theme_stylebox_override("pressed", _box(BUTTON_HOVER))
		button.pressed.connect(pick.bind(k))
		_buttons.add_child(button)
	visible = true


## Closes the menu and reports a choice; -1 cancels.
func pick(choice: int) -> void:
	if not visible:
		return
	visible = false
	chosen.emit(choice)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode >= KEY_1 and key.keycode < KEY_1 + _count:
		pick(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		pick(-1)
		get_viewport().set_input_as_handled()


## The title and body shown, for tests.
func text() -> String:
	return "%s\n%s" % [_title.text, _body.text]


func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	box.set_content_margin_all(10)
	return box
