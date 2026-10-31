@tool
class_name WaterField
extends RefCounted
## The surface of the water poured into the land (RegionWater), on a grid with
## a sample every metre at whole x and north, like TerrainSculpt. Worked out
## from the land when the world is set up, and again when it's sculpted: a
## river's surface follows its course, within `CORRIDOR` metres of it, the lake
## is flat, and water fills what lies below them and connects to them. Read-only
## once built, so worker threads may ask; a rebuild swaps the whole grid.

## Metres either side of a river's middle in which its level holds.
const CORRIDOR := 25
const FOLDER := "res://data/world/water"
## Flow is evened out this many times, so turns and shores don't tear ripples.
const FLOW_PASSES := 3
## Sides of a sample.
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## A built surface: per sample, its level (-INF for none, also on the dry ring
## just past the shore, where the surface runs into the bank), whether water
## stands there, and its flow along world x and z.
class Grid:
	var columns := 0
	var rows := 0
	var levels := PackedFloat32Array()
	var wet := PackedByteArray()
	var flows := PackedVector2Array()


static var _plans: Array[RegionWater] = []
static var _grid: Grid
static var _reads_data := true
static var _loaded := false


## Reads the water data, once per run, and works out the surface.
static func load_all() -> void:
	if not _loaded and _reads_data:
		_loaded = true
		_plans.clear()
		if DirAccess.dir_exists_absolute(FOLDER):
			for file in ResourceLoader.list_directory(FOLDER):
				var plan := load(FOLDER.path_join(file)) as RegionWater
				if plan:
					_plans.append(plan)
	rebuild()


## Ignores the water data, so tests see the land as the code makes it; `plans`
## is what they pour instead.
static func use_only(plans: Array[RegionWater]) -> void:
	_reads_data = false
	_plans = plans
	rebuild()


## The water data, for tests.
static func saved_plans() -> Array[RegionWater]:
	var found: Array[RegionWater] = []
	if DirAccess.dir_exists_absolute(FOLDER):
		for file in ResourceLoader.list_directory(FOLDER):
			var plan := load(FOLDER.path_join(file)) as RegionWater
			if plan:
				found.append(plan)
	return found


## Works the surface out from the land as it is now.
static func rebuild() -> void:
	if _plans.is_empty():
		_grid = null
		return
	# Water lies in R1 alone for now, so the grid covers only R1.
	var grid := Grid.new()
	grid.columns = int(RegionMap.SIZE) + 1
	grid.rows = int(RegionMap.SIZE) + 1
	var count := grid.columns * grid.rows
	grid.levels.resize(count)
	grid.levels.fill(-INF)
	grid.wet.resize(count)
	grid.flows.resize(count)
	for plan in _plans:
		_pour(grid, plan)
	_ring_the_shore(grid)
	for pass_number in FLOW_PASSES:
		_even_out_flow(grid)
	_grid = grid


## Height of the surface at a world x and z, on the triangles the mesh draws;
## SectorDesign.NO_WATER where there is none.
static func level_at(xz: Vector2) -> float:
	var grid := _grid
	if grid == null:
		return SectorDesign.NO_WATER
	var north := -xz.y
	var i := floori(xz.x)
	var j := floori(north)
	if i < 0 or j < 0 or i >= grid.columns - 1 or j >= grid.rows - 1:
		return SectorDesign.NO_WATER
	var k := j * grid.columns + i
	var south_west := grid.levels[k]
	var south_east := grid.levels[k + 1]
	var north_west := grid.levels[k + grid.columns]
	var north_east := grid.levels[k + grid.columns + 1]
	if is_inf(south_west) or is_inf(south_east) or is_inf(north_west) or is_inf(north_east):
		return SectorDesign.NO_WATER
	var fu := xz.x - i
	var fv := north - j
	if fu + fv <= 1.0:
		return south_west + (south_east - south_west) * fu + (north_west - south_west) * fv
	return north_east + (north_west - north_east) * (1.0 - fu) + (south_east - north_east) * (1.0 - fv)


## The water's flow at the nearest sample, in metres a second along world x and
## z; zero on still water and dry land.
static func flow_at(xz: Vector2) -> Vector2:
	var grid := _grid
	if grid == null:
		return Vector2.ZERO
	var i := roundi(xz.x)
	var j := roundi(-xz.y)
	if i < 0 or j < 0 or i >= grid.columns or j >= grid.rows:
		return Vector2.ZERO
	return grid.flows[j * grid.columns + i]


## The surface's mesh for water.gdshader, with each vertex's flow in its colour;
## null when there's no water.
static func mesh() -> ArrayMesh:
	var grid := _grid
	if grid == null:
		return null
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var numbers := PackedInt32Array()
	numbers.resize(grid.levels.size())
	numbers.fill(-1)
	for j in grid.rows - 1:
		for i in grid.columns - 1:
			var k := j * grid.columns + i
			var square: Array[int] = [k, k + 1, k + grid.columns, k + grid.columns + 1]
			var complete := true
			var any_wet := false
			for corner in square:
				complete = complete and not is_inf(grid.levels[corner])
				any_wet = any_wet or grid.wet[corner] == 1
			if not (complete and any_wet):
				continue
			for corner in square:
				if numbers[corner] < 0:
					numbers[corner] = vertices.size()
					vertices.append(Vector3(corner % grid.columns, grid.levels[corner], -(corner / grid.columns)))
					var flow := grid.flows[corner] / NatureKit.WATER_MAX_FLOW * 0.5 + Vector2(0.5, 0.5)
					colors.append(Color(clampf(flow.x, 0.0, 1.0), clampf(flow.y, 0.0, 1.0), 0.0, 1.0))
			# South-west, north-west, south-east; south-east, north-west, north-east.
			for corner: int in [square[0], square[2], square[1], square[1], square[2], square[3]]:
				indices.append(numbers[corner])
	if vertices.is_empty():
		return null
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var built := ArrayMesh.new()
	built.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return built


## The sectors holding at least some water, by name, in map order.
static func wet_sectors() -> PackedStringArray:
	var names := PackedStringArray()
	var grid := _grid
	if grid == null:
		return names
	var seen: Dictionary[Vector2i, bool] = {}
	for j in grid.rows:
		for i in grid.columns:
			if grid.wet[j * grid.columns + i] == 1:
				seen[Vector2i(mini(i, grid.columns - 2), mini(j, grid.rows - 2)) / int(SectorMap.SIZE)] = true
	var cells: Array[Vector2i] = []
	cells.assign(seen.keys())
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	for cell in cells:
		names.append(SectorMap.name_of(cell))
	return names


## Fills one plan's lake and rivers into the grid.
static func _pour(grid: Grid, plan: RegionWater) -> void:
	var count := grid.levels.size()
	# Each sample near a river takes the level and flow of the nearest point of
	# its middle, spreading out ring by ring.
	var near_level := PackedFloat32Array()
	near_level.resize(count)
	near_level.fill(-INF)
	var near_flow := PackedVector2Array()
	near_flow.resize(count)
	var ring: Array[int] = []
	for course in plan.courses:
		_lay_course(grid, course, near_level, near_flow, ring)
	var sources: Array[int] = []
	sources.assign(ring)
	for step in CORRIDOR:
		var next: Array[int] = []
		for k in ring:
			for side in SIDES:
				var other := _neighbour(grid, k, side)
				if other >= 0 and is_inf(near_level[other]):
					near_level[other] = near_level[k]
					near_flow[other] = near_flow[k]
					next.append(other)
		ring = next
	# Water stands where the land lies below the level here, connected to a
	# river's middle or the lake.
	var open: Array[int] = []
	var seen := PackedByteArray()
	seen.resize(count)
	for k in sources:
		seen[k] = 1
		open.append(k)
	if not is_inf(plan.lake_level):
		var seed_sample := Vector2i(plan.lake_seed.round())
		var seed_k := seed_sample.y * grid.columns + seed_sample.x
		if seed_k >= 0 and seed_k < count:
			seen[seed_k] = 1
			open.append(seed_k)
	while not open.is_empty():
		var k: int = open.pop_back()
		var level := near_level[k] if not is_inf(near_level[k]) else plan.lake_level
		if is_inf(level):
			continue
		var i := k % grid.columns
		var j := k / grid.columns
		# The world's edge meets the flat land around it.
		if i < 1 or j < 1 or i >= grid.columns - 1 or j >= grid.rows - 1:
			continue
		if WorldShape.height(Vector2(i, -j)) >= level:
			continue
		grid.wet[k] = 1
		grid.levels[k] = level
		grid.flows[k] = near_flow[k]
		for side in SIDES:
			var other := _neighbour(grid, k, side)
			if other >= 0 and seen[other] == 0:
				seen[other] = 1
				open.append(other)


## Marks the samples under a river's middle with its level and flow.
static func _lay_course(grid: Grid, course: WaterCourse, near_level: PackedFloat32Array, near_flow: PackedVector2Array, sources: Array[int]) -> void:
	var total := 0.0
	for s in course.points.size() - 1:
		total += course.points[s].distance_to(course.points[s + 1])
	var travelled := 0.0
	for s in course.points.size() - 1:
		var from := course.points[s]
		var to := course.points[s + 1]
		var length := from.distance_to(to)
		if length == 0.0:
			continue
		var along := (to - from).normalized()
		var steps := ceili(length * 2.0)
		for n in steps + 1:
			var t := float(n) / steps
			var at := from.lerp(to, t)
			var k := _sample_at(grid, at)
			if k < 0 or not is_inf(near_level[k]):
				continue
			var done := travelled + length * t
			var speed := course.speed
			if course.ease_in > 0.0:
				speed *= smoothstep(0.0, course.ease_in, done)
			if course.ease_out > 0.0:
				speed *= smoothstep(0.0, course.ease_out, total - done)
			near_level[k] = lerpf(course.levels[s], course.levels[s + 1], t)
			# Flow is along world x and z; the course's y runs north, -z.
			near_flow[k] = Vector2(along.x, -along.y) * speed
			sources.append(k)
		travelled += length


static func _sample_at(grid: Grid, point: Vector2) -> int:
	var i := roundi(point.x)
	var j := roundi(point.y)
	if i < 0 or j < 0 or i >= grid.columns or j >= grid.rows:
		return -1
	return j * grid.columns + i


static func _neighbour(grid: Grid, k: int, side: Vector2i) -> int:
	var i := k % grid.columns + side.x
	var j := k / grid.columns + side.y
	if i < 0 or j < 0 or i >= grid.columns or j >= grid.rows:
		return -1
	return j * grid.columns + i


## Gives the dry samples around the water its level, so the surface runs on into
## the bank and the shore lies where they cross.
static func _ring_the_shore(grid: Grid) -> void:
	var ring: Dictionary[int, float] = {}
	for k in grid.wet.size():
		if grid.wet[k] == 0:
			continue
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var other := _neighbour(grid, k, Vector2i(dx, dy))
				if other >= 0 and grid.wet[other] == 0:
					ring[other] = maxf(ring.get(other, -INF), grid.levels[k])
	for k: int in ring:
		grid.levels[k] = ring[k]


static func _even_out_flow(grid: Grid) -> void:
	var evened := grid.flows.duplicate()
	for k in grid.wet.size():
		if grid.wet[k] == 0:
			continue
		var sum := grid.flows[k]
		var parts := 1
		for side in SIDES:
			var other := _neighbour(grid, k, side)
			if other >= 0 and grid.wet[other] == 1:
				sum += grid.flows[other]
				parts += 1
		evened[k] = sum / parts
	grid.flows = evened
