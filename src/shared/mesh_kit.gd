@tool
class_name MeshKit
extends RefCounted
## Helpers for building meshes in code from Godot's primitive meshes.

const LOWPOLY_SHADER := preload("res://src/shared/shaders/lowpoly.gdshader")


## Merges primitive meshes, each placed by its transform, into one mesh.
static func merge(parts: Array[Mesh], transforms: Array[Transform3D]) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in parts.size():
		tool.append_from(parts[i], 0, transforms[i])
	return tool.commit()


## A flat-shaded material tinted by vertex or MultiMesh instance colours.
static func lowpoly_material(tint: Color = Color.WHITE, roughness: float = 0.9) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = LOWPOLY_SHADER
	material.set_shader_parameter("albedo", tint)
	material.set_shader_parameter("roughness", roughness)
	return material


static func sphere(radius: float, segments: int = 8, rings: int = 5) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh


static func cone(radius: float, height: float, segments: int = 8) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


static func cylinder(top_radius: float, bottom_radius: float, height: float, segments: int = 8) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## A MultiMeshInstance3D with per-instance colours, ready to be filled.
static func multimesh_instance(mesh: Mesh, material: Material, count: int) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	return instance


## A mesh's first surface as a flat triangle list (three vertices per
## triangle), ready for NatureKit.Batch.
static func triangles(mesh: Mesh) -> PackedVector3Array:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if arrays[Mesh.ARRAY_INDEX] == null:
		return vertices
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var result := PackedVector3Array()
	for index in indices:
		result.append(vertices[index])
	return result
