extends GutTest
## Sound: footsteps as the hero walks, splashing in water; wind always and
## birds by day, crickets by night; sounds made in code, on their own buses.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _player: Player
var _steps: Footsteps


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_player = _world.call("player") as Player
	_steps = _player.get_node("Footsteps") as Footsteps


func after_all() -> void:
	Input.action_release(&"move_forward")
	_world.free()


func test_the_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index(&"Effects"), -1)
	assert_ne(AudioServer.get_bus_index(&"Ambient"), -1)


func test_sounds_are_made_and_not_silent() -> void:
	for stream: AudioStreamWAV in [SoundSynth.footstep(&"grass", 0), SoundSynth.footstep(&"water", 1), SoundSynth.bird(2), SoundSynth.cricket(0)]:
		assert_gt(stream.get_length(), 0.05)
		assert_gt(_loudest(stream), 2000, "audible")
	var wind := SoundSynth.wind()
	assert_eq(wind.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_gt(wind.get_length(), 5.0)
	assert_eq(SoundSynth.bird(3).data, SoundSynth.bird(3).data, "the same every time")


func test_walking_makes_footsteps_on_grass() -> void:
	_world.call("teleport", SectorMap.cell_named("C1"))
	await wait_physics_frames(10)
	watch_signals(_steps)
	Input.action_press(&"move_forward")
	await wait_seconds(1.5)
	Input.action_release(&"move_forward")
	assert_gt(get_signal_emit_count(_steps, "stepped"), 3, "a step every stride")
	assert_signal_emitted_with_parameters(_steps, "stepped", [&"grass"])


func test_water_splashes() -> void:
	var stream := _world.get_node("Sectors/A1A3Stream") as SectorDesign
	var wet := Vector2.ZERO
	for k in 400:
		var xz := Vector2(1.0 + (k % 20) * 0.45, -1.0 - (k / 20) * 0.45)
		if stream.water_level_at(xz) > stream.height_at(xz) + 0.1:
			wet = xz
			break
	assert_ne(wet, Vector2.ZERO, "found water in the pond")
	_steps.global_position = Vector3(wet.x, stream.height_at(wet), wet.y)
	assert_eq(_steps.surface_underfoot(), &"water")
	_steps.position = Vector3.ZERO


func test_birds_by_day_crickets_by_night() -> void:
	var ambience := _world.get_node("Ambience") as Ambience
	var clock := _world.get_node("Clock") as WorldClock
	clock.hour = 12.0
	assert_eq(ambience.call_now(), &"birds")
	clock.hour = 0.5
	assert_eq(ambience.call_now(), &"crickets")
	assert_true((ambience.get_node("Wind") as AudioStreamPlayer).playing, "the wind always blows")
	clock.hour = 8.0


func _loudest(stream: AudioStreamWAV) -> int:
	var most := 0
	for k in range(0, stream.data.size(), 2):
		most = maxi(most, absi(stream.data.decode_s16(k)))
	return most
