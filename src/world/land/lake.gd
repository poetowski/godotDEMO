@tool
class_name Lake
extends Resource
## A lake in a region design: a basin carved into the land with a flat water
## surface at `level`, a bank just above it all round (raised where the land
## is lower), an optional island in the middle, and thick woods on its
## shores. Its outline wavers a little. It reaches out to `reach()` from
## `centre`, where it blends back into the land. Positions are world metres,
## x east and y north, like Landform's.

## Its middle (x east, y north).
@export var centre: Vector2 = Vector2.ZERO
## Metres from the middle to the shore, on average.
@export var radius: float = 60.0
## The water's surface, in metres (absolute height).
@export var level: float = 0.0
## Metres from the surface to the deepest bed.
@export var depth: float = 4.0
## An island in the middle: metres from its middle to its shore (0 for
## none), and how high it rises above the water.
@export var island_radius: float = 0.0
@export var island_height: float = 5.0
## How likely a tree is on its shores (and island), 0 to 1, whatever the
## woods around do.
@export_range(0.0, 1.0) var shore_woods: float = 0.85

## Where the bed starts rising to the bank, and how far beyond the shore
## (in radii) the land blends back, as fractions of the radius.
const BED := 0.88
const BLEND := 1.3
## The water stops this far in from the shore, under the bank.
const WATER := 0.95
## How much the outline wavers, at most.
const WOBBLE := 0.08


## Metres from the middle to its edge (where it stops changing the land).
func reach() -> float:
	return radius * BLEND * (1.0 + WOBBLE)


## The box it can reach, x east and y north.
func bounds() -> Rect2:
	return Rect2(centre - Vector2.ONE * reach(), Vector2.ONE * reach() * 2.0)


## The shore's distance from the middle in the direction of a point.
func shore(north: Vector2) -> float:
	var to := north - centre
	var angle := atan2(to.y, to.x)
	return radius * (1.0 + 0.05 * sin(3.0 * angle) + 0.03 * sin(5.0 * angle + 1.0))


## The land at a world x and z, given the land without the lake.
func shape(xz: Vector2, land: float) -> float:
	var north := Vector2(xz.x, -xz.y)
	var distance := north.distance_to(centre)
	var t := distance / shore(north)
	if t >= BLEND:
		return land
	var bank := maxf(land, level + 0.6)
	var height: float
	if t < BED:
		var u := t / BED
		height = level - 0.4 - (depth - 0.4) * (1.0 - u * u)
	else:
		height = lerpf(level - 0.4, bank, smoothstep(BED, 1.0, t))
	if t > 1.0:
		height = lerpf(bank, land, smoothstep(1.0, BLEND, t))
	if island_radius > 0.0 and distance < island_radius:
		var p := 1.0 - distance / island_radius
		height = maxf(height, level - depth + (island_height + depth) * p * p * (3.0 - 2.0 * p))
	return height


## The water's surface at a world x and z, or SectorDesign.NO_WATER.
func level_at(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	return level if north.distance_to(centre) < shore(north) * WATER else SectorDesign.NO_WATER


## How far around it the shore woods reach, 0 to 1 at a point.
func woods_at(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	var t := north.distance_to(centre) / shore(north)
	return shore_woods * (1.0 - smoothstep(1.3, 1.6, t))
