@tool
extends "res://src/world/field/sectors/r1_waterside/r1_waterside.gd"
## The lake's far shores, in R4 and its tips in R5 and R6: everything the waterside
## grows, and besides it alders standing back from the water, flat slabs at the
## waterline and alders fallen into the lake. A block of sectors per design, so they
## stream. The brief is in docs/DESIGN_DECISIONS.md; the layout is placeholder.

## Places tried per sector for the big things.
const SHORE_TRIES := 30
## Metres at least between alders.
const ALDER_SPACING := 13.0
## Metres at least between fallen alders.
const FALLEN_SPACING := 45.0

var _alders: Array[Vector2] = []
var _fallen: Array[Vector2] = []


func _place_props() -> void:
	super()
	_alders.clear()
	_fallen.clear()
	for cell in cells():
		rng.seed = hash(Vector3i(design_seed + 2, cell.x, cell.y))
		var corner := SectorMap.corner_of(cell)
		for attempt in SHORE_TRIES:
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			var slug := _big_thing_at(xz)
			if slug.is_empty():
				continue
			var room := PropLibrary.asset_room(PropLibrary.asset_scene(slug))
			# Turned and scaled up, a model reaches this much further.
			if not fits(xz, room * 1.7) or crowds_start(xz, room) or not is_clear(xz, room * 0.7, 0.9):
				continue
			_place_big_thing(slug, xz)


func _big_thing_at(xz: Vector2) -> String:
	var shore := _shore_at(xz)
	var slope := _slope(xz)
	var roll := rng.randf()
	if shore > 4.0 and shore < 10.5 and slope < 0.5 and roll < 0.2 and _far_from(xz, _alders, ALDER_SPACING):
		return "lake_alder"
	if shore > 0.3 and shore < 2.5 and slope < STEEPEST and roll < 0.05 and _far_from(xz, _fallen, FALLEN_SPACING):
		return "fallen_alder"
	if shore > -1.0 and shore < 1.2 and slope < STEEPEST and roll < 0.12:
		return "shore_slab"
	return ""


func _far_from(xz: Vector2, others: Array[Vector2], metres: float) -> bool:
	for other in others:
		if xz.distance_to(other) < metres:
			return false
	return true


func _place_big_thing(slug: String, xz: Vector2) -> void:
	var size := rng.randf_range(0.9, 1.2)
	var angle := rng.randf() * TAU
	if slug == "lake_alder":
		_alders.append(xz)
	elif slug == "fallen_alder":
		_fallen.append(xz)
		# Crown first down the bank, so it lies out into the water.
		var east := height_at(xz + Vector2(0.5, 0.0)) - height_at(xz - Vector2(0.5, 0.0))
		var south := height_at(xz + Vector2(0.0, 0.5)) - height_at(xz - Vector2(0.0, 0.5))
		angle = atan2(south, -east) + rng.randf_range(-0.3, 0.3)
	var where := Transform3D(Basis(Vector3.UP, angle).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, 0.5) - 0.08, xz.y))
	place_prop(PropLibrary.Kind.ASSET, 0, where, true, PropLibrary.asset_scene(slug))
