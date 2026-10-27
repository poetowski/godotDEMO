@tool
extends Node3D
## A cornflower about 0.7 m tall, built in code: a slender stem with narrow
## leaves, green bracts and a head of frilled blue florets around a violet
## heart. Its base is at the origin. Generated children have no owner, so the
## editor never saves them.

const STEM := Color(0.3, 0.48, 0.24)
const BLUE := Color(0.22, 0.4, 0.95)
const PALE_BLUE := Color(0.45, 0.62, 1.0)
const HEART := Color(0.32, 0.16, 0.5)

@export var height: float = 0.7


func _ready() -> void:
	var batch := NatureKit.Batch.new()
	var top := Vector3(0.03, height, 0.0)
	_twig(batch, Vector3.ZERO, Vector3(0.015, height * 0.5, 0.0), 0.008)
	_twig(batch, Vector3(0.015, height * 0.5, 0.0), top - Vector3.UP * 0.03, 0.007)
	for side: float in [-1.0, 1.0]:
		_leaf(batch, Vector3(0.012, height * (0.28 if side < 0.0 else 0.4), 0.0), side)
	batch.add(MeshKit.triangles(MeshKit.cone(0.04, 0.06, 8)), Transform3D(Basis(Vector3.RIGHT, PI), top), STEM * 0.9)
	var florets := 12
	for f in florets:
		_floret(batch, top + Vector3.UP * 0.005, TAU * f / florets)
	batch.add(MeshKit.triangles(MeshKit.sphere(0.028, 8, 5)), Transform3D(Basis(), top + Vector3.UP * 0.02), HEART)
	var flower := MeshInstance3D.new()
	flower.name = "Flower"
	flower.mesh = batch.commit()
	flower.material_override = MeshKit.lowpoly_material(Color.WHITE, 0.7)
	add_child(flower)


func _twig(batch: NatureKit.Batch, a: Vector3, b: Vector3, radius: float) -> void:
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD).normalized()
	batch.add(MeshKit.triangles(MeshKit.cylinder(radius * 0.8, radius, a.distance_to(b), 5)), Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5), STEM)


## A narrow leaf springing from the stem, two-faced.
func _leaf(batch: NatureKit.Batch, at: Vector3, side: float) -> void:
	var out := Vector3(side * 0.13, 0.12, side * 0.03)
	var across := Vector3(0.0, 0.0, 0.012)
	var leaf := PackedVector3Array([at, at + out * 0.5 + across, at + out, at, at + out, at + out * 0.5 - across])
	batch.add(leaf, Transform3D(), STEM * 1.1)
	leaf.reverse()
	batch.add(leaf, Transform3D(), STEM * 0.9)


## One trumpet-shaped floret: a fan of three ragged points flaring out and up,
## two-faced.
func _floret(batch: NatureKit.Batch, centre: Vector3, angle: float) -> void:
	var out := Vector3(cos(angle), 0.0, sin(angle))
	var across := out.cross(Vector3.UP)
	var base := centre + out * 0.012
	var reach := 0.1
	var lift := Vector3.UP * 0.025
	var tips: Array[Vector3] = [
		base + out * reach * 0.9 + across * 0.034 + lift,
		base + out * reach + lift * 1.2,
		base + out * reach * 0.9 - across * 0.034 + lift,
	]
	for k in 2:
		var triangle := PackedVector3Array([base, tips[k], tips[k + 1]])
		var paint := PackedColorArray([BLUE * 0.8, PALE_BLUE, PALE_BLUE])
		batch.add_painted(triangle, paint, Transform3D())
		triangle.reverse()
		paint.reverse()
		batch.add_painted(triangle, paint, Transform3D())
