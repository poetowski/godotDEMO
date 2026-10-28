extends "res://src/world/field/field.gd"
## The stress-test world: the field with all 400 sectors filled with
## woodland on Perlin hills, and villagers around J10 living by daily
## programs on a world clock. Built to measure baking, streaming, memory and
## frame times at full size, and to try systems at that size; not game
## content. Play it with `npm run game -- src/world/stress/stress_field.tscn`;
## T fast-forwards time.

## Metres the hills rise and fall at most.
const HILL_HEIGHT := 3.5
const VILLAGER_SCRIPT := preload("res://src/npc/villager.gd")
## Placeholder names, one villager each.
const VILLAGERS: Array[String] = ["Ada", "Bran", "Cora", "Dain", "Elin", "Finn", "Greta", "Hal", "Ivy", "Jory"]
const TUNICS: Array[Color] = [
	Color(0.62, 0.22, 0.18), Color(0.2, 0.32, 0.6), Color(0.7, 0.55, 0.2), Color(0.45, 0.25, 0.5),
	Color(0.3, 0.5, 0.55), Color(0.55, 0.4, 0.3), Color(0.25, 0.45, 0.2), Color(0.6, 0.6, 0.62),
]
## Where the villagers meet: the middle of J10.
const MEETING_PLACE := Vector2(95.0, -95.0)
## Game hours per real second while fast-forwarding.
const FAST_HOURS_PER_SECOND := 1.0

var _clock: WorldClock


func _init() -> void:
	super()
	WorldShape.configure(HILL_HEIGHT, 0.02, 7)
	start_sector = "J10"


func _ready() -> void:
	_clock = WorldClock.new()
	_clock.name = "Clock"
	add_child(_clock)
	super()
	_add_villagers()


func _process(delta: float) -> void:
	super(delta)
	_hud.show_clock(_clock.text())


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_T:
		var fast := is_equal_approx(_clock.speed, 1.0)
		_clock.speed = FAST_HOURS_PER_SECOND / _clock.game_hours_per_second() if fast else 1.0
		_hud.notify(tr("Time runs fast") if fast else tr("Time runs normally"))


func clock() -> WorldClock:
	return _clock


func villagers() -> Array[Villager]:
	var found: Array[Villager] = []
	found.assign(get_tree().get_nodes_in_group(&"villagers"))
	return found


## Ten villagers with homes and work places scattered around J10 and the
## same day: work in the morning, lunch together, work, an evening at the
## meeting place, then home. Their hours differ a little.
func _add_villagers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var root := Node3D.new()
	root.name = "Villagers"
	add_child(root)
	for k in VILLAGERS.size():
		var villager := VILLAGER_SCRIPT.new() as Villager
		villager.name = VILLAGERS[k]
		villager.display_name = VILLAGERS[k]
		villager.tunic = TUNICS[k % TUNICS.size()]
		villager.meet = MEETING_PLACE
		villager.home = _spot_around(rng, 12.0, 22.0)
		villager.work = _spot_around(rng, 15.0, 30.0)
		var late := (k % 3) * 0.5
		villager.program = [
			{"from": 6.0 + late, "place": &"work", "do": &"work"},
			{"from": 12.0, "place": &"meet", "do": &"talk"},
			{"from": 13.0, "place": &"work", "do": &"work"},
			{"from": 18.0 + late, "place": &"meet", "do": &"talk"},
			{"from": 21.0 + late, "place": &"home", "do": &"rest"},
		]
		villager.clock = _clock
		villager.terrain = _terrain
		villager.viewer = _player
		villager.add_to_group(&"villagers")
		root.add_child(villager)


func _spot_around(rng: RandomNumberGenerator, near: float, far: float) -> Vector2:
	var angle := rng.randf() * TAU
	return MEETING_PLACE + Vector2(cos(angle), sin(angle)) * rng.randf_range(near, far)
