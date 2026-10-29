extends GutTest
## Sector B5: a great tree 18 m tall with a thick trunk, a big crown and
## glowing vines.

var _world: Node
var _design: SectorDesign


func before_all() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(_world)
	(_world.get_node("Streamer") as SectorStreamer).load_all_now()
	_design = _world.get_node("Sectors/B5GreatTree") as SectorDesign


func after_all() -> void:
	_world.free()


func test_the_tree_is_about_18_m_tall_with_a_big_crown() -> void:
	var box := AABB()
	var first := true
	for node in _design.content().find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.name.begins_with("Tree") or mesh.name.begins_with("Crown"):
			var piece := mesh.global_transform * mesh.get_aabb()
			box = piece if first else box.merge(piece)
			first = false
	assert_between(box.end.y - _design.height_at(Vector2(15.0, -45.0)), 16.5, 19.5, "18 m tall")
	assert_gt(box.size.x, 8.0, "a wide crown")


func test_the_vines_glow() -> void:
	var vines := _design.part("Vines") as MeshInstance3D
	assert_not_null(vines)
	var material := vines.material_override
	assert_true((material as StandardMaterial3D).emission_enabled)
	assert_not_null(_design.part("VineGlow"))
