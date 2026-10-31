@tool
extends "res://src/world/field/sectors/r1_waterside/r1_waterside.gd"
## The river beyond R1: its delta, the rapids to the ravine's rim, and the fall.
## Everything the waterside grows, and besides it foaming stones in the rapids,
## gravel bars on the delta's shoals, cushions of moss in the fall's spray,
## bedrock showing along the fall, and dead trees on the rim. A block of sectors
## per design, so they stream. The brief is in docs/DESIGN_DECISIONS.md; the layout
## is placeholder.

## Where the fall runs (x east, y north), as in data/world/water/r1_water.tres.
const FALL_TOP := Vector2(-64.0, -10.0)
const FALL_BOTTOM := Vector2(-112.0, 3.0)
## Metres either side of the fall that its spray keeps wet.
const SPRAY := 14.0
## Metres along the fall between bedrock outcrops, on each side.
const OUTCROP_STEP := 9.0
## Metres from the fall's middle to the outcrops, least and most.
const OUTCROP_NEAR := 7.5
const OUTCROP_FAR := 14.0
## Flow in metres a second above which water counts as rapids.
const RAPIDS := 0.65
## Ground lower than this is below the rim.
const RIM_LEVEL := -2.5
const SNAG_TRIES := 40


func _grows_at(xz: Vector2) -> bool:
	return super(xz) or _from_fall(xz) < SPRAY


## Metres from the fall's middle, as seen from above.
func _from_fall(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	return north.distance_to(Geometry2D.get_closest_point_to_segment(north, FALL_TOP, FALL_BOTTOM))


## Plants grow bigger here, in the spray, so they keep further from a block's edge.
func _try_mass(xz: Vector2) -> void:
	if fits(xz, 1.1):
		super(xz)


func _choose(xz: Vector2, shore: float, depth: float) -> String:
	if depth > 0.0 and flow_at(xz).length() >= RAPIDS:
		var roll := rng.randf()
		if depth < 1.4 and roll < 0.1:
			return "rapid_stone_a" if rng.randf() < 0.45 else "rapid_stone_b"
		return "" if roll < 0.5 else _any_stone()
	# Shoals in the slow water.
	if depth > 0.0 and depth < 0.35 and rng.randf() < 0.05:
		return "gravel_bar"
	if depth <= 0.0 and _from_fall(xz) < SPRAY:
		var roll := rng.randf()
		if roll < 0.14:
			return "spray_moss"
		if roll < 0.2:
			return "waterside_fern"
		return "river_stone_c" if roll < 0.24 else ""
	return super(xz, shore, depth)


func _place_props() -> void:
	super()
	_place_outcrops()
	_place_snags()


## Bedrock either side of the fall, down its whole length, so it reads as a rock
## face with water coming down it.
func _place_outcrops() -> void:
	rng.seed = hash(Vector2i(design_seed, 91))
	var along := FALL_BOTTOM - FALL_TOP
	var across := along.orthogonal().normalized()
	var steps := floori(along.length() / OUTCROP_STEP)
	for k in steps + 1:
		for side: float in [-1.0, 1.0]:
			var reach := rng.randf_range(OUTCROP_NEAR, OUTCROP_FAR)
			var slide := rng.randf_range(-2.5, 2.5)
			var north := FALL_TOP + along * (float(k) / steps) + along.normalized() * slide + across * side * reach
			var xz := Vector2(north.x, -north.y)
			var slug := "cliff_outcrop_a" if rng.randf() < 0.55 else "cliff_outcrop_b"
			var size := rng.randf_range(0.9, 1.5)
			# Drawn whatever else: only the block owning the spot places it.
			if not owns(xz) or water_level_at(xz) != NO_WATER:
				continue
			_place_rock(slug, xz, size)


func _place_rock(slug: String, xz: Vector2, size: float) -> void:
	var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
	# Sunk, so a slope doesn't lift its uphill side off the ground.
	var where := Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 1.5) - 0.2, xz.y))
	place_prop(PropLibrary.Kind.ASSET, 0, where, true, PropLibrary.asset_scene(slug))


## Dead trees and boulders along the rim, near the top of the fall.
func _place_snags() -> void:
	rng.seed = hash(Vector2i(design_seed, 92))
	var placed := 0
	for attempt in SNAG_TRIES:
		if placed >= 3:
			break
		var north := FALL_TOP + Vector2(rng.randf_range(0.0, 20.0), rng.randf_range(-32.0, 32.0))
		var xz := Vector2(north.x, -north.y)
		var height := height_at(xz)
		if not owns(xz) or water_level_at(xz) != NO_WATER or height < RIM_LEVEL or _from_fall(xz) < 8.0:
			continue
		var slug := "wind_snag" if placed % 2 == 0 else "mossy_boulder_b"
		# The bend leans away from the drop, to the east.
		var size := rng.randf_range(0.9, 1.2)
		var basis := Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)).scaled(Vector3.ONE * size)
		place_prop(PropLibrary.Kind.ASSET, 0, Transform3D(basis, Vector3(xz.x, lowest_ground(xz, 0.5) - 0.05, xz.y)), true, PropLibrary.asset_scene(slug))
		placed += 1
