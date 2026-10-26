@tool
extends SectorDesign
## Sectors D1, D2, E1 and E2: Bratislava Castle on its hill, stylised. A white
## rectangular palace around a courtyard under a red hipped roof, with a
## square tower at each corner capped by a red pyramid roof. A low white
## fortification wall rings the hilltop, and a road climbs the south slope
## from near D1's start to the gate. Trees, bushes, rocks and grass cover the
## slopes. The brief is in docs/DESIGN_DECISIONS.md; proportions, sizes and
## colours are placeholders.

## The hilltop's centre (world x, z).
const HILL := Vector2(40.0, -10.8)
## Half the hilltop's size, east-west and north-south, in metres.
const PLATEAU := Vector2(6.2, 5.0)
const PLATEAU_CORNER := 2.2
## The road from the foot of the hill to the gate.
const ROAD_FOOT := Vector2(33.6, -2.2)
const ROAD_TOP := Vector2(40.0, -6.4)
const ROAD_HALF_WIDTH := 0.9
## The palace: centre, half size east-west and north-south.
const PALACE := Vector2(40.0, -11.4)
const PALACE_HALF := Vector2(4.0, 2.9)
const WING := 1.4
const PLASTER := Color(0.93, 0.92, 0.88)
const ROOF := Color(0.72, 0.31, 0.2)
const WINDOW := Color(0.14, 0.15, 0.17)
const DIRT := Color(0.56, 0.47, 0.34)
const GRAVEL := Color(0.72, 0.68, 0.6)

## Hilltop height above the field.
@export var hill_height: float = 3.0
## Metres over which the hill falls from its top to the field.
@export var slope_width: float = 3.6
@export var wall_height: float = 4.2
@export var tower_height: float = 6.0
@export var trees: int = 7
@export var bushes: int = 12
@export var grass: int = 2600

var _bumps: FastNoiseLite
var _top := 0.0


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.18


func _ground(xz: Vector2) -> float:
	var outside := _plateau_distance(xz)
	var hill := hill_height * (1.0 - smoothstep(0.0, slope_width, outside))
	hill += 0.12 * _bumps.get_noise_2d(xz.x, xz.y) * smoothstep(-0.5, 0.5, outside)
	var road := _road(xz)
	return lerpf(hill, road.y, 1.0 - smoothstep(ROAD_HALF_WIDTH, ROAD_HALF_WIDTH + 1.2, road.x))


## Gravel on the hilltop, a dirt road up the slope.
func _ground_tint(xz: Vector2) -> Color:
	var road_grass := smoothstep(ROAD_HALF_WIDTH - 0.2, ROAD_HALF_WIDTH + 0.3, _road(xz).x)
	var top_grass := smoothstep(-1.0, -0.4, _plateau_distance(xz))
	var tint := DIRT if road_grass < top_grass else GRAVEL
	tint.a = minf(road_grass, top_grass)
	return tint


func _populate() -> void:
	_top = hill_height
	var batch := merged("Castle", PALACE)
	_build_palace(batch)
	_build_towers(batch)
	_build_rim_wall(batch)
	claim(HILL, PLATEAU.x + 0.4)
	commit_merged("Castle", MeshKit.lowpoly_material(Color.WHITE, 0.85))
	_place_trees()
	commit_merged("Trees", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	_place_rocks_and_bushes()
	commit_merged("Rocks", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	commit_merged("Bushes", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	_place_grass()


## Signed distance from the rounded-rectangle hilltop: negative on top.
func _plateau_distance(xz: Vector2) -> float:
	var q := (xz - HILL).abs() - PLATEAU + Vector2.ONE * PLATEAU_CORNER
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - PLATEAU_CORNER


## Distance from the road's centre line and the road's height there, as x and y.
func _road(xz: Vector2) -> Vector2:
	var along := ROAD_TOP - ROAD_FOOT
	var t := clampf((xz - ROAD_FOOT).dot(along) / along.length_squared(), 0.0, 1.0)
	return Vector2(xz.distance_to(ROAD_FOOT + along * t), hill_height * t)


func _box(batch: NatureKit.Batch, centre: Vector3, size: Vector3, color: Color) -> void:
	batch.add(MeshKit.triangles(MeshKit.box(size)), Transform3D(Basis(), centre), color)


func _solid(centre: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	add_collider(shape, Transform3D(Basis(), centre))


func _at(xz: Vector2, height: float) -> Vector3:
	return Vector3(xz.x, _top + height, xz.y)


## Four wings around a courtyard, windows in rows on every outer face, a
## cornice, the gate in the south wing, and the hipped roof.
func _build_palace(batch: NatureKit.Batch) -> void:
	var h := wall_height
	var base := -0.4
	var outer := PALACE_HALF * 2.0
	# South and north wings run the full width; east and west wings fill between.
	for side: float in [-1.0, 1.0]:
		var z := PALACE.y + side * (PALACE_HALF.y - WING * 0.5)
		var centre := _at(Vector2(PALACE.x, z), (h + base) * 0.5)
		if side > 0.0:
			# The gate wing: two halves either side of the gateway, and a lintel.
			var half_width := (outer.x - 1.2) * 0.5
			for part: float in [-1.0, 1.0]:
				var x := PALACE.x + part * (0.6 + half_width * 0.5)
				_box(batch, Vector3(x, centre.y, z), Vector3(half_width, h - base, WING), PLASTER)
				_solid(Vector3(x, centre.y, z), Vector3(half_width, h - base, WING))
			_box(batch, _at(Vector2(PALACE.x, z), (h + 2.0) * 0.5), Vector3(1.2, h - 2.0, WING), PLASTER)
			_box(batch, _at(Vector2(PALACE.x, z - 0.02), 0.85), Vector3(1.1, 2.0, WING + 0.06), WINDOW * 0.6)
		else:
			_box(batch, centre, Vector3(outer.x, h - base, WING), PLASTER)
			_solid(centre, Vector3(outer.x, h - base, WING))
	for side: float in [-1.0, 1.0]:
		var x := PALACE.x + side * (PALACE_HALF.x - WING * 0.5)
		var size := Vector3(WING, h - base, outer.y - 2.0 * WING)
		_box(batch, _at(Vector2(x, PALACE.y), (h + base) * 0.5), size, PLASTER)
		_solid(_at(Vector2(x, PALACE.y), (h + base) * 0.5), size)
	# Courtyard floor.
	_box(batch, _at(PALACE, -0.02), Vector3(outer.x - 2.0 * WING, 0.06, outer.y - 2.0 * WING), Color(0.6, 0.57, 0.52))
	# Cornice under the eaves.
	_box(batch, _at(PALACE, h - 0.12), Vector3(outer.x + 0.16, 0.18, outer.y + 0.16), PLASTER * 0.92)
	_build_windows(batch)
	_build_hipped_roof(batch, h)


## Dark windows in three rows along the outer faces, leaving the gate and the
## corners, where the towers stand, clear.
func _build_windows(batch: NatureKit.Batch) -> void:
	var rows: Array[float] = [0.9, 2.1, 3.3]
	var size := Vector3(0.36, 0.62, 0.06)
	for row in rows:
		for k in 8:
			var x := PALACE.x - PALACE_HALF.x + 1.6 + k * (PALACE_HALF.x * 2.0 - 3.2) / 7.0
			for side: float in [-1.0, 1.0]:
				if side > 0.0 and absf(x - PALACE.x) < 0.9 and row < 2.0:
					continue
				var z := PALACE.y + side * (PALACE_HALF.y + 0.02)
				_box(batch, _at(Vector2(x, z), row), size, WINDOW)
		for k in 5:
			var z := PALACE.y - PALACE_HALF.y + 1.5 + k * (PALACE_HALF.y * 2.0 - 3.0) / 4.0
			for side: float in [-1.0, 1.0]:
				var x := PALACE.x + side * (PALACE_HALF.x + 0.02)
				_box(batch, _at(Vector2(x, z), row), Vector3(size.z, size.y, size.x), WINDOW)


## A roof over the wings: slopes rise from the outer eaves and from the
## courtyard's eaves to a ridge running around above the middle of the wings.
func _build_hipped_roof(batch: NatureKit.Batch, eave: float) -> void:
	var overhang := 0.2
	var ridge_rise := 1.5
	var outer := _rect(PALACE_HALF + Vector2.ONE * overhang, eave)
	var ridge := _rect(PALACE_HALF - Vector2.ONE * WING * 0.5, eave + ridge_rise)
	var inner := _rect(PALACE_HALF - Vector2.ONE * (WING + overhang * 0.5), eave)
	_roof_band(batch, outer, ridge)
	_roof_band(batch, ridge, inner)


## The four corners of a rectangle around the palace's centre at a height,
## going round: south-west, south-east, north-east, north-west.
func _rect(half: Vector2, height: float) -> Array[Vector3]:
	return [
		_at(PALACE + Vector2(-half.x, half.y), height),
		_at(PALACE + Vector2(half.x, half.y), height),
		_at(PALACE + Vector2(half.x, -half.y), height),
		_at(PALACE + Vector2(-half.x, -half.y), height),
	]


## Quads joining two concentric rectangles, two-faced so they show from above
## and below.
func _roof_band(batch: NatureKit.Batch, a: Array[Vector3], b: Array[Vector3]) -> void:
	for k in 4:
		var n := (k + 1) % 4
		var shade := ROOF * (0.94 if k % 2 == 0 else 1.04)
		var quad := PackedVector3Array([a[k], a[n], b[k], a[n], b[n], b[k]])
		batch.add(quad, Transform3D(), shade)
		quad.reverse()
		batch.add(quad, Transform3D(), shade)


## A square tower at each corner, taller than the wings, with windows, a
## cornice and a red pyramid roof under a gold finial.
func _build_towers(batch: NatureKit.Batch) -> void:
	var size := 2.0
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var xz := PALACE + Vector2(sx * PALACE_HALF.x, sz * PALACE_HALF.y)
			var body := Vector3(size, tower_height + 0.4, size)
			_box(batch, _at(xz, tower_height * 0.5 - 0.2), body, PLASTER)
			_solid(_at(xz, tower_height * 0.5 - 0.2), body)
			_box(batch, _at(xz, tower_height - 0.1), Vector3(size + 0.16, 0.2, size + 0.16), PLASTER * 0.92)
			for row: float in [2.1, 3.3, 4.6]:
				for face in 4:
					var out := Vector2(cos(face * PI * 0.5), sin(face * PI * 0.5))
					var window_size := Vector3(0.06, 0.62, 0.36) if face % 2 == 0 else Vector3(0.36, 0.62, 0.06)
					_box(batch, _at(xz + out * (size * 0.5 + 0.02), row), window_size, WINDOW)
			var roof := MeshKit.triangles(MeshKit.cone((size + 0.3) * 0.7071, 2.0, 4))
			batch.add(roof, Transform3D(Basis(Vector3.UP, PI * 0.25), _at(xz, tower_height + 1.0)), ROOF)
			batch.add(MeshKit.triangles(MeshKit.cylinder(0.03, 0.05, 0.6, 6)), Transform3D(Basis(), _at(xz, tower_height + 2.2)), Color(0.88, 0.7, 0.3))


## A low white wall along the hilltop's straight edges, open where the road
## arrives.
func _build_rim_wall(batch: NatureKit.Batch) -> void:
	var inset := PLATEAU - Vector2.ONE * 0.45
	var height := 0.9
	var segment := 1.0
	var thickness := 0.35
	for side: float in [-1.0, 1.0]:
		var count := floori((inset.x - PLATEAU_CORNER) * 2.0 / segment)
		for k in count:
			var x := HILL.x - inset.x + PLATEAU_CORNER + (k + 0.5) * segment
			var xz := Vector2(x, HILL.y + side * inset.y)
			if side > 0.0 and absf(x - ROAD_TOP.x) < 1.3:
				continue
			_wall_segment(batch, xz, Vector3(segment + 0.02, height, thickness), height)
		var rows := floori((inset.y - PLATEAU_CORNER) * 2.0 / segment)
		for k in rows:
			var z := HILL.y - inset.y + PLATEAU_CORNER + (k + 0.5) * segment
			_wall_segment(batch, Vector2(HILL.x + side * inset.x, z), Vector3(thickness, height, segment + 0.02), height)


func _wall_segment(batch: NatureKit.Batch, xz: Vector2, size: Vector3, height: float) -> void:
	var foot := height_at(xz) - 0.3
	var centre := Vector3(xz.x, foot + (height + 0.3) * 0.5, xz.y)
	var full := Vector3(size.x, height + 0.3, size.z)
	_box(batch, centre, full, PLASTER * 0.95)
	_box(batch, centre + Vector3.UP * (full.y * 0.5 + 0.04), Vector3(size.x + 0.04, 0.08, size.z + 0.06), Color(0.62, 0.6, 0.56))
	_solid(centre, full)


## Round-crowned trees on the slopes and at the foot of the hill.
func _place_trees() -> void:
	var placed := 0
	for attempt in trees * 20:
		if placed >= trees:
			return
		var xz := random_point()
		var outside := _plateau_distance(xz)
		if outside < 0.8 or _road(xz).x < 2.2 or not fits(xz, 1.6) or crowds_start(xz, 1.6) or not is_clear(xz, 1.6):
			continue
		var batch := merged("Trees", xz)
		var foot := lowest_ground(xz, 0.3) - 0.1
		var height := rng.randf_range(3.0, 4.2)
		batch.add(MeshKit.triangles(MeshKit.cylinder(0.12, 0.2, height, 7)), Transform3D(Basis(), Vector3(xz.x, foot + height * 0.5, xz.y)), Color(0.38, 0.27, 0.18))
		for lump in 4:
			var radius := rng.randf_range(0.8, 1.2)
			var offset := Vector3(rng.randf_range(-0.5, 0.5), height + rng.randf_range(-0.3, 0.5), rng.randf_range(-0.5, 0.5))
			batch.add(NatureKit.lumpy_sphere(rng, radius, 0.25), Transform3D(Basis(), Vector3(xz.x, foot, xz.y) + offset), NatureKit.LEAF_GREENS[rng.randi() % NatureKit.LEAF_GREENS.size()])
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.22
		trunk.height = height
		add_collider(trunk, Transform3D(Basis(), Vector3(xz.x, foot + height * 0.5, xz.y)))
		claim(xz, 1.6)
		placed += 1


func _place_rocks_and_bushes() -> void:
	var shapes: Array[PackedVector3Array] = []
	for k in 4:
		shapes.append(NatureKit.rock_shape(rng))
	var placed := 0
	for attempt in bushes * 10:
		var xz := random_point()
		if _plateau_distance(xz) < 0.3 or _road(xz).x < 1.6:
			continue
		var size := rng.randf_range(0.5, 0.9)
		var radius := size * 0.75
		if not fits(xz, radius) or crowds_start(xz, radius) or not is_clear(xz, radius):
			continue
		var where := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, lowest_ground(xz, radius * 0.5) - 0.05, xz.y))
		if placed < bushes:
			NatureKit.add_bush(merged("Bushes", xz), rng, where)
		else:
			where = Transform3D(where.basis.scaled(Vector3.ONE * 0.5), where.origin)
			merged("Rocks", xz).add(shapes[rng.randi() % shapes.size()], where, NatureKit.rock_color(rng))
		claim(xz, radius)
		placed += 1
		if placed >= bushes + 10:
			return


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if _plateau_distance(xz) < -0.2 or _road(xz).x < ROAD_HALF_WIDTH + 0.2 or not fits(xz, 0.25) or not is_clear(xz, 0.0, 0.6):
			continue
		var size := rng.randf_range(0.8, 1.2)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.85, 1.2), size)), surface(xz) - Vector3(0.0, 0.02, 0.0)))
		var shade := rng.randf_range(0.88, 1.08)
		colors.append(Color(shade, shade, shade))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
