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
static var _noise: FastNoiseLite


static func configure(hill_height: float, hill_frequency: float = 0.02, hill_seed: int = 1) -> void:
	amplitude = hill_height
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
	return amplitude * (_noise.get_noise_2d(xz.x, xz.y) + 0.35) * smoothstep(0.0, border, inside)
