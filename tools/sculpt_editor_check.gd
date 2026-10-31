extends RefCounted
## Runs inside the real editor (`npm run sculpt-check`): selects the terrain,
## drags the brush with made-up mouse events, undoes, screenshots the editor
## into .shots/ and quits with 0 if the ground did what the brush said, then the
## same for the Paint tab. Saves to user://, leaving the project's sculpted and
## painted ground alone.

const FOLDER := "user://sculpt_check"
const PAINT_FOLDER := "user://paint_check"

var _plugin: EditorPlugin
var _failures: Array[String] = []


func run(plugin: EditorPlugin) -> void:
	_plugin = plugin
	TerrainSculpt.folder = FOLDER
	TerrainSculpt.start_empty()
	TerrainPaint.folder = PAINT_FOLDER
	TerrainPaint.start_empty()
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
	# Its own camera straight above open ground in R1, so strokes land where they
	# should wherever the author last left the editor's view.
	var spot := Vector2(100.0, -150.0)
	var camera := Camera3D.new()
	EditorInterface.get_editor_viewport_3d(0).add_child(camera)
	camera.global_position = Vector3(spot.x, 90.0, spot.y)
	camera.global_rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	var looked_at := terrain.ground_hit(camera.project_ray_origin(_screen(camera, spot)), camera.project_ray_normal(_screen(camera, spot)))
	_expect(looked_at != Vector3.INF, "the view looks at the ground")
	if looked_at == Vector3.INF:
		_finish()
		return
	var tile := Vector2i(floori(spot.x / TerrainSculpt.TILE), floori(-spot.y / TerrainSculpt.TILE))
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
	_expect(FileAccess.file_exists(TerrainSculpt.tile_path(tile)), "the stroke was saved")
	await tree.create_timer(1.5).timeout
	var chunks := terrain.chunks()
	_expect(chunks != null and is_equal_approx(chunks.step_at(spot), 1.0), "the ground under the brush is 1 m tiles")
	_shot("sculpt_2_raised")
	# A trench, screenshotted while it's being dug, so the live update shows.
	brush.tool = SculptBrush.Tool.LOWER
	brush.radius = 4.0
	var from := spot + Vector2(-12.0, 16.0)
	var to := from + Vector2(24.0, 0.0)
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
	_expect(not FileAccess.file_exists(TerrainSculpt.tile_path(tile)), "undo removed the emptied tile")
	await tree.create_timer(2.0).timeout
	_shot("sculpt_5_undone")
	await _check_painting(camera, spot, tile, history)
	await _check_moving_the_fog()
	_finish()


func _check_painting(camera: Camera3D, spot: Vector2, tile: Vector2i, history: UndoRedo) -> void:
	var tree := _plugin.get_tree()
	var height := WorldShape.height(spot)
	var sample := Vector2i(roundi(spot.x), roundi(-spot.y))
	_plugin.call(&"set_mode", 1)
	await tree.process_frame
	var tabs := _plugin.get(&"_tabs") as TabContainer
	_expect(tabs.visible and tabs.current_tab == 1, "the Paint tab opens beside the view")
	var brush: PaintBrush = _plugin.get(&"paint_brush")
	brush.surface = 6
	brush.radius = 5.0
	await _drag(camera, spot + Vector2(-10.0, 0.0), spot + Vector2(10.0, 0.0), 1.5)
	_expect(TerrainPaint.share(sample.x, sample.y, 6) > 0.9, "a stroke laid cobbles")
	_expect(FileAccess.file_exists(TerrainPaint.tile_path(tile)), "the stroke was saved")
	_expect(WorldShape.height(spot) == height, "painting left the land alone")
	await tree.create_timer(1.0).timeout
	_shot("paint_1_painted")
	history.undo()
	_expect(TerrainPaint.is_empty(), "undo took the paint away")
	_expect(not FileAccess.file_exists(TerrainPaint.tile_path(tile)), "undo removed the emptied tile")
	_plugin.call(&"set_mode", 0)
	_expect(tabs.current_tab == 0, "back to the Sculpt tab")


## Dragging one of the fog's points in the editor moves the fog, without saving.
func _check_moving_the_fog() -> void:
	var barrier := EditorInterface.get_edited_scene_root().get_node("MistBarrier") as MistBarrier
	var marker := barrier.get_node("FogLine").get_child(22) as Node3D
	var was := marker.position
	var spot := Vector2(was.x + 15.0, was.z)
	_expect(barrier.depth_at(spot) == 0.0, "no fog east of the fog's line")
	marker.position.x += 40.0
	await _plugin.get_tree().create_timer(1.0).timeout
	_expect(barrier.depth_at(spot) > 0.0, "moving a point moved the fog")
	marker.position = was
	await _plugin.get_tree().create_timer(1.0).timeout
	_expect(barrier.depth_at(spot) == 0.0, "moving it back moved the fog back")
	_shot("fog_1_points")


## Presses at `from` and moves to `to` over `seconds`; releases unless `hold`.
func _drag(camera: Camera3D, from: Vector2, to: Vector2, seconds: float, hold: bool = false) -> void:
	_button(camera, from, true)
	var started := Time.get_ticks_msec()
	var frames := 0
	while true:
		var t := (Time.get_ticks_msec() - started) / (seconds * 1000.0)
		var motion := InputEventMouseMotion.new()
		motion.position = _screen(camera, from.lerp(to, minf(t, 1.0)))
		_plugin.call(&"_forward_3d_gui_input", camera, motion)
		if t >= 1.0:
			break
		await _plugin.get_tree().process_frame
		frames += 1
	print("sculpt-check: %d frames in a drag of %.1f s" % [frames, seconds])
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
	DirAccess.make_dir_recursive_absolute(PAINT_FOLDER)
	for file in DirAccess.get_files_at(PAINT_FOLDER):
		DirAccess.remove_absolute(PAINT_FOLDER.path_join(file))
	print("sculpt-check: %s" % ("passed" if _failures.is_empty() else "%d failed" % _failures.size()))
	# With the terrain selected, the inspector logs an error while quitting.
	EditorInterface.get_selection().clear()
	await _plugin.get_tree().process_frame
	_plugin.get_tree().quit(0 if _failures.is_empty() else 1)
