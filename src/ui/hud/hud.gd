class_name Hud
extends CanvasLayer
## On-screen text: the current sector, the interaction prompt, a line of
## controls and a hint to click the window for mouse look; and the inventory,
## opened with I. While it's open the hero stands still and the mouse is
## free. Esc opens the game menu, which pauses the game and saves and loads;
## F5 quicksaves and F9 quickloads. The field does the saving and loading
## through `save_requested` and `load_requested`. Placeholder style.

signal save_requested(slot: String)
signal load_requested(slot: String)

var _prompt: Label
var _mouse_hint: Label
var _controls: Label
var _sector: Label
var _inventory: InventoryPanel
var _choices: ChoiceMenu
var _menu: GameMenu
var _toast: Label
var _toast_left := 0.0
var _on_chosen: Callable
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
	_controls.text = tr("WASD move    Shift sprint    Space jump    E interact    I inventory    Left click swing    Wheel zoom    Esc menu    F5 save    F9 load")
	_controls.anchor_top = 1.0
	_controls.anchor_bottom = 1.0
	_controls.anchor_right = 1.0
	_controls.offset_top = -56.0
	_controls.offset_bottom = -20.0
	_mouse_hint = _label(26, Color(1.0, 1.0, 1.0, 0.9))
	_mouse_hint.text = tr("Click to look around with the mouse")
	_mouse_hint.anchor_right = 1.0
	_mouse_hint.offset_top = 24.0
	_mouse_hint.offset_bottom = 60.0
	_inventory = InventoryPanel.new()
	_inventory.name = "Inventory"
	add_child(_inventory)
	_inventory.opened.connect(_on_inventory_opened)
	_inventory.closed.connect(_on_inventory_closed)
	_choices = ChoiceMenu.new()
	_choices.name = "Choices"
	add_child(_choices)
	_choices.chosen.connect(_on_choice_made)
	_toast = _label(30, Color(1.0, 1.0, 1.0, 0.95))
	_toast.anchor_right = 1.0
	_toast.offset_top = 80.0
	_toast.offset_bottom = 120.0
	_menu = GameMenu.new()
	_menu.name = "GameMenu"
	add_child(_menu)
	_menu.opened.connect(_on_menu_opened)
	_menu.closed.connect(_on_menu_closed)
	_menu.save_requested.connect(func(slot: String) -> void: save_requested.emit(slot))
	_menu.load_requested.connect(func(slot: String) -> void: load_requested.emit(slot))


## Shows the player's prompts and inventory.
func track(player: Player) -> void:
	_player = player
	player.prompt_changed.connect(_on_prompt_changed)
	player.choice_requested.connect(_on_choice_requested)
	_inventory.bind(player.inventory)


func inventory_panel() -> InventoryPanel:
	return _inventory


func choice_menu() -> ChoiceMenu:
	return _choices


func game_menu() -> GameMenu:
	return _menu


## Shows a short message for a moment, and in the game menu if it's open.
func notify(text: String) -> void:
	_toast.text = text
	_toast_left = 2.5
	_menu.note(text)


func toast_text() -> String:
	return _toast.text if _toast_left > 0.0 else ""


## Closes every menu and panel, as after loading a save.
func close_menus() -> void:
	_menu.close()
	_inventory.close()
	if _choices.is_open():
		_choices.pick(-1)


## Shows the sector the player stands in; an empty name means off the grid.
func show_sector(sector_name: String) -> void:
	_sector.text = tr("Off the grid") if sector_name.is_empty() else tr("Sector %s") % sector_name


func sector_text() -> String:
	return _sector.text


func _process(delta: float) -> void:
	_toast_left -= delta
	_toast.visible = _toast_left > 0.0
	_mouse_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _inventory.is_open()
	_controls.visible = not _inventory.is_open() and not _choices.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if _choices.is_open() or _menu.is_open():
		return
	if event.is_action_pressed("quick_save"):
		save_requested.emit(SaveGame.QUICK)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_load"):
		load_requested.emit(SaveGame.QUICK)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and not _inventory.is_open():
		_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		_inventory.toggle()
		get_viewport().set_input_as_handled()
	elif _inventory.is_open() and event.is_action_pressed("ui_cancel"):
		_inventory.close()
		get_viewport().set_input_as_handled()


func _on_choice_requested(title: String, labels: PackedStringArray, on_chosen: Callable) -> void:
	_inventory.close()
	_on_chosen = on_chosen
	_choices.ask(title, labels)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _player:
		_player.input_enabled = false


func _on_choice_made(choice: int) -> void:
	if _player:
		_player.input_enabled = true
	var reply := _on_chosen
	_on_chosen = Callable()
	if reply.is_valid():
		reply.call(choice)


func _on_menu_opened() -> void:
	_inventory.close()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_menu_closed() -> void:
	get_tree().paused = false


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
