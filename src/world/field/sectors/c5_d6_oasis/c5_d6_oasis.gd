@tool
extends SectorDesign
## Sectors C5, C6, D5, D6: an oasis. A patch of low sand dunes in the field
## around a still spring-fed pond ringed by green grass, reeds and date
## palms, with a camp of three tents (a big striped one with an awning, two
## small ones) around a campfire. Its resident lives in the field's
## `Residents` (they walk on whether or not the oasis is loaded). The brief is
## in docs/DESIGN_DECISIONS.md; everything beyond "oasis with tents" is
## placeholder.

const POND := Vector2(30.0, -49.0)
const POND_RADIUS := 3.8
const WATER := 0.0
const FIRE := Vector2(30.0, -55.0)
const SAND := Color(0.84, 0.74, 0.52)
const OASIS_GREEN := Color(0.3, 0.5, 0.2)
const TRUNK := Color(0.47, 0.36, 0.24)
const FROND := Color(0.29, 0.47, 0.17)
const POLE := Color(0.36, 0.25, 0.16)
## Tents: centre, facing (radians, 0 = door toward -z), width, depth, height,
## cloth, stripe (alpha 0 = none).
const TENTS: Array[Dictionary] = [
	{"at": Vector2(35.0, -56.5), "yaw": -0.9, "size": Vector3(3.4, 2.4, 3.6), "cloth": Color(0.86, 0.8, 0.68), "stripe": Color(0.62, 0.2, 0.15, 1.0)},
	{"at": Vector2(24.8, -56.6), "yaw": 1.27, "size": Vector3(2.0, 1.5, 2.4), "cloth": Color(0.7, 0.56, 0.38), "stripe": Color(0, 0, 0, 0)},
	{"at": Vector2(36.0, -46.8), "yaw": -1.92, "size": Vector3(2.0, 1.5, 2.4), "cloth": Color(0.56, 0.42, 0.3), "stripe": Color(0, 0, 0, 0)},
]

## How high the dunes rise, in metres.
@export var dune_height: float = 0.45
@export var palms: int = 9
@export var grass: int = 1400

var _dunes: FastNoiseLite
var _shore: FastNoiseLite


func _setup() -> void:
	_dunes = FastNoiseLite.new()
	_dunes.seed = design_seed
	_dunes.frequency = 0.07
	_dunes.fractal_octaves = 2
	_shore = FastNoiseLite.new()
	_shore.seed = design_seed + 1
	_shore.frequency = 0.35


## Metres outside the pond's wavy shore (negative in the water).
func _from_shore(xz: Vector2) -> float:
	var to := xz - POND
	var radius := POND_RADIUS + 0.6 * _shore.get_noise_1d(atan2(to.y, to.x) * 3.0)
	return to.length() - radius


## 0 near the pond, 1 out on the sand.
func _sandiness(xz: Vector2) -> float:
	return smoothstep(1.5, 4.5, _from_shore(xz))


func _ground(xz: Vector2) -> float:
	var shore := _from_shore(xz)
	if shore < 0.0:
		var reach := clampf(-shore / POND_RADIUS, 0.0, 1.0)
		return WATER - 0.12 - 0.7 * (1.0 - pow(1.0 - reach, 2.0))
	var lip := 0.16 * (1.0 - smoothstep(0.0, 1.5, shore))
	var dunes := dune_height * (0.5 + 0.5 * _dunes.get_noise_2d(xz.x, xz.y)) * _sandiness(xz)
	# The camp ground around the fire stays level.
	var camp := 1.0 - smoothstep(4.0, 7.0, xz.distance_to(FIRE))
	return lerpf(0.06 + lip + dunes, 0.08, camp)


func _water_level(xz: Vector2) -> float:
	return WATER if _from_shore(xz) < 0.6 else NO_WATER


func _ground_tint(xz: Vector2) -> Color:
	var sand := _sandiness(xz)
	if xz.distance_to(FIRE) < 2.2:
		return Color(0.6, 0.5, 0.36, 0.0)
	if sand <= 0.0:
		return Color(OASIS_GREEN, 1.0)
	return Color(SAND.lerp(OASIS_GREEN, 1.0 - sand), 1.0 - sand)


func _populate() -> void:
	for tent: Dictionary in TENTS:
		_build_tent(tent)
	_build_campfire()
	_build_palms()
	commit_merged("Camp", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	commit_merged("Palms", MeshKit.lowpoly_material(Color.WHITE, 0.85))
	if not props_frozen:
		_place_rocks()
	_place_reeds_and_grass()
	_place_lilies()


## A ridge tent of two sloping cloth panels on poles, closed at the back,
## its open door showing the dark inside. The big one has a striped cloth and
## an awning over the door.
func _build_tent(tent: Dictionary) -> void:
	var at: Vector2 = tent["at"]
	var size: Vector3 = tent["size"]
	var cloth: Color = tent["cloth"]
	var stripe: Color = tent["stripe"]
	var basis := Basis(Vector3.UP, float(tent["yaw"]))
	var origin := Vector3(at.x, lowest_ground(at, 1.0) - 0.02, at.y)
	var place := Transform3D(basis, origin)
	var batch := merged("Camp", at)
	var w := size.x * 0.5
	var h := size.y
	var d := size.z * 0.5
	var strips := 6 if stripe.a > 0.0 else 1
	for side: float in [-1.0, 1.0]:
		for k in strips:
			var z0 := -d + size.z * k / strips
			var z1 := -d + size.z * (k + 1) / strips
			var colour := stripe if stripe.a > 0.0 and k % 2 == 1 else cloth
			var panel := _quad(Vector3(side * w, 0, z0), Vector3(side * w, 0, z1), Vector3(0, h, z1), Vector3(0, h, z0))
			batch.add(panel, place, colour * (0.92 if side > 0.0 else 1.0))
	# The back wall, and the dark inside seen through the door.
	batch.add(_two_sided([Vector3(-w, 0, -d), Vector3(0, h, -d), Vector3(w, 0, -d)]), place, cloth * 0.85)
	batch.add(_two_sided([Vector3(-w * 0.7, 0, -d + 0.05), Vector3(0, h * 0.7, -d + 0.05), Vector3(w * 0.7, 0, -d + 0.05)]), place, Color(0.12, 0.09, 0.07))
	batch.add(_two_sided([Vector3(-w * 0.95, 0, d - 0.02), Vector3(0, h * 0.97, d - 0.02), Vector3(-w * 0.95, 0, -d + 0.1)]), place, Color(0.16, 0.12, 0.09))
	batch.add(_two_sided([Vector3(w * 0.95, 0, d - 0.02), Vector3(w * 0.95, 0, -d + 0.1), Vector3(0, h * 0.97, d - 0.02)]), place, Color(0.16, 0.12, 0.09))
	# Door flaps tied back on either side.
	for side: float in [-1.0, 1.0]:
		batch.add(_two_sided([Vector3(side * w, 0, d), Vector3(side * w * 0.55, 0, d + 0.12), Vector3(0, h, d)]), place, cloth * 0.95)
	# Poles at the ends of the ridge, and the ridge itself.
	for z: float in [-d, d]:
		_box(batch, place * Vector3(0, h * 0.5, z), Vector3(0.07, h + 0.15, 0.07), POLE, basis)
	_box(batch, place * Vector3(0, h, 0), Vector3(0.06, 0.06, size.z + 0.1), POLE, basis)
	if stripe.a > 0.0:
		_build_awning(batch, place, basis, w, h, d, stripe, cloth)
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.8, h * 0.8, size.z)
	add_collider(shape, Transform3D(basis, place * Vector3(0, h * 0.4, 0)))
	claim(at, maxf(size.x, size.z) * 0.6)


func _build_awning(batch: NatureKit.Batch, place: Transform3D, basis: Basis, w: float, h: float, d: float, stripe: Color, cloth: Color) -> void:
	var reach := 1.2
	var low := h * 0.62
	for k in 4:
		var x0 := -w + 2.0 * w * k / 4
		var x1 := -w + 2.0 * w * (k + 1) / 4
		var colour := stripe if k % 2 == 0 else cloth
		batch.add(_quad(Vector3(x0, h * 0.85, d), Vector3(x0, low, d + reach), Vector3(x1, low, d + reach), Vector3(x1, h * 0.85, d)), place, colour)
	for side: float in [-1.0, 1.0]:
		_box(batch, place * Vector3(side * w, low * 0.5, d + reach), Vector3(0.06, low, 0.06), POLE, basis)
	# A rug under the awning.
	_box(batch, place * Vector3(0, 0.03, d + reach * 0.5), Vector3(w * 1.5, 0.03, reach * 0.9), Color(0.52, 0.17, 0.14), basis)
	_box(batch, place * Vector3(0, 0.035, d + reach * 0.5), Vector3(w * 1.1, 0.03, reach * 0.6), Color(0.82, 0.62, 0.3), basis)
	# Clay water jars beside the door.
	for k in 3:
		var jar := place * Vector3(w + 0.35, 0.0, d - 0.2 - 0.42 * k)
		batch.add(MeshKit.triangles(MeshKit.sphere(0.2, 8, 5)), Transform3D(Basis().scaled(Vector3(1, 1.3, 1)), jar + Vector3.UP * 0.24), Color(0.7, 0.42, 0.26))
		batch.add(MeshKit.triangles(MeshKit.cylinder(0.08, 0.1, 0.12, 8)), Transform3D(Basis(), jar + Vector3.UP * 0.53), Color(0.66, 0.4, 0.25))


## A ring of stones around logs and embers, with a low flickerless glow.
func _build_campfire() -> void:
	var batch := merged("Camp", FIRE)
	var base := height_at(FIRE)
	var stone := NatureKit.rock_shape(rng)
	for k in 9:
		var angle := TAU * k / 9.0
		var xz := FIRE + Vector2(cos(angle), sin(angle)) * 0.6
		batch.add(stone, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * 0.24), Vector3(xz.x, base - 0.03, xz.y)), NatureKit.rock_color(rng))
	for k in 3:
		var log_basis := Basis(Vector3.UP, TAU * k / 3.0) * Basis(Vector3.RIGHT, PI * 0.5 - 0.35)
		_box(batch, Vector3(FIRE.x, base + 0.14, FIRE.y), Vector3(0.1, 0.1, 0.62), TRUNK * 0.7, log_basis)
	var embers := StandardMaterial3D.new()
	embers.albedo_color = Color(1.0, 0.45, 0.12)
	embers.emission_enabled = true
	embers.emission = Color(1.0, 0.42, 0.1)
	embers.emission_energy_multiplier = 3.0
	var flame := add_mesh("Embers", MeshKit.cone(0.2, 0.42, 6), embers, false)
	flame.position = Vector3(FIRE.x, base + 0.24, FIRE.y)
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.6, 0.3)
	light.light_energy = 1.6
	light.omni_range = 7.0
	light.position = Vector3(FIRE.x, base + 0.8, FIRE.y)
	add_content(light)
	# Logs to sit on.
	for k in 3:
		var angle := 0.5 + TAU * k / 3.0
		var xz := FIRE + Vector2(cos(angle), sin(angle)) * 1.6
		_box(batch, Vector3(xz.x, base + 0.14, xz.y), Vector3(1.1, 0.26, 0.28), TRUNK, Basis(Vector3.UP, -angle))
	claim(FIRE, 2.0)


## Date palms around the pond, leaning out over it a little, with drooping
## fronds and clusters of dates.
func _build_palms() -> void:
	var trunk_piece := MeshKit.triangles(MeshKit.cylinder(1.0, 1.0, 1.0, 7))
	var placed := 0
	for attempt in palms * 8:
		if placed >= palms:
			break
		var angle := rng.randf() * TAU
		var xz := POND + Vector2(cos(angle), sin(angle)) * (POND_RADIUS + rng.randf_range(1.6, 3.4))
		if not fits(xz, 2.5) or crowds_start(xz, 0.6) or not is_clear(xz, 0.6, 1.2) or not is_dry(xz, 0.1):
			continue
		var height := rng.randf_range(4.5, 6.5)
		var lean := (POND - xz).normalized() * rng.randf_range(0.6, 1.4)
		_build_palm(merged("Palms", xz), trunk_piece, Vector3(xz.x, height_at(xz) - 0.1, xz.y), height, lean)
		var shape := CylinderShape3D.new()
		shape.radius = 0.2
		shape.height = 2.0
		add_collider(shape, Transform3D(Basis(), Vector3(xz.x, height_at(xz) + 1.0, xz.y)))
		claim(xz, 0.6)
		placed += 1


func _build_palm(batch: NatureKit.Batch, piece: PackedVector3Array, foot: Vector3, height: float, lean: Vector2) -> void:
	var segments := 8
	var previous := foot
	for k in segments:
		var t := float(k + 1) / segments
		var point := foot + Vector3(lean.x * t * t, height * t, lean.y * t * t)
		var axis := point - previous
		var radius := lerpf(0.2, 0.13, t)
		var basis := Basis(Quaternion(Vector3.UP, axis.normalized())).scaled(Vector3(radius, axis.length() * 1.05, radius))
		batch.add(piece, Transform3D(basis, (point + previous) * 0.5), TRUNK * (0.9 + 0.12 * float(k % 2)))
		previous = point
	var crown := previous
	for k in 9:
		var yaw := TAU * k / 9.0 + rng.randf() * 0.3
		_add_frond(batch, crown, Vector3(cos(yaw), rng.randf_range(0.15, 0.5), sin(yaw)).normalized(), rng.randf_range(2.0, 2.8))
	for k in 3:
		var yaw := TAU * k / 3.0
		var bunch := crown + Vector3(cos(yaw) * 0.22, -0.3, sin(yaw) * 0.22)
		batch.add(MeshKit.triangles(MeshKit.sphere(0.16, 6, 4)), Transform3D(Basis().scaled(Vector3(1, 1.4, 1)), bunch), Color(0.62, 0.36, 0.14))


## One frond: a leaf strip arching out and drooping, wide in the middle.
func _add_frond(batch: NatureKit.Batch, crown: Vector3, out: Vector3, length: float) -> void:
	var side := out.cross(Vector3.UP).normalized()
	var steps := 5
	var triangles := PackedVector3Array()
	var previous_mid := crown
	var previous_half := Vector3.ZERO
	for k in steps:
		var t := float(k + 1) / steps
		var mid := crown + out * length * t + Vector3.DOWN * (t * t * length * 0.55)
		var half := side * 0.32 * sin(PI * minf(t, 0.96)) + Vector3.DOWN * 0.08 * t
		var a := previous_mid - previous_half
		var b := previous_mid + previous_half
		var c := mid + half
		var e := mid - half
		triangles.append_array(_two_sided([a, b, c]))
		triangles.append_array(_two_sided([a, c, e]))
		previous_mid = mid
		previous_half = half
	batch.add(triangles, Transform3D(), FROND * rng.randf_range(0.85, 1.12))


func _place_rocks() -> void:
	for k in 14:
		var xz := random_point()
		var size := lerpf(0.2, 0.7, pow(rng.randf(), 2.0))
		var radius := size * 0.62
		if not fits(xz, radius + 2.0) or crowds_start(xz, radius) or not is_clear(xz, radius, 1.0) or not is_dry(xz, 0.1):
			continue
		var base := lowest_ground(xz, radius * 0.7) - 0.08 * size
		place_prop(PropLibrary.Kind.ROCK, rng.randi() % 5, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, base, xz.y)), size >= 0.45)
		claim(xz, radius)


## Tall reeds on the shore and grass on the green ring; the sand stays bare.
func _place_reeds_and_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass * 2:
		var xz := random_point()
		var shore := _from_shore(xz)
		var sand := _sandiness(xz)
		if shore < 0.0 or rng.randf() < sand * 1.4 or not is_clear(xz, 0.0, 0.5) or not fits(xz, 0.25):
			continue
		var reed := shore < 1.0
		var size := rng.randf_range(1.6, 2.4) if reed else rng.randf_range(0.8, 1.2)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size * (0.6 if reed else 1.0), size, size * (0.6 if reed else 1.0)))
		transforms.append(Transform3D(basis, Vector3(xz.x, height_at(xz) - 0.02, xz.y)))
		var shade := rng.randf_range(0.88, 1.08)
		colors.append(Color(shade, shade * (1.05 if reed else 1.0), shade * 0.9))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)


func _place_lilies() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in 40:
		if transforms.size() >= 10:
			break
		var angle := rng.randf() * TAU
		var xz := POND + Vector2(cos(angle), sin(angle)) * rng.randf_range(1.0, POND_RADIUS - 0.6)
		if _from_shore(xz) > -0.5:
			continue
		var size := rng.randf_range(0.8, 1.2)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, WATER + 0.01, xz.y)))
		colors.append(Color.WHITE)
	add_multimesh("Lilies", NatureKit.lily_pad(rng, true), NatureKit.floating_material(), transforms, colors, 45.0)


func _box(batch: NatureKit.Batch, centre: Vector3, size: Vector3, color: Color, basis: Basis = Basis()) -> void:
	batch.add(MeshKit.triangles(MeshKit.box(size)), Transform3D(basis, centre), color)


func _quad(a: Vector3, b: Vector3, c: Vector3, e: Vector3) -> PackedVector3Array:
	var triangles := _two_sided([a, b, c])
	triangles.append_array(_two_sided([a, c, e]))
	return triangles


## A triangle seen from both sides.
func _two_sided(corners: Array[Vector3]) -> PackedVector3Array:
	return PackedVector3Array([corners[0], corners[1], corners[2], corners[0], corners[2], corners[1]])
