class_name DayNight
extends Node
## Day and night from the world clock: the sun rises in the east at
## `sunrise`, crosses the southern sky and sets in the west at `sunset`; at
## night the moon lights the land from the opposite side, dimmer and bluer,
## and stars come out. The sky, ambient light and fog follow through dawn,
## day, dusk and night. Only one of the two lights casts shadows at a time.
## Colours and timings are placeholders.

@export var clock: WorldClock
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export_group("Timing")
## Hour the sun crosses the horizon in the morning, and in the evening.
@export var sunrise: float = 6.0
@export var sunset: float = 20.0
## Degrees above the southern horizon the sun reaches at noon.
@export var noon_elevation: float = 60.0
@export_group("Light")
@export var sun_energy: float = 1.3
@export var moon_energy: float = 0.55
@export var sun_day_color: Color = Color(1.0, 0.95, 0.86)
@export var sun_low_color: Color = Color(1.0, 0.55, 0.3)
@export var moon_color: Color = Color(0.62, 0.72, 1.0)
## The ambient light at night, mixed in where the dark sky gives too little.
@export var night_ambient: Color = Color(0.3, 0.36, 0.52)
@export_group("Sky")
@export var day_top: Color = Color(0.26, 0.47, 0.8)
@export var day_horizon: Color = Color(0.7, 0.79, 0.88)
@export var dusk_horizon: Color = Color(0.95, 0.58, 0.38)
@export var dusk_top: Color = Color(0.32, 0.36, 0.62)
@export var night_top: Color = Color(0.015, 0.025, 0.07)
@export var night_horizon: Color = Color(0.05, 0.07, 0.14)

var _sky: ProceduralSkyMaterial
var _stars: Texture2D


func _ready() -> void:
	var environment := world_environment.environment
	_sky = environment.sky.sky_material as ProceduralSkyMaterial
	_stars = _star_texture()
	_sky.sky_cover = _stars
	update()


func _process(_delta: float) -> void:
	update()


## Points the lights and colours the sky for the clock's hour.
func update() -> void:
	apply(clock.hour)


## Lights the world as at `hour`.
func apply(hour: float) -> void:
	var to_sun := sun_direction(hour)
	var height := to_sun.y
	var day := daylight(hour)
	var low := 1.0 - smoothstep(0.05, 0.45, height)
	_aim(sun, to_sun)
	sun.light_energy = sun_energy * smoothstep(-0.03, 0.12, height)
	sun.light_color = sun_day_color.lerp(sun_low_color, low)
	sun.visible = sun.light_energy > 0.001
	sun.shadow_enabled = sun.visible
	var to_moon := Vector3(-to_sun.x, -to_sun.y, to_sun.z * 0.6).normalized()
	_aim(moon, to_moon)
	moon.light_energy = moon_energy * smoothstep(-0.03, 0.15, to_moon.y) * (1.0 - day)
	moon.light_color = moon_color
	moon.visible = moon.light_energy > 0.001
	moon.shadow_enabled = moon.visible and not sun.visible
	var dusk := (1.0 - smoothstep(0.0, 0.35, absf(height))) * smoothstep(-0.25, 0.0, height)
	var top := night_top.lerp(day_top, day).lerp(dusk_top, dusk * 0.6)
	var horizon := night_horizon.lerp(day_horizon, day).lerp(dusk_horizon, dusk)
	_sky.sky_top_color = top
	_sky.sky_horizon_color = horizon
	_sky.ground_horizon_color = horizon
	_sky.ground_bottom_color = night_top.lerp(Color(0.64, 0.72, 0.78), day)
	_sky.sky_cover_modulate = Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.0, 0.5, day))
	var environment := world_environment.environment
	environment.fog_light_color = horizon
	# The night sky is too dark to light the land; a moonlit blue takes over
	# from it.
	environment.ambient_light_color = night_ambient
	environment.ambient_light_sky_contribution = lerpf(0.15, 1.0, day)
	environment.ambient_light_energy = 1.0


## 1 in full day, 0 at night, in between at dawn and dusk.
func daylight(hour: float) -> float:
	return smoothstep(-0.12, 0.2, sun_direction(hour).y)


## The direction toward the sun at an hour: east (+X) at sunrise, high in
## the south (+Z) at midday, west at sunset, below the horizon at night.
func sun_direction(hour: float) -> Vector3:
	var day_length := sunset - sunrise
	var night_length := 24.0 - day_length
	var arc: float
	if hour >= sunrise and hour <= sunset:
		arc = (hour - sunrise) / day_length * PI
	else:
		var since_sunset := fposmod(hour - sunset, 24.0)
		arc = PI + since_sunset / night_length * PI
	var tilt := deg_to_rad(noon_elevation)
	return Vector3(cos(arc), sin(arc) * sin(tilt), sin(arc) * cos(tilt) + 0.15).normalized()


## Turns a directional light so it shines from `toward`.
func _aim(light: DirectionalLight3D, toward: Vector3) -> void:
	var up := Vector3.UP if absf(toward.y) < 0.99 else Vector3.FORWARD
	light.global_basis = Basis.looking_at(-toward, up)


## Scattered stars of a few sizes and brightnesses, for the night sky. The
## same every run.
func _star_texture() -> Texture2D:
	var image := Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 2600:
		var x := rng.randi_range(0, image.get_width() - 1)
		# The upper half is the sky; thinner toward the horizon.
		var y := int(pow(rng.randf(), 1.4) * image.get_height() * 0.5)
		var bright := rng.randf_range(0.35, 1.0)
		var tint := Color(bright, bright, minf(1.0, bright * 1.12), 1.0)
		image.set_pixel(x, y, tint)
		if rng.randf() < 0.08:
			image.set_pixel(mini(x + 1, image.get_width() - 1), y, tint * 0.7)
	return ImageTexture.create_from_image(image)
