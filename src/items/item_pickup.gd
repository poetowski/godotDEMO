@tool
class_name ItemPickup
extends Interactable
## An item lying in the world: its model, a few slow sparkles so it can be
## spotted, and an area that offers it to the player. Interacting puts it in
## the player's inventory and removes it from the world. Generated children
## have no owner, so the editor never saves them.

signal picked_up(item: ItemData)

@export var item: ItemData
## Metres from which the player is offered the item.
@export var reach: float = 1.4
## Names this pickup in WorldState, so it stays gone once taken; empty for
## none.
@export var persist_id: String = ""


func _ready() -> void:
	if not Engine.is_editor_hint() and not persist_id.is_empty() and WorldState.is_taken(persist_id):
		queue_free()
		return
	if item == null or item.model == null:
		return
	var model := item.model.instantiate() as Node3D
	model.name = "Model"
	add_child(model)
	add_child(_sparkles())
	var area := Area3D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	shape.shape = sphere
	shape.position = Vector3.UP * 0.4
	area.add_child(shape)
	add_child(area)
	if not Engine.is_editor_hint():
		watch(area)


func can_interact(player: Player) -> bool:
	return item != null and player.inventory.can_add(item)


func prompt() -> String:
	return "[E]  Pick up %s" % item.display_name


func interact(player: Player) -> void:
	if player.inventory.add(item):
		if not persist_id.is_empty():
			WorldState.mark_taken(persist_id)
		picked_up.emit(item)
		queue_free()


func _sparkles() -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.25
	process.direction = Vector3.UP
	process.spread = 30.0
	process.initial_velocity_min = 0.04
	process.initial_velocity_max = 0.12
	process.gravity = Vector3.ZERO
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(1.0, 0.95, 0.7, 0.8)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	quad.material = material
	var sparkles := GPUParticles3D.new()
	sparkles.name = "Sparkles"
	sparkles.amount = 10
	sparkles.lifetime = 2.5
	sparkles.process_material = process
	sparkles.draw_pass_1 = quad
	sparkles.position = Vector3.UP * 0.5
	return sparkles
