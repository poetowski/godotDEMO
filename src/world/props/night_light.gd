class_name NightLight
extends Node3D
## The flame of something that burns at night, such as a lantern: a light and a small
## glow that come up after sunset and die down before sunrise, by the world's clock
## (DayNight's hours). Added beside a model by SectorDesign, from
## PropLibrary.NIGHT_LIGHTS. Off when there's no clock.

const COLOR := Color(1.0, 0.7, 0.36)
const ENERGY := 1.5
const REACH := 9.0
const GLOW_RADIUS := 0.07
## The hours it comes up from and is out by, and how long that takes.
const LIT_FROM := 19.5
const OUT_FROM := 5.5
const FADE_HOURS := 0.5
## Seconds between looks at the clock while it's out.
const CHECK_SECONDS := 1.0
## How far the flame wavers, and how slowly: it's meant to be calm.
const WAVER := 0.05
const WAVER_SPEED := 1.3
## Metres at which the light fades out, for what's far off.
const FADE_BEGIN := 60.0
const FADE_LENGTH := 15.0

var _light: OmniLight3D
var _glow: MeshInstance3D
var _clock: WorldClock
var _wait := 0.0
var _time := 0.0
var _lit := 0.0


func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.omni_range = REACH
	_light.shadow_enabled = false
	_light.distance_fade_enabled = true
	_light.distance_fade_begin = FADE_BEGIN
	_light.distance_fade_length = FADE_LENGTH
	add_child(_light)
	var sphere := SphereMesh.new()
	sphere.radius = GLOW_RADIUS
	sphere.height = GLOW_RADIUS * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(1.0, 0.82, 0.5)
	_glow = MeshInstance3D.new()
	_glow.mesh = sphere
	_glow.material_override = look
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	_time = position.x
	refresh()


func _process(delta: float) -> void:
	_time += delta
	_wait -= delta
	if _wait <= 0.0:
		refresh()
	if _lit > 0.0:
		_light.light_energy = ENERGY * _lit * (1.0 + WAVER * sin(_time * WAVER_SPEED))


## Reads the clock now.
func refresh() -> void:
	_wait = CHECK_SECONDS
	if _clock == null and is_inside_tree():
		_clock = get_tree().get_first_node_in_group(&"world_clocks") as WorldClock
	_lit = amount_at(_clock.hour) if _clock else 0.0
	_light.visible = _lit > 0.0
	_glow.visible = _lit > 0.0
	_light.light_energy = ENERGY * _lit


## How lit it is at an hour, 0 to 1.
static func amount_at(hour: float) -> float:
	if hour >= LIT_FROM:
		return minf((hour - LIT_FROM) / FADE_HOURS, 1.0)
	if hour <= OUT_FROM:
		return 1.0
	return maxf(1.0 - (hour - OUT_FROM) / FADE_HOURS, 0.0)
