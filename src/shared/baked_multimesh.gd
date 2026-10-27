@tool
class_name BakedMultiMesh
extends MultiMeshInstance3D
## A MultiMeshInstance3D that keeps its copies in its own exported buffer and
## hands it to its MultiMesh in one call when it enters the tree. Saved
## scenes carry the copies even when baked headless, where the MultiMesh
## itself keeps no data, and the copies can always be read back.

## Floats per copy in the buffer: a 3 x 4 transform, row by row, then an RGBA
## colour; MultiMesh's own layout with TRANSFORM_3D and colours.
const STRIDE := 16

@export var buffer: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	fill()


## Stores copies, one transform and colour each.
func set_copies(transforms: Array[Transform3D], colors: PackedColorArray) -> void:
	buffer.resize(transforms.size() * STRIDE)
	for i in transforms.size():
		var t := transforms[i]
		var c := colors[i] if i < colors.size() else Color.WHITE
		var at := i * STRIDE
		var values := [t.basis.x.x, t.basis.y.x, t.basis.z.x, t.origin.x, t.basis.x.y, t.basis.y.y, t.basis.z.y, t.origin.y, t.basis.x.z, t.basis.y.z, t.basis.z.z, t.origin.z, c.r, c.g, c.b, c.a]
		for k in STRIDE:
			buffer[at + k] = values[k]


func copy_count() -> int:
	return buffer.size() / STRIDE


## The copies' transforms, read back from the buffer.
func transforms() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i in copy_count():
		var at := i * STRIDE
		var basis := Basis(Vector3(buffer[at], buffer[at + 4], buffer[at + 8]), Vector3(buffer[at + 1], buffer[at + 5], buffer[at + 9]), Vector3(buffer[at + 2], buffer[at + 6], buffer[at + 10]))
		result.append(Transform3D(basis, Vector3(buffer[at + 3], buffer[at + 7], buffer[at + 11])))
	return result


## Hands the stored copies to the MultiMesh. Another copy of the same baked
## scene may share it and have filled it already; the format can only change
## while it's empty.
func fill() -> void:
	if multimesh == null:
		return
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = copy_count()
	if copy_count() > 0:
		multimesh.buffer = buffer
