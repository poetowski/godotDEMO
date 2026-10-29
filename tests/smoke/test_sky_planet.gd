extends GutTest
## A giant ringed planet hangs in the day sky, far beyond the land, and
## fades away at night.

var _world: Node
var _planet: SkyPlanet
var _clock: WorldClock


func before_all() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(_world)
	_planet = _world.get_node("SkyPlanet") as SkyPlanet
	_clock = _world.call("clock") as WorldClock


func after_all() -> void:
	_world.free()


func test_shows_by_day_with_rings() -> void:
	_clock.hour = 12.0
	await wait_process_frames(2)
	assert_true(_planet.visible)
	assert_almost_eq(_planet.shown(), 1.0, 0.01)
	assert_not_null(_planet.get_node("Rings"))
	assert_gt(_planet.radius, 300.0, "big")


func test_fades_away_at_night() -> void:
	_clock.hour = 0.5
	await wait_process_frames(2)
	assert_false(_planet.visible)
	_clock.hour = 12.0


func test_two_smaller_planets_without_rings_elsewhere() -> void:
	_clock.hour = 12.0
	await wait_process_frames(2)
	for planet_name: String in ["BluePlanet", "RedPlanet"]:
		var planet := _world.get_node(planet_name) as SkyPlanet
		assert_true(planet.visible, planet_name)
		assert_lt(planet.radius, _planet.radius * 0.5, "%s is smaller" % planet_name)
		assert_null(planet.get_node_or_null("Rings"), "%s has no rings" % planet_name)
		assert_lt(planet.direction.normalized().dot(_planet.direction.normalized()), 0.5, "%s is elsewhere" % planet_name)
