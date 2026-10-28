@tool
class_name WorldShape
extends RefCounted
## The lay of the land under every sector: rolling hills from Perlin noise,
## easing back to flat near the grid's border. Designs add their own shapes on
## top, and the ground between them follows it, so hills run across sector
## borders without a step. Flat (amplitude 0) unless the world's root sets it,
## as the stress-test world does.

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
static var _noise: FastNoiseLite


static func configure(hill_height: float, hill_frequency: float = 0.02, hill_seed: int = 1) -> void:
	amplitude = hill_height
	border = 15.0
	home = Rect2()
	frequency = hill_frequency
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.seed = hill_seed
	_noise.frequency = frequency
	_noise.fractal_octaves = 3


static func is_flat() -> bool:
	return amplitude == 0.0


## The height of the land at a world x and z.
static func height(xz: Vector2) -> float:
	if amplitude == 0.0 or _noise == null:
		return 0.0
	var grid := Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y)
	var extent := SectorMap.extent()
	var inside := minf(minf(grid.x, grid.y), minf(extent.x - grid.x, extent.y - grid.y))
	var rise := 1.0
	if home.has_area():
		var outside := Vector2(maxf(home.position.x - grid.x, grid.x - home.end.x), maxf(home.position.y - grid.y, grid.y - home.end.y))
		rise = smoothstep(0.0, home_blend, maxf(maxf(outside.x, outside.y), 0.0))
	return amplitude * (_noise.get_noise_2d(xz.x, xz.y) + 0.35) * smoothstep(0.0, border, inside) * rise


## True inside the flat home area.
static func is_home(xz: Vector2) -> bool:
	return home.has_area() and home.has_point(Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y))
