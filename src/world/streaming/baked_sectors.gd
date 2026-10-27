class_name BakedSectors
extends RefCounted
## Where `npm run bake` keeps each sector design's generated content (a
## scene) and ground (heights and water), and whether those files are still
## fresh. They are stale once any source they come from is newer than the
## stamp written at the end of a bake; the game then generates designs live
## instead, which is slower but always current. Exported games trust them.

const FOLDER := "res://baked/sectors"
const STAMP := FOLDER + "/stamp.txt"
## What baked content is made from.
const SOURCES: Array[String] = ["res://src", "res://data", "res://tools/bake_sectors.gd"]
const SOURCE_EXTENSIONS: Array[String] = ["gd", "gdshader", "tscn", "tres", "res"]

## -1 not checked yet, 0 stale, 1 fresh.
static var _fresh := -1


static func scene_path(design_name: String) -> String:
	return "%s/%s.scn" % [FOLDER, design_name]


static func far_path(design_name: String) -> String:
	return "%s/%s.far.res" % [FOLDER, design_name]


## The baked far model of a design, or null when there is none or it's stale.
static func load_far(design_name: String) -> Mesh:
	var path := far_path(design_name)
	if not is_fresh() or not ResourceLoader.exists(path):
		return null
	return load(path) as Mesh


static func ground_path(design_name: String) -> String:
	return "%s/%s.ground.res" % [FOLDER, design_name]


## True if the baked files can be used. Checked once per run.
static func is_fresh() -> bool:
	if _fresh == -1:
		_fresh = 1 if _check() else 0
	return _fresh == 1


## Forgets the freshness check, after a bake or for tests.
static func forget() -> void:
	_fresh = -1


## The baked ground of a design, or null when there is no fresh one.
static func load_ground(design_name: String) -> SectorGround:
	var path := ground_path(design_name)
	if not is_fresh() or not ResourceLoader.exists(path):
		return null
	return load(path) as SectorGround


## The baked content scene of a design, or "" when there is no fresh one.
static func scene_for(design_name: String) -> String:
	var path := scene_path(design_name)
	return path if is_fresh() and ResourceLoader.exists(path) else ""


static func _check() -> bool:
	if not FileAccess.file_exists(STAMP):
		return false
	if OS.has_feature("template"):
		return true
	var stamp := FileAccess.get_modified_time(STAMP)
	for source in SOURCES:
		if _newest(source) > stamp:
			return false
	return true


## The newest modification time of the source files at or under a path.
static func _newest(path: String) -> int:
	if FileAccess.file_exists(path):
		return FileAccess.get_modified_time(path)
	var newest := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return newest
	for file in dir.get_files():
		if file.get_extension() in SOURCE_EXTENSIONS:
			newest = maxi(newest, FileAccess.get_modified_time(path.path_join(file)))
	for sub in dir.get_directories():
		newest = maxi(newest, _newest(path.path_join(sub)))
	return newest
