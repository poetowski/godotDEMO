extends GutTest
## Day and night in the field: the sun crosses the sky from east to west by
## day and sets; at night the moon lights the land and stars come out.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node3D
var _day_night: DayNight
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _sky: ProceduralSkyMaterial


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_day_night = _world.get_node("DayNight") as DayNight
	_sun = _world.get_node("Sun") as DirectionalLight3D
	_moon = _world.get_node("Moon") as DirectionalLight3D
	_sky = (_world.get_node("WorldEnvironment") as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial


func after_all() -> void:
	_world.free()


func test_noon_is_bright_with_the_sun_high_in_the_south() -> void:
	_day_night.apply(13.0)
	var to_sun := _day_night.sun_direction(13.0)
	assert_gt(to_sun.y, 0.7, "high")
	assert_gt(to_sun.z, 0.3, "in the south")
	assert_gt(_sun.light_energy, 1.0)
	assert_true(_sun.shadow_enabled)
	assert_false(_moon.visible)
	assert_almost_eq(_sky.sky_cover_modulate.a, 0.0, 0.01, "no stars")


func test_the_sun_rises_in_the_east_and_sets_in_the_west() -> void:
	assert_gt(_day_night.sun_direction(8.0).x, 0.5)
	assert_lt(_day_night.sun_direction(18.0).x, -0.5)
	assert_almost_eq(_day_night.sun_direction(_day_night.sunrise).y, 0.0, 0.01)
	assert_almost_eq(_day_night.sun_direction(_day_night.sunset).y, 0.0, 0.01)


func test_midnight_has_moonlight_and_stars() -> void:
	_day_night.apply(0.5)
	assert_lt(_day_night.sun_direction(0.5).y, -0.3)
	assert_false(_sun.visible)
	assert_true(_moon.visible)
	assert_true(_moon.shadow_enabled, "the moon casts the shadows at night")
	assert_gt(_sky.sky_cover_modulate.a, 0.9, "stars")
	assert_lt(_sky.sky_top_color.v, 0.15, "a dark sky")


func test_the_lights_follow_the_clock() -> void:
	var clock := _world.get_node("Clock") as WorldClock
	clock.hour = 23.0
	_day_night.update()
	assert_true(_moon.visible)
	clock.hour = 12.0
	_day_night.update()
	assert_true(_sun.visible)
