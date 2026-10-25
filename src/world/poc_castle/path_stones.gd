@tool
extends Node3D
## Paves the PoC path with irregular flagstones laid along PocLayout's path,
## tilted to the ground, with a few gaps so it reads as worn.

const ROW_SPACING := 0.62
const STONE_SPACING := 0.6
const GAP_CHANCE := 0.08
const STONE_COLORS: Array[Color] = [
	Color(0.62, 0.6, 0.56), Color(0.55, 0.53, 0.5), Color(0.68, 0.64, 0.57), Color(0.5, 0.49, 0.47),
]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PocLayout.SEED + 20
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var path := PocLayout.path_points()
	var next_row := 0.0
	var travelled := 0.0
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var length := a.distance_to(b)
		var along := (b - a) / length
		var across := Vector2(-along.y, along.x)
		while next_row <= travelled + length:
			var center := a + along * (next_row - travelled)
			var offset := -PocLayout.PATH_HALF_WIDTH + STONE_SPACING * 0.5
			while offset < PocLayout.PATH_HALF_WIDTH:
				if rng.randf() > GAP_CHANCE:
					var jitter := Vector2(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1))
					var spot := center + across * offset + jitter
					transforms.append(_stone_transform(spot, rng))
					colors.append(STONE_COLORS[rng.randi() % STONE_COLORS.size()].darkened(rng.randf_range(0.0, 0.12)))
				offset += STONE_SPACING
			next_row += ROW_SPACING
		travelled += length

	var mesh := MeshKit.cylinder(0.3, 0.33, 0.12, 7)
	var stones := MeshKit.multimesh_instance(mesh, MeshKit.lowpoly_material(Color.WHITE, 0.95), transforms.size())
	stones.name = "Stones"
	stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in transforms.size():
		stones.multimesh.set_instance_transform(i, transforms[i])
		stones.multimesh.set_instance_color(i, colors[i])
	add_child(stones)


func _stone_transform(spot: Vector2, rng: RandomNumberGenerator) -> Transform3D:
	var up := PocLayout.normal_at(spot.x, spot.y)
	var tilt := Quaternion(Vector3.UP, up)
	var spin := Basis(Vector3.UP, rng.randf() * TAU)
	var size := Vector3(rng.randf_range(0.8, 1.1), rng.randf_range(0.7, 1.0), rng.randf_range(0.8, 1.1))
	var stone_basis := Basis(tilt) * spin * Basis.from_scale(size)
	return Transform3D(stone_basis, PocLayout.ground(spot) + Vector3.UP * 0.02)
