@tool
class_name PocLayout
extends RefCounted
## Where things sit in the castle proof of concept, and the terrain height
## field that every generator samples. All of it is PoC placeholder content.
##
## The world is a square of SIZE metres centred on the origin. Positions are
## given as Vector2(x, z).

const SIZE := 200.0
const GRID := 201
const HILLS := 3.5
const RIM_HEIGHT := 12.0
const SEED := 2026

const CASTLE_CENTER := Vector2(0.0, -48.0)
const CASTLE_GROUND := 4.0
const CASTLE_FLAT_RADIUS := 28.0
const CASTLE_SLOPE := 14.0

const SPAWN := Vector2(2.0, 70.0)
const SWORD := Vector2(-13.0, 45.0)
const PATH_HALF_WIDTH := 1.6

## Control points of the path from the spawn meadow, through the gate, to the keep.
const PATH_CONTROL_POINTS: Array[Vector2] = [
	Vector2(3.0, 80.0), Vector2(2.0, 70.0), Vector2(-5.0, 58.0), Vector2(-8.0, 44.0),
	Vector2(-2.0, 30.0), Vector2(6.0, 16.0), Vector2(8.0, 2.0), Vector2(3.0, -12.0),
	Vector2(0.0, -24.0), Vector2(0.0, -32.0), Vector2(0.0, -41.0),
]

const _FAR := 1.0e6
const _PATH_SAMPLES_PER_SPAN := 10
const _PATH_RASTER_MARGIN := 10.0

static var _heights := PackedFloat32Array()
static var _path_distance := PackedFloat32Array()
static var _path := PackedVector2Array()


## Heights for the whole grid, row by row along z, one metre apart.
static func heights() -> PackedFloat32Array:
	_ensure_built()
	return _heights


## Terrain height at any point, interpolated between grid samples.
static func height_at(x: float, z: float) -> float:
	_ensure_built()
	return _sample(_heights, x, z)


## Ground position for a point given as Vector2(x, z).
static func ground(point: Vector2) -> Vector3:
	return Vector3(point.x, height_at(point.x, point.y), point.y)


## Approximate terrain normal at a point.
static func normal_at(x: float, z: float) -> Vector3:
	var dx := height_at(x - 0.5, z) - height_at(x + 0.5, z)
	var dz := height_at(x, z - 0.5) - height_at(x, z + 0.5)
	return Vector3(dx, 1.0, dz).normalized()


## Distance from a point to the path's centre line (large when far away).
static func path_distance_at(x: float, z: float) -> float:
	_ensure_built()
	return _sample(_path_distance, x, z)


## The path's centre line as a dense polyline.
static func path_points() -> PackedVector2Array:
	_ensure_built()
	return _path


## World coordinate of grid index `i` along either axis.
static func grid_coordinate(i: int) -> float:
	return i - (GRID - 1) * 0.5


static func _ensure_built() -> void:
	if not _heights.is_empty():
		return
	_path = _catmull_rom(PATH_CONTROL_POINTS, _PATH_SAMPLES_PER_SPAN)
	_path_distance = _rasterize_distance(_path)

	var bumps := FastNoiseLite.new()
	bumps.seed = SEED
	bumps.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	bumps.frequency = 0.035
	bumps.fractal_octaves = 3
	var swells := FastNoiseLite.new()
	swells.seed = SEED + 1
	swells.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	swells.frequency = 0.008
	swells.fractal_octaves = 2

	_heights.resize(GRID * GRID)
	for iz in GRID:
		var z := grid_coordinate(iz)
		for ix in GRID:
			var x := grid_coordinate(ix)
			var gentle := swells.get_noise_2d(x, z) * HILLS * 1.2
			var h := gentle + bumps.get_noise_2d(x, z) * HILLS
			var rim := maxf(absf(x), absf(z)) / (SIZE * 0.5)
			h += smoothstep(0.78, 1.0, rim) * RIM_HEIGHT
			var point := Vector2(x, z)
			var level := 1.0 - smoothstep(PATH_HALF_WIDTH, PATH_HALF_WIDTH + 4.0, _path_distance[iz * GRID + ix])
			level = maxf(level, 1.0 - smoothstep(4.0, 9.0, point.distance_to(SPAWN)))
			level = maxf(level, 1.0 - smoothstep(3.0, 7.0, point.distance_to(SWORD)))
			h = lerpf(h, gentle, level)
			var plateau := 1.0 - smoothstep(CASTLE_FLAT_RADIUS, CASTLE_FLAT_RADIUS + CASTLE_SLOPE, point.distance_to(CASTLE_CENTER))
			_heights[iz * GRID + ix] = lerpf(h, CASTLE_GROUND, plateau)


static func _sample(grid: PackedFloat32Array, x: float, z: float) -> float:
	var half := (GRID - 1) * 0.5
	var fx := clampf(x + half, 0.0, GRID - 1.001)
	var fz := clampf(z + half, 0.0, GRID - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var i := iz * GRID + ix
	var top := lerpf(grid[i], grid[i + 1], tx)
	var bottom := lerpf(grid[i + GRID], grid[i + GRID + 1], tx)
	return lerpf(top, bottom, tz)


static func _catmull_rom(points: Array[Vector2], samples_per_span: int) -> PackedVector2Array:
	var dense := PackedVector2Array()
	var last := points.size() - 1
	for i in last:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, last)]
		for s in samples_per_span:
			var t := float(s) / samples_per_span
			var t2 := t * t
			var t3 := t2 * t
			dense.append(0.5 * (2.0 * p1 + (p2 - p0) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
	dense.append(points[last])
	return dense


## Distance to the polyline for every grid sample within reach of it.
static func _rasterize_distance(polyline: PackedVector2Array) -> PackedFloat32Array:
	var distances := PackedFloat32Array()
	distances.resize(GRID * GRID)
	distances.fill(_FAR)
	var half := (GRID - 1) * 0.5
	for i in polyline.size() - 1:
		var a := polyline[i]
		var b := polyline[i + 1]
		var x0 := clampi(int(floorf(minf(a.x, b.x) - _PATH_RASTER_MARGIN + half)), 0, GRID - 1)
		var x1 := clampi(int(ceilf(maxf(a.x, b.x) + _PATH_RASTER_MARGIN + half)), 0, GRID - 1)
		var z0 := clampi(int(floorf(minf(a.y, b.y) - _PATH_RASTER_MARGIN + half)), 0, GRID - 1)
		var z1 := clampi(int(ceilf(maxf(a.y, b.y) + _PATH_RASTER_MARGIN + half)), 0, GRID - 1)
		for iz in range(z0, z1 + 1):
			for ix in range(x0, x1 + 1):
				var p := Vector2(ix - half, iz - half)
				var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
				var index := iz * GRID + ix
				if d < distances[index]:
					distances[index] = d
	return distances
