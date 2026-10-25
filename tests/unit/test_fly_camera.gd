extends GutTest

const ACTIONS: Array[StringName] = [&"move_forward", &"dev_fly_up", &"dev_fly_fast"]


func after_each() -> void:
	for action in ACTIONS:
		Input.action_release(action)


func test_moves_forward_along_negative_z() -> void:
	var camera := FlyCamera.new()
	add_child_autofree(camera)
	Input.action_press(&"move_forward")
	await wait_process_frames(5)
	assert_lt(camera.position.z, 0.0)
	assert_almost_eq(camera.position.x, 0.0, 0.001)


func test_rises_with_fly_up() -> void:
	var camera := FlyCamera.new()
	add_child_autofree(camera)
	Input.action_press(&"dev_fly_up")
	await wait_process_frames(5)
	assert_gt(camera.position.y, 0.0)


func test_stays_put_without_input() -> void:
	var camera := FlyCamera.new()
	add_child_autofree(camera)
	await wait_process_frames(5)
	assert_eq(camera.position, Vector3.ZERO)
