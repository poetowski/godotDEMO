@tool
class_name WorldShape
extends RefCounted
## The lay of the land under every sector, in layers that add up: rolling
## hills from Perlin noise, the landforms of region designs (Landforms:
## mountains, ridges, valleys...), and a little small-scale detail; easing
## back to flat near the world's border; and last what was sculpted by hand in
## the editor (TerrainSculpt). The hills and the detail stay off
## in the home area (R1) where the world is built by hand; landforms go
## wherever region designs put them. Designs add their own shapes on
## top, and the ground between them follows it, so hills run across sector
## borders without a step. Flat (amplitude 0) unless the world's root sets it,
## as the stress-test world did.

## Metres the hills rise and fall at most; 0 for flat.
static var amplitude := 0.0
static var frequency := 0.02
## Metres inside the grid's border over which the hills ease to flat.
static var border := 15.0
## Ground (world x and z, x east and y north as -z) kept flat, where the
## world is being built by hand; empty for none.
static var home := Rect2()
## Metres beyond `home` over which the hills rise to their full height.
static var home_blend := 300.0
## Ground whose outline the hills ease flat around, on both sides, like the
## world's border (x east, y north); empty for none.
static var rim := Rect2()
## Metres of small bumps on top of everything (beyond `home`).
static var detail := 0.5
static var _noise: FastNoiseLite
static var _detail_noise: FastNoiseLite


static func configure(hill_height: float, hill_frequency: float = 0.02, hill_seed: int = 1) -> void:
	amplitude = hill_height
	border = 15.0
	home = Rect2()
	rim = Rect2()
	frequency = hill_frequency
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.seed = hill_seed
	_noise.frequency = frequency
	_noise.fractal_octaves = 3
	_detail_noise = FastNoiseLite.new()
	_detail_noise.seed = hill_seed + 1
	_detail_noise.frequency = 0.09
	_detail_noise.fractal_octaves = 2
	Landforms.load_all()
	TerrainSculpt.load_all()


static func is_flat() -> bool:
	return amplitude == 0.0 and Landforms.sets().is_empty() and TerrainSculpt.is_empty()


## The height of the land at a world x and z.
static func height(xz: Vector2) -> float:
	return base_height(xz) + TerrainSculpt.height(xz)


## The height of the land before anything sculpted by hand.
static func base_height(xz: Vector2) -> float:
	if _noise == null:
		return 0.0
	var grid := Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y)
	var inside := _inside(grid, SectorMap.bounds())
	if rim.has_area():
		var within := _inside(grid, rim)
		inside = minf(inside, within if within >= 0.0 else _gap(grid, rim))
	var rise := 1.0
	if home.has_area():
		var outside := Vector2(maxf(home.position.x - grid.x, grid.x - home.end.x), maxf(home.position.y - grid.y, grid.y - home.end.y))
		rise = smoothstep(0.0, home_blend, maxf(maxf(outside.x, outside.y), 0.0))
	var edge := smoothstep(0.0, border, inside)
	# Flat worlds (no hills) get no detail either.
	var hills := 0.0 if amplitude == 0.0 else amplitude * (_noise.get_noise_2d(xz.x, xz.y) + 0.35) + detail * _detail_noise.get_noise_2d(xz.x, xz.y)
	return Landforms.shape_lakes(xz, hills * edge * rise + Landforms.height(xz) * edge)


## Metres inside a rectangle's nearest side; negative outside it.
static func _inside(point: Vector2, area: Rect2) -> float:
	return minf(minf(point.x - area.position.x, point.y - area.position.y), minf(area.end.x - point.x, area.end.y - point.y))


## Metres from a point outside a rectangle to the rectangle.
static func _gap(point: Vector2, area: Rect2) -> float:
	return Vector2(maxf(maxf(area.position.x - point.x, point.x - area.end.x), 0.0), maxf(maxf(area.position.y - point.y, point.y - area.end.y), 0.0)).length()


## True inside the flat home area.
static func is_home(xz: Vector2) -> bool:
	return home.has_area() and home.has_point(Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y))
