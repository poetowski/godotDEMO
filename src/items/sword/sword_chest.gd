@tool
class_name SwordChest
extends SwordHolder
## An iron-banded wooden chest with a blade lying on its lid for the player
## to take. Built in code: the chest is about 0.9 m long along its local x,
## standing on y = 0, its lock facing +z. Generated children have no owner,
## so the editor never saves them.

const SIZE := Vector3(0.9, 0.5, 0.56)
const WOOD: Array[Color] = [Color(0.45, 0.28, 0.16), Color(0.4, 0.25, 0.14), Color(0.5, 0.32, 0.18)]
const IRON := Color(0.25, 0.25, 0.27)
const GOLD := Color(0.88, 0.68, 0.28)

## Names the blade in WorldState, so it stays taken when the chest is
## loaded again; empty for none.
@export var persist_id: String = ""

## The blade on the lid; a FlameKatana unless set before the chest enters
## the tree.
var blade: Node3D


func _ready() -> void:
	_build_chest()
	var body := StaticBody3D.new()
	body.name = "Body"
	var box := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIZE.x, SIZE.y + SIZE.z * 0.5, SIZE.z)
	box.shape = shape
	box.position = Vector3(0.0, shape.size.y * 0.5, 0.0)
	body.add_child(box)
	add_child(body)
	var taken := not Engine.is_editor_hint() and not persist_id.is_empty() and WorldState.is_taken(persist_id)
	if blade == null and not taken:
		blade = FlameKatana.new()
	if blade:
		blade.name = "Blade"
		# Lying along the lid, edge toward the lock.
		blade.transform = Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-0.39, SIZE.y + SIZE.z * 0.5 + 0.02, 0.0))
		add_child(blade)
	var area := Area3D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	reach.shape = sphere
	reach.position = Vector3(0.0, 0.5, 0.0)
	area.add_child(reach)
	add_child(area)
	if not Engine.is_editor_hint():
		watch(area)


func has_sword() -> bool:
	return blade != null and blade.get_parent() == self


func take_sword() -> Node3D:
	if not has_sword():
		return null
	var taken := blade
	remove_child(taken)
	blade = null
	if not persist_id.is_empty():
		WorldState.mark_taken(persist_id)
	return taken


## Planked box, a rounded lid, iron bands and a gold lock.
func _build_chest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var batch := NatureKit.Batch.new()
	var planks := 4
	for p in planks:
		var plank := MeshKit.triangles(MeshKit.box(Vector3(SIZE.x, SIZE.y / planks - 0.01, SIZE.z)))
		batch.add(plank, Transform3D(Basis(), Vector3(0.0, (p + 0.5) * SIZE.y / planks, 0.0)), WOOD[rng.randi() % WOOD.size()])
	var lid := MeshKit.triangles(MeshKit.cylinder(SIZE.z * 0.5, SIZE.z * 0.5, SIZE.x, 10))
	var lid_basis := Basis(Vector3.BACK, PI * 0.5)
	batch.add(lid, Transform3D(lid_basis, Vector3(0.0, SIZE.y, 0.0)), WOOD[0] * 1.05)
	for x: float in [-0.36, 0.0, 0.36]:
		batch.add(MeshKit.triangles(MeshKit.box(Vector3(0.05, SIZE.y + 0.01, SIZE.z + 0.02))), Transform3D(Basis(), Vector3(x, SIZE.y * 0.5, 0.0)), IRON)
		batch.add(MeshKit.triangles(MeshKit.cylinder(SIZE.z * 0.5 + 0.012, SIZE.z * 0.5 + 0.012, 0.05, 10)), Transform3D(lid_basis, Vector3(x, SIZE.y, 0.0)), IRON)
	batch.add(MeshKit.triangles(MeshKit.box(Vector3(0.1, 0.12, 0.03))), Transform3D(Basis(), Vector3(0.0, SIZE.y - 0.04, SIZE.z * 0.5 + 0.02)), GOLD)
	var chest := MeshInstance3D.new()
	chest.name = "Chest"
	chest.mesh = batch.commit()
	chest.material_override = MeshKit.lowpoly_material(Color.WHITE, 0.75)
	add_child(chest)
