extends SceneTree
## Generates every sector design's content and ground once and saves them in
## res://baked/sectors, so the game loads them in the background instead of
## generating them while the player walks. Run it through `npm run bake`;
## `npm run game`, `shot` and `test` run it when the files are stale.
##
## A node a design added is saved with the scene; nodes that build their own
## children (a chest, a pickup) are saved without those children, since they
## build them again when they enter the tree.

const FIELD := "res://src/world/field/field.tscn"


func _initialize() -> void:
	var folder := ProjectSettings.globalize_path(BakedSectors.FOLDER)
	DirAccess.make_dir_recursive_absolute(folder)
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	var field := (load(FIELD) as PackedScene).instantiate()
	var failures := 0
	var started := Time.get_ticks_msec()
	for child in field.get_node("Sectors").get_children():
		var design := child as SectorDesign
		if design == null:
			continue
		var content := design.generate_content()
		_own(content, content)
		var scene := PackedScene.new()
		var packed := scene.pack(content)
		var saved := ResourceSaver.save(scene, BakedSectors.scene_path(design.name), ResourceSaver.FLAG_COMPRESS) if packed == OK else packed
		var grounded := ResourceSaver.save(design.ground(), BakedSectors.ground_path(design.name), ResourceSaver.FLAG_COMPRESS)
		content.free()
		if saved != OK or grounded != OK:
			printerr("bake: could not save %s: %s, %s" % [design.name, error_string(saved), error_string(grounded)])
			failures += 1
		else:
			print("bake: %s" % design.name)
	field.free()
	if failures == 0:
		var stamp := FileAccess.open(BakedSectors.STAMP, FileAccess.WRITE)
		stamp.store_string(Time.get_datetime_string_from_system() + "\n")
		stamp.close()
	print("bake: done in %d ms" % (Time.get_ticks_msec() - started))
	quit(1 if failures > 0 else 0)


## Makes `root` the owner of everything under `node`, except what scripted
## nodes build for themselves.
func _own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		if child.get_script() == null:
			_own(child, root)
