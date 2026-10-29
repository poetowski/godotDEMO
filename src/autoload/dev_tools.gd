extends Node
## Developer hooks. Present in debug builds only; frees itself in release.
##
## Command-line user arguments (after `--`), used by `npm run shot`:
##   --shot=<path>         save a PNG of the window once the scene settles, then quit
##   --shot-frames=<n>     frames to wait before that capture (default 60)
##   --shot-camera=x,y,z   take the shot from a temporary camera at this point
##   --shot-look=x,y,z     ...looking at this point (default: the world origin)
##   --shot-frame=A1:C3    ...or from a camera framing those sectors from above
##   --shot-player=x,y,z   put the player there first
##   --shot-hold=<action>  keep an input action pressed until the shot
##
## Hotkeys: F12 (dev_screenshot) saves a PNG into .shots/ (user://shots outside
## the editor); F3 (dev_overlay) toggles the performance overlay; F4 toggles
## the streaming map (StreamingMap); F7 runs the world clock fast (a game
## hour per second) or normally again; ` opens the console (DevConsole).

const DEFAULT_SHOT_FRAMES := 60
## Game hours per real second while F7 fast-forwards the world clock.
const FAST_HOURS_PER_SECOND := 1.0


## Options read from the command line.
class Options:
	var shot_path: String = ""
	var shot_frames: int = DEFAULT_SHOT_FRAMES
	var has_shot_camera: bool = false
	var shot_camera := Vector3.ZERO
	var shot_look := Vector3.ZERO
	var has_shot_player: bool = false
	var shot_player := Vector3.ZERO
	var shot_hold: StringName = &""


var _overlay_layer: CanvasLayer
var _overlay_label: Label
var _console: DevConsole
var _map_layer: CanvasLayer
var _map: StreamingMap


static func parse_args(args: PackedStringArray) -> Options:
	var options := Options.new()
	for arg in args:
		if arg.begins_with("--shot="):
			options.shot_path = arg.trim_prefix("--shot=")
		elif arg.begins_with("--shot-frames="):
			options.shot_frames = maxi(1, arg.trim_prefix("--shot-frames=").to_int())
		elif arg.begins_with("--shot-camera="):
			options.shot_camera = _parse_vector(arg.trim_prefix("--shot-camera="))
			options.has_shot_camera = true
		elif arg.begins_with("--shot-player="):
			options.shot_player = _parse_vector(arg.trim_prefix("--shot-player="))
			options.has_shot_player = true
		elif arg.begins_with("--shot-hold="):
			options.shot_hold = StringName(arg.trim_prefix("--shot-hold="))
		elif arg.begins_with("--shot-look="):
			options.shot_look = _parse_vector(arg.trim_prefix("--shot-look="))
		elif arg.begins_with("--shot-frame="):
			var view := frame_view(arg.trim_prefix("--shot-frame="))
			if not view.is_empty():
				options.has_shot_camera = true
				options.shot_camera = view[0]
				options.shot_look = view[1]
	return options


## A camera position and the point it looks at, framing the sectors from one
## named corner to the other ("A1:C3", or one sector) from above and across
## their longer side. Empty when a name is no sector.
static func frame_view(sectors: String) -> PackedVector3Array:
	var names := sectors.split(":")
	var first := SectorMap.cell_named(names[0])
	var last := SectorMap.cell_named(names[names.size() - 1])
	if first == SectorMap.NONE or last == SectorMap.NONE:
		return PackedVector3Array()
	var low := SectorMap.corner_of(Vector2i(mini(first.x, last.x), mini(first.y, last.y)))
	var high := SectorMap.corner_of(Vector2i(maxi(first.x, last.x) + 1, maxi(first.y, last.y) + 1))
	var centre := (low + high) * 0.5
	var width := high.x - low.x
	var depth := low.z - high.z
	var across := Vector3(1.0, 0.0, 0.3) if depth > width else Vector3(0.3, 0.0, 1.0)
	var distance := maxf(width, depth) * 0.5 + 5.0
	var camera := centre + (across.normalized() + Vector3.UP * 0.85).normalized() * distance
	return PackedVector3Array([camera, centre])


static func _parse_vector(text: String) -> Vector3:
	var parts := text.split_floats(",")
	return Vector3(parts[0], parts[1], parts[2]) if parts.size() == 3 else Vector3.ZERO


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	_console = DevConsole.new()
	_console.name = "DevConsole"
	add_child(_console)
	var options := parse_args(OS.get_cmdline_user_args())
	if not options.shot_path.is_empty():
		_capture_and_quit(options)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_screenshot"):
		save_screenshot(_hotkey_shot_path())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dev_overlay"):
		_toggle_overlay()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and not event.is_echo() and (event as InputEventKey).keycode == KEY_F7:
		toggle_fast_time()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and not event.is_echo() and (event as InputEventKey).keycode == KEY_F4:
		toggle_streaming_map()
		get_viewport().set_input_as_handled()


func console() -> DevConsole:
	return _console


## Shows or hides the streaming map; returns whether it's shown now.
func toggle_streaming_map() -> bool:
	if _map_layer == null:
		_map_layer = CanvasLayer.new()
		_map_layer.layer = 126
		_map = StreamingMap.new()
		_map.name = "StreamingMap"
		_map_layer.add_child(_map)
		add_child(_map_layer)
	else:
		_map_layer.visible = not _map_layer.visible
	_map.set_process(_map_layer.visible)
	return _map_layer.visible


## Runs every world clock a game hour per real second, or back at normal
## speed. Returns whether time now runs fast.
func toggle_fast_time() -> bool:
	var fast := false
	for node in get_tree().get_nodes_in_group(&"world_clocks"):
		var clock := node as WorldClock
		fast = is_equal_approx(clock.speed, 1.0)
		clock.speed = FAST_HOURS_PER_SECOND / clock.game_hours_per_second() if fast else 1.0
	return fast


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var where := camera.global_position if camera else Vector3.ZERO
	_overlay_label.text = "\n".join([
		"%d fps   process %.1f ms   physics %.1f ms" % [
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		],
		"%d draw calls   %d primitives   %d objects" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		],
		"%d nodes   video %.0f MB   static %.0f MB" % [
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		],
		"camera %.1f, %.1f, %.1f" % [where.x, where.y, where.z],
	])


## Saves the window's current frame as a PNG at `path` (absolute or res://).
func save_screenshot(path: String) -> Error:
	if DisplayServer.get_name() == "headless":
		push_error("[DevTools] screenshots need a window; headless runs cannot render")
		return ERR_UNAVAILABLE
	var image := get_viewport().get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error == OK:
		print("[DevTools] screenshot saved: ", absolute_path)
	else:
		push_error("[DevTools] could not save %s: %s" % [absolute_path, error_string(error)])
	return error


func _capture_and_quit(options: Options) -> void:
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if options.has_shot_player and scene and scene.has_method(&"player"):
		var player := scene.call(&"player") as Node3D
		player.global_position = options.shot_player
	if options.shot_hold != &"" and InputMap.has_action(options.shot_hold):
		Input.action_press(options.shot_hold)
	for i in options.shot_frames:
		await get_tree().process_frame
	if options.has_shot_camera and get_tree().current_scene is Node3D:
		var camera := Camera3D.new()
		get_tree().current_scene.add_child(camera)
		camera.global_position = options.shot_camera
		camera.look_at(options.shot_look)
		camera.make_current()
		await get_tree().process_frame
	await _streaming_settled()
	await RenderingServer.frame_post_draw
	var error := save_screenshot(options.shot_path)
	get_tree().quit(0 if error == OK else 1)


## Waits, up to a few seconds, until every sector streamer has loaded what
## the camera can see.
func _streaming_settled() -> void:
	for i in 600:
		var settled := true
		for streamer in get_tree().get_nodes_in_group(&"sector_streamers"):
			settled = settled and bool(streamer.call(&"is_settled"))
		if settled:
			return
		await get_tree().process_frame


func _hotkey_shot_path() -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var folder := "res://.shots" if OS.has_feature("editor") else "user://shots"
	return folder.path_join("shot-%s.png" % stamp)


func _toggle_overlay() -> void:
	if _overlay_layer == null:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.layer = 128
		_overlay_label = Label.new()
		_overlay_label.position = Vector2(12.0, 8.0)
		_overlay_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_overlay_label.add_theme_constant_override("outline_size", 4)
		_overlay_layer.add_child(_overlay_label)
		add_child(_overlay_layer)
	else:
		_overlay_layer.visible = not _overlay_layer.visible
	set_process(_overlay_layer.visible)
