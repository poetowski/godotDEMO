class_name Hud
extends CanvasLayer
## On-screen text: the current sector, the interaction prompt, a line of
## controls and a hint to click the window for mouse look; the inventory,
## opened with I, and the quest log, opened with Q; and conversations, run
## here from dialogue data through the choice menu. While it's open the hero stands still and the mouse is
## free. Esc opens the game menu, which pauses the game and saves and loads;
## F5 quicksaves and F9 quickloads. The field does the saving and loading
## through `save_requested` and `load_requested`. Placeholder style.

signal save_requested(slot: String)
signal load_requested(slot: String)

var _prompt: Label
var _mouse_hint: Label
var _controls: Label
var _sector: Label
var _clock: Label
var _inventory: InventoryPanel
var _quests: QuestPanel
var _character: CharacterPanel
var _talk: Talk
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
	_clock = _label(34, Color(0.75, 0.95, 1.0))
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.anchor_left = 1.0
	_clock.anchor_right = 1.0
	_clock.offset_left = -400.0
	_clock.offset_right = -28.0
	_clock.offset_top = 20.0
	_prompt = _label(40, Color(1.0, 0.9, 0.6))
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -230.0
	_prompt.offset_bottom = -170.0
	_controls = _label(24, Color(1.0, 1.0, 1.0, 0.85))
	_controls.text = tr("WASD move    Shift sprint    Space jump    E interact    I inventory    Q quests    C character    Left click swing    Wheel zoom    Esc menu    F5 save    F9 load")
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
	_quests = QuestPanel.new()
	_quests.name = "Quests"
	add_child(_quests)
	_quests.opened.connect(_on_inventory_opened)
	_quests.closed.connect(_on_inventory_closed)
	_character = CharacterPanel.new()
	_character.name = "Character"
	add_child(_character)
	_character.opened.connect(_on_inventory_opened)
	_character.closed.connect(_on_inventory_closed)
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
	player.talk_requested.connect(_on_talk_requested)
	_inventory.bind(player.inventory)
	_quests.bind(player.inventory)
	_character.bind(player)


func inventory_panel() -> InventoryPanel:
	return _inventory


func quest_panel() -> QuestPanel:
	return _quests


func character_panel() -> CharacterPanel:
	return _character


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
	_quests.close()
	_character.close()
	if _choices.is_open():
		_choices.pick(-1)


## Shows the sector the player stands in; an empty name means off the grid.
func show_sector(sector_name: String) -> void:
	_sector.text = tr("Off the grid") if sector_name.is_empty() else tr("Sector %s") % sector_name


## Shows the time of day in the top right; worlds without a clock never
## call it.
func show_clock(text: String) -> void:
	_clock.text = text


func sector_text() -> String:
	return _sector.text


func _process(delta: float) -> void:
	_toast_left -= delta
	_toast.visible = _toast_left > 0.0
	var panel_open := _inventory.is_open() or _quests.is_open() or _character.is_open()
	_mouse_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not panel_open and not _choices.is_open()
	_controls.visible = not panel_open and not _choices.is_open()
	_prompt.visible = not panel_open and not _choices.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if _choices.is_open() or _menu.is_open():
		return
	if event.is_action_pressed("quick_save"):
		save_requested.emit(SaveGame.QUICK)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_load"):
		load_requested.emit(SaveGame.QUICK)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and not _inventory.is_open() and not _quests.is_open() and not _character.is_open():
		_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		_quests.close()
		_character.close()
		_inventory.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quests"):
		_inventory.close()
		_character.close()
		_quests.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("character"):
		_inventory.close()
		_quests.close()
		_character.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_inventory.close()
		_quests.close()
		_character.close()
		get_viewport().set_input_as_handled()


func _on_choice_requested(title: String, labels: PackedStringArray, on_chosen: Callable, body: String = "") -> void:
	_inventory.close()
	_quests.close()
	_character.close()
	_on_chosen = on_chosen
	_choices.ask(title, labels, body)
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


## Opens a conversation where its dialogue opens now.
func _on_talk_requested(talk: Talk) -> void:
	_talk = talk
	_say(talk.dialogue.opening(_player.inventory))


func is_talking() -> bool:
	return _talk != null


## Shows what the speaker says at an entry and the answers; null ends the
## conversation.
func _say(entry: DialogueEntry) -> void:
	if entry == null or _talk == null:
		_end_talk()
		return
	var choices := _talk.dialogue.choices_of(entry, _player.inventory)
	var labels := PackedStringArray()
	for choice in choices:
		labels.append(choice.text)
	if labels.is_empty():
		labels.append(Text.mark("Goodbye."))
	_player.ask(_talk.speaker(), labels, _answer.bind(entry, choices), entry.line)


func _answer(picked: int, entry: DialogueEntry, choices: Array[DialogueChoice]) -> void:
	if picked < 0 or picked >= choices.size():
		_end_talk()
		return
	var choice := choices[picked]
	var messages := DialogueRules.run(choice.then, _player.inventory)
	if not messages.is_empty():
		notify("    ".join(messages))
	_say(_talk.dialogue.entry(choice.goto) if not choice.goto.is_empty() else null)


func _end_talk() -> void:
	var talk := _talk
	_talk = null
	if talk and is_instance_valid(talk):
		talk.finish(_player)


func _on_menu_opened() -> void:
	_inventory.close()
	_quests.close()
	_character.close()
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
