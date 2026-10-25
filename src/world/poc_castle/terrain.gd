@tool
extends StaticBody3D
## Builds the PoC terrain from PocLayout's height field: a smooth mesh coloured
## per vertex (grass, dry patches, rock on slopes, dirt along the path, gravel
## in the courtyard) and a matching height-map collision shape.
##
## Generated children have no owner, so the editor never saves them.

const GRASS := Color(0.36, 0.55, 0.22)
const GRASS_DARK := Color(0.24, 0.42, 0.17)
const GRASS_DRY := Color(0.55, 0.57, 0.3)
const ROCK := Color(0.47, 0.45, 0.42)
const DIRT := Color(0.5, 0.4, 0.28)
const GRAVEL := Color(0.58, 0.54, 0.46)
const COURTYARD_HALF := 15.0


func _ready() -> void:
	var heights := PocLayout.heights()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = _build_mesh(heights)
	add_child(mesh_instance)

	var shape := HeightMapShape3D.new()
	shape.map_width = PocLayout.GRID
	shape.map_depth = PocLayout.GRID
	shape.map_data = heights
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	add_child(collision)


func _build_mesh(heights: PackedFloat32Array) -> ArrayMesh:
	var grid := PocLayout.GRID
	var patches := FastNoiseLite.new()
	patches.seed = PocLayout.SEED + 10
	patches.frequency = 0.04
	var dryness := FastNoiseLite.new()
	dryness.seed = PocLayout.SEED + 11
	dryness.frequency = 0.015

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(grid * grid)
	normals.resize(grid * grid)
	colors.resize(grid * grid)
	for iz in grid:
		var z := PocLayout.grid_coordinate(iz)
		for ix in grid:
			var x := PocLayout.grid_coordinate(ix)
			var i := iz * grid + ix
			var left := heights[i - 1] if ix > 0 else heights[i]
			var right := heights[i + 1] if ix < grid - 1 else heights[i]
			var back := heights[i - grid] if iz > 0 else heights[i]
			var front := heights[i + grid] if iz < grid - 1 else heights[i]
			var normal := Vector3(left - right, 2.0, back - front).normalized()
			vertices[i] = Vector3(x, heights[i], z)
			normals[i] = normal
			colors[i] = _ground_color(x, z, normal, patches, dryness)

	var indices := PackedInt32Array()
	indices.resize((grid - 1) * (grid - 1) * 6)
	var k := 0
	for iz in grid - 1:
		for ix in grid - 1:
			var i := iz * grid + ix
			indices[k] = i
			indices[k + 1] = i + 1
			indices[k + 2] = i + grid
			indices[k + 3] = i + 1
			indices[k + 4] = i + grid + 1
			indices[k + 5] = i + grid
			k += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh


func _ground_color(x: float, z: float, normal: Vector3, patches: FastNoiseLite, dryness: FastNoiseLite) -> Color:
	var color := GRASS.lerp(GRASS_DARK, smoothstep(-0.2, 0.5, patches.get_noise_2d(x, z)))
	color = color.lerp(GRASS_DRY, smoothstep(0.2, 0.7, dryness.get_noise_2d(x, z)) * 0.7)
	color = color.lerp(ROCK, smoothstep(0.22, 0.4, 1.0 - normal.y))
	var to_castle := Vector2(x, z) - PocLayout.CASTLE_CENTER
	if absf(to_castle.x) < COURTYARD_HALF and absf(to_castle.y) < COURTYARD_HALF:
		color = color.lerp(GRAVEL, 0.85)
	var verge := 1.0 - smoothstep(PocLayout.PATH_HALF_WIDTH + 0.2, PocLayout.PATH_HALF_WIDTH + 1.4, PocLayout.path_distance_at(x, z))
	return color.lerp(DIRT, verge)
