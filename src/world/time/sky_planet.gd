class_name SkyPlanet
extends Node3D
## A planet in the day sky: a banded sphere, with a tilted ring system if it
## has rings, far beyond the land, kept at the same place in the sky wherever the
## camera goes (it can never be reached), lit by the sun so its lit side
## follows the day, and fading out at dusk and in at dawn. Mountains and trees
## pass in front of it. Textures are made in code. Placeholder look.

@export var day_night: DayNight
## Where it hangs in the sky, from the viewer (normalized on use).
@export var direction: Vector3 = Vector3(0.45, 0.42, -0.79)
## Metres from the viewer: beyond everything, inside the camera's reach.
@export var distance: float = 3000.0
## Metres; at `distance` 3000 m, 560 m spans about 21 degrees of sky.
@export var radius: float = 560.0
## How far the rings tilt sideways, in degrees.
@export var ring_tilt: float = 22.0
@export var ring_inner: float = 1.35
@export var ring_outer: float = 2.35
@export var has_rings: bool = true
## Band colours (sRGB), mixed across its latitudes.
@export var bands: Array[Color] = [Color(0.93, 0.85, 0.66), Color(0.82, 0.68, 0.48), Color(0.96, 0.9, 0.74), Color(0.75, 0.6, 0.42), Color(0.9, 0.79, 0.58), Color(0.68, 0.55, 0.4)]
## Shapes its bands, so planets differ.
@export var pattern_seed: int = 9
## A pale storm in its bands.
@export var has_storm: bool = true

var _planet_material: StandardMaterial3D
var _ring_material: StandardMaterial3D


func _ready() -> void:
	var planet := MeshInstance3D.new()
	planet.name = "Planet"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0 * 0.92
	sphere.radial_segments = 64
	sphere.rings = 32
	planet.mesh = sphere
	_planet_material = _material(_band_texture())
	# Writes depth, so the near side of the rings draws in front of it.
	_planet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	planet.material_override = _planet_material
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(planet)
	_ring_material = _material(_ring_texture()) if has_rings else null
	if has_rings:
		_add_rings()
	_orient()


func _add_rings() -> void:
	var rings := MeshInstance3D.new()
	rings.name = "Rings"
	rings.mesh = _ring_mesh()
	_ring_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Drawn after the planet, so the planet's depth hides only the far side.
	_ring_material.render_priority = 1
	rings.material_override = _ring_material
	rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rings)


func _orient() -> void:
	# The axis leans toward the viewer, so the rings open into a wide
	# ellipse, and tilts sideways by `ring_tilt`.
	var toward_viewer := -direction.normalized()
	var side := Vector3.UP.cross(toward_viewer).normalized()
	var axis := (Vector3.UP + toward_viewer * 0.12).normalized().rotated(toward_viewer, deg_to_rad(ring_tilt))
	var forward := side.cross(axis).normalized()
	basis = Basis(axis.cross(forward).normalized(), axis, forward)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_position = camera.global_position + direction.normalized() * distance
	var day := day_night.daylight(day_night.clock.hour) if day_night else 1.0
	var shown := smoothstep(0.15, 0.7, day)
	visible = shown > 0.01
	_planet_material.albedo_color.a = shown
	if _ring_material:
		_ring_material.albedo_color.a = shown


## How much it shows now, 0 at night to 1 by day.
func shown() -> float:
	return _planet_material.albedo_color.a if visible else 0.0


func _material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = true
	material.roughness = 1.0
	material.metallic_specular = 0.0
	# A little light of its own, so the night side isn't black against the
	# blue sky.
	material.emission_enabled = true
	material.emission = Color(0.22, 0.24, 0.32)
	return material


## Bands of cream, tan and gold around the planet, wavering a little, and a
## pale storm.
func _band_texture() -> Texture2D:
	var image := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	var wobble := FastNoiseLite.new()
	wobble.seed = pattern_seed + 1
	wobble.frequency = 0.02
	var rng := RandomNumberGenerator.new()
	rng.seed = pattern_seed
	var stripes := PackedFloat32Array()
	for k in 24:
		stripes.append(rng.randf())
	for y in image.get_height():
		for x in image.get_width():
			var latitude := float(y) / image.get_height() + 0.012 * wobble.get_noise_2d(x * 0.6, y * 3.0)
			var band := clampi(int(latitude * stripes.size()), 0, stripes.size() - 1)
			var pick := stripes[band] * (bands.size() - 1)
			var colour := bands[int(pick)].lerp(bands[mini(int(pick) + 1, bands.size() - 1)], pick - int(pick))
			var storm := Vector2((x - 330.0) / 26.0, (y - 160.0) / 12.0).length()
			if has_storm and storm < 1.0:
				colour = colour.lerp(Color(0.97, 0.92, 0.8), 1.0 - storm)
			image.set_pixel(x, y, Color(colour, 1.0))
	return ImageTexture.create_from_image(image)


## A flat ring from `ring_inner` to `ring_outer` radii; UV.x runs across it.
func _ring_mesh() -> ArrayMesh:
	var sides := 128
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for k in sides + 1:
		var angle := TAU * k / sides
		var out := Vector3(cos(angle), 0.0, sin(angle))
		vertices.append(out * radius * ring_inner)
		vertices.append(out * radius * ring_outer)
		uvs.append(Vector2(0.0, float(k) / sides))
		uvs.append(Vector2(1.0, float(k) / sides))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	for k in sides:
		var a := k * 2
		indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Ringlets across the rings: pale and dusty, denser and thinner, with a
## dark gap.
func _ring_texture() -> Texture2D:
	var image := Image.create(256, 4, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var density := 0.5
	for x in image.get_width():
		var t := float(x) / image.get_width()
		density = clampf(density + rng.randf_range(-0.12, 0.12), 0.25, 0.95)
		var gap := 1.0 - (1.0 - smoothstep(0.0, 0.025, absf(t - 0.62)))
		var edges := smoothstep(0.0, 0.06, t) * smoothstep(1.0, 0.9, t)
		var colour := Color(0.88, 0.8, 0.66).lerp(Color(0.7, 0.62, 0.52), t)
		for y in image.get_height():
			image.set_pixel(x, y, Color(colour, minf(1.0, density * 1.3) * gap * edges))
	return ImageTexture.create_from_image(image)
