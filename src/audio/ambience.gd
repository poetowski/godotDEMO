class_name Ambience
extends Node
## The world's ambient sound: a soft wind always, birds calling now and then
## by day and crickets by night, fading between them with the light
## (DayNight). One layer of sound for the whole world for now; places of
## their own come later.

const BIRD_VARIANTS := 5
const CRICKET_VARIANTS := 3

@export var day_night: DayNight
@export var clock: WorldClock
@export var wind_db: float = -16.0
@export var calls_db: float = -12.0
## Seconds between calls, at least and at most.
@export var call_gap: Vector2 = Vector2(1.5, 6.0)

var _wind: AudioStreamPlayer
var _caller: AudioStreamPlayer
var _birds: Array[AudioStreamWAV] = []
var _crickets: Array[AudioStreamWAV] = []
var _rng := RandomNumberGenerator.new()
var _until_call := 2.0


func _ready() -> void:
	_rng.seed = 23
	for k in BIRD_VARIANTS:
		_birds.append(SoundSynth.bird(k))
	for k in CRICKET_VARIANTS:
		_crickets.append(SoundSynth.cricket(k))
	_wind = AudioStreamPlayer.new()
	_wind.name = "Wind"
	_wind.bus = &"Ambient"
	_wind.stream = SoundSynth.wind()
	_wind.volume_db = wind_db
	add_child(_wind)
	_wind.play()
	_caller = AudioStreamPlayer.new()
	_caller.name = "Calls"
	_caller.bus = &"Ambient"
	add_child(_caller)


func _process(delta: float) -> void:
	_until_call -= delta
	if _until_call <= 0.0:
		_until_call = _rng.randf_range(call_gap.x, call_gap.y)
		call_now()


## What calls at this hour: &"birds" by day, &"crickets" by night.
func layer() -> StringName:
	return &"birds" if _daylight() >= 0.5 else &"crickets"


## Plays one call of the hour's creatures, from a random side.
func call_now() -> StringName:
	var calling := layer()
	var pool := _birds if calling == &"birds" else _crickets
	_caller.stream = pool[_rng.randi() % pool.size()]
	_caller.pitch_scale = _rng.randf_range(0.9, 1.1)
	_caller.volume_db = calls_db + _rng.randf_range(-6.0, 0.0)
	_caller.play()
	return calling


func _daylight() -> float:
	if day_night and clock:
		return day_night.daylight(clock.hour)
	return 1.0
