@tool
class_name SectorDesign
extends Node3D
## One environment design: it owns some sectors of the field and shapes only
## those. A subclass describes the place through the hooks (`_setup`,
## `_ground`, `_water_level`, `_flow`, `_ground_tint`) and places its props in
## `_populate`. The base samples the hooks on a fine grid and eases the ground
## back to flat grass at every edge shared with a sector it doesn't own.
##
## Two parts, so the world can stream: the ground (heights and water) is
## always known, from `npm run bake`'s files or by sampling the hooks; the
## content (the ground's meshes and collision, the water, the props) is built
## by `generate_content` into a node outside the tree and attached with
## `attach_content`. In the editor it is attached at once; in the game the
## SectorStreamer attaches it, from the baked scene when fresh, while the
## player is near, and detaches it when they leave.
##
## A design node stays at the world origin and works in world coordinates;
## ground points are Vector2(x, z). Generated children have no owner, so the
## editor never saves them.

## Emitted when content is attached (true) or detached (false).
signal content_changed(loaded: bool)

## Metres between ground samples.
const RESOLUTION := 0.25
## Ground samples along each side of a sector.
const SAMPLES := 41
## `_water_level` and `water_level_at` for dry ground.
const NO_WATER := -INF
## `_ground_tint` for plain grass. The ground shader reads alpha as how much
## grass shows and the colour, in sRGB, as what shows instead.
const GRASS := Color(1.0, 1.0, 1.0, 1.0)
## Metres kept free of props around each owned sector's start point, beyond
## the prop's own radius.
const START_CLEARANCE := 1.2
## Metres per side of the squares that file claimed ground.
const CLAIM_BUCKET := 2.0

## The sectors this design owns, by name: "A1", "B2"...
@export var sectors: PackedStringArray = PackedStringArray()
## Names this design in saves for good, such as "b1_cornflower": unique,
## lowercase, and never changed once the game has been played. Node names can
## change freely; this can't.
@export var design_id: String = ""
## Seeds `rng` and anything else random, so the design comes out the same
## every time.
@export var design_seed: int = 1
## Metres over which the ground eases back to flat at edges shared with
## sectors this design doesn't own.
@export var edge_blend: float = 2.0
## True once the design's props are placed in the scene, as Prop nodes under
## its `Props` node, editable by hand (npm run props -- <Design> freezes the
## ones its code places). Its code then stops placing them.
@export var props_frozen: bool = false
## Adds content only: its sectors keep the open ground and the water poured into
## the land (WaterField), and its hooks for ground and water aren't used.
@export var decorates_land: bool = false

## Seeded with `design_seed` before `_populate`; use it for every random choice.
var rng := RandomNumberGenerator.new()

var _ground_known := false
var _sampled := false
var _set_up := false
var _cells: Array[Vector2i] = []
var _owned: Dictionary[Vector2i, bool] = {}
var _heights: Dictionary[Vector2i, PackedFloat32Array] = {}
var _water: Dictionary[Vector2i, PackedFloat32Array] = {}
var _flows: Dictionary[Vector2i, PackedVector2Array] = {}
var _tints: Dictionary[Vector2i, PackedColorArray] = {}
var _merged: Dictionary[String, NatureKit.Batch] = {}
## Claimed ground as x, z and radius, filed under every CLAIM_BUCKET-sized
## square each claim touches.
var _claims: Dictionary[Vector2i, Array] = {}
var _issued: Dictionary[String, bool] = {}
## Props placed by the design's code this generation: {kind, variant,
## where, solid}, for freezing them into the scene.
## What assets that span ground keep clear: [inverse placement, half size].
var _spans: Array[Array] = []
var _placed_props: Array[Dictionary] = []
var _colliders: StaticBody3D
## The content being generated, and the content attached.
var _building: Node3D
var _content: Node3D


func _ready() -> void:
	bake()
	if Engine.is_editor_hint():
		attach_content(generate_content())


## Prepares whatever the hooks need, before any sampling: noise, paths...
func _setup() -> void:
	pass


## Ground height before easing at the edges, above the world's own shape
## (WorldShape; flat in the main field). 0 is the land as it lies.
func _ground(_xz: Vector2) -> float:
	return 0.0


## Height of the water surface, or NO_WATER. Water shows where it is above
## the ground.
func _water_level(_xz: Vector2) -> float:
	return NO_WATER


## The water's flow in metres per second along world x and z.
func _flow(_xz: Vector2) -> Vector2:
	return Vector2.ZERO


## The ground's colour: GRASS, or a colour whose alpha says how much grass
## still shows through it.
func _ground_tint(_xz: Vector2) -> Color:
	return GRASS


## Places the design's props with `add_content` and the helpers below, after
## the ground and water exist.
func _populate() -> void:
	pass


## Makes the ground known, once: from the baked file when fresh, otherwise by
## sampling the hooks. Anything asking about heights calls it, so the order
## of nodes in the tree doesn't matter.
func bake() -> void:
	if _ground_known:
		return
	_ground_known = true
	_read_sectors()
	if decorates_land:
		return
	var ground: SectorGround = null if Engine.is_editor_hint() else BakedSectors.load_ground(name)
	if ground:
		_heights = ground.heights
		_water = ground.water
		_flows = ground.flows
	else:
		_sample()


## Builds the content, the same every time, into a new node named "Content"
## that isn't in the tree: the ground's meshes and collision, the water, and
## whatever `_populate` adds.
func generate_content() -> Node3D:
	bake()
	if not _sampled:
		_sample()
	_merged.clear()
	_claims.clear()
	_issued.clear()
	_placed_props.clear()
	_spans.clear()
	_colliders = null
	_building = Node3D.new()
	_building.name = "Content"
	rng.seed = design_seed
	if not decorates_land:
		_build_ground()
		_build_water()
	_add_scene_props()
	_populate()
	_commit_props()
	var built := _building
	_building = null
	return built


## Shows content built by `generate_content` or loaded from a baked scene,
## replacing any attached before.
func attach_content(content: Node3D) -> void:
	if _content:
		_drop_content()
	content.name = "Content"
	_content = content
	add_child(content)
	content_changed.emit(true)


func detach_content() -> void:
	if _content:
		_drop_content()
		content_changed.emit(false)


func is_content_loaded() -> bool:
	return _content != null


## The attached content, or null.
func content() -> Node3D:
	return _content


## A node in the attached content by path, or null.
func part(path: NodePath) -> Node:
	return _content.get_node_or_null(path) if _content else null


## The ground to bake.
func ground() -> SectorGround:
	bake()
	var data := SectorGround.new()
	data.heights = _heights
	data.water = _water
	data.flows = _flows
	return data


## A stable id for a hand-placed thing in the content, for WorldState and
## saves: "<design_id>/<local name>", such as "b1_cornflower/cornflower".
## Never change a local name once the game has been played; saves hold it.
func content_id(local_name: String) -> String:
	return _issue("%s/%s" % [design_id, local_name])


## A stable id for a scattered thing, from its kind and where it stands to
## the decimetre, such as "stress_j10/mushroom@928,-931". It doesn't depend
## on the order things were placed in, so retuning a scatter can only make
## moved things count as new, never mix two of them up.
func scatter_id(kind: String, xz: Vector2) -> String:
	return _issue("%s/%s@%d,%d" % [design_id, kind, roundi(xz.x * 10.0), roundi(xz.y * 10.0)])


func _issue(id: String) -> String:
	if design_id.is_empty():
		push_error("SectorDesign %s: design_id is empty, so its ids aren't stable" % name)
	if _issued.has(id):
		push_error("SectorDesign %s: id %s given twice" % [name, id])
	_issued[id] = true
	return id


## The cells of the owned sectors.
func cells() -> Array[Vector2i]:
	bake()
	return _cells


func owns_cell(cell: Vector2i) -> bool:
	return _owned.has(cell)


func owns(xz: Vector2) -> bool:
	return _owned.has(SectorMap.unbounded_cell_at(xz))


## 1 inside the design, easing to 0 at edges shared with sectors it doesn't
## own (and at the edge of the grid). Edges between its own sectors don't
## count.
func edge_weight(xz: Vector2) -> float:
	var cell := SectorMap.unbounded_cell_at(xz)
	if not owns_cell(cell):
		return 0.0
	# Grid metres: east and north of A1's corner.
	var point := Vector2(xz.x - SectorMap.ORIGIN.x, SectorMap.ORIGIN.z - xz.y)
	var inside := point - Vector2(cell) * SectorMap.SIZE
	if minf(minf(inside.x, inside.y), SectorMap.SIZE - maxf(inside.x, inside.y)) >= edge_blend:
		return 1.0
	var nearest := INF
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var neighbour := cell + Vector2i(dx, dy)
			if owns_cell(neighbour):
				continue
			var low := Vector2(neighbour) * SectorMap.SIZE
			var high := low + Vector2.ONE * SectorMap.SIZE
			var gap := Vector2(maxf(maxf(low.x - point.x, point.x - high.x), 0.0), maxf(maxf(low.y - point.y, point.y - high.y), 0.0))
			nearest = minf(nearest, gap.length())
	return smoothstep(0.0, edge_blend, nearest)


## Ground height at a point, on the same triangles the ground mesh draws; the
## world's own shape outside the design.
func height_at(xz: Vector2) -> float:
	bake()
	if decorates_land or not owns(xz):
		return WorldShape.height(xz)
	return _interpolate(_heights, xz, 0.0)


## Height of the water surface at a point, or NO_WATER.
func water_level_at(xz: Vector2) -> float:
	bake()
	if decorates_land:
		return Waters.level_at(xz)
	return _interpolate(_water, xz, NO_WATER)


## The water's flow at the nearest sample, in metres per second along x and
## z.
func flow_at(xz: Vector2) -> Vector2:
	bake()
	if decorates_land:
		return WaterField.flow_at(xz)
	var cell := SectorMap.unbounded_cell_at(xz)
	if not _flows.has(cell):
		return Vector2.ZERO
	var corner := SectorMap.corner_of(cell)
	var i := clampi(roundi((xz.x - corner.x) / RESOLUTION), 0, SAMPLES - 1)
	var j := clampi(roundi((corner.z - xz.y) / RESOLUTION), 0, SAMPLES - 1)
	return _flows[cell][j * SAMPLES + i]


## True where the ground stands at least `margin` metres above any water.
func is_dry(xz: Vector2, margin: float = 0.05) -> bool:
	return height_at(xz) > water_level_at(xz) + margin


## The ground point under a world x and z.
func surface(xz: Vector2) -> Vector3:
	return Vector3(xz.x, height_at(xz), xz.y)


## The lowest ground within `radius` of a point, so something wide can sit
## there without floating on a slope.
func lowest_ground(xz: Vector2, radius: float) -> float:
	var lowest := height_at(xz)
	for k in 6:
		var angle := TAU * k / 6.0
		lowest = minf(lowest, height_at(xz + Vector2(cos(angle), sin(angle)) * radius))
	return lowest


## True if a square of `radius` metres around a point lies inside the owned
## sectors.
func fits(xz: Vector2, radius: float) -> bool:
	for corner: Vector2 in [Vector2(-radius, -radius), Vector2(radius, -radius), Vector2(-radius, radius), Vector2(radius, radius)]:
		if not owns(xz + corner):
			return false
	return true


## True if something of `radius` metres at a point would crowd the start
## point of an owned sector.
func crowds_start(xz: Vector2, radius: float) -> bool:
	for cell in cells():
		var start := SectorMap.start_of(cell)
		if xz.distance_to(Vector2(start.x, start.z)) < radius + START_CLEARANCE:
			return true
	return false


## Marks a circle of ground as taken by a prop, so later props can keep clear
## of it with `is_clear`.
func claim(xz: Vector2, radius: float) -> void:
	var entry := Vector3(xz.x, xz.y, radius)
	for key in _claim_buckets(xz, radius):
		if not _claims.has(key):
			_claims[key] = []
		_claims[key].append(entry)


## True if a prop of `radius` at a point keeps clear of claimed ground: the
## gap between centres is at least `spacing` times the two radii together.
func is_clear(xz: Vector2, radius: float, spacing: float = 0.85) -> bool:
	if _under_a_span(xz, radius):
		return false
	for key in _claim_buckets(xz, radius):
		for entry: Vector3 in _claims.get(key, []):
			if xz.distance_to(Vector2(entry.x, entry.y)) < (radius + entry.z) * spacing:
				return false
	return true


## True under an asset that spans ground, such as a bridge.
func _under_a_span(xz: Vector2, radius: float) -> bool:
	for span: Array in _spans:
		var inverse: Transform3D = span[0]
		var half: Vector2 = span[1]
		var local := inverse * Vector3(xz.x, 0.0, xz.y)
		if absf(local.x) < half.x + radius and absf(local.z) < half.y + radius:
			return true
	return false


## A random point inside the owned sectors.
func random_point() -> Vector2:
	var corner := SectorMap.corner_of(_cells[rng.randi() % _cells.size()])
	return Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)


## Adds a node to the content being generated. Only for `_populate`.
func add_content(node: Node) -> void:
	if _building == null:
		push_error("%s: add_content works only while generating content" % name)
		return
	_building.add_child(node)


## Remakes the ground of the owned sectors under an area of samples (x, north)
## after the land under them was sculpted. Only for the editor, where the
## content is built live. Props and water stay as they are.
func reshape_ground(area: Rect2i) -> void:
	if decorates_land or not _sampled or _content == null:
		return
	var body := part("GroundBody")
	for cell in _cells:
		var corner := SectorMap.corner_of(cell)
		var sector := Rect2i(int(corner.x) - 1, int(-corner.z) - 1, int(SectorMap.SIZE) + 2, int(SectorMap.SIZE) + 2)
		if not sector.intersects(area):
			continue
		var heights := PackedFloat32Array()
		heights.resize(SAMPLES * SAMPLES)
		for j in SAMPLES:
			for i in SAMPLES:
				var xz := Vector2(corner.x + i * RESOLUTION, corner.z - j * RESOLUTION)
				heights[j * SAMPLES + i] = WorldShape.height(xz) + _ground(xz) * edge_weight(xz)
		_heights[cell] = heights
		var built := _ground_of(cell)
		var ground_mesh := part("Ground" + SectorMap.node_name(cell)) as MeshInstance3D
		if ground_mesh:
			ground_mesh.mesh = built[0]
		var collision := body.get_node_or_null(SectorMap.node_name(cell)) as CollisionShape3D if body else null
		if collision:
			collision.shape = built[1]


## The batch merging `group` props in the sector under a point, so each
## sector's rocks, say, are one mesh. `commit_merged` turns the batches into
## meshes.
func merged(group: String, xz: Vector2) -> NatureKit.Batch:
	var key := group + "_" + SectorMap.node_name(SectorMap.unbounded_cell_at(xz))
	if not _merged.has(key):
		_merged[key] = NatureKit.Batch.new()
	return _merged[key]


## Adds one MeshInstance3D per sector for everything merged into `group`.
func commit_merged(group: String, material: Material, shadows: bool = true) -> void:
	for key: String in _merged.keys():
		if key.begins_with(group + "_"):
			add_mesh(key.replace("_", ""), _merged[key].commit(), material, shadows)
			_merged.erase(key)


func add_mesh(node_name: String, mesh: Mesh, material: Material, shadows: bool = true) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	if not shadows:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_content(instance)
	return instance


## Adds many copies of a mesh, one BakedMultiMesh per sector so distant
## sectors can be culled. `colors` tints each copy; `visible_distance` (when
## above 0) hides them farther from the camera.
func add_multimesh(node_name: String, mesh: Mesh, material: Material, transforms: Array[Transform3D], colors: PackedColorArray, visible_distance: float = 0.0) -> void:
	var by_cell: Dictionary[Vector2i, Array] = {}
	for i in transforms.size():
		var cell := SectorMap.unbounded_cell_at(Vector2(transforms[i].origin.x, transforms[i].origin.z))
		if not by_cell.has(cell):
			by_cell[cell] = []
		by_cell[cell].append(i)
	for cell: Vector2i in by_cell.keys():
		var picks: Array = by_cell[cell]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = mesh
		var instance := BakedMultiMesh.new()
		instance.multimesh = multimesh
		instance.material_override = material
		instance.name = node_name + SectorMap.node_name(cell)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if visible_distance > 0.0:
			instance.visibility_range_end = visible_distance
			instance.visibility_range_end_margin = visible_distance * 0.15
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		var picked: Array[Transform3D] = []
		var tints := PackedColorArray()
		for k in picks.size():
			var i: int = picks[k]
			picked.append(transforms[i])
			tints.append(colors[i])
		instance.set_copies(picked, tints)
		add_content(instance)


## Where the copies in one of `add_multimesh`'s nodes stand, read from the
## attached content.
func instance_transforms(node_name: StringName) -> Array[Transform3D]:
	var node := part(NodePath(node_name)) as BakedMultiMesh
	var placed: Array[Transform3D] = []
	if node:
		placed = node.transforms()
	return placed


## Makes a shape solid for the player and the camera.
## Places a prop from code: merged into the sector's meshes like a prop
## placed by hand, solid if `solid`, and its room claimed. Call it only
## while `props_frozen` is false; `npm run props` turns these into Prop nodes.
func place_prop(kind: PropLibrary.Kind, variant: int, where: Transform3D, solid: bool, asset: PackedScene = null) -> void:
	_placed_props.append({"kind": kind, "variant": variant, "where": where, "solid": solid, "asset": asset})
	_merge_prop(kind, variant, where, solid, asset)


## The props the design's code placed in the last generation.
func placed_props() -> Array[Dictionary]:
	return _placed_props


## The Prop nodes placed by hand under `Props`.
func scene_props() -> Array[Prop]:
	var found: Array[Prop] = []
	var holder := get_node_or_null("Props")
	if holder:
		for child in holder.get_children():
			if child is Prop:
				found.append(child as Prop)
	return found


func _add_scene_props() -> void:
	for prop in scene_props():
		var where := prop.placement()
		if prop.asset and PropLibrary.SPANS.has(PropLibrary.slug_of(prop.asset)):
			_spans.append([where.affine_inverse(), PropLibrary.SPANS[PropLibrary.slug_of(prop.asset)]])
		if Engine.is_editor_hint():
			# The editor shows each prop by itself; only keep room for it.
			claim(Vector2(where.origin.x, where.origin.z), PropLibrary.room(prop.kind, where, prop.asset))
		else:
			_merge_prop(prop.kind, prop.variant, where, prop.solid, prop.asset)


func _merge_prop(kind: PropLibrary.Kind, variant: int, where: Transform3D, solid: bool, asset: PackedScene = null) -> void:
	var xz := Vector2(where.origin.x, where.origin.z)
	if kind == PropLibrary.Kind.ASSET:
		# A whole model: placed as it is, with its own collision.
		if asset:
			var model := asset.instantiate() as Node3D
			model.transform = where
			add_content(model)
			var slug := PropLibrary.slug_of(asset)
			if PropLibrary.NIGHT_LIGHTS.has(slug):
				var flame := NightLight.new()
				flame.position = where * PropLibrary.NIGHT_LIGHTS[slug]
				add_content(flame)
			claim(xz, PropLibrary.room(kind, where, asset))
		return
	PropLibrary.add_to(merged(PropLibrary.group(kind), xz), kind, variant, where)
	if solid:
		var shape := PropLibrary.collider(kind, where)
		if not shape.is_empty():
			add_collider(shape[0], shape[1])
	claim(xz, PropLibrary.room(kind, where))


## Commits the props' meshes the design's own code didn't commit.
func _commit_props() -> void:
	var groups: Dictionary[String, bool] = {}
	for key: String in _merged.keys():
		for group_name in PropLibrary.GROUPS:
			if not group_name.is_empty() and key.begins_with(group_name + "_"):
				groups[group_name] = true
	for group_name: String in groups:
		commit_merged(group_name, PropLibrary.material(group_name))


func add_collider(shape: Shape3D, where: Transform3D) -> void:
	if _colliders == null:
		_colliders = StaticBody3D.new()
		_colliders.name = "Colliders"
		add_content(_colliders)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = where
	_colliders.add_child(collision)


func _read_sectors() -> void:
	for sector_name in sectors:
		var cell := SectorMap.cell_named(sector_name)
		if cell == SectorMap.NONE:
			push_error("%s: there is no sector named '%s'" % [name, sector_name])
		elif not _owned.has(cell):
			_owned[cell] = true
			_cells.append(cell)


## Samples the hooks over every owned sector.
func _sample() -> void:
	_sampled = true
	if not _set_up:
		_set_up = true
		_setup()
	if decorates_land:
		return
	for cell in _cells:
		var heights := PackedFloat32Array()
		var water := PackedFloat32Array()
		var flows := PackedVector2Array()
		var tints := PackedColorArray()
		var corner := SectorMap.corner_of(cell)
		for j in SAMPLES:
			for i in SAMPLES:
				var xz := Vector2(corner.x + i * RESOLUTION, corner.z - j * RESOLUTION)
				var weight := edge_weight(xz)
				heights.append(WorldShape.height(xz) + _ground(xz) * weight)
				water.append(_water_level(xz))
				flows.append(_flow(xz))
				var tint := _ground_tint(xz)
				tint.a = lerpf(1.0, tint.a, weight)
				tints.append(tint)
		_heights[cell] = heights
		_water[cell] = water
		_flows[cell] = flows
		_tints[cell] = tints


func _drop_content() -> void:
	remove_child(_content)
	_content.queue_free()
	_content = null


## The claim squares a circle touches. Two circles that overlap always share
## one, so a lookup only needs the squares of the circle it asks about.
func _claim_buckets(xz: Vector2, radius: float) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for bx in range(floori((xz.x - radius) / CLAIM_BUCKET), floori((xz.x + radius) / CLAIM_BUCKET) + 1):
		for bz in range(floori((xz.y - radius) / CLAIM_BUCKET), floori((xz.y + radius) / CLAIM_BUCKET) + 1):
			keys.append(Vector2i(bx, bz))
	return keys


## The ground at a point from the sampled grid, on the triangle the ground
## mesh draws there. Water levels use the same grid; a point touching dry
## samples has no water.
func _interpolate(grids: Dictionary[Vector2i, PackedFloat32Array], xz: Vector2, outside: float) -> float:
	var cell := SectorMap.unbounded_cell_at(xz)
	if not grids.has(cell):
		return outside
	var grid := grids[cell]
	var corner := SectorMap.corner_of(cell)
	var u := (xz.x - corner.x) / RESOLUTION
	var v := (corner.z - xz.y) / RESOLUTION
	var i := clampi(floori(u), 0, SAMPLES - 2)
	var j := clampi(floori(v), 0, SAMPLES - 2)
	var fu := u - i
	var fv := v - j
	var k := j * SAMPLES + i
	var south_west := grid[k]
	var south_east := grid[k + 1]
	var north_west := grid[k + SAMPLES]
	var north_east := grid[k + SAMPLES + 1]
	if is_inf(south_west) or is_inf(south_east) or is_inf(north_west) or is_inf(north_east):
		return NO_WATER
	# Each grid square is two triangles split from south-east to north-west.
	if fu + fv <= 1.0:
		return south_west + (south_east - south_west) * fu + (north_west - south_west) * fv
	return north_east + (north_west - north_east) * (1.0 - fu) + (south_east - north_east) * (1.0 - fv)


## The ground of every owned sector at full detail: a mesh painted with the
## field's grass-and-grid shader and the design's tints, and its collision.
func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	add_content(body)
	for cell in _cells:
		var built := _ground_of(cell)
		add_mesh("Ground" + SectorMap.node_name(cell), built[0], FieldTerrain.ground_material())
		var collision := CollisionShape3D.new()
		collision.name = SectorMap.node_name(cell)
		collision.shape = built[1]
		body.add_child(collision)


## An owned sector's ground from its sampled heights: [mesh, collision shape].
func _ground_of(cell: Vector2i) -> Array:
	var heights := _heights[cell]
	var corner := SectorMap.corner_of(cell)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for j in SAMPLES:
		for i in SAMPLES:
			var k := j * SAMPLES + i
			var xz := Vector2(corner.x + i * RESOLUTION, corner.z - j * RESOLUTION)
			vertices.append(Vector3(xz.x, heights[k], xz.y))
			# Row j + 1 lies to the north. Border samples look across into
			# the next sector, so normals match at the seam.
			var east_slope: float
			var south_slope: float
			if i > 0 and i < SAMPLES - 1 and j > 0 and j < SAMPLES - 1:
				east_slope = heights[k + 1] - heights[k - 1]
				south_slope = heights[k - SAMPLES] - heights[k + SAMPLES]
			else:
				east_slope = height_at(xz + Vector2(RESOLUTION, 0.0)) - height_at(xz - Vector2(RESOLUTION, 0.0))
				south_slope = height_at(xz + Vector2(0.0, RESOLUTION)) - height_at(xz - Vector2(0.0, RESOLUTION))
			normals.append(Vector3(-east_slope, 2.0 * RESOLUTION, -south_slope).normalized())
	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	for j in SAMPLES - 1:
		for i in SAMPLES - 1:
			var south_west := j * SAMPLES + i
			var north_west := south_west + SAMPLES
			for index: int in [south_west, north_west, south_west + 1, south_west + 1, north_west, north_west + 1]:
				indices.append(index)
				faces.append(vertices[index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = _tints[cell]
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	return [mesh, shape]


## The water surface: a quad on every grid square where water stands above
## the ground at one of its corners. The banks hide the rest. Each vertex
## carries its flow for water.gdshader.
func _build_water() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for cell in _cells:
		var heights := _heights[cell]
		var water := _water[cell]
		var flows := _flows[cell]
		var corner := SectorMap.corner_of(cell)
		for j in SAMPLES - 1:
			for i in SAMPLES - 1:
				var square := PackedInt32Array([j * SAMPLES + i, j * SAMPLES + i + 1, (j + 1) * SAMPLES + i, (j + 1) * SAMPLES + i + 1])
				var wet := false
				var all_water := true
				for k in square:
					all_water = all_water and not is_inf(water[k])
					wet = wet or water[k] > heights[k]
				if not (wet and all_water):
					continue
				# South-west, north-west, south-east; south-east, north-west, north-east.
				for index: int in [square[0], square[2], square[1], square[1], square[2], square[3]]:
					var i_k := index % SAMPLES
					var j_k := index / SAMPLES
					vertices.append(Vector3(corner.x + i_k * RESOLUTION, water[index], corner.z - j_k * RESOLUTION))
					var flow := flows[index] / NatureKit.WATER_MAX_FLOW * 0.5 + Vector2(0.5, 0.5)
					colors.append(Color(clampf(flow.x, 0.0, 1.0), clampf(flow.y, 0.0, 1.0), 0.0, 1.0))
	if vertices.is_empty():
		return
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	add_mesh("Water", mesh, NatureKit.water_material(), false)
