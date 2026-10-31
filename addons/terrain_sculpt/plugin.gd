@tool
extends EditorPlugin
## Sculpting and painting the field's ground by hand. Select the Terrain node, or
## press Sculpt or Paint in the 3D view's toolbar, and work with the left mouse
## button; the tabs beside the view pick the brush. Sculpt strokes change
## TerrainSculpt, so the game and the design tools get them through WorldShape;
## paint strokes change TerrainPaint. Both are saved after each stroke.
##
## It also keeps the streamed ground around whatever the 3D view looks at, while
## any scene with a chunked FieldTerrain is open.

enum Mode { SCULPT, PAINT }

const PANEL := preload("res://addons/terrain_sculpt/sculpt_panel.gd")
const PAINT_PANEL := preload("res://addons/terrain_sculpt/paint_panel.gd")
const CHECK_ARG := "--sculpt-check"
## Seconds between moves of the streamed ground's focus.
const FOCUS_INTERVAL := 0.25
## Seconds between remaking designed sectors during a stroke; they cost more
## than the open ground.
const DESIGN_INTERVAL := 0.25
## Points around the brush's outline.
const RING_POINTS := 64
const SIZE_STEP := 1.1

var brush := SculptBrush.new()
var paint_brush := PaintBrush.new()
var mode: Mode = Mode.SCULPT

## The terrain being sculpted, null when not sculpting.
var _terrain: FieldTerrain
var _tabs: TabContainer
var _panel: PanelContainer
var _paint_panel: PanelContainer
var _toolbar_button: Button
var _paint_button: Button
var _camera: Camera3D
var _mouse := Vector2.ZERO
var _hit := Vector3.INF
var _stroking := false
var _before: Dictionary[Vector2i, PackedFloat32Array] = {}
var _paint_before: Dictionary[Vector2i, PackedByteArray] = {}
var _stroke_area := Rect2i()
var _pending_design_area := Rect2i()
var _focus_timer := 0.0
var _design_timer := 0.0
## The running editor check, kept alive while it awaits.
var _check: RefCounted


func _enter_tree() -> void:
	_tabs = TabContainer.new()
	_tabs.visible = false
	_panel = PANEL.new(brush)
	_panel.name = "Sculpt"
	_tabs.add_child(_panel)
	_paint_panel = PAINT_PANEL.new(paint_brush)
	_paint_panel.name = "Paint"
	_tabs.add_child(_paint_panel)
	_tabs.tab_changed.connect(_on_tab_changed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _tabs)
	_toolbar_button = _make_toolbar_button("Sculpt", "Sculpt the terrain (selects the Terrain node)", Mode.SCULPT)
	_paint_button = _make_toolbar_button("Paint", "Paint the terrain (selects the Terrain node)", Mode.PAINT)
	set_force_draw_over_forwarding_enabled()
	if CHECK_ARG in OS.get_cmdline_user_args():
		_check = (load("res://tools/sculpt_editor_check.gd") as GDScript).new()
		_check.call(&"run", self)


func _exit_tree() -> void:
	if _stroking:
		_end_stroke()
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _tabs)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar_button)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _paint_button)
	_tabs.queue_free()
	_toolbar_button.queue_free()
	_paint_button.queue_free()


func _handles(object: Object) -> bool:
	return object is FieldTerrain


func _edit(object: Object) -> void:
	if _stroking:
		_end_stroke()
	_terrain = object as FieldTerrain
	if _terrain == null:
		_hit = Vector3.INF
	update_overlays()


func _make_visible(visible: bool) -> void:
	_tabs.visible = visible
	_show_mode()
	if not visible:
		_toolbar_button.set_pressed_no_signal(false)
		_paint_button.set_pressed_no_signal(false)
	if not visible:
		_edit(null)


func _process(delta: float) -> void:
	_focus_timer -= delta
	if _focus_timer <= 0.0:
		_focus_timer = FOCUS_INTERVAL
		_follow_view()
	if _stroking:
		_paint(minf(delta, 0.1))


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if _terrain == null:
		return AFTER_GUI_INPUT_PASS
	_camera = camera
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		_update_hit()
		update_overlays()
		return AFTER_GUI_INPUT_STOP if _stroking else AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton:
		return _on_mouse_button(event as InputEventMouseButton)
	if event is InputEventKey:
		return _on_key(event as InputEventKey)
	return AFTER_GUI_INPUT_PASS


func _forward_3d_force_draw_over_viewport(overlay: Control) -> void:
	if _terrain == null or _camera == null or _hit == Vector3.INF:
		return
	var moves_land := brush.tool == SculptBrush.Tool.RAISE or brush.tool == SculptBrush.Tool.LOWER
	var color := Color(1.0, 0.85, 0.35) if moves_land else Color(0.5, 0.9, 1.0)
	var radius := brush.radius
	var softness := brush.softness
	if mode == Mode.PAINT:
		color = Color(1.0, 0.45, 0.45) if paint_brush.surface == TerrainPaint.ERASE else TerrainPaint.SWATCHES[paint_brush.surface].lightened(0.35)
		radius = paint_brush.radius
		softness = paint_brush.softness
	_draw_ring(overlay, radius, color, 2.0)
	if softness > 0.05 and softness < 0.95:
		_draw_ring(overlay, radius * (1.0 - softness), Color(color, 0.45), 1.0)


## The terrain a sculpting session would use in the open scene, or null.
func find_terrain() -> FieldTerrain:
	var scene := EditorInterface.get_edited_scene_root()
	return scene.get_node_or_null("Terrain") as FieldTerrain if scene else null


## Opens a tab, ending any stroke under way.
func set_mode(new_mode: Mode) -> void:
	if _stroking:
		_end_stroke()
	mode = new_mode
	_show_mode()
	update_overlays()


func _make_toolbar_button(text: String, tooltip: String, for_mode: Mode) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.toggle_mode = true
	button.flat = true
	button.pressed.connect(_on_toolbar_button.bind(button, for_mode))
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button)
	return button


## Pressing the other mode's button changes tab; pressing the lit one stops.
func _on_toolbar_button(button: Button, for_mode: Mode) -> void:
	var selection := EditorInterface.get_selection()
	if not button.button_pressed:
		selection.clear()
		return
	set_mode(for_mode)
	if _terrain:
		return
	var terrain := find_terrain()
	if terrain:
		selection.clear()
		selection.add_node(terrain)
	else:
		button.set_pressed_no_signal(false)


func _on_tab_changed(tab: int) -> void:
	if int(mode) != tab:
		set_mode(tab as Mode)


## The tab and the toolbar show the mode.
func _show_mode() -> void:
	_tabs.set_current_tab(int(mode))
	_toolbar_button.set_pressed_no_signal(_tabs.visible and mode == Mode.SCULPT)
	_paint_button.set_pressed_no_signal(_tabs.visible and mode == Mode.PAINT)


func _on_mouse_button(event: InputEventMouseButton) -> int:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.position
		_update_hit()
		if event.pressed:
			if _hit == Vector3.INF or event.alt_pressed:
				return AFTER_GUI_INPUT_PASS
			_begin_stroke()
		elif _stroking:
			_end_stroke()
		return AFTER_GUI_INPUT_STOP
	if event.ctrl_pressed and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_resize(SIZE_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / SIZE_STEP)
		return AFTER_GUI_INPUT_STOP
	return AFTER_GUI_INPUT_PASS


func _on_key(event: InputEventKey) -> int:
	if not event.pressed or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return AFTER_GUI_INPUT_PASS
	match event.keycode:
		KEY_BRACKETLEFT:
			_resize(1.0 / SIZE_STEP)
		KEY_BRACKETRIGHT:
			_resize(SIZE_STEP)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_0:
			return _pick_by_key(event.keycode)
		_:
			return AFTER_GUI_INPUT_PASS
	return AFTER_GUI_INPUT_STOP


## A number picks a surface or a sculpting tool; keys with no tool pass through.
func _pick_by_key(keycode: int) -> int:
	if mode == Mode.PAINT:
		paint_brush.surface = TerrainPaint.ERASE if keycode == KEY_0 else keycode - KEY_1
		_paint_panel.call(&"refresh")
	elif keycode >= KEY_1 and keycode <= KEY_5:
		brush.tool = (keycode - KEY_1) as SculptBrush.Tool
		_panel.call(&"refresh")
	else:
		return AFTER_GUI_INPUT_PASS
	update_overlays()
	return AFTER_GUI_INPUT_STOP


func _resize(factor: float) -> void:
	if mode == Mode.PAINT:
		paint_brush.radius = clampf(paint_brush.radius * factor, PaintBrush.MIN_RADIUS, PaintBrush.MAX_RADIUS)
		_paint_panel.call(&"refresh")
	else:
		brush.radius = clampf(brush.radius * factor, SculptBrush.MIN_RADIUS, SculptBrush.MAX_RADIUS)
		_panel.call(&"refresh")
	update_overlays()


func _update_hit() -> void:
	if _camera == null or _terrain == null:
		_hit = Vector3.INF
		return
	_hit = _terrain.ground_hit(_camera.project_ray_origin(_mouse), _camera.project_ray_normal(_mouse))


func _begin_stroke() -> void:
	_stroking = true
	_before = {}
	_paint_before = {}
	_stroke_area = Rect2i()
	_pending_design_area = Rect2i()
	_design_timer = DESIGN_INTERVAL
	brush.flatten_height = WorldShape.height(Vector2(_hit.x, _hit.z))
	_paint(1.0 / 60.0)


func _paint(delta: float) -> void:
	_update_hit()
	if _hit == Vector3.INF:
		return
	var xz := Vector2(_hit.x, _hit.z)
	if mode == Mode.PAINT:
		_lay_paint(xz, delta)
		return
	var missing: Array[Vector2i] = []
	for key in TerrainSculpt.tiles_in(brush.area_at(xz)):
		if not _before.has(key):
			missing.append(key)
	_before.merge(TerrainSculpt.snapshot(missing))
	var area := brush.apply(xz, delta, Input.is_key_pressed(KEY_SHIFT))
	if not area.has_area():
		return
	_stroke_area = _stroke_area.merge(area) if _stroke_area.has_area() else area
	_pending_design_area = _pending_design_area.merge(area) if _pending_design_area.has_area() else area
	_terrain.reshape_ground(area, false)
	_design_timer -= delta
	if _design_timer <= 0.0:
		_design_timer = DESIGN_INTERVAL
		_terrain.reshape_ground(_pending_design_area, true)
		_pending_design_area = Rect2i()
	update_overlays()


func _lay_paint(xz: Vector2, delta: float) -> void:
	var missing: Array[Vector2i] = []
	for key in TerrainSculpt.tiles_in(paint_brush.area_at(xz)):
		if not _paint_before.has(key):
			missing.append(key)
	_paint_before.merge(TerrainPaint.snapshot(missing))
	paint_brush.apply(xz, delta, Input.is_key_pressed(KEY_SHIFT))
	update_overlays()


func _end_stroke() -> void:
	_stroking = false
	if not _paint_before.is_empty():
		_end_paint_stroke()
		return
	if _before.is_empty() or not _stroke_area.has_area():
		return
	var keys: Array[Vector2i] = []
	keys.assign(_before.keys())
	var after := TerrainSculpt.snapshot(keys)
	_save(keys)
	if _terrain:
		_terrain.finish_reshaping(_stroke_area)
	var undo := get_undo_redo()
	undo.create_action("Sculpt terrain", UndoRedo.MERGE_DISABLE, EditorInterface.get_edited_scene_root(), false, false)
	undo.add_do_method(self, &"_put_back", after, _stroke_area)
	undo.add_undo_method(self, &"_put_back", _before, _stroke_area)
	undo.commit_action(false)
	_before = {}


func _end_paint_stroke() -> void:
	var keys: Array[Vector2i] = []
	keys.assign(_paint_before.keys())
	_save_paint(keys)
	var undo := get_undo_redo()
	undo.create_action("Paint terrain", UndoRedo.MERGE_DISABLE, EditorInterface.get_edited_scene_root(), false, false)
	undo.add_do_method(self, &"_put_back_paint", TerrainPaint.snapshot(keys))
	undo.add_undo_method(self, &"_put_back_paint", _paint_before)
	undo.commit_action(false)
	_paint_before = {}


## Undo and redo of painting: tiles as they were, saved.
func _put_back_paint(tiles: Dictionary) -> void:
	var typed: Dictionary[Vector2i, PackedByteArray] = {}
	typed.assign(tiles)
	TerrainPaint.restore(typed)
	var keys: Array[Vector2i] = []
	keys.assign(typed.keys())
	_save_paint(keys)


func _save_paint(keys: Array[Vector2i]) -> void:
	var error := TerrainPaint.save(keys)
	if error != OK:
		push_error("Terrain Paint: could not save: %s" % error_string(error))


## Undo and redo: tiles as they were, saved, and the ground following.
func _put_back(tiles: Dictionary, area: Rect2i) -> void:
	var typed: Dictionary[Vector2i, PackedFloat32Array] = {}
	typed.assign(tiles)
	TerrainSculpt.restore(typed)
	var keys: Array[Vector2i] = []
	keys.assign(typed.keys())
	_save(keys)
	var terrain := _terrain if _terrain else find_terrain()
	if terrain:
		terrain.finish_reshaping(area)
	update_overlays()


func _save(keys: Array[Vector2i]) -> void:
	var error := TerrainSculpt.save(keys)
	if error != OK:
		push_error("Terrain Sculpt: could not save: %s" % error_string(error))


## Keeps the streamed ground detailed where the 3D view looks, or at the brush.
func _follow_view() -> void:
	var terrain := find_terrain()
	if terrain == null or terrain.view_focus() == null:
		return
	if _hit != Vector3.INF and _terrain:
		terrain.move_view_focus(_hit)
		return
	var viewport := EditorInterface.get_editor_viewport_3d(0)
	var camera := viewport.get_camera_3d() if viewport else null
	if camera == null:
		return
	var forward := -camera.global_basis.z
	var looked_at := terrain.ground_hit(camera.global_position, forward, 800.0)
	terrain.move_view_focus(camera.global_position if looked_at == Vector3.INF else looked_at)


## The brush's outline lying on the ground, drawn over the view.
func _draw_ring(overlay: Control, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for k in RING_POINTS + 1:
		var angle := TAU * k / RING_POINTS
		var xz := Vector2(_hit.x + cos(angle) * radius, _hit.z + sin(angle) * radius)
		var point := Vector3(xz.x, _terrain.height_at(xz), xz.y)
		if _camera.is_position_behind(point):
			if points.size() >= 2:
				overlay.draw_polyline(points, color, width, true)
			points = PackedVector2Array()
			continue
		points.append(_camera.unproject_position(point))
	if points.size() >= 2:
		overlay.draw_polyline(points, color, width, true)
