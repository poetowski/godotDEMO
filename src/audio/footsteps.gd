class_name Footsteps
extends AudioStreamPlayer3D
## The hero's footsteps: a step every `step_length` metres walked on the
## ground (longer strides when sprinting), soft on grass and splashing in
## water, a little different each time; and a heavier one on landing from a
## jump. Child of the player; asks the world's terrain what's underfoot.

signal stepped(surface: StringName)

const VARIANTS := 4

## Metres between steps while walking, and while sprinting.
@export var step_length: float = 0.8
@export var sprint_step_length: float = 1.25
@export var sprint_speed: float = 6.0

var _streams: Dictionary[StringName, Array] = {}
var _walked := 0.0
var _was_on_floor := true
var _last := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bus = &"Effects"
	unit_size = 4.0
	max_db = 0.0
	for surface: StringName in [&"grass", &"water"]:
		var streams: Array[AudioStreamWAV] = []
		for k in VARIANTS:
			streams.append(SoundSynth.footstep(surface, k))
		_streams[surface] = streams
	_rng.seed = 17
	_last = global_position


func _physics_process(_delta: float) -> void:
	var body := get_parent() as CharacterBody3D
	if body == null:
		return
	var moved := Vector2(global_position.x - _last.x, global_position.z - _last.z).length()
	_last = global_position
	var player := body as Player
	var on_floor := body.is_on_floor() and not (player != null and player.is_swimming)
	if on_floor and not _was_on_floor:
		step(1.3)
		_walked = 0.0
	_was_on_floor = on_floor
	if not on_floor or moved > 2.0:
		# Airborne, or carried somewhere (a teleport, loading a save).
		return
	_walked += moved
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var stride := sprint_step_length if speed > sprint_speed else step_length
	if _walked >= stride:
		_walked -= stride
		step(1.0)


## Plays one step on what's underfoot, `weight` making it louder and lower.
func step(weight: float = 1.0) -> void:
	var surface := surface_underfoot()
	var streams: Array = _streams[surface]
	stream = streams[_rng.randi() % streams.size()]
	pitch_scale = _rng.randf_range(0.88, 1.12) / sqrt(weight)
	volume_db = -8.0 + 6.0 * (weight - 1.0)
	play()
	stepped.emit(surface)


## &"water" when standing in water, not merely above it, else &"grass".
func surface_underfoot() -> StringName:
	var terrain := get_tree().get_first_node_in_group(&"terrains") as FieldTerrain if is_inside_tree() else null
	if terrain and LevelMap.at(terrain, global_position).water_over_point() > 0.03:
		return &"water"
	return &"grass"
