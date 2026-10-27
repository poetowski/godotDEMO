class_name GameMenu
extends Control
## The game menu, opened with Esc: the game pauses behind it. Resume, Save,
## Load and Quit; Save and Load list the save slots with where and when each
## was saved. Asks the field to save or load through its signals and shows a
## short note of what happened. Built in code; placeholder style.

signal opened
signal closed
signal save_requested(slot: String)
signal load_requested(slot: String)

const BACKGROUND := Color(0.08, 0.09, 0.12, 0.92)
const BUTTON := Color(0.16, 0.18, 0.23, 0.95)
const BUTTON_HOVER := Color(0.24, 0.28, 0.36, 0.95)
const ACCENT := Color(0.75, 0.95, 1.0)
const MUTED := Color(0.65, 0.68, 0.74)

var _title: Label
var _buttons: VBoxContainer
var _note: Label
## "main", "save" or "load".
var _page := "main"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = BACKGROUND
	box.set_corner_radius_all(14)
	box.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", box)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	_title = _label("", 44, ACCENT)
	column.add_child(_title)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 10)
	column.add_child(_buttons)
	_note = _label("", 24, MUTED)
	column.add_child(_note)
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	visible = true
	_note.text = ""
	show_page("main")
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Shows a short line under the buttons, such as "Saved to slot 1".
func note(text: String) -> void:
	_note.text = text


## "main", "save" or "load".
func page() -> String:
	return _page


func show_page(which: String) -> void:
	_page = which
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	match which:
		"main":
			_title.text = tr("Paused")
			_button(tr("Resume"), close)
			_button(tr("Save game"), show_page.bind("save"))
			_button(tr("Load game"), show_page.bind("load"))
			_button(tr("Quit"), func() -> void: get_tree().quit())
		"save", "load":
			_title.text = tr("Save game") if which == "save" else tr("Load game")
			for slot in SaveGame.SLOTS:
				var label := "%s   %s" % [tr("Quicksave") if slot == SaveGame.QUICK else tr("Slot %s") % slot, SaveGame.describe(slot)]
				var button := _button(label, _pick_slot.bind(slot))
				button.disabled = which == "load" and SaveGame.read(slot).is_empty()
			_button(tr("Back"), show_page.bind("main"))


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _page == "main":
			close()
		else:
			show_page("main")
		get_viewport().set_input_as_handled()


func _pick_slot(slot: String) -> void:
	if _page == "save":
		save_requested.emit(slot)
		show_page("save")
	else:
		load_requested.emit(slot)


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(620.0, 60.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 30)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = BUTTON_HOVER if state in ["hover", "pressed"] else BUTTON
		box.set_corner_radius_all(8)
		box.set_content_margin_all(12)
		button.add_theme_stylebox_override(state, box)
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
