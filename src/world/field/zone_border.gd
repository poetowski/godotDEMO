@tool
class_name ZoneBorder
extends Node3D
## A border the player may not cross, for the world's edge or between zones. Past
## its line the player is warned; RETURN_METRES further on they are returned to the
## spawn point. Field applies it and SectorGrid draws both lines in red. See
## "Borders" in docs/world/README.md.
##
## The line is the Marker3D children of `Line`, in order, with the forbidden side on
## its right-hand side. Drag them in the editor and the red lines follow; duplicate
## one to add a point, in order in the scene tree.

## The line moved; SectorGrid draws it again.
signal moved

## Metres past the line at which the player is returned.
const RETURN_METRES := 8.0
## How far past the world the forbidden side reaches, in metres.
const BEYOND := 300.0
## Seconds between looks at whether the points moved, in the editor.
const WATCH_INTERVAL := 0.3

var _line := PackedVector2Array()
var _polygon := PackedVector2Array()
var _watch := 0.0


## True in a world with regions to the west, not in test worlds.
static func applies() -> bool:
	return RegionMap.south_west.x < 0


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(delta: float) -> void:
	_watch -= delta
	if _watch > 0.0:
		return
	_watch = WATCH_INTERVAL
	if _read_line() != _line:
		rebuild()
		moved.emit()


## The line of points (world x and z), in order.
func line() -> PackedVector2Array:
	return _read_line() if _line.is_empty() else _line


## The line moved RETURN_METRES into the forbidden side, where the player is returned.
func return_line() -> PackedVector2Array:
	var points := line()
	var further := PackedVector2Array()
	for k in points.size():
		var along := (points[mini(k + 1, points.size() - 1)] - points[maxi(k - 1, 0)]).normalized()
		# World z runs south, so on the ground the right-hand side is (-z, x).
		further.append(points[k] + Vector2(-along.y, along.x) * RETURN_METRES)
	return further


## Metres past the line at a world x and z; 0 on the allowed side.
func depth_at(xz: Vector2) -> float:
	if _polygon.is_empty() or not Geometry2D.is_point_in_polygon(xz, _polygon):
		return 0.0
	var nearest := INF
	for k in _line.size() - 1:
		var on_line := Geometry2D.get_closest_point_to_segment(xz, _line[k], _line[k + 1])
		nearest = minf(nearest, xz.distance_squared_to(on_line))
	return sqrt(nearest)


## Reads the points as they are now.
func rebuild() -> void:
	_line = _read_line()
	_polygon = PackedVector2Array()
	if _line.size() < 2:
		return
	var bounds := SectorMap.bounds()
	var west := bounds.position.x - BEYOND
	# World z runs south, so a norths' end is a small z.
	_polygon = _line.duplicate()
	_polygon.append(Vector2(_line[_line.size() - 1].x, -bounds.position.y + BEYOND))
	_polygon.append(Vector2(west, -bounds.position.y + BEYOND))
	_polygon.append(Vector2(west, -bounds.end.y - BEYOND))
	_polygon.append(Vector2(_line[0].x, -bounds.end.y - BEYOND))


func _read_line() -> PackedVector2Array:
	var points := PackedVector2Array()
	var holder := get_node_or_null("Line")
	if holder:
		for child in holder.get_children():
			var marker := child as Node3D
			if marker:
				points.append(Vector2(marker.position.x, marker.position.z))
	return points
