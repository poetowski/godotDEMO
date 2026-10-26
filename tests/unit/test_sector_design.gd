extends GutTest
## SectorDesign keeps a design to its own sectors: the ground eases back to
## flat at every edge shared with a sector it doesn't own, and props only fit
## inside.


## One metre of ground everywhere it owns.
class Plateau:
	extends SectorDesign

	func _ground(_xz: Vector2) -> float:
		return 1.0


var _design: Plateau


## An L of B2, C2 and B3, so C3 touches it only at an inner corner.
func before_each() -> void:
	_design = Plateau.new()
	_design.sectors = PackedStringArray(["B2", "C2", "B3"])
	add_child_autofree(_design)


func test_owns_only_its_sectors() -> void:
	assert_true(_design.owns(Vector2(15.0, -15.0)), "B2")
	assert_true(_design.owns(Vector2(25.0, -15.0)), "C2")
	assert_true(_design.owns(Vector2(15.0, -25.0)), "B3")
	assert_false(_design.owns(Vector2(25.0, -25.0)), "C3")
	assert_false(_design.owns(Vector2(5.0, -15.0)), "A2")


func test_full_height_inside() -> void:
	assert_almost_eq(_design.height_at(Vector2(15.0, -15.0)), 1.0, 0.001)


func test_eases_to_flat_at_foreign_edges() -> void:
	assert_almost_eq(_design.height_at(Vector2(10.001, -15.0)), 0.0, 0.001)
	assert_almost_eq(_design.height_at(Vector2(11.0, -15.0)), 0.5, 0.01)


func test_edges_between_its_own_sectors_stay_full_height() -> void:
	assert_almost_eq(_design.height_at(Vector2(20.0, -15.0)), 1.0, 0.001)
	assert_almost_eq(_design.height_at(Vector2(15.0, -20.0)), 1.0, 0.001)


func test_inner_corner_eases_to_flat() -> void:
	assert_almost_eq(_design.height_at(Vector2(19.999, -19.999)), 0.0, 0.001)
	var near_corner := _design.height_at(Vector2(19.0, -19.0))
	assert_between(near_corner, 0.1, 0.9)


func test_flat_and_dry_outside() -> void:
	assert_eq(_design.height_at(Vector2(5.0, -15.0)), 0.0)
	assert_eq(_design.water_level_at(Vector2(5.0, -15.0)), SectorDesign.NO_WATER)


func test_props_fit_only_inside() -> void:
	assert_true(_design.fits(Vector2(15.0, -15.0), 1.0))
	assert_false(_design.fits(Vector2(10.5, -15.0), 1.0), "would reach into A2")
	assert_true(_design.fits(Vector2(19.5, -15.0), 1.0), "reaches into C2, also owned")
	assert_false(_design.fits(Vector2(19.8, -19.8), 0.5), "would reach into C3")


func test_random_points_stay_inside() -> void:
	for i in 200:
		assert_true(_design.owns(_design.random_point()))


func test_start_points_are_kept_clear() -> void:
	var start := SectorMap.start_of(SectorMap.cell_named("B2"))
	assert_true(_design.crowds_start(Vector2(start.x, start.z), 0.3))
	assert_false(_design.crowds_start(Vector2(15.0, -18.0), 0.3))
