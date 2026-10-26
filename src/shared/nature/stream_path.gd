@tool
class_name StreamPath
extends RefCounted
## A stream's course: a smooth centre line through control points, each with a
## half-width and a water level. `nearest` says how far a ground point is from
## the water, the water level there and which way it flows. A wide last point
## gives the stream a pond to end in; the first point is its source.


## What `nearest` found.
class Hit:
	## Metres from the centre line.
	var distance: float = 0.0
	var half_width: float = 1.0
	## Height of the water surface.
	var level: float = 0.0
	## Downstream, unit length.
	var direction := Vector2.ZERO
	## Metres along the stream from its source.
	var along: float = 0.0

	## Metres outside the water's edge: negative under water.
	func edge() -> float:
		return distance - half_width

	## The distance in half-widths: below 1 is under water.
	func reach() -> float:
		return distance / half_width


## Metres per side of the lookup buckets.
const BUCKET := 2.0

## The smoothed centre line, densely sampled from source to end.
var points := PackedVector2Array()
var half_widths := PackedFloat32Array()
var levels := PackedFloat32Array()
## Metres from the source to each point.
var distances := PackedFloat32Array()
## How far outside the water's edge `nearest` still answers, in metres.
var reach_metres: float

var _buckets: Dictionary[Vector2i, PackedInt32Array] = {}


## `control` holds one Vector4 per point: world x, world z, half-width and water
## level. The line is sampled every `step` metres.
func _init(control: Array[Vector4], reach: float = 4.0, step: float = 0.3) -> void:
	reach_metres = reach
	for k in control.size() - 1:
		var a := control[k]
		var b := control[k + 1]
		var before := control[maxi(k - 1, 0)]
		var after := control[mini(k + 2, control.size() - 1)]
		var from := Vector2(a.x, a.y)
		var to := Vector2(b.x, b.y)
		var pieces := maxi(1, ceili(from.distance_to(to) / step))
		for p in pieces:
			var t := float(p) / pieces
			_append(from.cubic_interpolate(to, Vector2(before.x, before.y), Vector2(after.x, after.y), t),
				lerpf(a.z, b.z, smoothstep(0.0, 1.0, t)), lerpf(a.w, b.w, t))
	var last := control[control.size() - 1]
	_append(Vector2(last.x, last.y), last.z, last.w)
	_fill_buckets()


## The closest stretch of stream to a ground point given as world x and z, or
## null when the point is more than `reach_metres` outside the water.
func nearest(xz: Vector2) -> Hit:
	var key := Vector2i(floori(xz.x / BUCKET), floori(xz.y / BUCKET))
	if not _buckets.has(key):
		return null
	# The closest water's edge wins, so a wide pond doesn't claim points that
	# sit beside the narrow stream.
	var best_segment := -1
	var best_t := 0.0
	var best_distance := 0.0
	var best_edge := INF
	for s in _buckets[key]:
		var a := points[s]
		var ab := points[s + 1] - a
		var t := clampf((xz - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var distance := xz.distance_to(a + ab * t)
		var edge := distance - lerpf(half_widths[s], half_widths[s + 1], t)
		if edge < best_edge:
			best_edge = edge
			best_distance = distance
			best_segment = s
			best_t = t
	var a := points[best_segment]
	var b := points[best_segment + 1]
	var hit := Hit.new()
	hit.half_width = lerpf(half_widths[best_segment], half_widths[best_segment + 1], best_t)
	hit.distance = best_distance
	hit.level = lerpf(levels[best_segment], levels[best_segment + 1], best_t)
	hit.direction = (b - a).normalized()
	hit.along = lerpf(distances[best_segment], distances[best_segment + 1], best_t)
	return hit if hit.edge() <= reach_metres else null


## Metres from the source to the end.
func length() -> float:
	return distances[distances.size() - 1]


func _append(point: Vector2, half_width: float, level: float) -> void:
	if not points.is_empty() and points[points.size() - 1].distance_squared_to(point) < 1e-6:
		return
	distances.append(0.0 if points.is_empty() else distances[distances.size() - 1] + points[points.size() - 1].distance_to(point))
	points.append(point)
	half_widths.append(half_width)
	levels.append(level)


func _fill_buckets() -> void:
	for s in points.size() - 1:
		var grow := maxf(half_widths[s], half_widths[s + 1]) + reach_metres
		var low := Vector2(minf(points[s].x, points[s + 1].x), minf(points[s].y, points[s + 1].y)) - Vector2(grow, grow)
		var high := Vector2(maxf(points[s].x, points[s + 1].x), maxf(points[s].y, points[s + 1].y)) + Vector2(grow, grow)
		for bx in range(floori(low.x / BUCKET), floori(high.x / BUCKET) + 1):
			for bz in range(floori(low.y / BUCKET), floori(high.y / BUCKET) + 1):
				var key := Vector2i(bx, bz)
				# Packed arrays are values: append to a copy and store it back.
				var segments: PackedInt32Array = _buckets.get(key, PackedInt32Array())
				segments.append(s)
				_buckets[key] = segments
