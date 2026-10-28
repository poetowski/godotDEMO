class_name StreamingMap
extends Control
## The streaming map, toggled with F4 or the console's `map`: the sector grid
## seen from above with each sector coloured by what the streamer holds of
## it, the hero as an arrow, the load and unload radius around the hero, and
## counts and memory beneath. North is up. Part of DevTools, so debug builds
## only; its text is for developers and isn't translated.

const CELL := 13.0
const LOADED := Color(0.35, 0.8, 0.4)
const LOADING := Color(0.95, 0.75, 0.2)
const DISTANT := Color(0.3, 0.5, 0.85)
const EMPTY := Color(0.22, 0.24, 0.28)
const BACKGROUND := Color(0.04, 0.05, 0.07, 0.85)

## The world shown; the current scene when unset.
var world: Node

var _stats: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	var side := CELL * SectorMap.COLUMNS
	custom_minimum_size = Vector2(side + 24.0, side + 150.0)
	size = custom_minimum_size
	position = Vector2(get_viewport_rect().size.x - size.x - 16.0, 70.0)
	_stats = Label.new()
	_stats.position = Vector2(12.0, side + 18.0)
	_stats.add_theme_font_size_override("font_size", 15)
	add_child(_stats)


func _process(_delta: float) -> void:
	position.x = get_viewport_rect().size.x - size.x - 16.0
	queue_redraw()
	_stats.text = _stats_text()


## What the streamer holds of a sector: &"loaded", &"loading", &"distant"
## (only the far model and ground stand-in) or &"empty" (no design).
func cell_state(cell: Vector2i) -> StringName:
	var field := _field()
	if field == null:
		return &"empty"
	var terrain := field.call("terrain") as FieldTerrain
	var streamer := field.call("streamer") as SectorStreamer
	var centre := SectorMap.center_of(cell)
	var design := terrain.design_at(Vector2(centre.x, centre.z))
	if design == null:
		return &"empty"
	if design.is_content_loaded():
		return &"loaded"
	if streamer.is_loading(design):
		return &"loading"
	return &"distant"


func _draw() -> void:
	var side := CELL * SectorMap.COLUMNS
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var origin := Vector2(12.0, 12.0)
	for column in SectorMap.COLUMNS:
		for row in SectorMap.ROWS:
			var cell := Vector2i(column, row)
			# Row 1 (A1) is at the bottom: north is up.
			var corner := origin + Vector2(column * CELL, (SectorMap.ROWS - 1 - row) * CELL)
			draw_rect(Rect2(corner + Vector2.ONE, Vector2.ONE * (CELL - 2.0)), _color(cell_state(cell)))
	var field := _field()
	if field == null:
		return
	var player := field.call("player") as Player
	var streamer := field.call("streamer") as SectorStreamer
	var at := player.global_position
	var dot := origin + Vector2(at.x / SectorMap.SIZE, SectorMap.ROWS + at.z / SectorMap.SIZE) * CELL
	for radius: int in [streamer.load_radius, streamer.unload_radius]:
		var reach := (radius + 0.5) * CELL
		draw_rect(Rect2(dot - Vector2.ONE * reach, Vector2.ONE * reach * 2.0), Color(1, 1, 1, 0.35 if radius == streamer.load_radius else 0.15), false, 1.0)
	var facing := player.facing()
	var ahead := Vector2(-sin(facing), -cos(facing))
	var across := Vector2(ahead.y, -ahead.x)
	draw_colored_polygon(PackedVector2Array([dot + ahead * 7.0, dot - ahead * 4.0 + across * 4.0, dot - ahead * 4.0 - across * 4.0]), Color.WHITE)
	draw_rect(Rect2(origin, Vector2.ONE * side), Color(1, 1, 1, 0.2), false, 1.0)


func _stats_text() -> String:
	var field := _field()
	if field == null:
		return "No field world here."
	var counts := {&"loaded": 0, &"loading": 0, &"distant": 0}
	for design in (field.call("terrain") as FieldTerrain).designs():
		var state := cell_state(design.cells()[0])
		counts[state] = int(counts.get(state, 0)) + 1
	return "\n".join([
		"designs %d loaded, %d loading," % [counts[&"loaded"], counts[&"loading"]],
		"%d distant" % counts[&"distant"],
		"memory %.0f MB   video %.0f MB" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		],
		"%d draw calls   %d fps" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			Engine.get_frames_per_second(),
		],
		"green loaded, yellow loading,",
		"blue distant view only",
	])


func _color(state: StringName) -> Color:
	match state:
		&"loaded":
			return LOADED
		&"loading":
			return LOADING
		&"distant":
			return DISTANT
	return EMPTY


func _world() -> Node:
	if world and is_instance_valid(world):
		return world
	return get_tree().current_scene if is_inside_tree() else null


func _field() -> Node:
	var found := _world()
	return found if found and found.has_method("teleport") else null
