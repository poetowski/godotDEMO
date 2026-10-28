class_name WorldClock
extends Node
## The time of day: hours run from 0 to 24 and roll over into the next day.
## A game day lasts `minutes_per_day` real minutes; `speed` fast-forwards it.
## Villagers follow their daily programs by it.

## Real minutes per game day.
@export var minutes_per_day: float = 24.0
## The hour a new game starts at.
@export var start_hour: float = 8.0

var day: int = 1
## 0 to 24, with fractions: 13.5 is half past one.
var hour: float = 8.0
## How many times faster than normal the clock runs.
var speed: float = 1.0


func _ready() -> void:
	hour = start_hour


func _process(delta: float) -> void:
	advance(delta)


## Moves the clock on by real seconds, at the current speed.
func advance(seconds: float) -> void:
	hour += seconds * speed * game_hours_per_second()
	while hour >= 24.0:
		hour -= 24.0
		day += 1


## Game hours that pass in one real second at normal speed.
func game_hours_per_second() -> float:
	return 24.0 / (minutes_per_day * 60.0)


## "Day 1  08:30", for the HUD.
func text() -> String:
	return tr("Day %d  %02d:%02d") % [day, int(hour), int(fmod(hour, 1.0) * 60.0)]
