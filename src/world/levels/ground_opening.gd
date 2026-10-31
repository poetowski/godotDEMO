@tool
class_name GroundOpening
extends Node3D
## A hole in the open ground, the way down into a cave or a cellar: the ground's mesh
## and collision leave out every square whose middle is inside this rectangle. Near
## the player those squares are 1 m, so the rim is jagged, and what goes in the hole
## hides it. Far off, a hole smaller than the coarse squares closes over.
##
## It belongs in the scene, not in a design's content, because the ground around it is
## there whether or not the design is loaded. It cuts only the open ground: a design
## that shapes its own ground leaves its own hole. Drag it in the editor and the hole
## follows. Generated children have no owner, so the editor never saves them.

const GROUP := &"ground_openings"
const OUTLINE_COLOR := Color(1.0, 0.6, 0.2)
## Metres up that its outline shows.
const OUTLINE_HEIGHT := 2.0
## Seconds between looks at whether it moved, in the editor.
const WATCH_INTERVAL := 0.3

## Metres across and along.
@export var size: Vector2 = Vector2(4.0, 4.0):
	set(value):
		size = value
		_show_outline()

var _outline: MeshInstance3D
var _watch := 0.0
var _seen_area := Rect2i()


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_seen_area = samples_around()
	_show_outline()


func _process(delta: float) -> void:
	_watch -= delta
	if _watch > 0.0:
		return
	_watch = WATCH_INTERVAL
	var now := samples_around()
	if now == _seen_area:
		return
	var terrain := get_tree().get_first_node_in_group(&"terrains") as FieldTerrain
	if terrain:
		terrain.refresh_openings(now.merge(_seen_area))
	_seen_area = now


## The samples of the ground (x, north) it touches, turned as it is.
func samples_around() -> Rect2i:
	var half := size * 0.5
	var low := Vector2(INF, INF)
	var high := -low
	for corner: Vector3 in [Vector3(-half.x, 0.0, -half.y), Vector3(half.x, 0.0, -half.y), Vector3(half.x, 0.0, half.y), Vector3(-half.x, 0.0, half.y)]:
		var at := global_transform * corner
		low = Vector2(minf(low.x, at.x), minf(low.y, -at.z))
		high = Vector2(maxf(high.x, at.x), maxf(high.y, -at.z))
	var start := Vector2i(floori(low.x), floori(low.y))
	return Rect2i(start, Vector2i(ceili(high.x), ceili(high.y)) - start)


func _show_outline() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _outline:
		_outline.free()
	_outline = LevelMap.outline(Vector3(size.x, OUTLINE_HEIGHT, size.y), OUTLINE_COLOR)
	add_child(_outline)
