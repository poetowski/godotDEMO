@tool
class_name Landform
extends Resource
## One shape in the land: a mountain, hill, ridge, valley or plateau, added
## to the world's height wherever it reaches (`WorldShape`). It rises from
## nothing at its edge, so it never reaches past `radius` from its centre
## (or from the line between `centre` and `end`, for a ridge). Region
## designs (LandformSet) are made of these. Positions are world metres: x to
## the east, y to the north (y = -z in the world).

enum Kind { MOUNTAIN, HILL, RIDGE, VALLEY, PLATEAU }

@export var kind: Kind = Kind.HILL
## Where it stands (x east, y north, metres).
@export var centre: Vector2 = Vector2.ZERO
## A ridge's other end; unused by the other kinds.
@export var end: Vector2 = Vector2.ZERO
## Metres from the centre (or the ridge's line) to where it meets the land.
@export var radius: float = 50.0
## Metres it rises at its highest (a valley sinks by this much).
@export var height: float = 20.0
## 0 smooth to 1 craggy: ridges and gullies on the slopes and an uneven
## outline.
@export_range(0.0, 1.0) var roughness: float = 0.3
## How many trees grow on it compared with the woods around, 0 to 1.
@export_range(0.0, 1.0) var tree_density: float = 1.0
## Metres above which no trees grow on it (absolute height); 0 for none.
@export var tree_line: float = 0.0
## Metres above which its ground is snow (absolute height); 0 for none.
@export var snow_line: float = 0.0
## Shapes the noise of its slopes, so twin landforms differ.
@export var noise_seed: int = 1

var _noise: FastNoiseLite


## Metres it adds to the land at a point (negative for a valley).
func height_at(xz: Vector2) -> float:
	var reach := _reach(xz)
	if reach >= 1.0:
		return 0.0
	var p := 1.0 - reach
	match kind:
		Kind.MOUNTAIN:
			# Gentle feet, steepening flanks, a sharp top, gullies and ridges.
			var cone := pow(p, 1.7)
			var crest := p * p * (3.0 - 2.0 * p)
			var shape := lerpf(crest, cone, 0.55)
			var ridges := 1.0 - absf(_noise_at(xz * 0.035))
			return height * shape * (1.0 - roughness * 0.35 + roughness * 0.35 * ridges)
		Kind.RIDGE:
			var ridges := 1.0 - absf(_noise_at(xz * 0.04))
			return height * p * p * (3.0 - 2.0 * p) * (1.0 - roughness * 0.3 + roughness * 0.3 * ridges)
		Kind.VALLEY:
			return -height * p * p * (3.0 - 2.0 * p)
		Kind.PLATEAU:
			return height * smoothstep(0.0, 0.35, p)
	return height * p * p * (3.0 - 2.0 * p)


## How much of it covers a point: 1 well inside, 0 outside.
func cover_at(xz: Vector2) -> float:
	return 1.0 - smoothstep(0.75, 1.0, _reach(xz))


## The box it can reach, x east and y north.
func bounds() -> Rect2:
	var low := Vector2(minf(centre.x, end.x if kind == Kind.RIDGE else centre.x), minf(centre.y, end.y if kind == Kind.RIDGE else centre.y))
	var high := Vector2(maxf(centre.x, end.x if kind == Kind.RIDGE else centre.x), maxf(centre.y, end.y if kind == Kind.RIDGE else centre.y))
	var grow := radius * (1.0 + roughness * 0.2)
	return Rect2(low - Vector2.ONE * grow, high - low + Vector2.ONE * grow * 2.0)


## 0 at the centre (or the ridge's line), 1 at the edge; the edge wavers
## with roughness.
func _reach(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	var distance: float
	if kind == Kind.RIDGE:
		distance = Geometry2D.get_closest_point_to_segment(north, centre, end).distance_to(north)
	else:
		distance = north.distance_to(centre)
	var wobble := 1.0 + roughness * 0.18 * _noise_at(north * 0.012 + Vector2(37.0, 11.0))
	return distance / (radius * wobble)


## Sets up its noise. Called once when loaded, before any worker thread
## asks for heights.
func prepare() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = noise_seed
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.fractal_octaves = 3


func _noise_at(p: Vector2) -> float:
	if _noise == null:
		prepare()
	return _noise.get_noise_2d(p.x, p.y)
