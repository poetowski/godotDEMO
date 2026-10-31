@tool
extends EditorPlugin
## Sculpting the field's ground by hand. Select the Terrain node, or press
## Sculpt in the 3D view's toolbar, and paint with the left mouse button; the
## panel beside the view picks the brush. Strokes change TerrainSculpt, saved
## after each one, so the game and the design tools get them through WorldShape.
##
## It also keeps the streamed ground around whatever the 3D view looks at, while
## any scene with a chunked FieldTerrain is open.

const PANEL := preload("res://addons/terrain_sculpt/sculpt_panel.gd")
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

## The terrain being sculpted, null when not sculpting.
var _terrain: FieldTerrain
var _panel: PanelContainer
var _toolbar_button: Button
var _camera: Camera3D
var _mouse := Vector2.ZERO
var _hit := Vector3.INF
var _stroking := false
var _before: Dictionary[Vector2i, PackedFloat32Array] = {}
var _stroke_area := Rect2i()
var _pending_design_area := Rect2i()
var _focus_timer := 0.0
var _design_timer := 0.0
## The running editor check, kept alive while it awaits.
var _check: RefCounted


func _enter_tree() -> void:
	_panel = PANEL.new(brush)
	_panel.visible = false
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _panel)
	_toolbar_button = Button.new()
	_toolbar_button.text = "Sculpt"
	_toolbar_button.tooltip_text = "Sculpt the terrain (selects the Terrain node)"
	_toolbar_button.toggle_mode = true
	_toolbar_button.flat = true
	_toolbar_button.pressed.connect(_toggle_sculpting)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar_button)
	set_force_draw_over_forwarding_enabled()
	if CHECK_ARG in OS.get_cmdline_user_args():
		_check = (load("res://tools/sculpt_editor_check.gd") as GDScript).new()
		_check.call(&"run", self)


func _exit_tree() -> void:
	if _stroking:
		_end_stroke()
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _panel)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar_button)
	_panel.queue_free()
	_toolbar_button.queue_free()


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
	_panel.visible = visible
	_toolbar_button.set_pressed_no_signal(visible)
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
	_draw_ring(overlay, brush.radius, color, 2.0)
	if brush.softness > 0.05 and brush.softness < 0.95:
		_draw_ring(overlay, brush.radius * (1.0 - brush.softness), Color(color, 0.45), 1.0)


## The terrain a sculpting session would use in the open scene, or null.
func find_terrain() -> FieldTerrain:
	var scene := EditorInterface.get_edited_scene_root()
	return scene.get_node_or_null("Terrain") as FieldTerrain if scene else null


func _toggle_sculpting() -> void:
	var selection := EditorInterface.get_selection()
	selection.clear()
	if _toolbar_button.button_pressed:
		var terrain := find_terrain()
		if terrain:
			selection.add_node(terrain)
		else:
			_toolbar_button.set_pressed_no_signal(false)


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
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			brush.tool = (event.keycode - KEY_1) as SculptBrush.Tool
			_panel.call(&"refresh")
			update_overlays()
		_:
			return AFTER_GUI_INPUT_PASS
	return AFTER_GUI_INPUT_STOP


func _resize(factor: float) -> void:
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


func _end_stroke() -> void:
	_stroking = false
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
