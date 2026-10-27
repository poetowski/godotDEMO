@tool
extends Node3D
## A small forest mushroom built in code: a stem and a cap, the cap domed,
## flat or funnel-shaped, optionally dotted with spots. Its base is at the
## origin. The three kinds set their look in their scenes. Generated
## children have no owner, so the editor never saves them.

enum Cap { DOME, FLAT, FUNNEL }

@export var cap: Cap = Cap.DOME
@export var cap_color: Color = Color(0.5, 0.3, 0.15)
@export var gill_color: Color = Color(0.85, 0.8, 0.65)
@export var stem_color: Color = Color(0.9, 0.86, 0.75)
@export var spot_color: Color = Color.WHITE
@export var spots: int = 0
@export var height: float = 0.12
@export var cap_radius: float = 0.06
@export var stem_radius: float = 0.018


func _ready() -> void:
	var batch := NatureKit.Batch.new()
	var stem_height := height * (0.85 if cap == Cap.FUNNEL else 0.7)
	batch.add(MeshKit.triangles(MeshKit.cylinder(stem_radius * (1.8 if cap == Cap.FUNNEL else 0.85), stem_radius, stem_height, 7)), Transform3D(Basis(), Vector3.UP * stem_height * 0.5), stem_color)
	var top := Vector3.UP * stem_height
	match cap:
		Cap.DOME, Cap.FLAT:
			var squash := 0.75 if cap == Cap.DOME else 0.35
			var dome := MeshKit.triangles(MeshKit.sphere(cap_radius, 9, 6))
			var kept := PackedVector3Array()
			for k in range(0, dome.size(), 3):
				if dome[k].y + dome[k + 1].y + dome[k + 2].y >= -0.001:
					kept.append_array([dome[k], dome[k + 1], dome[k + 2]])
			batch.add(kept, Transform3D(Basis().scaled(Vector3(1.0, squash, 1.0)), top), cap_color)
			batch.add(MeshKit.triangles(MeshKit.cylinder(cap_radius * 0.98, stem_radius, 0.012, 9)), Transform3D(Basis(), top + Vector3.UP * 0.002), gill_color)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			for s in spots:
				var angle := rng.randf() * TAU
				var tilt := rng.randf_range(0.15, 1.2)
				var out := Vector3(sin(tilt) * cos(angle), cos(tilt) * squash, sin(tilt) * sin(angle)) * cap_radius
				batch.add(MeshKit.triangles(MeshKit.sphere(cap_radius * 0.13, 5, 3)), Transform3D(Basis().scaled(Vector3(1.0, 0.45, 1.0)), top + out), spot_color)
		Cap.FUNNEL:
			batch.add(MeshKit.triangles(MeshKit.cylinder(cap_radius, stem_radius * 1.8, height * 0.3, 10)), Transform3D(Basis(), top + Vector3.UP * height * 0.15), cap_color)
			batch.add(MeshKit.triangles(MeshKit.cylinder(cap_radius * 0.92, cap_radius * 0.6, 0.008, 10)), Transform3D(Basis(), top + Vector3.UP * height * 0.3), cap_color * 0.82)
	var mushroom := MeshInstance3D.new()
	mushroom.name = "Mushroom"
	mushroom.mesh = batch.commit()
	mushroom.material_override = MeshKit.lowpoly_material(Color.WHITE, 0.8)
	add_child(mushroom)
