extends SceneTree
## Renders an asset (assets/models/props/<slug>/<slug>.glb) in Godot for
## `npm run asset-preview -- <slug>`: on a grey floor in daylight, next to a
## 1.8 m figure for scale, from the front-left, the side and close up;
## writes .shots/assets/<slug>_front.png, _side.png and _close.png. Also
## prints its size and whether it brought its collision.

const FIGURE_HEIGHT := 1.8


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_run(OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "")


func _run(slug: String) -> void:
	var path := "res://assets/models/props/%s/%s.glb" % [slug, slug]
	if slug.is_empty() or not ResourceLoader.exists(path):
		push_error("[preview] no asset at %s" % path)
		quit(1)
		return
	_stage()
	var asset := (load(path) as PackedScene).instantiate() as Node3D
	root.add_child(asset)
	await process_frame
	var box := _bounds(asset)
	var figure := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = FIGURE_HEIGHT
	capsule.radius = 0.25
	figure.mesh = capsule
	# On the left of the front view, out of the side view's way.
	figure.position = Vector3(box.position.x - 0.6, FIGURE_HEIGHT * 0.5, 0.0)
	root.add_child(figure)
	var collision := not asset.find_children("*", "CollisionShape3D", true, false).is_empty()
	print("[preview] %s: %.2f x %.2f x %.2f m (x, height, z); collision: %s" % [slug, box.size.x, box.size.y, box.size.z, "yes" if collision else "NO"])
	var camera := Camera3D.new()
	camera.fov = 40.0
	root.add_child(camera)
	camera.current = true
	var centre := box.get_center()
	var reach := maxf(box.size.y, maxf(box.size.x, box.size.z)) * 1.6 + 1.0
	var views := {
		"front": Vector3(-0.55, 0.35, 1.0),
		"side": Vector3(1.0, 0.2, 0.15),
		"close": Vector3(-0.3, 0.15, 0.55),
	}
	var out := ProjectSettings.globalize_path("res://.shots/assets")
	DirAccess.make_dir_recursive_absolute(out)
	for view: String in views:
		var offset: Vector3 = views[view]
		var distance := reach * (0.55 if view == "close" else 1.0)
		var look := centre + (Vector3.UP * box.size.y * 0.15 if view == "close" else Vector3.ZERO)
		camera.look_at_from_position(look + offset.normalized() * distance, look)
		for k in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%s_%s.png" % [slug, view]))
	print("[preview] wrote %s" % out.path_join(slug + "_*.png"))
	quit()


## Daylight, a soft sky and a grey floor.
func _stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.6, 0.68, 0.76)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.77, 0.8)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.glow_enabled = true
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	floor_mesh.mesh = plane
	root.add_child(floor_mesh)


func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		var piece := mesh_instance.global_transform * mesh_instance.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	return box
