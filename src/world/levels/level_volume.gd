@tool
class_name LevelVolume
extends Node3D
## A place at its own height: one floor of a building, a chamber of a cave. A box
## standing on the node's origin and turned with it, asked about by LevelMap. Place it
## by hand and see its outline in the editor, or add it from a design with
## `add_content`, when it comes and goes with the design. Generated children have no
## owner, so the editor never saves them.

const GROUP := &"level_volumes"
const OUTLINE_COLOR := Color(0.35, 0.85, 1.0)

## Metres across, up and along. Its floor is at the node's origin.
@export var size: Vector3 = Vector3(10.0, 3.0, 10.0):
	set(value):
		size = value
		_show_outline()
## What the HUD shows beside the sector, in English; empty for nothing.
@export var place_name: String = ""
## Under a roof, away from the wind and the birds. Off for a rooftop or an open pit.
@export var enclosed: bool = true
## Metres of water standing on its floor, for a pool the world's water can't be: a
## second surface above or below the land's. The design draws it.
@export var water_depth: float = 0.0

var _outline: MeshInstance3D


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_show_outline()


func contains(point: Vector3) -> bool:
	var local := global_transform.affine_inverse() * point
	return absf(local.x) <= size.x * 0.5 and absf(local.z) <= size.z * 0.5 and local.y >= 0.0 and local.y <= size.y


## Cubic metres inside.
func space() -> float:
	return size.x * size.y * size.z


## The height of the water in it.
func water_surface() -> float:
	return global_position.y + water_depth


func _show_outline() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _outline:
		_outline.free()
	_outline = LevelMap.outline(size, OUTLINE_COLOR)
	add_child(_outline)
