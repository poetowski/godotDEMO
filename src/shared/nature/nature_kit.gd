@tool
class_name NatureKit
extends RefCounted
## Low-poly nature built in code: rocks, bushes, grass tufts and lily pads,
## and the materials that suit them. Pieces are coloured triangle lists (three
## vertices per triangle) that a Batch merges into one mesh; colours are
## picked in sRGB, like every other colour in the project.

const GRASS_SHADER := preload("res://src/shared/nature/grass_blades.gdshader")
const WATER_SHADER := preload("res://src/shared/nature/water.gdshader")
const FLOATING_SHADER := preload("res://src/shared/nature/floating.gdshader")
## The flow, in metres per second, that a water vertex colour of 0 or 1 stands
## for (see water.gdshader).
const WATER_MAX_FLOW := 1.0

const ROCK_GREYS: Array[Color] = [Color(0.47, 0.46, 0.44), Color(0.54, 0.52, 0.5), Color(0.41, 0.42, 0.41), Color(0.45, 0.48, 0.41)]
const LEAF_GREENS: Array[Color] = [Color(0.2, 0.37, 0.16), Color(0.26, 0.44, 0.19), Color(0.31, 0.5, 0.21), Color(0.36, 0.53, 0.2)]


## Collects coloured triangles from many pieces and merges them into one mesh.
class Batch:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()

	## Adds triangles placed by `where`, all in one colour.
	func add(triangles: PackedVector3Array, where: Transform3D, color: Color) -> void:
		for vertex in triangles:
			vertices.append(where * vertex)
			colors.append(color)

	## Adds triangles placed by `where`, coloured per vertex.
	func add_painted(triangles: PackedVector3Array, paint: PackedColorArray, where: Transform3D) -> void:
		for i in triangles.size():
			vertices.append(where * triangles[i])
			colors.append(paint[i])

	func is_empty() -> bool:
		return vertices.is_empty()

	## One mesh with a flat normal per triangle.
	func commit() -> ArrayMesh:
		var normals := PackedVector3Array()
		normals.resize(vertices.size())
		for t in range(0, vertices.size(), 3):
			var normal := (vertices[t + 2] - vertices[t]).cross(vertices[t + 1] - vertices[t]).normalized()
			normals[t] = normal
			normals[t + 1] = normal
			normals[t + 2] = normal
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


## A low-poly ball whose surface bulges and dents by up to `lumpiness` of its
## radius. Shared corners move together, so it has no cracks.
static func lumpy_sphere(rng: RandomNumberGenerator, radius: float, lumpiness: float, segments: int = 7, rings: int = 4) -> PackedVector3Array:
	var arrays := MeshKit.sphere(radius, segments, rings).get_mesh_arrays()
	var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.3 / radius
	var triangles := PackedVector3Array()
	for index in indices:
		var vertex := source[index]
		triangles.append(vertex * (1.0 + lumpiness * noise.get_noise_3dv(vertex)))
	return triangles


## A rock about one metre across with a flat base at y = 0. Make a few shapes
## and reuse them at different sizes and turns.
static func rock_shape(rng: RandomNumberGenerator) -> PackedVector3Array:
	var squash := rng.randf_range(0.5, 0.8)
	var stretch := rng.randf_range(0.8, 1.25)
	var base := 0.12
	var triangles := lumpy_sphere(rng, 0.5, 0.35)
	for i in triangles.size():
		var vertex := triangles[i]
		triangles[i] = Vector3(vertex.x * stretch, maxf(vertex.y * squash, -base) + base, vertex.z / stretch)
	return triangles


## A rock colour: weathered greys, a few touched with moss.
static func rock_color(rng: RandomNumberGenerator) -> Color:
	return ROCK_GREYS[rng.randi() % ROCK_GREYS.size()] * rng.randf_range(0.88, 1.1)


## Adds a small bush, about one metre tall at scale 1, standing at `where`: a
## cluster of leafy lumps in a few greens.
static func add_bush(batch: Batch, rng: RandomNumberGenerator, where: Transform3D) -> void:
	var lumps := rng.randi_range(3, 6)
	var turn := rng.randf() * TAU
	for i in lumps:
		var radius := rng.randf_range(0.3, 0.42) if i == 0 else rng.randf_range(0.2, 0.32)
		var angle := turn + TAU * i / lumps
		var spread := 0.0 if i == 0 else rng.randf_range(0.18, 0.34)
		var centre := Vector3(cos(angle) * spread, radius * 0.8 + (0.18 if i == 0 else rng.randf_range(0.0, 0.12)), sin(angle) * spread)
		var color := LEAF_GREENS[rng.randi() % LEAF_GREENS.size()] * rng.randf_range(0.92, 1.08)
		batch.add(lumpy_sphere(rng, radius, 0.3, 6, 4), where * Transform3D(Basis(), centre), color)


## Adds a round-crowned tree `height` metres to the top of its trunk, standing
## at `foot`: a tapering trunk under a few leafy lumps.
static func add_round_tree(batch: Batch, rng: RandomNumberGenerator, foot: Vector3, height: float) -> void:
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.1, 0.18, height, 6)), Transform3D(Basis(), foot + Vector3.UP * height * 0.5), Color(0.38, 0.27, 0.18))
	for lump in rng.randi_range(3, 4):
		var radius := rng.randf_range(0.7, 1.1) * height / 3.5
		var offset := Vector3(rng.randf_range(-0.45, 0.45), height + rng.randf_range(-0.3, 0.5), rng.randf_range(-0.45, 0.45)) * Vector3(height / 3.5, 1.0, height / 3.5)
		batch.add(lumpy_sphere(rng, radius, 0.25, 7, 4), Transform3D(Basis(), foot + offset), LEAF_GREENS[rng.randi() % LEAF_GREENS.size()])


## Adds a pine `height` metres tall standing at `foot`: a trunk under tiers of
## dark cones.
static func add_pine(batch: Batch, rng: RandomNumberGenerator, foot: Vector3, height: float) -> void:
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.08, 0.2, height * 0.85, 6)), Transform3D(Basis(), foot + Vector3.UP * height * 0.425), Color(0.36, 0.25, 0.17))
	var tiers := 4
	for t in tiers:
		var f := float(t) / (tiers - 1)
		var radius := lerpf(0.32, 0.09, f) * height
		var cone := MeshKit.triangles(MeshKit.cone(radius, lerpf(0.28, 0.18, f) * height, 7))
		var green := Color(0.15, 0.3, 0.17).lerp(Color(0.2, 0.38, 0.2), f) * rng.randf_range(0.95, 1.05)
		batch.add(cone, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), foot + Vector3.UP * lerpf(0.3, 0.88, f) * height), green)


## A tuft of grass blades about 0.3 m tall, for MultiMesh use with
## `grass_material()`. UV.y runs from 0 at the roots to 1 at the tips.
static func grass_tuft(rng: RandomNumberGenerator, blades: int = 7) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for b in blades:
		var angle := rng.randf() * TAU
		var root := Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.0, 0.06)
		var lean_angle := angle + rng.randf_range(-0.7, 0.7)
		var lean := Vector3(cos(lean_angle), 0.0, sin(lean_angle))
		var tip := root + lean * rng.randf_range(0.03, 0.11) + Vector3.UP * rng.randf_range(0.2, 0.38)
		var side := lean.cross(Vector3.UP) * rng.randf_range(0.016, 0.026)
		vertices.append_array(PackedVector3Array([root - side, tip, root + side]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 1.0), Vector2(1.0, 0.0)]))
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## A lily pad of radius 1 lying at y = 0, notched like a real one, for
## MultiMesh use with `floating_material()`. With `with_flower`, a water lily
## blooms on it.
static func lily_pad(rng: RandomNumberGenerator, with_flower: bool) -> ArrayMesh:
	var batch := Batch.new()
	var segments := 14
	var notch := rng.randf_range(0.3, 0.5)
	var centre := Vector3(0.0, 0.04, 0.0)
	var heart := Color(0.4, 0.6, 0.27)
	var rim := Color(0.25, 0.44, 0.18)
	for s in segments:
		var a0 := lerpf(notch * 0.5, TAU - notch * 0.5, float(s) / segments)
		var a1 := lerpf(notch * 0.5, TAU - notch * 0.5, float(s + 1) / segments)
		var p0 := Vector3(cos(a0), 0.0, sin(a0)) * rng.randf_range(0.96, 1.02)
		var p1 := Vector3(cos(a1), 0.0, sin(a1))
		batch.add_painted(PackedVector3Array([centre, p0, p1]), PackedColorArray([heart, rim, rim]), Transform3D())
	if with_flower:
		_add_lily_flower(batch, rng, Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(-0.15, 0.03, 0.0)))
	return batch.commit()


## Petals around a golden heart, white turning pink at the tips. Each petal is
## two-faced so it shows from any side.
static func _add_lily_flower(batch: Batch, rng: RandomNumberGenerator, where: Transform3D) -> void:
	var white := Color(0.97, 0.95, 0.92)
	var pink := Color(0.95, 0.62, 0.76) if rng.randf() < 0.6 else Color(0.98, 0.9, 0.92)
	for ring in 2:
		var count := 8 if ring == 0 else 6
		var reach := 0.9 if ring == 0 else 0.6
		var rise := 0.35 if ring == 0 else 0.55
		for p in count:
			var angle := TAU * (p + 0.5 * ring) / count
			var out := Vector3(cos(angle), 0.0, sin(angle))
			var side := out.cross(Vector3.UP) * (0.22 if ring == 0 else 0.18)
			var base := Vector3.UP * 0.05
			var tip := out * reach + Vector3.UP * rise
			var middle := out * reach * 0.5 + Vector3.UP * rise * 0.4
			var triangles := PackedVector3Array([base, middle + side, tip, base, tip, middle - side])
			var paint := PackedColorArray([white, white, pink, white, pink, white])
			batch.add_painted(triangles, paint, where)
			triangles.reverse()
			paint.reverse()
			batch.add_painted(triangles, paint, where)
	var gold := Color(0.98, 0.78, 0.25)
	for p in 5:
		var a0 := TAU * p / 5.0
		var a1 := TAU * (p + 1) / 5.0
		var top := Vector3.UP * 0.32
		batch.add(PackedVector3Array([top, Vector3(cos(a0), 0.4, sin(a0)) * 0.22, Vector3(cos(a1), 0.4, sin(a1)) * 0.22]), where, gold)


## Grass blades that fade from the field's grass at the root to a sunlit tip
## and sway gently in the wind.
static func grass_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	return material


## Flowing water for surfaces whose vertices carry their flow (see
## water.gdshader).
static func water_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("max_flow_speed", WATER_MAX_FLOW)
	return material


## The low-poly look for things floating on water: each MultiMesh instance
## bobs and turns a little.
static func floating_material(roughness: float = 0.6) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FLOATING_SHADER
	material.set_shader_parameter("roughness", roughness)
	return material
