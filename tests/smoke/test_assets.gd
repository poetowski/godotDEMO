extends GutTest
## Assets made by /asset-design (assets/models/props/<slug>/<slug>.glb):
## each loads with meshes, solid ones with their own collision, is a sensible
## size, and has a prop scene (src/world/props/assets/<slug>.tscn) to place it
## with. New assets are covered without changes here; their own sizes are checked
## below.

const FOLDER := "res://assets/models/props"
const PROP_FOLDER := "res://src/world/props/assets"
## Expected height in metres (low, high) per asset, from its brief.
const HEIGHTS := {
	"mossy_boulder_a": Vector2(0.8, 1.2),
	"mossy_boulder_b": Vector2(1.0, 1.4),
	"reeds_a": Vector2(1.2, 1.6),
	"reeds_b": Vector2(0.8, 1.2),
	"cattails": Vector2(1.5, 1.9),
	"sedge_a": Vector2(0.35, 0.55),
	"sedge_b": Vector2(0.45, 0.7),
	"waterside_fern": Vector2(0.3, 0.6),
	"blue_flag_iris": Vector2(0.75, 1.0),
	"marsh_marigold": Vector2(0.25, 0.4),
	"willow_shrub": Vector2(1.3, 1.9),
	"young_willow": Vector2(3.7, 4.8),
}


func _slugs() -> PackedStringArray:
	var found := PackedStringArray()
	for folder in DirAccess.get_directories_at(FOLDER):
		if ResourceLoader.exists("%s/%s/%s.glb" % [FOLDER, folder, folder]):
			found.append(folder)
	return found


func test_there_are_assets() -> void:
	assert_gt(_slugs().size(), 0)


func test_every_asset_loads_and_stands_on_its_origin() -> void:
	for slug in _slugs():
		var model := (load("%s/%s/%s.glb" % [FOLDER, slug, slug]) as PackedScene).instantiate() as Node3D
		add_child(model)
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		assert_gt(meshes.size(), 0, "%s has meshes" % slug)
		var box := _bounds(meshes)
		assert_lt(box.size.length(), 30.0, "%s is a sensible size" % slug)
		assert_almost_eq(box.position.y, 0.0, 0.05, "%s stands on its origin" % slug)
		if HEIGHTS.has(slug):
			var height: Vector2 = HEIGHTS[slug]
			assert_between(box.size.y, height.x, height.y, "%s's height" % slug)
		model.free()


func test_every_asset_has_a_prop_scene_and_solid_ones_collide() -> void:
	for slug in _slugs():
		var path := "%s/%s.tscn" % [PROP_FOLDER, slug]
		assert_true(ResourceLoader.exists(path), "%s has a prop scene" % slug)
		var prop := (load(path) as PackedScene).instantiate() as Prop
		assert_not_null(prop)
		assert_eq(prop.kind, PropLibrary.Kind.ASSET)
		assert_eq(prop.asset.resource_path, "%s/%s/%s.glb" % [FOLDER, slug, slug])
		if prop.solid:
			var model := prop.asset.instantiate()
			assert_gt(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "%s has its collision" % slug)
			model.free()
		prop.free()


func _bounds(meshes: Array[Node]) -> AABB:
	var box := AABB()
	var first := true
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		var piece := mesh_instance.global_transform * mesh_instance.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	return box
