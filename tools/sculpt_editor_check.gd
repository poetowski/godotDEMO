extends RefCounted
## Runs inside the real editor (`npm run sculpt-check`): selects the terrain,
## drags the brush with made-up mouse events, undoes, screenshots the editor
## into .shots/ and quits with 0 if the ground did what the brush said. Saves
## to user://, leaving the project's sculpted ground alone.

const FOLDER := "user://sculpt_check"

var _plugin: EditorPlugin
var _failures: Array[String] = []


func run(plugin: EditorPlugin) -> void:
	_plugin = plugin
	TerrainSculpt.folder = FOLDER
	TerrainSculpt.start_empty()
	_steps.call_deferred()


func _steps() -> void:
	var tree := _plugin.get_tree()
	await tree.create_timer(6.0).timeout
	var scene := EditorInterface.get_edited_scene_root()
	if scene == null or scene.get_node_or_null("Terrain") == null:
		EditorInterface.open_scene_from_path("res://src/world/field/field.tscn")
		await tree.create_timer(12.0).timeout
	var terrain := _plugin.call(&"find_terrain") as FieldTerrain
	_expect(terrain != null, "the field's terrain is found")
	if terrain == null:
		_finish()
		return
	EditorInterface.set_main_screen_editor("3D")
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(terrain)
	await tree.create_timer(1.0).timeout
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	var spot := Vector2(130.0, -70.0)
	await tree.create_timer(5.0).timeout
	_shot("sculpt_1_before")
	var brush: SculptBrush = _plugin.get(&"brush")
	brush.tool = SculptBrush.Tool.RAISE
	brush.radius = 10.0
	brush.strength = 8.0
	var before := WorldShape.height(spot)
	await _drag(camera, spot, spot, 1.0)
	var raised := WorldShape.height(spot)
	_expect(raised > before + 2.0, "a stroke raised the ground (%.2f -> %.2f)" % [before, raised])
	_expect(FileAccess.file_exists(TerrainSculpt.tile_path(Vector2i(1, 0))), "the stroke was saved")
	await tree.create_timer(1.5).timeout
	var chunks := terrain.chunks()
	_expect(chunks != null and is_equal_approx(chunks.step_at(spot), 1.0), "the ground under the brush is 1 m tiles")
	_shot("sculpt_2_raised")
	# A trench, screenshotted while it's being dug, so the live update shows.
	brush.tool = SculptBrush.Tool.LOWER
	brush.radius = 4.0
	var from := spot + Vector2(-18.0, 20.0)
	var to := from + Vector2(30.0, 0.0)
	await _drag(camera, from, to, 2.0, true)
	_shot("sculpt_3_digging")
	_button(camera, to, false)
	await tree.create_timer(2.0).timeout
	var dug := from.lerp(to, 0.5)
	_expect(WorldShape.height(dug) < WorldShape.base_height(dug) - 1.0, "dragging the lower brush dug a trench")
	_shot("sculpt_4_dug")
	var undo := _plugin.get_undo_redo()
	var history := undo.get_history_undo_redo(undo.get_object_history_id(EditorInterface.get_edited_scene_root()))
	var count := 0
	while history.has_undo() and count < 2:
		history.undo()
		count += 1
	_expect(count == 2, "both strokes are in the undo history")
	_expect(absf(WorldShape.height(spot) - before) < 0.001, "undo put the ground back")
	_expect(not FileAccess.file_exists(TerrainSculpt.tile_path(Vector2i(1, 0))), "undo removed the emptied tile")
	await tree.create_timer(2.0).timeout
	_shot("sculpt_5_undone")
	_finish()


## Presses at `from` and moves to `to` over `seconds`; releases unless `hold`.
func _drag(camera: Camera3D, from: Vector2, to: Vector2, seconds: float, hold: bool = false) -> void:
	_button(camera, from, true)
	var started := Time.get_ticks_msec()
	while true:
		var t := (Time.get_ticks_msec() - started) / (seconds * 1000.0)
		var motion := InputEventMouseMotion.new()
		motion.position = _screen(camera, from.lerp(to, minf(t, 1.0)))
		_plugin.call(&"_forward_3d_gui_input", camera, motion)
		if t >= 1.0:
			break
		await _plugin.get_tree().process_frame
	if not hold:
		_button(camera, to, false)


func _button(camera: Camera3D, at: Vector2, pressed: bool) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = pressed
	press.position = _screen(camera, at)
	_plugin.call(&"_forward_3d_gui_input", camera, press)


func _screen(camera: Camera3D, xz: Vector2) -> Vector2:
	return camera.unproject_position(Vector3(xz.x, WorldShape.height(xz), xz.y))


func _shot(file: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://.shots")
	var image := EditorInterface.get_base_control().get_viewport().get_texture().get_image()
	image.save_png("res://.shots/%s.png" % file)


func _expect(ok: bool, what: String) -> void:
	print("sculpt-check: %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		_failures.append(what)


func _finish() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	for file in DirAccess.get_files_at(FOLDER):
		DirAccess.remove_absolute(FOLDER.path_join(file))
	print("sculpt-check: %s" % ("passed" if _failures.is_empty() else "%d failed" % _failures.size()))
	# With the terrain selected, the inspector logs an error while quitting.
	EditorInterface.get_selection().clear()
	await _plugin.get_tree().process_frame
	_plugin.get_tree().quit(0 if _failures.is_empty() else 1)
