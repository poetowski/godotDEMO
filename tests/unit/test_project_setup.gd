extends GutTest
## Guards against project files losing what the game relies on, such as an
## editor that was open during a change saving its older copy over it.

const FIELD := "res://src/world/field/field.tscn"
const SECTORS := "res://src/world/field/sectors"


func test_every_input_action_exists() -> void:
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "interact", "attack", "inventory", "quick_save", "quick_load", "dev_screenshot", "dev_overlay"]:
		assert_true(InputMap.has_action(action), action)


func test_every_sector_design_is_in_the_field() -> void:
	assert_true(FileAccess.file_exists(FIELD))
	if not DirAccess.dir_exists_absolute(SECTORS):
		return
	var field := FileAccess.get_file_as_string(FIELD)
	for folder in DirAccess.get_directories_at(SECTORS):
		var script := "%s/%s/%s.gd" % [SECTORS, folder, folder]
		assert_true(field.contains(script), "%s is registered in the field" % folder)
