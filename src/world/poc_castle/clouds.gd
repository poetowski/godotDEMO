@tool
extends Node3D
## Soft low-poly clouds drifting slowly east across the PoC sky, wrapping
## around at the edge of the world. Generated children have no owner, so the
## editor never saves them.

@export var count: int = 16
@export var drift_speed: float = 1.2
@export var span: float = 320.0

var _clouds: Array[Node3D] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PocLayout.SEED + 40
	var material := MeshKit.lowpoly_material(Color(0.97, 0.97, 1.0), 1.0)
	for i in count:
		var parts: Array[Mesh] = []
		var places: Array[Transform3D] = []
		for p in rng.randi_range(4, 7):
			parts.append(MeshKit.sphere(rng.randf_range(2.5, 5.0), 8, 5))
			places.append(Transform3D(Basis(), Vector3(rng.randf_range(-7.0, 7.0), rng.randf_range(-0.8, 1.2), rng.randf_range(-3.5, 3.5))))
		var cloud := MeshInstance3D.new()
		cloud.mesh = MeshKit.merge(parts, places)
		cloud.material_override = material
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloud.scale = Vector3(1.0, 0.55, 1.0)
		cloud.position = Vector3(rng.randf_range(-span, span) * 0.5, rng.randf_range(55.0, 80.0), rng.randf_range(-130.0, 130.0))
		add_child(cloud)
		_clouds.append(cloud)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for cloud in _clouds:
		cloud.position.x += drift_speed * delta
		if cloud.position.x > span * 0.5:
			cloud.position.x -= span
