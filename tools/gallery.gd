extends SceneTree
## Takes the pictures behind `npm run gallery`, into .shots/gallery/. It only looks: it starts the
## real world in a window, hides the borders, the HUD and the hero for this run, and saves nothing
## but PNGs. Shots and their text are in tools/gallery/gallery.json.
##
## User arguments (after --):
##   --models           photograph every model on a plain floor instead of the world
##   --only=a,b         only the shots whose id starts with one of these ("r1_", "aerial")

const WORLD := "res://src/world/field/field.tscn"
const LIST := "res://tools/gallery/gallery.json"
const OUT := "res://.shots/gallery"
const MODELS := "res://assets/models/props"
const HERO := "res://assets/models/hero/hero.glb"
const SETTLE_FRAMES := 40
## Metres a region's overhead view is across, and the height it's taken from.
const AERIAL_SIZE := 200.0
const AERIAL_HIGH := 260.0
const AERIAL_HOUR := 14.5
const SHOT_FOV := 58.0
const MODEL_FOV := 26.0


func _initialize() -> void:
	# Sharper than play, for this window only.
	root.msaa_3d = Viewport.MSAA_4X
	root.scaling_3d_scale = 1.5
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join("models")))
	var only := PackedStringArray()
	var models := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--models":
			models = true
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",", false)
	if models:
		_photograph_models()
	else:
		_photograph_world(only)


func _photograph_world(only: PackedStringArray) -> void:
	var list: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LIST))
	var world := (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var streamer := world.call("streamer") as SectorStreamer
	var terrain := world.call("terrain") as FieldTerrain
	var player := world.call("player") as Node3D
	streamer.load_all_now()
	streamer.active = false
	world.get_node("SectorGrid").call("set_marks_shown", false)
	world.get_node("Hud").set("visible", false)
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var clock := world.get_node("Clock")
	clock.set("speed", 0.0)
	var camera := Camera3D.new()
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	for k in SETTLE_FRAMES:
		await process_frame
	for shot: Dictionary in _shots(list):
		if not _wanted(String(shot["id"]), only):
			continue
		var from: Array = shot["from"]
		var look: Array = shot["look"]
		var eye := _above_ground(terrain, from)
		var target := _above_ground(terrain, look)
		player.global_position = target
		clock.set("hour", float(shot.get("hour", 11.0)))
		camera.fov = float(shot.get("fov", SHOT_FOV))
		camera.look_at_from_position(eye, target)
		await _save(String(shot["id"]))
	var aerials: Array = []
	for region: Dictionary in list["regions"]:
		if _wanted("aerial_" + String(region["id"]), only):
			aerials.append(region)
	if not aerials.is_empty():
		await _photograph_aerials(world, camera, player, clock, aerials)
	quit()


## Straight down with north up, at the same scale for every region so they join into a map. Everything
## stands at any distance here, and the haze and the short shadow reach are lifted.
func _photograph_aerials(world: Node, camera: Camera3D, player: Node3D, clock: Node, regions: Array) -> void:
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).visibility_range_end = 0.0
	var environment := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	environment.fog_enabled = false
	environment.volumetric_fog_enabled = false
	(world.get_node("Sun") as DirectionalLight3D).directional_shadow_max_distance = AERIAL_HIGH * 2.0
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = AERIAL_SIZE
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	clock.set("hour", AERIAL_HOUR)
	for region: Dictionary in regions:
		var origin: Array = region["origin"]
		var middle := Vector2(float(origin[0]) + AERIAL_SIZE * 0.5, -(float(origin[1]) + AERIAL_SIZE * 0.5))
		player.global_position = Vector3(middle.x, 0.0, middle.y)
		camera.global_position = Vector3(middle.x, AERIAL_HIGH, middle.y)
		await _save("aerial_" + String(region["id"]))


func _shots(list: Dictionary) -> Array:
	var shots: Array = []
	shots.append_array(list.get("cover", []))
	for region: Dictionary in list["regions"]:
		shots.append_array(region.get("shots", []))
	for group: Dictionary in list.get("extra", []):
		shots.append_array(group.get("shots", []))
	return shots


func _wanted(id: String, only: PackedStringArray) -> bool:
	if only.is_empty():
		return true
	for start in only:
		if id.begins_with(start):
			return true
	return false


## [x east, y north, metres above the ground there] as a point in the world, or with a fourth
## item, "abs", that many metres above sea level, for hanging over a drop.
func _above_ground(terrain: FieldTerrain, point: Array) -> Vector3:
	var xz := Vector2(float(point[0]), -float(point[1]))
	var ground := 0.0 if point.size() > 3 else terrain.height_at(xz)
	return Vector3(xz.x, ground + float(point[2]), xz.y)


func _save(id: String) -> void:
	for k in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUT.path_join(id + ".png"))
	root.get_texture().get_image().save_png(path)
	print("[gallery] %s" % id)


## One picture of each model from its front-left, filling the frame, with its size for the caption.
func _photograph_models() -> void:
	_stage()
	var camera := Camera3D.new()
	camera.fov = MODEL_FOV
	camera.far = 4000.0
	root.add_child(camera)
	camera.make_current()
	var sizes := {}
	var paths := {"hero": HERO}
	for slug in DirAccess.get_directories_at(MODELS):
		paths[slug] = MODELS.path_join(slug).path_join(slug + ".glb")
	for slug: String in paths:
		if not ResourceLoader.exists(paths[slug]):
			continue
		var model := (load(paths[slug]) as PackedScene).instantiate() as Node3D
		root.add_child(model)
		await process_frame
		var box := _bounds(model)
		sizes[slug] = [box.size.x, box.size.y, box.size.z]
		var reach := box.size.length() * 0.5
		var away := reach / sin(deg_to_rad(MODEL_FOV * 0.5)) * 0.92
		camera.look_at_from_position(box.get_center() + Vector3(-0.6, 0.5, 1.0).normalized() * away, box.get_center())
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT.path_join("models/%s.png" % slug)))
		model.free()
	var file := FileAccess.open(OUT.path_join("models.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(sizes, "\t"))
	file.close()
	print("[gallery] %d models" % sizes.size())
	quit()


## Daylight and a plain floor reaching past the frame.
func _stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.6, 0.68, 0.76)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.78, 0.79, 0.82)
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 300.0
	root.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6000.0, 6000.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.45)
	material.roughness = 1.0
	plane.material = material
	ground.mesh = plane
	root.add_child(ground)


func _bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		var piece := mesh_instance.global_transform * mesh_instance.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	return box
