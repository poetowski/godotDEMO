extends SceneTree
## Loads every script, scene and resource in the project's own folders so parse
## errors and broken references surface without opening the editor.
## Run it through `npm run check`, which also fails on any error in the log.

const ROOTS: Array[String] = ["res://src", "res://data", "res://assets", "res://tests", "res://tools"]
const EXTENSIONS: Array[String] = ["gd", "tscn", "scn", "tres", "res"]


func _initialize() -> void:
	var paths: Array[String] = []
	for root in ROOTS:
		_collect(root, paths)
	var failures: Array[String] = []
	for path in paths:
		if ResourceLoader.load(path) == null:
			failures.append(path)
	for path in failures:
		printerr("check: failed to load ", path)
	print("check: loaded %d of %d files" % [paths.size() - failures.size(), paths.size()])
	quit(1 if not failures.is_empty() else 0)


func _collect(dir_path: String, into: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.get_extension() in EXTENSIONS:
			into.append(dir_path.path_join(file))
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), into)
