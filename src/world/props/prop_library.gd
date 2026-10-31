@tool
class_name PropLibrary
extends RefCounted
## Every kind of prop (Prop): how one is built (low-poly, from NatureKit, the
## same every time for the same variant), which merged mesh it joins in a
## sector, how much room it takes, and whether and how it's solid. Props are
## built at the origin, standing on it, one metre across at scale 1 for
## bushes and rocks; trees are their real height. An ASSET prop is a whole
## model from assets/models/props/ (made by /asset-design): placed as it is,
## with its own collision, never merged.

enum Kind { BUSH, ROCK, ROUND_TREE, PINE, ASSET }

const MASS_SHADER := preload("res://src/world/props/mass_prop.gdshader")
## The merged mesh each kind joins in a sector, named <group><sector>
## (assets join none).
const GROUPS: Array[String] = ["Bushes", "Rocks", "Trees", "Trees", ""]
## Metres of room each kind takes around its foot, at scale 1 (an asset's
## comes from its size).
const ROOM: Array[float] = [0.75, 0.62, 1.4, 1.2, 0.0]
## Whether a new prop of each kind is solid unless set otherwise.
const SOLID: Array[bool] = [false, true, true, true, true]

static var _parts: Dictionary[Vector2i, Array] = {}
static var _meshes: Dictionary[Vector2i, ArrayMesh] = {}
static var _materials: Dictionary[String, Material] = {}
static var _asset_rooms: Dictionary[String, float] = {}
static var _mass_meshes: Dictionary[String, ArrayMesh] = {}
static var _mutex := Mutex.new()


## The scene of an asset (assets/models/props/), by its slug.
static func asset_scene(slug: String) -> PackedScene:
	return load("res://assets/models/props/%s/%s.glb" % [slug, slug]) as PackedScene


## An asset's mesh for scattering in masses (a MultiMesh), with its materials'
## colours in a shader that tints each copy, sways it by `sway` and bobs it by
## `bob` metres.
static func mass_mesh(slug: String, sway: float = 0.0, bob: float = 0.0) -> ArrayMesh:
	var key := "%s/%f/%f" % [slug, sway, bob]
	if _mass_meshes.has(key):
		return _mass_meshes[key]
	var model := asset_scene(slug).instantiate() as Node3D
	var source: Mesh = null
	for child in model.find_children("*", "MeshInstance3D", true, false):
		source = (child as MeshInstance3D).mesh
		break
	model.free()
	var built := source.duplicate() as ArrayMesh
	for surface in built.get_surface_count():
		var from := source.surface_get_material(surface) as BaseMaterial3D
		var material := ShaderMaterial.new()
		material.shader = MASS_SHADER
		material.set_shader_parameter("albedo", from.albedo_color if from else Color.WHITE)
		material.set_shader_parameter("roughness", from.roughness if from else 0.9)
		material.set_shader_parameter("sway", sway)
		material.set_shader_parameter("bob", bob)
		built.surface_set_material(surface, material)
	_mass_meshes[key] = built
	return built


## Adds a prop to `batch`, placed by `where`.
static func add_to(batch: NatureKit.Batch, kind: Kind, variant: int, where: Transform3D) -> void:
	var parts := _parts_of(kind, variant)
	batch.add_painted(parts[0], parts[1], where)


## One prop as a mesh (for previews in the editor).
static func mesh(kind: Kind, variant: int) -> ArrayMesh:
	var key := Vector2i(kind, variant)
	_mutex.lock()
	var found: ArrayMesh = _meshes.get(key)
	_mutex.unlock()
	if found:
		return found
	var batch := NatureKit.Batch.new()
	add_to(batch, kind, variant, Transform3D())
	found = batch.commit()
	_mutex.lock()
	_meshes[key] = found
	_mutex.unlock()
	return found


static func group(kind: Kind) -> String:
	return GROUPS[kind]


## The material of a group's merged mesh.
static func material(group_name: String) -> Material:
	if not _materials.has(group_name):
		_materials[group_name] = MeshKit.lowpoly_material(Color.WHITE, 0.9 if group_name == "Bushes" else 0.95)
	return _materials[group_name]


## Metres of room a prop placed by `where` takes around its foot; for an
## asset, half its width.
static func room(kind: Kind, where: Transform3D, asset: PackedScene = null) -> float:
	if kind == Kind.ASSET:
		return asset_room(asset) * where.basis.get_scale().x
	return ROOM[kind] * where.basis.get_scale().x


## Half an asset's widest side, measured once.
static func asset_room(asset: PackedScene) -> float:
	if asset == null:
		return 0.0
	if not _asset_rooms.has(asset.resource_path):
		var model := asset.instantiate() as Node3D
		var box := AABB()
		for child in model.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			box = box.merge(_transform_to(model, mesh_instance) * mesh_instance.get_aabb())
		model.free()
		_asset_rooms[asset.resource_path] = maxf(box.size.x, box.size.z) * 0.5
	return _asset_rooms[asset.resource_path]


static func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var where := Transform3D()
	var at: Node = node
	while at != root and at is Node3D:
		where = (at as Node3D).transform * where
		at = at.get_parent()
	return where


## The collision shape of a solid prop placed by `where`, and where it goes;
## an empty array for kinds that are never solid.
static func collider(kind: Kind, where: Transform3D) -> Array:
	var size := where.basis.get_scale().x
	match kind:
		Kind.ROCK:
			var sphere := SphereShape3D.new()
			sphere.radius = size * 0.38
			return [sphere, Transform3D(Basis(), where.origin + Vector3.UP * size * 0.12)]
		Kind.ROUND_TREE, Kind.PINE:
			var trunk := CylinderShape3D.new()
			trunk.radius = 0.2 * size
			trunk.height = 4.0 * size
			return [trunk, Transform3D(Basis(), where.origin + Vector3.UP * trunk.height * 0.5)]
	return []


## A prop's triangles and their colours, built once per kind and variant.
static func _parts_of(kind: Kind, variant: int) -> Array:
	var key := Vector2i(kind, variant)
	_mutex.lock()
	var found: Array = _parts.get(key, [])
	_mutex.unlock()
	if not found.is_empty():
		return found
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var batch := NatureKit.Batch.new()
	match kind:
		Kind.BUSH:
			NatureKit.add_bush(batch, rng, Transform3D())
		Kind.ROCK:
			batch.add(NatureKit.rock_shape(rng), Transform3D(), NatureKit.rock_color(rng))
		Kind.ROUND_TREE:
			NatureKit.add_round_tree(batch, rng, Vector3.ZERO, 4.5)
		Kind.PINE:
			NatureKit.add_pine(batch, rng, Vector3.ZERO, 7.0)
	found = [batch.vertices, batch.colors]
	_mutex.lock()
	_parts[key] = found
	_mutex.unlock()
	return found
