extends SceneTree
## What the land as it is now means for what stands on it, for `npm run land-check`,
## after the author sculpts: props floating, buried, drowned or left far from the
## water; water cut short or missing; shores with no decoration; borders that no longer
## fit the ground; and sculpted land nothing decorates yet. It only reports and changes
## nothing. /land-sync reads the report and proposes what to do about it.

const SCENE := "res://src/world/field/field.tscn"
const Settle := preload("res://tools/settle_props.gd")
## Metres under the water at which a prop has drowned.
const DROWNED := 0.8
## Metres from the water at which something that lies at the waterline is stranded.
const STRANDED := 8
const WATERLINE_PROPS: Array[String] = ["driftwood_log", "driftwood_branch", "fallen_alder", "shore_slab"]
## Metres from the water within which a sector wants decorating.
const SHORE := 7
## Metres from the water within which a decoration block has something to do.
const BLOCK_REACH := 11
## Metres sculpted downward that may be a dug hollow, its least samples, and how deep
## it must be below its lowest way out.
const DUG := 0.8
const SMALLEST_HOLLOW := 40
const HOLDS := 0.5
## How far down the ground should lie under a border's line, and under the fog's.
const BORDER_GROUND := Vector2(-12.0, -3.0)
const FOG_GROUND := Vector2(-30.0, -5.0)
## Sectors in a block of decoration, along a side.
const BLOCK := 5
## Rise per metre that counts as steep, and metres above the land that count as high.
const STEEP := 1.0
const HIGH := 4.0
const MOST_LISTED := 40
## Metres from the border within which land counts as the ravine's rim.
const RIM_METRES := 25.0

var _area := Rect2i()
var _wet := PackedByteArray()
var _distance := PackedInt32Array()
var _border: ZoneBorder


func _initialize() -> void:
	FieldWorld.configure()
	var world := (load(SCENE) as PackedScene).instantiate()
	_border = world.get_node("ZoneBorder") as ZoneBorder
	_border.rebuild()
	_read_water()
	_report_tiles()
	_report_props(world)
	_report_water()
	_report_decoration(world)
	_report_lines(world)
	_report_bare_land(world)
	world.free()
	quit()


func _report_tiles() -> void:
	var regions := {}
	var tiles := OS.get_cmdline_user_args()
	for tile in tiles:
		var parts := tile.split(",")
		var corner := Vector2(parts[0].to_int(), parts[1].to_int()) * TerrainSculpt.TILE
		for offset: Vector2 in [Vector2(1.0, 1.0), Vector2(99.0, 1.0), Vector2(1.0, 99.0), Vector2(99.0, 99.0)]:
			var at := corner + offset
			regions[SectorMap.name_of(SectorMap.unbounded_cell_at(Vector2(at.x, -at.y))).get_slice(":", 0)] = true
	if tiles.is_empty():
		print("[land] no uncommitted land: checking everything as it stands")
	else:
		print("[land] changed tiles (x,north): %s; in about %s" % [" ".join(tiles), ", ".join(PackedStringArray(regions.keys()))])


## Per sample in the world: whether water stands there, and metres to the nearest
## water, ring by ring.
func _read_water() -> void:
	var bounds := SectorMap.bounds()
	_area = Rect2i(bounds)
	var columns := _area.size.x
	_wet.resize(columns * _area.size.y)
	_distance.resize(_wet.size())
	_distance.fill(1 << 20)
	var ring: Array[int] = []
	for j in _area.size.y:
		for i in columns:
			if _is_wet(_xz(i, j)):
				var k := j * columns + i
				_wet[k] = 1
				_distance[k] = 0
				ring.append(k)
	var distance := 0
	while not ring.is_empty() and distance < BLOCK_REACH + STRANDED:
		distance += 1
		var next: Array[int] = []
		for k in ring:
			for side: int in [1, -1, columns, -columns]:
				var other := k + side
				if other >= 0 and other < _distance.size() and _distance[other] > distance:
					_distance[other] = distance
					next.append(other)
		ring = next


func _is_wet(xz: Vector2) -> bool:
	var level := WaterField.level_at(xz)
	return level != SectorDesign.NO_WATER and level > WorldShape.height(xz)


func _xz(i: int, j: int) -> Vector2:
	return Vector2(_area.position.x + i, -(_area.position.y + j))


func _distance_at(xz: Vector2) -> int:
	var i := roundi(xz.x) - _area.position.x
	var j := roundi(-xz.y) - _area.position.y
	if i < 0 or j < 0 or i >= _area.size.x or j >= _area.size.y:
		return 1 << 20
	return _distance[j * _area.size.x + i]


func _sector(xz: Vector2) -> String:
	return SectorMap.name_of(SectorMap.unbounded_cell_at(xz))


func _report_props(world: Node) -> void:
	var floating := PackedStringArray()
	var buried := PackedStringArray()
	var drowned := PackedStringArray()
	var stranded := PackedStringArray()
	var used := {}
	var total := 0
	for design in world.get_node("Sectors").get_children():
		var props := design.get_node_or_null("Props")
		if props == null:
			continue
		for child in props.get_children():
			var prop := child as Prop
			if prop == null or prop.asset == null:
				continue
			total += 1
			var slug := prop.asset.resource_path.get_file().get_basename()
			used[slug] = used.get(slug, 0) + 1
			var xz := Vector2(prop.position.x, prop.position.z)
			var line := "%s/%s %s in %s" % [design.name, prop.name, slug, _sector(xz)]
			var off := prop.position.y - Settle.standing_height(prop)
			if off > Settle.TOLERANCE:
				floating.append("%s, %.2f m up" % [line, off])
			elif off < -Settle.TOLERANCE:
				buried.append("%s, %.2f m down" % [line, -off])
			var level := WaterField.level_at(xz)
			if level != SectorDesign.NO_WATER and level - WorldShape.height(xz) > DROWNED:
				drowned.append("%s, %.2f m under" % [line, level - WorldShape.height(xz)])
			elif slug in WATERLINE_PROPS and _distance_at(xz) > STRANDED:
				stranded.append(line)
	print("[land] props: %d" % total)
	_list("floating (npm run settle lowers them)", floating)
	_list("buried (npm run settle raises them)", buried)
	_list("drowned (settling won't help: move or remove)", drowned)
	_list("stranded from the water (move or remove)", stranded)
	var unused := PackedStringArray()
	for file in DirAccess.get_files_at("res://src/world/props/assets"):
		if file.ends_with(".tscn") and not used.has(file.get_basename()):
			unused.append(file.get_basename())
	_list("assets placed nowhere by hand (may still be masses)", unused)


func _report_water() -> void:
	for plan in WaterField.saved_plans():
		if not is_inf(plan.lake_level):
			_report_lake_edge(plan)
		for course in plan.courses:
			var dry := PackedStringArray()
			for k in course.points.size():
				var xz := Vector2(course.points[k].x, -course.points[k].y)
				if WorldShape.height(xz) >= course.levels[k]:
					dry.append(_sector(xz))
			if not dry.is_empty():
				_list("river points left above their water, in %s" % plan.resource_path.get_file(), dry)
		for fall in plan.falls:
			var top := Vector2(fall.top.x, -fall.top.y)
			var bottom := Vector2(fall.bottom.x, -fall.bottom.y)
			print("[land] fall at %s drops %.1f m" % [_sector(top), WorldShape.height(top) - WorldShape.height(bottom)])
	_report_hollows()


## A lake stops at its reach: ground below its level just past there means it's cut off.
func _report_lake_edge(plan: RegionWater) -> void:
	var cut := {}
	var reach := roundi(plan.lake_reach)
	var seed_at := Vector2i(plan.lake_seed)
	for k in range(-reach, reach + 1):
		for pair: Array in [
			[Vector2i(reach, k), Vector2i(1, 0)], [Vector2i(-reach, k), Vector2i(-1, 0)],
			[Vector2i(k, reach), Vector2i(0, 1)], [Vector2i(k, -reach), Vector2i(0, -1)],
		]:
			var edge: Vector2i = pair[0]
			var outward: Vector2i = pair[1]
			var inside := seed_at + edge - outward
			var beyond := inside + outward * 2
			var outer := Vector2(beyond.x, -beyond.y)
			var at_lake := is_equal_approx(WaterField.level_at(Vector2(inside.x, -inside.y)), plan.lake_level)
			if at_lake and _is_wet(Vector2(inside.x, -inside.y)) and not _is_wet(outer) and WorldShape.height(outer) < plan.lake_level:
				cut[_sector(outer)] = true
	if not cut.is_empty():
		_list("lake cut off by its lake_reach (%.0f m), beyond in" % plan.lake_reach, PackedStringArray(cut.keys()))


## Dug ground with no water in it that could hold some.
func _report_hollows() -> void:
	var columns := _area.size.x
	var seen := PackedByteArray()
	seen.resize(_wet.size())
	var found := PackedStringArray()
	for start in _wet.size():
		if seen[start] == 1 or not _is_dug(start):
			continue
		var open: Array[int] = [start]
		seen[start] = 1
		var count := 0
		var lowest := INF
		var lowest_k := start
		var way_out := INF
		while not open.is_empty():
			var k: int = open.pop_back()
			count += 1
			var ground := WorldShape.height(_xz(k % columns, k / columns))
			if ground < lowest:
				lowest = ground
				lowest_k = k
			for side: int in [1, -1, columns, -columns]:
				var other := k + side
				if other < 0 or other >= _wet.size():
					continue
				if _is_dug(other):
					if seen[other] == 0:
						seen[other] = 1
						open.append(other)
				else:
					way_out = minf(way_out, WorldShape.height(_xz(other % columns, other / columns)))
		if count >= SMALLEST_HOLLOW and way_out - lowest > HOLDS:
			found.append("%s: %d m2, lowest %.1f m, holds water up to about %.1f m" % [_sector(_xz(lowest_k % _area.size.x, lowest_k / _area.size.x)), count, lowest, way_out])
	_list("dug hollows with no water", found)


func _is_dug(k: int) -> bool:
	if _wet[k] == 1:
		return false
	var xz := _xz(k % _area.size.x, k / _area.size.x)
	return TerrainSculpt.height(xz) < -DUG and _border.depth_at(xz) == 0.0


func _report_decoration(world: Node) -> void:
	var owned := {}
	for design in world.get_node("Sectors").get_children():
		var near := false
		for sector: String in design.get("sectors"):
			var cell := SectorMap.cell_named(sector)
			owned[cell] = true
			near = near or _is_near_water(cell, BLOCK_REACH)
		if design.get("decorates_land") and not near:
			print("[land]   block with no water near any more: %s" % design.name)
	var blocks := {}
	var bounds := SectorMap.bounds()
	for x in range(int(bounds.position.x), int(bounds.end.x), int(SectorMap.SIZE)):
		for north in range(int(bounds.position.y), int(bounds.end.y), int(SectorMap.SIZE)):
			var cell := SectorMap.unbounded_cell_at(Vector2(x + 1.0, -north - 1.0))
			if owned.has(cell) or not _is_near_water(cell, SHORE):
				continue
			var centre := SectorMap.center_of(cell)
			if _border.depth_at(Vector2(centre.x, centre.z)) >= ZoneBorder.RETURN_METRES:
				continue
			var block := Vector2i(floori(float(cell.x) / BLOCK), floori(float(cell.y) / BLOCK))
			# Packed arrays inside dictionaries are values: read, change, store back.
			var names: PackedStringArray = blocks.get(block, PackedStringArray())
			names.append(SectorMap.name_of(cell))
			blocks[block] = names
	if blocks.is_empty():
		print("[land] every shore has a decoration block")
	else:
		print("[land] shores with no decoration, by block to add:")
		for block: Vector2i in blocks:
			var names: PackedStringArray = blocks[block]
			print("[land]   %s" % " ".join(names))


func _is_near_water(cell: Vector2i, metres: int) -> bool:
	var corner := SectorMap.corner_of(cell)
	for i in range(0, int(SectorMap.SIZE) + 1, 2):
		for j in range(0, int(SectorMap.SIZE) + 1, 2):
			if _distance_at(Vector2(corner.x + i, corner.z - j)) <= metres:
				return true
	return false


func _report_lines(world: Node) -> void:
	_report_line("ZoneBorder/Line", _border.line(), BORDER_GROUND)
	_report_line("MistBarrier/FogLine", (world.get_node("MistBarrier") as MistBarrier).line(), FOG_GROUND)


## The ends stand at the world's edge, where the land eases flat.
func _report_line(path: String, line: PackedVector2Array, allowed: Vector2) -> void:
	var off := PackedStringArray()
	for k in range(1, line.size() - 1):
		var ground := WorldShape.height(line[k])
		if ground < allowed.x or ground > allowed.y:
			off.append("P%02d in %s, ground %.1f m" % [k + 1, _sector(line[k]), ground])
	_list("%s points off the drop (ground should be %.0f to %.0f m)" % [path, allowed.x, allowed.y], off)


## Sculpted sectors nothing decorates, with what makes them stand out: where new
## props or assets may be worth proposing.
func _report_bare_land(world: Node) -> void:
	var owned := {}
	for design in world.get_node("Sectors").get_children():
		for sector: String in design.get("sectors"):
			owned[SectorMap.cell_named(sector)] = true
	var steep := PackedStringArray()
	var high := PackedStringArray()
	var low := PackedStringArray()
	var bounds := SectorMap.bounds()
	for x in range(int(bounds.position.x), int(bounds.end.x), int(SectorMap.SIZE)):
		for north in range(int(bounds.position.y), int(bounds.end.y), int(SectorMap.SIZE)):
			var cell := SectorMap.unbounded_cell_at(Vector2(x + 1.0, -north - 1.0))
			var centre := SectorMap.center_of(cell)
			if owned.has(cell) or _near_the_rim(Vector2(centre.x, centre.z)):
				continue
			var most := 0.0
			var deepest := 0.0
			var steepest := 0.0
			for i in range(1, 10, 2):
				for j in range(1, 10, 2):
					var xz := Vector2(x + i, -north - j)
					var sculpted := TerrainSculpt.height(xz)
					most = maxf(most, sculpted)
					deepest = minf(deepest, sculpted)
					var east := WorldShape.height(xz + Vector2(0.5, 0.0)) - WorldShape.height(xz - Vector2(0.5, 0.0))
					var south := WorldShape.height(xz + Vector2(0.0, 0.5)) - WorldShape.height(xz - Vector2(0.0, 0.5))
					steepest = maxf(steepest, Vector2(east, south).length())
			if most == 0.0 and deepest == 0.0:
				continue
			if most > HIGH:
				high.append(SectorMap.name_of(cell))
			if deepest < -HIGH:
				low.append(SectorMap.name_of(cell))
			if steepest > STEEP:
				steep.append(SectorMap.name_of(cell))
	_list("undecorated sculpted land, steep", steep)
	_list("undecorated sculpted land, raised high", high)
	_list("undecorated sculpted land, dug deep", low)


## Past the border, or close enough to it that steep ground is just the drop.
func _near_the_rim(xz: Vector2) -> bool:
	if _border.depth_at(xz) > 0.0:
		return true
	var line := _border.line()
	for k in line.size() - 1:
		if xz.distance_to(Geometry2D.get_closest_point_to_segment(xz, line[k], line[k + 1])) < RIM_METRES:
			return true
	return false


func _list(what: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		print("[land] %s: none" % what)
		return
	print("[land] %s: %d" % [what, lines.size()])
	for k in mini(lines.size(), MOST_LISTED):
		print("[land]   %s" % lines[k])
	if lines.size() > MOST_LISTED:
		print("[land]   ...and %d more" % (lines.size() - MOST_LISTED))
