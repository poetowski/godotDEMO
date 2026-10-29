extends GutTest
## Assets made by /asset-design (assets/models/props/<slug>/<slug>.glb):
## each loads with meshes and its own collision, is a sensible size, and has
## a prop scene (src/world/props/assets/<slug>.tscn) to place it with. New
## assets are covered without changes here; their own sizes are checked
## below.

const FOLDER := "res://assets/models/props"
const PROP_FOLDER := "res://src/world/props/assets"
## Expected height in metres (low, high) per asset, from its brief.
const HEIGHTS := {"alchemist_column": Vector2(1.8, 2.2)}


func _slugs() -> PackedStringArray:
	var found := PackedStringArray()
	for folder in DirAccess.get_directories_at(FOLDER):
		if ResourceLoader.exists("%s/%s/%s.glb" % [FOLDER, folder, folder]):
			found.append(folder)
	return found


func test_there_are_assets() -> void:
	assert_gt(_slugs().size(), 0)


func test_every_asset_loads_with_meshes_and_collision() -> void:
	for slug in _slugs():
		var model := (load("%s/%s/%s.glb" % [FOLDER, slug, slug]) as PackedScene).instantiate() as Node3D
		add_child(model)
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		assert_gt(meshes.size(), 0, "%s has meshes" % slug)
		assert_gt(model.find_children("*", "CollisionShape3D", true, false).size(), 0, "%s has its collision" % slug)
		var box := _bounds(meshes)
		assert_lt(box.size.length(), 30.0, "%s is a sensible size" % slug)
		assert_almost_eq(box.position.y, 0.0, 0.05, "%s stands on its origin" % slug)
		if HEIGHTS.has(slug):
			var height: Vector2 = HEIGHTS[slug]
			assert_between(box.size.y, height.x, height.y, "%s's height" % slug)
		model.free()


func test_every_asset_has_a_prop_scene() -> void:
	for slug in _slugs():
		var path := "%s/%s.tscn" % [PROP_FOLDER, slug]
		assert_true(ResourceLoader.exists(path), "%s has a prop scene" % slug)
		var prop := (load(path) as PackedScene).instantiate() as Prop
		assert_not_null(prop)
		assert_eq(prop.kind, PropLibrary.Kind.ASSET)
		assert_eq(prop.asset.resource_path, "%s/%s/%s.glb" % [FOLDER, slug, slug])
		prop.free()


func test_the_alchemist_column_stands_by_the_cottage() -> void:
	var world := (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(world)
	var cottage := world.get_node("Sectors/A5RainyCottage") as SectorDesign
	var content := cottage.generate_content()
	var column := content.find_child("AlchemistColumn*", false, false) as Node3D
	if column == null:
		for child in content.get_children():
			if child.scene_file_path.ends_with("alchemist_column.glb"):
				column = child as Node3D
	assert_not_null(column, "placed in the cottage's content")
	if column:
		assert_almost_eq(Vector2(column.position.x, column.position.z), Vector2(3.0, -44.3), Vector2.ONE * 0.01)
	content.free()
	world.free()


func _bounds(meshes: Array[Node]) -> AABB:
	var box := AABB()
	var first := true
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		var piece := mesh_instance.global_transform * mesh_instance.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	return box
