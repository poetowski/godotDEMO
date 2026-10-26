@tool
extends SectorDesign
## Sectors A1 to A3: a small stream rises from a spring among rocks in A3,
## winds south through A2 and opens into a lily pond in A1, a few steps from
## the start. The ground rolls gently, bushes follow the banks, and rocks and
## tufts of grass are scattered around. The brief is in
## docs/DESIGN_DECISIONS.md; the layout, sizes and colours are placeholders.

## The stream from the spring to the pond: world x, world z, half-width and
## water level, in metres.
const STREAM: Array[Vector4] = [
	Vector4(6.2, -25.6, 0.9, -0.1),
	Vector4(5.8, -23.8, 0.5, -0.12),
	Vector4(4.4, -21.6, 0.55, -0.14),
	Vector4(3.4, -18.8, 0.6, -0.16),
	Vector4(3.7, -15.6, 0.6, -0.18),
	Vector4(5.6, -13.0, 0.62, -0.2),
	Vector4(6.5, -10.4, 0.65, -0.22),
	Vector4(5.9, -8.6, 0.7, -0.24),
	Vector4(4.9, -7.4, 0.75, -0.245),
	Vector4(4.0, -6.0, 1.6, -0.25),
]
## Gentle mounds, each topped by a boulder: world x, world z, radius and
## height.
const MOUNDS: Array[Vector4] = [
	Vector4(7.9, -17.5, 2.3, 0.4),
	Vector4(2.8, -24.6, 2.0, 0.35),
	Vector4(8.0, -3.6, 1.8, 0.3),
]
## How high the banks' lip rises out of the water, in metres.
const BANK_RISE := 0.16
const MUD := Color(0.45, 0.39, 0.28)
const WET_EARTH := Color(0.34, 0.28, 0.19)

## How far the ground rises and dips, in metres.
@export var bumpiness: float = 0.35
## Metres per second in the narrow stretches; wider water flows slower.
@export var flow_speed: float = 0.55
@export var rocks_per_sector: int = 10
@export var bushes_per_sector: int = 5
@export var grass_per_sector: int = 1100
@export var lily_pads: int = 18
@export var flowering_share: float = 0.3

var _stream: StreamPath
var _bumps: FastNoiseLite
var _patches: FastNoiseLite
var _last_xz := Vector2(INF, INF)
var _last_hit: StreamPath.Hit


func _setup() -> void:
	_stream = StreamPath.new(STREAM, 2.5)
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.16
	_bumps.fractal_octaves = 3
	_patches = FastNoiseLite.new()
	_patches.seed = design_seed + 1
	_patches.frequency = 0.22


func _ground(xz: Vector2) -> float:
	var land := _land(xz)
	var hit := _hit(xz)
	if hit == null:
		return land
	var edge := hit.edge()
	if edge < 0.0:
		# Flattening toward the edge keeps the bed walkable, under 45 degrees.
		var reach := hit.reach()
		return hit.level - _depth(hit.half_width) * pow(1.0 - reach * reach, 2.0)
	# A lip rising out of the water, then banks that keep the land near the
	# stream above it, then the rolling land itself.
	var lip := hit.level + BANK_RISE * smoothstep(0.0, 0.5, edge)
	var shore := maxf(land, hit.level + BANK_RISE)
	var near := lerpf(lip, shore, smoothstep(0.3, 1.5, edge))
	return lerpf(near, land, smoothstep(1.5, 2.4, edge))


func _water_level(xz: Vector2) -> float:
	var hit := _hit(xz)
	return hit.level if hit != null and hit.edge() < 0.6 else NO_WATER


func _flow(xz: Vector2) -> Vector2:
	var hit := _hit(xz)
	if hit == null:
		return Vector2.ZERO
	var narrowness := minf(STREAM[1].z / hit.half_width, 1.2)
	var reach := clampf(hit.reach(), 0.0, 1.0)
	return hit.direction * flow_speed * narrowness * narrowness * (1.0 - 0.6 * reach * reach)


func _ground_tint(xz: Vector2) -> Color:
	var hit := _hit(xz)
	if hit == null:
		return GRASS
	var edge := hit.edge()
	var earth := MUD.lerp(WET_EARTH, smoothstep(-0.3, 0.05, edge))
	earth.a = smoothstep(0.1, 0.8, edge)
	return earth


func _populate() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 6:
		shapes.append(NatureKit.rock_shape(rng))
	_place_spring_rocks(shapes)
	_place_boulders(shapes)
	_place_bank_stones(shapes)
	_place_scattered_rocks(shapes)
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_bushes()
	commit_merged("Bushes", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_place_lilies()
	_place_grass()


## The rolling land before the stream cuts through it.
func _land(xz: Vector2) -> float:
	var height := 0.08 + bumpiness * _bumps.get_noise_2d(xz.x, xz.y)
	for mound in MOUNDS:
		var t := xz.distance_to(Vector2(mound.x, mound.y)) / mound.z
		if t < 1.0:
			height += mound.w * pow(1.0 - t * t, 2.0)
	return height


## Wider water runs deeper.
func _depth(half_width: float) -> float:
	return 0.22 + 0.15 * half_width


## The stream near a point. The hooks ask about the same point in turn, so the
## last answer is kept.
func _hit(xz: Vector2) -> StreamPath.Hit:
	if xz != _last_xz:
		_last_xz = xz
		_last_hit = _stream.nearest(xz)
	return _last_hit


## A boulder the spring wells up beside, and a ring of rocks around it, open
## where the stream leaves.
func _place_spring_rocks(shapes: Array[PackedVector3Array]) -> void:
	var spring := Vector2(STREAM[0].x, STREAM[0].y)
	var outflow := (Vector2(STREAM[1].x, STREAM[1].y) - spring).normalized()
	_try_rock(shapes, spring - outflow * (STREAM[0].z + 0.35), 0.85, 0.1, false)
	var count := 10
	for k in count:
		var angle := TAU * k / count + rng.randf_range(-0.15, 0.15)
		var direction := Vector2(cos(angle), sin(angle))
		if direction.dot(outflow) > 0.7:
			continue
		_try_rock(shapes, spring + direction * (STREAM[0].z + rng.randf_range(0.05, 0.2)), rng.randf_range(0.3, 0.52), 0.15, false)


## A boulder on each mound with a few smaller rocks at its feet.
func _place_boulders(shapes: Array[PackedVector3Array]) -> void:
	for mound in MOUNDS:
		var top := Vector2(mound.x, mound.y) + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4))
		_try_rock(shapes, top, rng.randf_range(0.65, 0.9), 0.15, true)
		for k in 3:
			var angle := rng.randf() * TAU
			_try_rock(shapes, top + Vector2(cos(angle), sin(angle)) * rng.randf_range(0.7, 1.3), rng.randf_range(0.14, 0.3), 0.15, true)


## Stones along the banks, half in the water, and two in the stream itself.
func _place_bank_stones(shapes: Array[PackedVector3Array]) -> void:
	var along := 1.5
	while along < _stream.length() - 1.0:
		var at := _stream_index(along)
		var side := _side(at) * (1.0 if rng.randf() < 0.5 else -1.0)
		var xz := _stream.points[at] + side * (_stream.half_widths[at] + rng.randf_range(-0.05, 0.35))
		_try_rock(shapes, xz, rng.randf_range(0.12, 0.3), 0.3, false)
		along += rng.randf_range(1.2, 2.6)
	for along_stream: float in [9.0, 16.5]:
		var at := _stream_index(along_stream)
		var xz := _stream.points[at] + _side(at) * _stream.half_widths[at] * 0.45
		_try_rock(shapes, xz, rng.randf_range(0.48, 0.55), 0.0, false)


func _place_scattered_rocks(shapes: Array[PackedVector3Array]) -> void:
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for k in rocks_per_sector * 3:
			if placed >= rocks_per_sector:
				break
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			if is_dry(xz, 0.12) and _try_rock(shapes, xz, lerpf(0.12, 0.55, pow(rng.randf(), 2.0)), 0.15, true):
				placed += 1


## Bushes in loose clumps along the banks, and a few out in the grass.
func _place_bushes() -> void:
	var along := 2.0
	while along < _stream.length() - 1.0:
		if rng.randf() < 0.65:
			var at := _stream_index(along)
			var side := _side(at) * (1.0 if rng.randf() < 0.5 else -1.0)
			_try_bush(_stream.points[at] + side * (_stream.half_widths[at] + rng.randf_range(0.8, 1.8)), rng.randf_range(0.55, 0.9))
		along += rng.randf_range(2.2, 4.0)
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		var placed := 0
		for k in bushes_per_sector * 4:
			if placed >= bushes_per_sector:
				break
			if _try_bush(Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE), rng.randf_range(0.5, 0.85)):
				placed += 1


## Lily pads on the still water of the pond and the spring, some in flower.
func _place_lilies() -> void:
	var pads: Array[Vector3] = []
	var spring := STREAM[0]
	var pond := STREAM[STREAM.size() - 1]
	_scatter_pads(pads, Vector2(pond.x, pond.y), pond.z * 0.85, lily_pads - 3)
	_scatter_pads(pads, Vector2(spring.x, spring.y), spring.z * 0.6, 3)
	var plain: Array[Transform3D] = []
	var plain_colors := PackedColorArray()
	var flowering: Array[Transform3D] = []
	var flowering_colors := PackedColorArray()
	for pad in pads:
		var xz := Vector2(pad.x, pad.y)
		var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * pad.z), Vector3(xz.x, water_level_at(xz) + 0.012, xz.y))
		var shade := rng.randf_range(0.9, 1.08)
		if rng.randf() < flowering_share:
			flowering.append(where)
			flowering_colors.append(Color(1.0, 1.0, 1.0))
		else:
			plain.append(where)
			plain_colors.append(Color(shade, shade, shade))
	var material := NatureKit.floating_material()
	add_multimesh("LilyPads", NatureKit.lily_pad(rng, false), material, plain, plain_colors, 70.0)
	add_multimesh("WaterLilies", NatureKit.lily_pad(rng, true), material, flowering, flowering_colors, 70.0)


func _scatter_pads(pads: Array[Vector3], centre: Vector2, radius: float, count: int) -> void:
	var placed := 0
	for attempt in count * 30:
		if placed >= count:
			return
		var angle := rng.randf() * TAU
		var xz := centre + Vector2(cos(angle), sin(angle)) * radius * sqrt(rng.randf())
		var size := rng.randf_range(0.15, 0.26)
		if water_level_at(xz) - height_at(xz) < 0.1 or flow_at(xz).length() > 0.2 or not is_clear(xz, size):
			continue
		var crowded := false
		for pad in pads:
			crowded = crowded or xz.distance_to(Vector2(pad.x, pad.y)) < size + pad.z + 0.04
		if crowded:
			continue
		pads.append(Vector3(xz.x, xz.y, size))
		placed += 1


## Tufts of grass in patches over the dry ground, lusher along the banks.
func _place_grass() -> void:
	var tufts: Array[ArrayMesh] = [NatureKit.grass_tuft(rng), NatureKit.grass_tuft(rng, 9)]
	var transforms: Array[Array] = [[], []]
	var colors: Array[PackedColorArray] = [PackedColorArray(), PackedColorArray()]
	for cell in cells():
		var corner := SectorMap.corner_of(cell)
		for k in int(grass_per_sector * 1.6):
			var xz := Vector2(corner.x + rng.randf() * SectorMap.SIZE, corner.z - rng.randf() * SectorMap.SIZE)
			var hit := _hit(xz)
			var bank := hit != null and hit.edge() > 0.3 and hit.edge() < 1.6
			var density := 1.0 if bank else 0.15 + 0.85 * smoothstep(-0.3, 0.3, _patches.get_noise_2d(xz.x, xz.y))
			if rng.randf() > density or not is_clear(xz, 0.0, 0.6) or not fits(xz, 0.25) or not is_dry(xz, 0.08) or _ground_tint(xz).a < 0.6:
				continue
			var size := rng.randf_range(0.8, 1.2) * (1.35 if bank else 1.0)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size))
			var variant := rng.randi() % 2
			transforms[variant].append(Transform3D(basis, Vector3(xz.x, height_at(xz) - 0.02, xz.y)))
			var shade := rng.randf_range(0.88, 1.08)
			colors[variant].append(Color(shade * 1.06, shade * 1.03, shade * 0.8) if rng.randf() < 0.12 else Color(shade, shade, shade))
	var material := NatureKit.grass_material()
	for variant in 2:
		var placed: Array[Transform3D] = []
		placed.assign(transforms[variant])
		add_multimesh("Grass%d" % variant, tufts[variant], material, placed, colors[variant], 45.0)


## Places a rock `size` metres across if it fits, resting on the lowest ground
## under it and sunk by `sink` of its size. Wide rocks become solid.
func _try_rock(shapes: Array[PackedVector3Array], xz: Vector2, size: float, sink: float, keep_dry: bool) -> bool:
	var radius := size * 0.62
	if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius):
		return false
	if keep_dry and not is_dry(xz, 0.05):
		return false
	var base := lowest_ground(xz, radius * 0.7) - sink * size * 0.5
	var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, base, xz.y))
	merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where, NatureKit.rock_color(rng))
	claim(xz, radius)
	if size >= 0.45:
		var shape := SphereShape3D.new()
		shape.radius = size * 0.38
		add_collider(shape, Transform3D(Basis(), Vector3(xz.x, base + size * 0.12, xz.y)))
	return true


func _try_bush(xz: Vector2, size: float) -> bool:
	var radius := size * 0.75
	if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius) or not is_dry(xz, 0.12):
		return false
	var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, radius * 0.4) - 0.04, xz.y))
	NatureKit.add_bush(merged("Bushes", xz), rng, where)
	claim(xz, radius)
	return true


## The index of the stream's centre-line point `along` metres from the spring.
func _stream_index(along: float) -> int:
	for i in _stream.distances.size() - 1:
		if _stream.distances[i] >= along:
			return i
	return _stream.distances.size() - 2


## Unit vector across the stream at a centre-line point.
func _side(at: int) -> Vector2:
	var direction := (_stream.points[at + 1] - _stream.points[at]).normalized()
	return Vector2(-direction.y, direction.x)
