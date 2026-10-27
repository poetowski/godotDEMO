extends "res://src/world/field/field.gd"
## The stress-test world: the field with all 400 sectors filled with
## woodland on Perlin hills. Built to measure baking, streaming, memory and
## frame times at full size; not game content. Play it with
## `npm run game -- src/world/stress/stress_field.tscn`.

## Metres the hills rise and fall at most.
const HILL_HEIGHT := 3.5


func _init() -> void:
	super()
	WorldShape.configure(HILL_HEIGHT, 0.02, 7)
