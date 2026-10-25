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


func test_ignores_unknown_args() -> void:
	var options := DevToolsScript.parse_args(PackedStringArray(["--verbose", "level=3"]))
	assert_eq(options.shot_path, "")
