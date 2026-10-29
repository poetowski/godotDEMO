class_name Villager
extends Node3D
## A villager living by a daily program: each step says from which hour to
## be where (home, work or the meeting place) and what to do there (rest,
## work, talk). The villager walks there over the ground, then does it.
## Walking and the program run wherever the player is; the body is only
## shown and animated near the player. No collision. Very simple on purpose:
## a placeholder for real NPCs.

const HERO := preload("res://assets/models/hero/hero.glb")
const HERO_BODY := preload("res://src/player/hero_body.gd")
## Seconds between strokes while working.
const WORK_STROKE := 1.6

@export var display_name: String = ""
@export var tunic: Color = Color(0.18, 0.42, 0.3)
@export var home: Vector2 = Vector2.ZERO
@export var work: Vector2 = Vector2.ZERO
@export var meet: Vector2 = Vector2.ZERO
## Metres per second.
@export var walk_speed: float = 2.0
## Metres from the player within which the body is shown.
@export var show_distance: float = 60.0

## The daily program, sorted by hour: {"from": 6.0, "place": &"work",
## "do": &"work"}. Places are home, work and meet; activities rest, work and
## talk. The last step runs on past midnight until the first.
@export var program: Array[Dictionary] = []
var clock: WorldClock
var terrain: FieldTerrain
## What it shows from, usually the player.
var viewer: Node3D

var _at: Vector2
var _facing: float = 0.0
var _moving: bool = false
var _stroke: float = 0.0
var _body: HeroBody
var _label: Label3D


func _ready() -> void:
	_at = home
	var body := HERO.instantiate() as Node3D
	body.set_script(HERO_BODY)
	body.name = "Body"
	add_child(body)
	_body = body as HeroBody
	_body.tint("Tunic", tunic)
	_label = Label3D.new()
	_label.text = display_name
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3.UP * 2.1
	_label.font_size = 40
	_label.outline_size = 10
	_label.visibility_range_end = 12.0
	add_child(_label)
	_place()


func _process(delta: float) -> void:
	advance(delta)


## The program step for an hour.
func step_at(hour: float) -> Dictionary:
	var current: Dictionary = program[program.size() - 1]
	for step in program:
		if float(step["from"]) <= hour:
			current = step
	return current


## Where the villager is heading now.
func target() -> Vector2:
	match StringName(step_at(clock.hour)["place"]):
		&"work":
			return work
		&"meet":
			# Around the meeting place, each villager at their own side.
			return meet + (home - meet).normalized() * 1.6
		_:
			return home


## What it is doing now: &"walk", or the step's activity once there.
func activity() -> StringName:
	return &"walk" if _moving else StringName(step_at(clock.hour)["do"])


## Where it stands, on the ground.
func ground_position() -> Vector2:
	return _at


## Runs the program for real seconds: walks on (faster when the clock is
## fast-forwarded) and acts.
func advance(delta: float) -> void:
	var goal := target()
	var reach := walk_speed * delta * clock.speed
	var to_goal := goal - _at
	_moving = to_goal.length() > 0.05
	if _moving:
		_at = _at.move_toward(goal, reach)
		_facing = atan2(to_goal.x, to_goal.y)
	elif StringName(step_at(clock.hour)["place"]) == &"meet":
		var to_meet := meet - _at
		_facing = atan2(to_meet.x, to_meet.y)
	_place()
	var near := viewer == null or viewer.global_position.distance_to(global_position) < show_distance
	_body.visible = near
	_body.set_active(near)
	if not near:
		return
	_body.move(walk_speed if _moving else 0.0, false, false, delta)
	if activity() == &"work":
		_stroke -= delta
		if _stroke <= 0.0:
			_stroke = WORK_STROKE
			_body.swing()


func _place() -> void:
	position = Vector3(_at.x, terrain.height_at(_at) if terrain else 0.0, _at.y)
	rotation.y = _facing
