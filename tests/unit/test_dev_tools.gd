extends GutTest

const DevToolsScript := preload("res://src/autoload/dev_tools.gd")


func test_no_user_args_means_no_screenshot() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray())
	assert_eq(options.shot_path, "")
	assert_eq(options.shot_frames, DevToolsScript.DEFAULT_SHOT_FRAMES)


func test_reads_shot_path_and_frames() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--shot=C:/shots/a.png", "--shot-frames=12"]))
	assert_eq(options.shot_path, "C:/shots/a.png")
	assert_eq(options.shot_frames, 12)


func test_waits_at_least_one_frame() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--shot-frames=0"]))
	assert_eq(options.shot_frames, 1)


func test_reads_a_shot_camera_and_target() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--shot-camera=1,2.5,-3", "--shot-look=0,1,0"]))
	assert_true(options.has_shot_camera)
	assert_eq(options.shot_camera, Vector3(1.0, 2.5, -3.0))
	assert_eq(options.shot_look, Vector3(0.0, 1.0, 0.0))


func test_no_shot_camera_by_default() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--shot=a.png"]))
	assert_false(options.has_shot_camera)


func test_ignores_unknown_args() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--verbose", "level=3"]))
	assert_eq(options.shot_path, "")


func test_frames_sectors_from_above_their_long_side() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--shot-frame=A1:A3"]))
	assert_true(options.has_shot_camera)
	assert_eq(options.shot_look, Vector3(5.0, 0.0, -15.0))
	assert_gt(options.shot_camera.y, 10.0, "above")
	assert_gt(options.shot_camera.x, 10.0, "east of the north-south strip")


func test_unknown_sectors_frame_nothing() -> void:
	assert_true(DevToolsScript.frame_view("Z9").is_empty())
	assert_false(DevToolsScript.parse_args(PackedStringArray(["--shot-frame=Z9"])).has_shot_camera)
