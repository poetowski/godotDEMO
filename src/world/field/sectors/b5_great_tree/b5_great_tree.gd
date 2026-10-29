@tool
extends SectorDesign
## Sector B5: a great tree, 18 m tall, on a low mound of its own roots: a
## thick trunk flaring into buttress roots, big branches spreading into a
## wide crown, and glowing vines hanging from the branches and winding down
## the trunk, softly lit. The brief is in docs/DESIGN_DECISIONS.md; all but
## the size, the thick trunk, the big crown and the glowing vines is
## placeholder.

const FOOT := Vector2(15.0, -45.0)
const BARK := Color(0.4, 0.3, 0.22)
const LEAVES: Array[Color] = [Color(0.17, 0.36, 0.16), Color(0.22, 0.43, 0.18), Color(0.27, 0.48, 0.2)]

## Metres to the top of the crown.
@export var height: float = 18.0
@export var trunk_radius: float = 1.1
## Where the trunk splits into branches.
@export var fork_height: float = 8.5
@export var vine_color: Color = Color(0.45, 1.0, 0.75)
@export var grass: int = 900

var _bumps: FastNoiseLite
var _branch_tips: Array[Vector3] = []


func _setup() -> void:
	_bumps = FastNoiseLite.new()
	_bumps.seed = design_seed
	_bumps.frequency = 0.18


## A low mound over the roots, gently uneven around it.
func _ground(xz: Vector2) -> float:
	var t := xz.distance_to(FOOT) / 4.5
	var mound := 0.45 * pow(maxf(0.0, 1.0 - t * t), 2.0)
	return 0.04 + 0.08 * _bumps.get_noise_2d(xz.x, xz.y) + mound


## Bare, root-trodden earth under the trunk.
func _ground_tint(xz: Vector2) -> Color:
	var t := xz.distance_to(FOOT)
	return Color(0.36, 0.29, 0.2, smoothstep(1.4, 3.2, t))


func _populate() -> void:
	var base := lowest_ground(FOOT, trunk_radius) - 0.1
	var foot := Vector3(FOOT.x, base, FOOT.y)
	var wood := merged("Tree", FOOT)
	var vines := NatureKit.Batch.new()
	_build_trunk(wood, foot)
	_build_roots(wood, foot)
	_build_branches(wood, foot)
	_build_crown(merged("Crown", FOOT), foot)
	_build_vines(vines, foot)
	commit_merged("Tree", MeshKit.lowpoly_material(Color.WHITE, 0.95))
	commit_merged("Crown", MeshKit.lowpoly_material(Color.WHITE, 0.9))
	add_mesh("Vines", vines.commit(), _glow_material(), false)
	_add_light(foot)
	var trunk := CylinderShape3D.new()
	trunk.radius = trunk_radius * 0.95
	trunk.height = fork_height
	add_collider(trunk, Transform3D(Basis(), foot + Vector3.UP * fork_height * 0.5))
	claim(FOOT, 4.5)
	_place_grass()


## A tapering trunk of joined rings, leaning and twisting a little.
func _build_trunk(batch: NatureKit.Batch, foot: Vector3) -> void:
	var path: Array[Vector3] = []
	var radii: Array[float] = []
	for k in 9:
		var t := float(k) / 8.0
		path.append(foot + Vector3(0.3 * sin(t * 2.4), fork_height * 1.05 * t, 0.25 * sin(t * 1.7)))
		radii.append(lerpf(trunk_radius * 1.25, trunk_radius * 0.62, pow(t, 0.8)))
	_tube(batch, path, radii, 10, BARK)


## Buttress roots: thick wedges flaring from the trunk into the ground.
func _build_roots(batch: NatureKit.Batch, foot: Vector3) -> void:
	for k in 7:
		var yaw := TAU * k / 7.0 + rng.randf_range(-0.2, 0.2)
		var out := Vector3(cos(yaw), 0.0, sin(yaw))
		var reach := rng.randf_range(2.4, 3.2)
		var path: Array[Vector3] = [foot + Vector3.UP * 1.6 + out * trunk_radius * 0.6, foot + Vector3.UP * 0.5 + out * (trunk_radius + 0.8), foot + out * reach + Vector3.DOWN * 0.15]
		var radii: Array[float] = [0.45, 0.35, 0.12]
		_tube(batch, path, radii, 6, BARK * 0.92)


## Big limbs from the fork out and up to the crown; remembers their tips
## for the crown and the vines.
func _build_branches(batch: NatureKit.Batch, foot: Vector3) -> void:
	var fork := foot + Vector3(0.3 * sin(2.4), fork_height, 0.25 * sin(1.7))
	for k in 6:
		var yaw := TAU * k / 6.0 + rng.randf_range(-0.25, 0.25)
		var out := Vector3(cos(yaw), 0.0, sin(yaw))
		var spread := rng.randf_range(2.3, 2.7)
		var rise := rng.randf_range(3.5, 5.5)
		var middle := fork + out * spread * 0.45 + Vector3.UP * rise * 0.6
		var tip := fork + out * spread + Vector3.UP * rise
		var path: Array[Vector3] = [fork + Vector3.DOWN * 0.6, middle, tip]
		var radii: Array[float] = [trunk_radius * 0.5, trunk_radius * 0.3, 0.12]
		_tube(batch, path, radii, 7, BARK)
		_branch_tips.append(tip)
		_branch_tips.append(middle)


## A wide, layered crown of leafy lumps over the branches, topping out at
## `height`.
func _build_crown(batch: NatureKit.Batch, foot: Vector3) -> void:
	var top := foot.y + height
	for tip in _branch_tips:
		for k in 3:
			var radius := rng.randf_range(1.4, 1.8)
			var at := tip + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.2, 1.4), rng.randf_range(-0.5, 0.5))
			at.y = minf(at.y, top - radius * 0.6)
			batch.add(NatureKit.lumpy_sphere(rng, radius, 0.25, 8, 5), Transform3D(Basis().scaled(Vector3(1.0, 0.7, 1.0)), at), LEAVES[rng.randi() % LEAVES.size()] * rng.randf_range(0.92, 1.08))
	# The crown's top.
	for k in 5:
		var at := foot + Vector3(rng.randf_range(-1.5, 1.5), height - 2.0, rng.randf_range(-1.5, 1.5))
		batch.add(NatureKit.lumpy_sphere(rng, rng.randf_range(1.8, 2.3), 0.25, 8, 5), Transform3D(Basis().scaled(Vector3(1.0, 0.7, 1.0)), at), LEAVES[rng.randi() % LEAVES.size()])


## Glowing vines: strands hanging from the branches and the crown's
## underside, swaying a little in their length, and a few spiralling down
## the trunk, with glowing buds along them.
func _build_vines(batch: NatureKit.Batch, foot: Vector3) -> void:
	for tip in _branch_tips:
		for k in rng.randi_range(2, 4):
			var start := tip + Vector3(rng.randf_range(-0.8, 0.8), -0.6, rng.randf_range(-0.8, 0.8))
			var length := rng.randf_range(3.0, minf(7.5, start.y - foot.y - 0.8))
			var path: Array[Vector3] = []
			for j in 6:
				var t := float(j) / 5.0
				path.append(start + Vector3(0.25 * sin(t * 5.0 + k), -length * t, 0.25 * cos(t * 4.0 + k)))
			var radii: Array[float] = []
			for j in path.size():
				radii.append(0.035)
			_tube(batch, path, radii, 4, Color.WHITE)
			_buds(batch, path)
	for k in 3:
		var path: Array[Vector3] = []
		var phase := TAU * k / 3.0
		for j in 13:
			var t := float(j) / 12.0
			var radius := lerpf(trunk_radius * 1.28, trunk_radius * 0.66, t) + 0.04
			var angle := phase + t * TAU * 1.3
			path.append(foot + Vector3(0.3 * sin(t * 2.4) + cos(angle) * radius, 0.3 + (fork_height - 0.5) * t, 0.25 * sin(t * 1.7) + sin(angle) * radius))
		var radii: Array[float] = []
		for j in path.size():
			radii.append(0.05)
		_tube(batch, path, radii, 4, Color.WHITE)
		_buds(batch, path)


func _buds(batch: NatureKit.Batch, path: Array[Vector3]) -> void:
	var bud := MeshKit.triangles(MeshKit.sphere(0.09, 6, 4))
	for j in range(1, path.size(), 2):
		batch.add(bud, Transform3D(Basis(), path[j]), Color.WHITE)


func _glow_material() -> StandardMaterial3D:
	var glow := StandardMaterial3D.new()
	glow.albedo_color = vine_color
	glow.emission_enabled = true
	glow.emission = vine_color
	glow.emission_energy_multiplier = 2.5
	return glow


## A soft light from the vines, strongest at night.
func _add_light(foot: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "VineGlow"
	light.light_color = vine_color
	light.light_energy = 0.9
	light.omni_range = 11.0
	light.position = foot + Vector3.UP * 5.0
	add_content(light)


## A tube through `path` with a radius per point: rings joined into one
## surface, capped at neither end.
func _tube(batch: NatureKit.Batch, path: Array[Vector3], radii: Array[float], sides: int, color: Color) -> void:
	var triangles := PackedVector3Array()
	var previous: Array[Vector3] = []
	for k in path.size():
		var along := (path[mini(k + 1, path.size() - 1)] - path[maxi(k - 1, 0)]).normalized()
		var side := along.cross(Vector3.FORWARD if absf(along.z) < 0.9 else Vector3.RIGHT).normalized()
		var other := along.cross(side).normalized()
		var ring: Array[Vector3] = []
		for j in sides:
			var angle := TAU * j / sides
			ring.append(path[k] + (side * cos(angle) + other * sin(angle)) * radii[k])
		if k > 0:
			for j in sides:
				var n := (j + 1) % sides
				triangles.append_array(PackedVector3Array([previous[j], ring[j], ring[n], previous[j], ring[n], previous[n]]))
				triangles.append_array(PackedVector3Array([previous[j], ring[n], ring[j], previous[j], previous[n], ring[n]]))
		previous = ring
	batch.add(triangles, Transform3D(), color)


func _place_grass() -> void:
	var transforms: Array[Transform3D] = []
	var colors := PackedColorArray()
	for k in grass:
		var xz := random_point()
		if not is_clear(xz, 0.0, 0.6) or not fits(xz, 0.25) or xz.distance_to(FOOT) < 2.6:
			continue
		var size := rng.randf_range(0.8, 1.2)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(xz.x, height_at(xz) - 0.02, xz.y)))
		var shade := rng.randf_range(0.88, 1.08)
		colors.append(Color(shade, shade, shade))
	add_multimesh("Grass", NatureKit.grass_tuft(rng), NatureKit.grass_material(), transforms, colors, 45.0)
