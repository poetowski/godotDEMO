class_name Hud
extends CanvasLayer
## On-screen text: the current sector, the interaction prompt, a line of
## controls and a hint to click the window for mouse look; and the inventory,
## opened with I. While it's open the hero stands still and the mouse is
## free. Placeholder style.

const CONTROLS := "WASD move    Shift sprint    Space jump    E interact    I inventory    Left click swing    Wheel zoom    Esc free the mouse"

var _prompt: Label
var _mouse_hint: Label
var _controls: Label
var _sector: Label
var _inventory: InventoryPanel
var _player: Player


func _ready() -> void:
	_sector = _label(34, Color(0.75, 0.95, 1.0))
	_sector.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_sector.offset_left = 28.0
	_sector.offset_top = 20.0
	_prompt = _label(40, Color(1.0, 0.9, 0.6))
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -230.0
	_prompt.offset_bottom = -170.0
	_controls = _label(24, Color(1.0, 1.0, 1.0, 0.85))
	_controls.text = CONTROLS
	_controls.anchor_top = 1.0
	_controls.anchor_bottom = 1.0
	_controls.anchor_right = 1.0
	_controls.offset_top = -56.0
	_controls.offset_bottom = -20.0
	_mouse_hint = _label(26, Color(1.0, 1.0, 1.0, 0.9))
	_mouse_hint.text = "Click to look around with the mouse"
	_mouse_hint.anchor_right = 1.0
	_mouse_hint.offset_top = 24.0
	_mouse_hint.offset_bottom = 60.0
	_inventory = InventoryPanel.new()
	_inventory.name = "Inventory"
	add_child(_inventory)
	_inventory.opened.connect(_on_inventory_opened)
	_inventory.closed.connect(_on_inventory_closed)


## Shows the player's prompts and inventory.
func track(player: Player) -> void:
	_player = player
	player.prompt_changed.connect(_on_prompt_changed)
	_inventory.bind(player.inventory)


func inventory_panel() -> InventoryPanel:
	return _inventory


## Shows the sector the player stands in; an empty name means off the grid.
func show_sector(sector_name: String) -> void:
	_sector.text = "Off the grid" if sector_name.is_empty() else "Sector " + sector_name


func sector_text() -> String:
	return _sector.text


func _process(_delta: float) -> void:
	_mouse_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _inventory.is_open()
	_controls.visible = not _inventory.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_inventory.toggle()
		get_viewport().set_input_as_handled()
	elif _inventory.is_open() and event.is_action_pressed("ui_cancel"):
		_inventory.close()
		get_viewport().set_input_as_handled()


func _on_inventory_opened() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _player:
		_player.input_enabled = false


func _on_inventory_closed() -> void:
	if _player:
		_player.input_enabled = true


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
