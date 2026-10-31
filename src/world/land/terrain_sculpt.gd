@tool
class_name TerrainSculpt
extends RefCounted
## The ground as sculpted by hand in the editor: metres added to or taken from
## the land, on a grid with a sample every metre at whole x and north (-z).
## WorldShape adds this last, so everything that asks about the ground (its
## meshes and collision, sector designs, trees, the sector grid) follows it.
##
## Kept in tiles, the same 100 m squares as the near terrain chunks, and only
## where something was sculpted: one file per tile in `folder`. A tile back to
## nothing loses its file. Worker threads read heights; while the editor writes
## (`editing`) the reads take a lock, and a tile is swapped whole.

## Metres, and samples, along a tile's side.
const TILE := 100
## Offsets smaller than this are nothing, in metres.
const NOTHING := 0.0005

## Where tiles are saved. Tests and the editor check point it elsewhere.
static var folder := "res://data/world/sculpt"
## True in the editor, where the tiles change while workers read them.
static var editing := false

static var _tiles: Dictionary[Vector2i, PackedFloat32Array] = {}
static var _loaded := false
static var _started_empty := false
static var _lock := Mutex.new()


## Reads the saved tiles, once per run.
static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	if not DirAccess.dir_exists_absolute(folder):
		return
	for file in DirAccess.get_files_at(folder):
		var tile := ResourceLoader.load(folder.path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE) as SculptTile
		if tile == null or tile.heights.size() != TILE * TILE:
			push_error("TerrainSculpt: can't read %s" % file)
			continue
		_tiles[key_of_file(file)] = tile.heights


## Reads the saved tiles again, as a new run would. Unsaved changes are lost.
static func read_again() -> void:
	_loaded = false
	_started_empty = false
	_tiles = {}
	load_all()


## Forgets everything sculpted and doesn't read the saved tiles, so tests see
## the land as the code makes it. Nothing on disk changes.
static func start_empty() -> void:
	_loaded = true
	_started_empty = true
	_tiles = {}


## True when `start_empty` left saved tiles unread, so anything baked from them
## doesn't match this run's land.
static func skips_saved_tiles() -> bool:
	return _started_empty and DirAccess.dir_exists_absolute(folder) and not DirAccess.get_files_at(folder).is_empty()


static func is_empty() -> bool:
	return _tiles.is_empty()


## The tiles holding something, for tests and tools.
static func tile_count() -> int:
	return _tiles.size()


## Metres sculpted at a world x and z, on the triangles the 1 m terrain draws.
static func height(xz: Vector2) -> float:
	if _tiles.is_empty():
		return 0.0
	var north := -xz.y
	var i := floori(xz.x)
	var j := floori(north)
	var fu := xz.x - i
	var fv := north - j
	if editing:
		_lock.lock()
	var south_west := _sample(i, j)
	var south_east := _sample(i + 1, j)
	var north_west := _sample(i, j + 1)
	var north_east := _sample(i + 1, j + 1)
	if editing:
		_lock.unlock()
	# Each square is two triangles split from south-east to north-west.
	if fu + fv <= 1.0:
		return south_west + (south_east - south_west) * fu + (north_west - south_west) * fv
	return north_east + (north_west - north_east) * (1.0 - fu) + (south_east - north_east) * (1.0 - fv)


## The sculpted metres at one sample.
static func sample(i: int, j: int) -> float:
	if editing:
		_lock.lock()
	var value := _sample(i, j)
	if editing:
		_lock.unlock()
	return value


## Adds to an area of samples: `deltas` holds area.size.x x area.size.y metres,
## row by row from the area's south-west.
static func add_area(area: Rect2i, deltas: PackedFloat32Array) -> void:
	for key in tiles_in(area):
		var tile_area := Rect2i(key * TILE, Vector2i.ONE * TILE).intersection(area)
		var grid: PackedFloat32Array = snapshot([key] as Array[Vector2i])[key]
		var changed := false
		for j in range(tile_area.position.y, tile_area.end.y):
			for i in range(tile_area.position.x, tile_area.end.x):
				var delta := deltas[(j - area.position.y) * area.size.x + i - area.position.x]
				if delta == 0.0:
					continue
				if grid.is_empty():
					grid.resize(TILE * TILE)
				grid[(j - key.y * TILE) * TILE + i - key.x * TILE] += delta
				changed = true
		if changed:
			_store(key, grid)


## The keys of the tiles an area of samples touches.
static func tiles_in(area: Rect2i) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	if not area.has_area():
		return keys
	for z in range(floori(float(area.position.y) / TILE), floori(float(area.end.y - 1) / TILE) + 1):
		for x in range(floori(float(area.position.x) / TILE), floori(float(area.end.x - 1) / TILE) + 1):
			keys.append(Vector2i(x, z))
	return keys


## Copies of some tiles as they stand; empty for a tile holding nothing.
static func snapshot(keys: Array[Vector2i]) -> Dictionary[Vector2i, PackedFloat32Array]:
	var copies: Dictionary[Vector2i, PackedFloat32Array] = {}
	if editing:
		_lock.lock()
	for key in keys:
		copies[key] = (_tiles.get(key, PackedFloat32Array()) as PackedFloat32Array).duplicate()
	if editing:
		_lock.unlock()
	return copies


## Puts tiles back as `snapshot` gave them.
static func restore(copies: Dictionary[Vector2i, PackedFloat32Array]) -> void:
	for key: Vector2i in copies:
		_store(key, copies[key])


## Writes some tiles to `folder`, or removes the file of a tile holding
## nothing. Returns the first error.
static func save(keys: Array[Vector2i]) -> Error:
	DirAccess.make_dir_recursive_absolute(folder)
	var result := OK
	for key in keys:
		var path := tile_path(key)
		var grid: PackedFloat32Array = snapshot([key] as Array[Vector2i])[key]
		var error := OK
		if _holds_something(grid):
			var tile := SculptTile.new()
			tile.heights = grid
			error = ResourceSaver.save(tile, path, ResourceSaver.FLAG_COMPRESS)
		elif FileAccess.file_exists(path):
			error = DirAccess.remove_absolute(path)
		if error != OK and result == OK:
			result = error
	return result


static func tile_path(key: Vector2i) -> String:
	return folder.path_join("tile_%d_%d.res" % [key.x, key.y])


static func key_of_file(file: String) -> Vector2i:
	var parts := file.get_basename().split("_")
	return Vector2i(parts[1].to_int(), parts[2].to_int())


## While editing, the caller holds the lock.
static func _sample(i: int, j: int) -> float:
	var key := Vector2i(floori(float(i) / TILE), floori(float(j) / TILE))
	if not _tiles.has(key):
		return 0.0
	return _tiles[key][(j - key.y * TILE) * TILE + i - key.x * TILE]


static func _store(key: Vector2i, grid: PackedFloat32Array) -> void:
	if editing:
		_lock.lock()
	if _holds_something(grid):
		_tiles[key] = grid
	else:
		_tiles.erase(key)
	if editing:
		_lock.unlock()


static func _holds_something(grid: PackedFloat32Array) -> bool:
	for value in grid:
		if absf(value) > NOTHING:
			return true
	return false
