extends GutTest
## A villager follows its daily program: the step for the hour says where to
## go and what to do there, and the villager walks there.

var _clock: WorldClock


func before_each() -> void:
	_clock = WorldClock.new()
	add_child_autofree(_clock)
	_clock.hour = 8.0


func _villager() -> Villager:
	var villager := Villager.new()
	villager.home = Vector2(0.0, 0.0)
	villager.work = Vector2(10.0, 0.0)
	villager.meet = Vector2(0.0, 10.0)
	villager.clock = _clock
	villager.program = [
		{"from": 6.0, "place": &"work", "do": &"work"},
		{"from": 12.0, "place": &"meet", "do": &"talk"},
		{"from": 21.0, "place": &"home", "do": &"rest"},
	]
	add_child_autofree(villager)
	return villager


func test_the_step_follows_the_hour() -> void:
	var villager := _villager()
	assert_eq(villager.step_at(7.0)["place"], &"work")
	assert_eq(villager.step_at(12.5)["do"], &"talk")
	assert_eq(villager.step_at(23.0)["place"], &"home")
	assert_eq(villager.step_at(2.0)["place"], &"home", "the last step runs on past midnight")


func test_walks_to_work_then_works() -> void:
	var villager := _villager()
	villager.advance(0.5)
	assert_eq(villager.activity(), &"walk")
	assert_gt(villager.ground_position().x, 0.5, "on the way")
	for k in 20:
		villager.advance(0.5)
	assert_almost_eq(villager.ground_position(), Vector2(10.0, 0.0), Vector2.ONE * 0.06)
	assert_eq(villager.activity(), &"work")


func test_fast_time_makes_the_walk_faster() -> void:
	var villager := _villager()
	_clock.speed = 10.0
	villager.advance(0.5)
	assert_almost_eq(villager.ground_position(), Vector2(10.0, 0.0), Vector2.ONE * 0.06)


func test_the_clock_rolls_into_the_next_day() -> void:
	_clock.hour = 23.5
	_clock.advance(_clock.minutes_per_day * 60.0 / 24.0)
	assert_eq(_clock.day, 2)
	assert_almost_eq(_clock.hour, 0.5, 0.001)
	assert_eq(_clock.text(), "Day 2  00:30")
