class_name FarModel
extends RefCounted
## A design's far model: its content's meshes merged and simplified into one
## light mesh, shown from afar while the content itself isn't loaded, so
## landmarks stay on the horizon. Built by the bake; ground and water are
## left out (the coarse ground stand-ins cover them), and so are MultiMesh
## copies such as grass and ivy, which vanish at that distance anyway.

## Share of the merged triangles a far model aims to keep.
const KEEP := 0.25
## Merged meshes smaller than this many triangles are kept as they are.
const SMALL := 300


## The far model for generated or baked content, or null when it has nothing
## to show.
static func build(content: Node3D) -> ArrayMesh:
	var merged := SurfaceTool.new()
	merged.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	var stack: Array[Node] = [content]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var instance := node as MeshInstance3D
		if instance == null or instance.mesh == null or _left_out(instance):
			continue
		var where := _relative_transform(instance, content)
		for surface in instance.mesh.get_surface_count():
			merged.append_from(instance.mesh, surface, where)
			any = true
	if not any:
		return null
	merged.index()
	var arrays := merged.commit_to_arrays()
	return _simplify(arrays)


static func triangle_count(mesh: Mesh) -> int:
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		count += indices.size() / 3 if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return count


static func _left_out(instance: MeshInstance3D) -> bool:
	var node_name := String(instance.name)
	return node_name.begins_with("Ground") or node_name == "Water"


## A node's transform relative to the content root, without needing the tree.
static func _relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var result := Transform3D()
	var at: Node = node
	while at and at != root:
		var spatial := at as Node3D
		if spatial:
			result = spatial.transform * result
		at = at.get_parent()
	return result


## Keeps the coarsest automatic level of detail that still has about KEEP of
## the triangles.
static func _simplify(arrays: Array) -> ArrayMesh:
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var total := indices.size() / 3
	if total > SMALL:
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		importer.generate_lods(25.0, 60.0, [])
		var best := indices
		for lod in importer.get_surface_lod_count(0):
			var lod_indices := importer.get_surface_lod_indices(0, lod)
			if lod_indices.size() / 3 >= total * KEEP * 0.5:
				best = lod_indices
		arrays[Mesh.ARRAY_INDEX] = best
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
