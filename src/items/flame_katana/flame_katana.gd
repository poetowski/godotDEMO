@tool
class_name FlameKatana
extends Node3D
## A katana whose blade burns: a gently curved blade with a flickering fire
## shader, flames streaming off it and a warm light that flickers with them.
## Built in code; the grip is at the origin and the blade runs along +Y, like
## the plain sword, so the player holds it the same way. Generated children
## have no owner, so the editor never saves them.

const BLADE_SHADER := preload("res://src/items/flame_katana/flame_blade.gdshader")

@export var blade_length: float = 0.95
@export var blade_width: float = 0.042
## How far the tip bends back from straight, in metres.
@export var curve: float = 0.05
@export var light_energy: float = 1.4

var _light: OmniLight3D
var _time := 0.0


func _ready() -> void:
	_build_blade()
	_build_hilt()
	_build_flames()
	_light = OmniLight3D.new()
	_light.name = "Glow"
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.light_energy = light_energy
	_light.omni_range = 3.5
	_light.position = Vector3(0.0, 0.1 + blade_length * 0.5, 0.0)
	add_child(_light)


func _process(delta: float) -> void:
	_time += delta
	_light.light_energy = light_energy * (0.85 + 0.15 * sin(_time * 13.0) * sin(_time * 7.3 + 1.0))


## A wedge-shaped blade, thick at the spine (-Z) and thin at the edge (+Z),
## bending back along its length and coming to a slanted tip.
func _build_blade() -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var sections := 12
	var base := 0.1
	for s in sections + 1:
		var t := float(s) / sections
		var width := blade_width * (1.0 - 0.45 * t * t * t)
		var y := base + t * blade_length
		var bend := curve * t * t
		var spine := Vector3(0.0, y, -width * 0.5 - bend)
		var edge := Vector3(0.0, y - (0.05 * smoothstep(0.85, 1.0, t)), width * 0.5 - bend)
		var thickness := 0.007 * (1.0 - 0.6 * t)
		# Left face, spine and right face share the edge line.
		vertices.append_array(PackedVector3Array([spine + Vector3(-thickness, 0.0, 0.0), edge, spine + Vector3(thickness, 0.0, 0.0)]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, t), Vector2(1.0, t), Vector2(0.0, t)]))
	var indices := PackedInt32Array()
	for s in sections:
		var a := s * 3
		var b := a + 3
		indices.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
		indices.append_array(PackedInt32Array([a + 2, a + 1, b + 2, a + 1, b + 1, b + 2]))
		indices.append_array(PackedInt32Array([a, a + 2, b, a + 2, b + 2, b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var tool := SurfaceTool.new()
	tool.create_from_arrays(arrays)
	tool.generate_normals()
	var material := ShaderMaterial.new()
	material.shader = BLADE_SHADER
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	blade.mesh = tool.commit()
	blade.material_override = material
	add_child(blade)


## Round guard, a cord-wrapped grip and a gold cap.
func _build_hilt() -> void:
	var batch := NatureKit.Batch.new()
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.055, 0.055, 0.014, 12)), Transform3D(Basis(), Vector3(0.0, 0.085, 0.0)), Color(0.18, 0.16, 0.15))
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.03, 0.03, 0.03, 10)), Transform3D(Basis(), Vector3(0.0, 0.065, 0.0)), Color(0.85, 0.66, 0.28))
	var wraps := 7
	for w in wraps:
		var y := 0.04 - w * 0.04
		batch.add(MeshKit.triangles(MeshKit.cylinder(0.019, 0.019, 0.03, 8)), Transform3D(Basis(Vector3.UP, w * 0.4), Vector3(0.0, y, 0.0)), Color(0.12, 0.08, 0.07) if w % 2 == 0 else Color(0.5, 0.1, 0.08))
	batch.add(MeshKit.triangles(MeshKit.cylinder(0.021, 0.024, 0.025, 10)), Transform3D(Basis(), Vector3(0.0, 0.04 - wraps * 0.04, 0.0)), Color(0.85, 0.66, 0.28))
	var hilt := MeshInstance3D.new()
	hilt.name = "Hilt"
	hilt.mesh = batch.commit()
	hilt.material_override = MeshKit.lowpoly_material(Color.WHITE, 0.6)
	add_child(hilt)


## Soft additive sparks of flame rising off the blade, left behind in the
## world as the blade moves.
func _build_flames() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.008, blade_length * 0.45, blade_width * 0.5)
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 40.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.2
	process.gravity = Vector3(0.0, 0.9, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.1))
	var scale_curve := CurveTexture.new()
	scale_curve.curve = shrink
	process.scale_curve = scale_curve
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	fade.set_color(1, Color(0.8, 0.1, 0.02, 0.0))
	fade.add_point(0.4, Color(1.0, 0.4, 0.08, 0.8))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	var dot := Gradient.new()
	dot.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	dot.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var dot_texture := GradientTexture2D.new()
	dot_texture.gradient = dot
	dot_texture.fill = GradientTexture2D.FILL_RADIAL
	dot_texture.fill_from = Vector2(0.5, 0.5)
	dot_texture.fill_to = Vector2(0.5, 0.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = dot_texture
	var quad := QuadMesh.new()
	quad.size = Vector2(0.07, 0.07)
	quad.material = material
	var flames := GPUParticles3D.new()
	flames.name = "Flames"
	flames.amount = 48
	flames.lifetime = 0.7
	flames.local_coords = false
	flames.process_material = process
	flames.draw_pass_1 = quad
	flames.position = Vector3(0.0, 0.1 + blade_length * 0.5, 0.0)
	flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flames)
