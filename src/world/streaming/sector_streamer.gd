class_name SectorStreamer
extends Node
## Keeps the sector designs around the player loaded and the rest unloaded.
## Every `check_interval` seconds it measures, in sectors, how far each design
## is from the focus and from the camera: designs within `load_radius` load,
## nearest first, and designs beyond `unload_radius` unload; the gap between
## the two keeps designs at the edge from flickering in and out. Content comes
## from `npm run bake`'s scenes, read on a background thread, or is generated
## live when there is no fresh bake. At most one design is attached per frame.

signal design_loaded(design: SectorDesign)
signal design_unloaded(design: SectorDesign)

## The node whose SectorDesign children stream.
@export var designs_root: Node3D
## What the world loads around, usually the player. The current camera counts
## too.
@export var focus: Node3D
## Designs with a sector this many sectors or nearer load.
@export var load_radius: int = 4
## Designs with every sector farther than this many sectors unload.
@export var unload_radius: int = 5
@export var check_interval: float = 0.25
## Whether loading and unloading follow the focus. load_all_now turns it off.
@export var active: bool = true

## Designs waiting to load, with the baked scene being read ("" to generate).
var _pending: Dictionary[SectorDesign, String] = {}
## Background reads nobody waits for any more (their design was unloaded or
## loaded another way), collected once they finish so they don't leak.
var _abandoned: PackedStringArray = []
var _timer := 0.0


func _ready() -> void:
	add_to_group(&"sector_streamers")


## Collects reads still running, so leaving a world mid-load leaks nothing.
func _exit_tree() -> void:
	for path: String in _pending.values():
		if not path.is_empty():
			ResourceLoader.load_threaded_get(path)
	_pending.clear()
	for path in _abandoned:
		ResourceLoader.load_threaded_get(path)
	_abandoned.clear()


func _process(delta: float) -> void:
	_collect_abandoned()
	_attach_one()
	_timer -= delta
	if active and _timer <= 0.0:
		_timer = check_interval
		update()


## Requests the designs near the focus and unloads the far ones.
func update() -> void:
	var focus_cells := _focus_cells()
	var wanted: Array[SectorDesign] = []
	for design in _designs():
		var distance := _distance(design, focus_cells)
		if distance <= load_radius:
			wanted.append(design)
		elif distance > unload_radius:
			unload(design)
	wanted.sort_custom(func(a: SectorDesign, b: SectorDesign) -> bool: return _distance(a, focus_cells) < _distance(b, focus_cells))
	for design in wanted:
		_request(design)


## Loads the designs near the focus at once, for the start of a game.
func load_around_now() -> void:
	var focus_cells := _focus_cells()
	for design in _designs():
		if _distance(design, focus_cells) <= load_radius:
			_load_now(design)


## Loads every design at once and stops streaming, for tests and tools.
func load_all_now() -> void:
	active = false
	for design in _designs():
		_load_now(design)


## Unloads every design, for loading a save somewhere else.
func unload_all() -> void:
	for design in _designs():
		unload(design)


func unload(design: SectorDesign) -> void:
	_abandon(design)
	if design.is_content_loaded():
		design.detach_content()
		design_unloaded.emit(design)


## True once everything near the focus is loaded.
func is_settled() -> bool:
	if active:
		update()
	return _pending.is_empty()


## True while a design's content is being read or waits to be attached.
func is_loading(design: SectorDesign) -> bool:
	return _pending.has(design)


func loaded_designs() -> Array[SectorDesign]:
	return _designs().filter(func(design: SectorDesign) -> bool: return design.is_content_loaded())


func _designs() -> Array[SectorDesign]:
	var found: Array[SectorDesign] = []
	if designs_root:
		for child in designs_root.get_children():
			if child is SectorDesign:
				found.append(child as SectorDesign)
	return found


func _request(design: SectorDesign) -> void:
	if design.is_content_loaded() or _pending.has(design):
		return
	var path := BakedSectors.scene_for(design.name)
	if not path.is_empty():
		ResourceLoader.load_threaded_request(path, "PackedScene", true)
	_pending[design] = path


## Attaches the nearest design whose content is ready: a baked scene read in
## the background, or one generated now.
func _attach_one() -> void:
	for design: SectorDesign in _pending.keys():
		var path := _pending[design]
		if not path.is_empty():
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				continue
			_pending.erase(design)
			var scene := ResourceLoader.load_threaded_get(path) as PackedScene if status == ResourceLoader.THREAD_LOAD_LOADED else null
			_attach(design, scene.instantiate() as Node3D if scene else design.generate_content())
		else:
			_pending.erase(design)
			_attach(design, design.generate_content())
		return


func _load_now(design: SectorDesign) -> void:
	if design.is_content_loaded():
		return
	var path := BakedSectors.scene_for(design.name)
	var scene: PackedScene = null
	if _pending.get(design, "") == path and not path.is_empty():
		# Already being read in the background: wait for that read.
		_pending.erase(design)
		scene = ResourceLoader.load_threaded_get(path) as PackedScene
	else:
		_abandon(design)
		scene = load(path) as PackedScene if not path.is_empty() else null
	_attach(design, scene.instantiate() as Node3D if scene else design.generate_content())


## Stops waiting for a design; its background read, if any, is collected
## later.
func _abandon(design: SectorDesign) -> void:
	var path: String = _pending.get(design, "")
	_pending.erase(design)
	if not path.is_empty():
		_abandoned.append(path)


func _collect_abandoned() -> void:
	for k in range(_abandoned.size() - 1, -1, -1):
		if ResourceLoader.load_threaded_get_status(_abandoned[k]) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(_abandoned[k])
			_abandoned.remove_at(k)


func _attach(design: SectorDesign, content: Node3D) -> void:
	design.attach_content(content)
	design_loaded.emit(design)


## The cells under the focus and the current camera.
func _focus_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	for watcher: Node3D in [focus, camera]:
		if watcher and watcher.is_inside_tree():
			var at := watcher.global_position
			cells.append(SectorMap.unbounded_cell_at(Vector2(at.x, at.z)))
	return cells


## Sectors from the nearest focus cell to the nearest owned cell, counting
## diagonal steps as one.
func _distance(design: SectorDesign, focus_cells: Array[Vector2i]) -> int:
	var nearest := 1 << 30
	for cell in design.cells():
		for at in focus_cells:
			nearest = mini(nearest, maxi(absi(cell.x - at.x), absi(cell.y - at.y)))
	return nearest
