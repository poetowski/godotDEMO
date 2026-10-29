class_name SwimSounds
extends AudioStreamPlayer3D
## The hero's splashing while swimming: a splash each time a hand comes down
## into the water, in time with the swim animation (two strokes a cycle,
## faster the faster they swim), and soft lapping while they paddle in
## place. Child of the player; silent on land.

signal splashed(strong: bool)

const VARIANTS := 4
## Seconds between strokes at the animation's own pace (HeroBody.SWIM_SPEED):
## half of the 32-frame cycle at 30 frames a second.
const STROKE := 16.0 / 30.0
## Metres per second under which the hero is paddling, not swimming.
const PADDLING := 0.4

var _strokes: Array[AudioStreamWAV] = []
var _laps: Array[AudioStreamWAV] = []
var _until := 0.0
var _paddling := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bus = &"Effects"
	unit_size = 4.0
	max_db = 0.0
	for k in VARIANTS:
		_strokes.append(SoundSynth.swim_stroke(k, true))
		_laps.append(SoundSynth.swim_stroke(k, false))
	_rng.seed = 23


func _physics_process(delta: float) -> void:
	var player := get_parent() as Player
	if player == null or not player.is_swimming:
		_until = 0.0
		return
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	_until -= delta
	if _paddling and speed >= PADDLING:
		# Setting off: the first stroke doesn't wait out the paddling.
		_until = minf(_until, 0.15)
	if _until > 0.0:
		return
	var pace := clampf(speed / HeroBody.SWIM_SPEED, 0.35, 1.6)
	_paddling = speed < PADDLING
	if _paddling:
		# Paddling: an occasional soft lap.
		_until = STROKE / pace * 2.0 * _rng.randf_range(0.8, 1.3)
		splash(false)
	else:
		_until = STROKE / pace
		splash(true)


## Plays one splash: a stroke, or a soft lap of a paddling hand.
func splash(strong: bool) -> void:
	var streams := _strokes if strong else _laps
	stream = streams[_rng.randi() % streams.size()]
	pitch_scale = _rng.randf_range(0.9, 1.1)
	volume_db = -6.0 if strong else -14.0
	play()
	splashed.emit(strong)
