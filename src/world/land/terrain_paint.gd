@tool
class_name TerrainPaint
extends RefCounted
## The ground as painted by hand in the editor: how much of each surface lies at
## each metre, on the same grid and in the same 100 m tiles as TerrainSculpt.
## Where the shares don't add up to everything, the land's own ground shows.
##
## Painting changes no heights and no meshes. The shares go to the ground shader
## as two world-sized textures (global shader parameters, so baked ground needs
## no copy), which is why a stroke shows at once and at every distance. While
## nothing is painted the textures are one black pixel.

## In the order the shader reads them. Placeholder: the list and the looks.
const NAMES: Array[String] = ["Dirt", "Mud", "Gravel", "Sand", "Dry grass", "Lush grass", "Cobblestone", "Flagstones"]
## The surfaces' colours on the panel, close to the shader's.
const SWATCHES: Array[Color] = [
	Color(0.45, 0.33, 0.21), Color(0.33, 0.25, 0.17), Color(0.52, 0.5, 0.45), Color(0.8, 0.72, 0.52),
	Color(0.68, 0.62, 0.33), Color(0.2, 0.42, 0.14), Color(0.46, 0.45, 0.43), Color(0.6, 0.57, 0.5),
]
const FIRST_PAVING := 6
const LAYERS := 8
const TILE := TerrainSculpt.TILE
## Bytes in a saved tile.
const TILE_BYTES := TILE * TILE * LAYERS
## The brush's way of taking paint away, in place of a surface.
const ERASE := -1

## Where tiles are saved. Tests and the editor check point it elsewhere.
static var folder := "res://data/world/paint"

static var _tiles: Dictionary[Vector2i, PackedByteArray] = {}
static var _loaded := false
## What the textures show, row by row from the south-west, four bytes a sample.
static var _first := PackedByteArray()
static var _second := PackedByteArray()
static var _size := Vector2i.ZERO
## The world's south-west corner, the textures' first sample.
static var _origin := Vector2i.ZERO
static var _textures: Array[ImageTexture] = []


## Reads the saved tiles, once per run, and gives the shader what it needs.
static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	if DirAccess.dir_exists_absolute(folder):
		for file in DirAccess.get_files_at(folder):
			var tile := ResourceLoader.load(folder.path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE) as PaintTile
			if tile == null or tile.layers.size() != TILE_BYTES:
				push_error("TerrainPaint: can't read %s" % file)
				continue
			_tiles[key_of_file(file)] = tile.layers
	publish()


## Reads the saved tiles again, as a new run would. Unsaved changes are lost.
static func read_again() -> void:
	_loaded = false
	_tiles = {}
	load_all()


## Forgets everything painted and doesn't read the saved tiles. Nothing on disk
## changes.
static func start_empty() -> void:
	_loaded = true
	_tiles = {}
	publish()


static func is_empty() -> bool:
	return _tiles.is_empty()


## Sends everything painted to the shader, sized for the world as it now is.
static func publish() -> void:
	if _tiles.is_empty():
		_show_nothing()
		return
	_make_room()
	for key: Vector2i in _tiles:
		_copy_to_textures(key)
	_push()


## How much of a surface lies at a whole-metre sample, 0 to 1.
static func share(i: int, j: int, surface: int) -> float:
	var key := Vector2i(floori(float(i) / TILE), floori(float(j) / TILE))
	if not _tiles.has(key):
		return 0.0
	return _tiles[key][_index(i - key.x * TILE, j - key.y * TILE) + surface] / 255.0


## How much of any paving lies at the sample nearest a world x and z, 0 to 1.
static func paving_at(xz: Vector2) -> float:
	var total := 0.0
	for surface in range(FIRST_PAVING, LAYERS):
		total += share(roundi(xz.x), roundi(-xz.y), surface)
	return total


## Lays a surface (or ERASE) over an area of samples. `amounts` holds
## area.size.x x area.size.y shares from 0 to 1, row by row from the south-west.
static func lay(area: Rect2i, amounts: PackedFloat32Array, surface: int) -> void:
	if _size != _world_size() or _origin != _world_origin():
		_make_room()
		for key: Vector2i in _tiles:
			_copy_to_textures(key)
	for key in TerrainSculpt.tiles_in(area):
		var tile_area := Rect2i(key * TILE, Vector2i.ONE * TILE).intersection(area)
		var grid: PackedByteArray = _tiles.get(key, PackedByteArray())
		var changed := false
		for j in range(tile_area.position.y, tile_area.end.y):
			for i in range(tile_area.position.x, tile_area.end.x):
				var amount := amounts[(j - area.position.y) * area.size.x + i - area.position.x]
				if amount <= 0.0:
					continue
				if grid.is_empty():
					if surface == ERASE:
						break
					grid.resize(TILE_BYTES)
				_lay_sample(grid, _index(i - key.x * TILE, j - key.y * TILE), ceili(amount * 255.0), surface)
				changed = true
		if changed:
			_store(key, grid)
			_copy_to_textures(key, tile_area)
	_push()


## Copies of some tiles as they stand; empty for a tile holding nothing.
static func snapshot(keys: Array[Vector2i]) -> Dictionary[Vector2i, PackedByteArray]:
	var copies: Dictionary[Vector2i, PackedByteArray] = {}
	for key in keys:
		copies[key] = (_tiles.get(key, PackedByteArray()) as PackedByteArray).duplicate()
	return copies


## Puts tiles back as `snapshot` gave them.
static func restore(copies: Dictionary[Vector2i, PackedByteArray]) -> void:
	for key: Vector2i in copies:
		_store(key, copies[key])
	publish()


## Writes some tiles to `folder`, or removes the file of a tile holding nothing.
## Returns the first error.
static func save(keys: Array[Vector2i]) -> Error:
	DirAccess.make_dir_recursive_absolute(folder)
	var result := OK
	for key in keys:
		var path := tile_path(key)
		var error := OK
		if _tiles.has(key):
			var tile := PaintTile.new()
			tile.layers = _tiles[key]
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


static func _index(i: int, j: int) -> int:
	return (j * TILE + i) * LAYERS


## The surface gains, and the others give way if the shares would pass 255.
static func _lay_sample(grid: PackedByteArray, at: int, amount: int, surface: int) -> void:
	if surface == ERASE:
		for k in LAYERS:
			grid[at + k] = maxi(grid[at + k] - amount, 0)
		return
	var gained := mini(grid[at + surface] + amount, 255)
	grid[at + surface] = gained
	var others := 0
	for k in LAYERS:
		if k != surface:
			others += grid[at + k]
	if others + gained <= 255:
		return
	var keep := float(255 - gained) / others
	for k in LAYERS:
		if k != surface:
			grid[at + k] = floori(grid[at + k] * keep)


static func _store(key: Vector2i, grid: PackedByteArray) -> void:
	if grid.count(0) < grid.size():
		_tiles[key] = grid
	else:
		_tiles.erase(key)
	if _size == _world_size() and _origin == _world_origin():
		_copy_to_textures(key)


static func _world_size() -> Vector2i:
	return Vector2i(SectorMap.extent())


static func _world_origin() -> Vector2i:
	return Vector2i(SectorMap.bounds().position)


## Clean textures the size of the world.
static func _make_room() -> void:
	_size = _world_size()
	_origin = _world_origin()
	_first = PackedByteArray()
	_first.resize(_size.x * _size.y * 4)
	_second = _first.duplicate()
	_textures = []


## Copies a tile, or the part of it in `area`, into the textures' bytes. A tile
## holding nothing clears its part.
static func _copy_to_textures(key: Vector2i, area: Rect2i = Rect2i()) -> void:
	var whole := Rect2i(key * TILE, Vector2i.ONE * TILE)
	var part := whole.intersection(Rect2i(_origin, _size))
	if area.has_area():
		part = part.intersection(area)
	var grid: PackedByteArray = _tiles.get(key, PackedByteArray())
	for j in range(part.position.y, part.end.y):
		for i in range(part.position.x, part.end.x):
			var to := ((j - _origin.y) * _size.x + i - _origin.x) * 4
			var from := _index(i - whole.position.x, j - whole.position.y)
			for k in 4:
				_first[to + k] = grid[from + k] if not grid.is_empty() else 0
				_second[to + k] = grid[from + 4 + k] if not grid.is_empty() else 0


## Sends the textures' bytes to the shader.
static func _push() -> void:
	var images: Array[Image] = [
		Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _first),
		Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _second),
	]
	if _textures.is_empty():
		_textures = [ImageTexture.create_from_image(images[0]), ImageTexture.create_from_image(images[1])]
		_set_globals(Vector2(_size))
	else:
		_textures[0].update(images[0])
		_textures[1].update(images[1])


static func _show_nothing() -> void:
	_size = Vector2i.ZERO
	_origin = Vector2i.ZERO
	_first = PackedByteArray()
	_second = PackedByteArray()
	var black := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	_textures = [ImageTexture.create_from_image(black), ImageTexture.create_from_image(black)]
	_set_globals(Vector2.ONE)


static func _set_globals(size: Vector2) -> void:
	RenderingServer.global_shader_parameter_set(&"terrain_paint_first", _textures[0])
	RenderingServer.global_shader_parameter_set(&"terrain_paint_second", _textures[1])
	RenderingServer.global_shader_parameter_set(&"terrain_paint_size", size)
	FieldTerrain.ground_material().set_shader_parameter(&"paint_origin", Vector2(_origin))
