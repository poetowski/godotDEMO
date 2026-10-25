extends GutTest
## The sandbox loads, shows through its own camera and has solid ground.

const SANDBOX_PATH := "res://src/world/sandbox/sandbox.tscn"


func _spawn_sandbox() -> Node3D:
	var sandbox := (load(SANDBOX_PATH) as PackedScene).instantiate() as Node3D
	add_child_autofree(sandbox)
	return sandbox


func test_uses_its_own_camera() -> void:
	var sandbox := _spawn_sandbox()
	await wait_process_frames(1)
	var camera := sandbox.get_viewport().get_camera_3d()
	assert_not_null(camera)
	assert_true(sandbox.is_ancestor_of(camera), "the active camera belongs to the sandbox")


func test_ground_is_solid_at_height_zero() -> void:
	var sandbox := _spawn_sandbox()
	await wait_physics_frames(2)
	var query := PhysicsRayQueryParameters3D.create(Vector3(20.0, 10.0, 20.0), Vector3(20.0, -10.0, 20.0))
	var hit := sandbox.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "a ray straight down hits the ground")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 0.0, 0.01)
