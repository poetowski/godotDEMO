class_name DevConsole
extends CanvasLayer
## The developer console, opened with ` (the key left of 1): type a command,
## Enter runs it, Up and Down walk the history, Esc or ` closes it. While
## it's open the hero ignores input. Part of DevTools, so debug builds only;
## its text is for developers and isn't translated.
##
## Commands act on the world being played (the current scene, a field):
## `help` lists them. Other code adds its own with `register`.

signal toggled(open: bool)

const HISTORY_SIZE := 50

## The world the commands act on; the current scene when unset.
var world: Node

var _commands: Dictionary[String, Dictionary] = {}
var _panel: PanelContainer
var _log: RichTextLabel
var _line: LineEdit
var _history: PackedStringArray = []
var _history_at := 0
var _mouse_before := Input.MOUSE_MODE_VISIBLE


func _init() -> void:
	layer = 127
	_register_builtins()


func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Console"
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.42
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.05, 0.07, 0.9)
	box.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.add_theme_font_size_override("normal_font_size", 22)
	column.add_child(_log)
	_line = LineEdit.new()
	_line.placeholder_text = "command (help lists them)"
	_line.add_theme_font_size_override("font_size", 24)
	_line.text_submitted.connect(_on_submitted)
	_line.gui_input.connect(_on_input_key)
	column.add_child(_line)
	_panel.visible = false
	print_line("Developer console. Type help.")


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_QUOTELEFT:
		toggle()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and is_open():
		toggle()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _panel != null and _panel.visible


func toggle() -> void:
	_panel.visible = not _panel.visible
	var player := _player()
	if player:
		player.input_enabled = not _panel.visible
	if _panel.visible:
		_mouse_before = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_line.clear()
		_line.grab_focus()
	else:
		Input.mouse_mode = _mouse_before
		_line.release_focus()
	toggled.emit(_panel.visible)


## Adds a command. `run` takes the words after the command's name and returns
## what to print.
func register(command: String, usage: String, help: String, run: Callable) -> void:
	_commands[command] = {"usage": usage, "help": help, "run": run}


func has_command(command: String) -> bool:
	return _commands.has(command)


## Runs a line as typed and returns what it printed.
func execute(line: String) -> String:
	var words := line.strip_edges().split(" ", false)
	if words.is_empty():
		return ""
	var command := words[0].to_lower()
	if not _commands.has(command):
		return "Unknown command: %s (help lists them)" % command
	var run: Callable = _commands[command]["run"]
	var result: Variant = run.call(words.slice(1))
	return str(result)


func print_line(text: String) -> void:
	if _log:
		_log.append_text(text + "\n")


func _on_submitted(line: String) -> void:
	_line.clear()
	if line.strip_edges().is_empty():
		return
	_history.append(line)
	if _history.size() > HISTORY_SIZE:
		_history.remove_at(0)
	_history_at = _history.size()
	print_line("[color=#8fd3ff]> %s[/color]" % line)
	var output := execute(line)
	if not output.is_empty():
		print_line(output)


func _on_input_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or _history.is_empty():
		return
	if key.keycode == KEY_UP:
		_history_at = maxi(0, _history_at - 1)
	elif key.keycode == KEY_DOWN:
		_history_at = mini(_history.size(), _history_at + 1)
	else:
		return
	_line.text = _history[_history_at] if _history_at < _history.size() else ""
	_line.caret_column = _line.text.length()
	_line.accept_event()


func _world() -> Node:
	if world and is_instance_valid(world):
		return world
	return get_tree().current_scene if is_inside_tree() else null


## The world if it's a field (has a player, clock and streamer), else null.
func _field() -> Node:
	var found := _world()
	return found if found and found.has_method("teleport") else null


func _player() -> Player:
	var field := _field()
	return field.call("player") as Player if field else null


func _register_builtins() -> void:
	register("help", "help", "lists the commands", _help)
	register("clear", "clear", "empties the console", _clear)
	register("where", "where", "the sector, position and time", _where)
	register("goto", "goto <sector>", "puts the hero in a sector, e.g. goto J10", _goto)
	register("time", "time [hh:mm]", "shows or sets the time of day", _time)
	register("fast", "fast", "runs time a game hour per second, or normally again", _fast)
	register("give", "give <item> [count]", "puts items in the inventory", _give)
	register("items", "items", "lists the item ids", _items)
	register("radius", "radius <load> [unload]", "sets the streaming radius in sectors", _radius)
	register("reset", "reset", "forgets everything taken from the world and reloads it", _reset)
	register("save", "save [slot]", "saves (quicksave by default)", _save)
	register("load", "load [slot]", "loads (quicksave by default)", _load)
	register("map", "map", "shows or hides the streaming map (F4)", _map)
	register("fps", "fps", "shows or hides the performance overlay (F3)", _fps)
	register("quit", "quit", "closes the game", _quit)


func _help(_args: PackedStringArray) -> String:
	var names := _commands.keys()
	names.sort()
	var lines: PackedStringArray = []
	for command: String in names:
		lines.append("%-26s %s" % [_commands[command]["usage"], _commands[command]["help"]])
	return "\n".join(lines)


func _where(_args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var at := (field.call("player") as Player).global_position
	var clock := field.call("clock") as WorldClock
	var place := LevelMap.at(field.call("terrain") as FieldTerrain, at)
	var level := "%.1f m above the ground" % (at.y - place.ground)
	if not place.place_name().is_empty():
		level += ", %s" % place.place_name()
	return "%s at (%.1f, %.1f, %.1f), %s, %s" % [SectorMap.name_of(SectorMap.cell_at(at)), at.x, at.y, at.z, level, clock.text()]


func _goto(args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	if args.is_empty():
		return "Usage: goto <sector>"
	var cell := SectorMap.cell_named(args[0].to_upper())
	if cell == SectorMap.NONE:
		return "No sector named %s." % args[0]
	field.call("teleport", cell)
	return "In %s." % SectorMap.name_of(cell)


func _time(args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var clock := field.call("clock") as WorldClock
	if not args.is_empty():
		var parts := args[0].split(":")
		var hours := parts[0].to_float()
		var minutes := parts[1].to_float() if parts.size() > 1 else 0.0
		if not parts[0].is_valid_float() or hours < 0.0 or hours >= 24.0 or minutes < 0.0 or minutes >= 60.0:
			return "Usage: time hh:mm, e.g. time 21:30"
		clock.hour = hours + minutes / 60.0
	return clock.text()


func _fast(_args: PackedStringArray) -> String:
	var fast: bool = get_parent().call("toggle_fast_time")
	return "Time runs fast." if fast else "Time runs normally."


func _give(args: PackedStringArray) -> String:
	var player := _player()
	if player == null:
		return "No hero here."
	if args.is_empty():
		return "Usage: give <item> [count]; items lists them"
	var item := ItemCatalog.find(StringName(args[0]))
	if item == null:
		return "No item %s; items lists them." % args[0]
	var count := maxi(1, args[1].to_int()) if args.size() > 1 else 1
	var given := 0
	for k in count:
		if not player.inventory.add(item):
			break
		given += 1
	return "Gave %d %s%s." % [given, item.display_name, "" if given == count else " (the inventory is full)"]


func _radius(args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var streamer := field.call("streamer") as SectorStreamer
	if not args.is_empty():
		streamer.load_radius = maxi(0, args[0].to_int())
		streamer.unload_radius = maxi(streamer.load_radius + 1, args[1].to_int()) if args.size() > 1 else streamer.load_radius + 1
		# Unloads what is now out of reach and loads what came in, at once.
		streamer.update()
		streamer.load_around_now()
	return "Load radius %d, unload radius %d." % [streamer.load_radius, streamer.unload_radius]


func _reset(_args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	WorldState.reset()
	var streamer := field.call("streamer") as SectorStreamer
	streamer.unload_all()
	streamer.load_around_now()
	return "The world is as new."


func _save(args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var slot := args[0] if not args.is_empty() else SaveGame.QUICK
	if slot not in SaveGame.SLOTS:
		return "Slots: %s" % ", ".join(SaveGame.SLOTS)
	var error: Error = field.call("save_to", slot)
	return "Saved to %s." % slot if error == OK else "Could not save: %s" % error_string(error)


func _load(args: PackedStringArray) -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var slot := args[0] if not args.is_empty() else SaveGame.QUICK
	if slot not in SaveGame.SLOTS:
		return "Slots: %s" % ", ".join(SaveGame.SLOTS)
	return "Loaded %s." % slot if field.call("load_from", slot) else "Nothing to load in %s." % slot


func _clear(_args: PackedStringArray) -> String:
	if _log:
		_log.clear()
	return ""


func _items(_args: PackedStringArray) -> String:
	return ", ".join(ItemCatalog.ids())


func _map(_args: PackedStringArray) -> String:
	var shown: bool = get_parent().call("toggle_streaming_map")
	return "Streaming map %s." % ("on" if shown else "off")


func _fps(_args: PackedStringArray) -> String:
	get_parent().call("_toggle_overlay")
	return ""


func _quit(_args: PackedStringArray) -> String:
	get_tree().quit()
	return ""
