extends SceneTree
## The benchmark behind `npm run perf`: plays a world in a window and moves
## the hero across it in a straight line at a steady speed (placed on the
## ground every frame, as if riding), then reports frame times, GPU time,
## draw calls, memory over time and what was streamed in, and writes them as
## JSON to .perf/<world>.json. Run plugged in: on battery the numbers drift.
##
## User arguments (after --):
##   --scene=res://...    the world (default: the field, the main world)
##   --seconds=60         how long to travel
##   --speed=12           metres per second
##   --heading=45         degrees from north toward east
##   --regions=10         passed on to the field (20 makes 4 km)
##   --without=A,B        switch off these nodes (paths from the world's
##                        root, such as Vegetation/FarForest), to measure
##                        what they cost

const DEFAULT_SCENE := "res://src/world/field/field.tscn"
const SETTLE_FRAMES := 120

var _options := {"scene": DEFAULT_SCENE, "seconds": 60.0, "speed": 12.0, "heading": 45.0, "without": ""}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var key := arg.trim_prefix("--").get_slice("=", 0)
			var value := arg.get_slice("=", 1)
			if _options.has(key):
				_options[key] = value if key in ["scene", "without"] else value.to_float()
	_run()


func _run() -> void:
	var started := Time.get_ticks_msec()
	var world := (load(String(_options["scene"])) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	var load_ms := Time.get_ticks_msec() - started
	for k in SETTLE_FRAMES:
		await process_frame
	for path in String(_options["without"]).split(",", false):
		var node := world.get_node_or_null(path)
		if node:
			node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is Node3D:
				(node as Node3D).visible = false
	var player := world.call("player") as Player
	var terrain := world.call("terrain") as FieldTerrain
	var streamer := world.call("streamer") as SectorStreamer
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var heading := deg_to_rad(float(_options["heading"]))
	var direction := Vector2(sin(heading), -cos(heading))
	var at := Vector2(player.global_position.x, player.global_position.z)
	var extent := SectorMap.extent()
	var frames := PackedFloat32Array()
	var gpu := PackedFloat32Array()
	var calls := PackedInt32Array()
	var memory: Array[float] = []
	var video: Array[float] = []
	var most_tiles := 0
	var slow: Array[Dictionary] = []
	var region := RegionMap.at(player.global_position)
	var crossings := 0
	var most_chunks := 0
	var travelled := 0.0
	var elapsed := 0.0
	var next_sample := 0.0
	var last := Time.get_ticks_usec()
	var delta := 1.0 / 60.0
	var seconds := float(_options["seconds"])
	var speed := float(_options["speed"])
	while elapsed < seconds:
		var step := direction * speed * delta
		var ahead := at + step
		if ahead.x < 20.0 or ahead.x > extent.x - 20.0 or -ahead.y < 20.0 or -ahead.y > extent.y - 20.0:
			direction = -direction
			step = -step
		at += step
		travelled += step.length()
		player.global_position = Vector3(at.x, terrain.height_at(at) + 0.05, at.y)
		player.velocity = Vector3.ZERO
		player.look_toward(player.global_position + Vector3(direction.x, 0.0, direction.y))
		await process_frame
		var now := Time.get_ticks_usec()
		var frame_ms := (now - last) / 1000.0
		delta = minf(frame_ms / 1000.0, 0.1)
		last = now
		elapsed += frame_ms / 1000.0
		frames.append(frame_ms)
		var now_region := RegionMap.at(player.global_position)
		var crossed := now_region != region
		if crossed:
			crossings += 1
			region = now_region
		if frame_ms > 40.0 and slow.size() < 40:
			slow.append({"at_s": snappedf(elapsed, 0.01), "ms": snappedf(frame_ms, 0.1), "region": RegionMap.name_of(now_region), "crossed_region": crossed})
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		if terrain.chunks():
			most_tiles = maxi(most_tiles, terrain.chunks().tile_count())
		if world.has_method("vegetation"):
			most_chunks = maxi(most_chunks, (world.call("vegetation") as Vegetation).chunk_count())
		if elapsed >= next_sample:
			next_sample += 1.0
			memory.append(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
			video.append(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	var report := {
		"scene": _options["scene"],
		"without": _options["without"],
		"regions": "%dx%d" % [RegionMap.columns, RegionMap.rows],
		"world_km": snappedf(extent.x / 1000.0, 0.1),
		"load_ms": load_ms,
		"seconds": snappedf(elapsed, 0.1),
		"travelled_m": roundi(travelled),
		"speed": speed,
		"frames": frames.size(),
		"frame_ms": _spread(frames),
		"gpu_ms": _spread(gpu),
		"draw_calls": {"median": _median_int(calls), "max": _max_int(calls)},
		"memory_mb": _trend(memory),
		"video_mb": _trend(video),
		"most_terrain_tiles": most_tiles,
		"most_vegetation_chunks": most_chunks,
		"designs_loaded_at_end": streamer.loaded_designs().size(),
		"region_crossings": crossings,
		"slow_frames": slow,
	}
	var out := "res://.perf/%s.json" % String(_options["scene"]).get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.perf"))
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report, "\t"))
	print("[perf] wrote %s" % ProjectSettings.globalize_path(out))
	quit()


## Median, 95th and 99th percentile and worst of a series.
func _spread(values: PackedFloat32Array) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	if sorted.is_empty():
		return {}
	return {
		"median": snappedf(sorted[sorted.size() / 2], 0.01),
		"p95": snappedf(sorted[int(sorted.size() * 0.95)], 0.01),
		"p99": snappedf(sorted[int(sorted.size() * 0.99)], 0.01),
		"worst": snappedf(sorted[sorted.size() - 1], 0.01),
	}


## Where memory started, peaked and ended, and the change over the second
## half of the run: near zero when nothing piles up.
func _trend(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {}
	var half := samples.size() / 2
	return {
		"start": roundi(samples[0]),
		"peak": roundi(samples.max()),
		"end": roundi(samples[samples.size() - 1]),
		"second_half_change": roundi(samples[samples.size() - 1] - samples[half]),
	}


func _median_int(values: PackedInt32Array) -> int:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2] if not sorted.is_empty() else 0


func _max_int(values: PackedInt32Array) -> int:
	var most := 0
	for value in values:
		most = maxi(most, value)
	return most
