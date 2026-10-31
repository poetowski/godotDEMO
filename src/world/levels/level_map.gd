@tool
class_name LevelMap
extends RefCounted
## What's at a height. The land and its water have one height for each x and z,
## which is all the open ground needs (WorldShape, FieldTerrain). But people also
## stand on a bridge, on a tower's fifth floor or in a cave under a lake, so anything
## asking about where someone is asks here, with the whole point.
##
## A floor needs no setting up: it's a collider, and this only has to know that the
## point isn't in the water below it. Places of their own are LevelVolumes, and ways
## down through the ground are GroundOpenings. See "Levels" in docs/world/README.md.

## Metres under the open ground at which a point counts as underground, and is no
## longer in any water lying on that ground.
const UNDERGROUND := 0.5


## What's at one point.
class Place:
	var point := Vector3.ZERO
	## The open ground's height at this x and z, whether it's above or below the point.
	var ground := 0.0
	## The smallest LevelVolume around the point, or null in the open.
	var volume: LevelVolume
	## The surface of the water around or below the point, or NO_WATER. On a bridge
	## it's the river's, below; in a cave under a lake there is none.
	var water: float = SectorDesign.NO_WATER
	## What that water stands on.
	var bed := 0.0

	func is_underground() -> bool:
		return point.y < ground - UNDERGROUND

	## Metres of water above the point; 0 when it's above the water or there's none.
	func water_over_point() -> float:
		return maxf(water - point.y, 0.0)

	func is_in_water() -> bool:
		return water_over_point() > 0.0

	## Under a roof or the ground, away from the wind and the birds. A volume decides
	## for itself, so a pit can stay open to the sky.
	func is_enclosed() -> bool:
		return volume.enclosed if volume else is_underground()

	## The name of the place, in English; empty in the open.
	func place_name() -> String:
		return volume.place_name if volume else ""


## What's at a point in the world.
static func at(terrain: FieldTerrain, point: Vector3) -> Place:
	var place := Place.new()
	var xz := Vector2(point.x, point.z)
	place.point = point
	place.ground = terrain.height_at(xz)
	place.volume = _volume_at(terrain, point)
	if place.volume and place.volume.water_depth > 0.0:
		place.water = place.volume.water_surface()
		place.bed = place.volume.global_position.y
	elif not place.is_underground():
		var level := terrain.water_level_at(xz)
		if level > place.ground:
			place.water = level
			place.bed = place.ground
	return place


## A box of lines standing on its origin, showing a level's shape in the editor.
static func outline(size: Vector3, color: Color) -> MeshInstance3D:
	var half := Vector3(size.x, 0.0, size.z) * 0.5
	var corners := PackedVector3Array()
	for corner: Vector3 in [Vector3(-half.x, 0.0, -half.z), Vector3(half.x, 0.0, -half.z), Vector3(half.x, 0.0, half.z), Vector3(-half.x, 0.0, half.z)]:
		corners.append(corner)
	var up := Vector3.UP * size.y
	var vertices := PackedVector3Array()
	for k in corners.size():
		var next := corners[(k + 1) % corners.size()]
		vertices.append_array(PackedVector3Array([corners[k], next, corners[k] + up, next + up, corners[k], corners[k] + up]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = color
	look.no_depth_test = true
	var lines := MeshInstance3D.new()
	lines.name = "Outline"
	lines.mesh = mesh
	lines.material_override = look
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return lines


## The smallest volume around a point, so a room inside a tower wins over the tower.
static func _volume_at(terrain: FieldTerrain, point: Vector3) -> LevelVolume:
	var smallest: LevelVolume = null
	for node in terrain.get_tree().get_nodes_in_group(LevelVolume.GROUP):
		var volume := node as LevelVolume
		if volume.contains(point) and (smallest == null or volume.space() < smallest.space()):
			smallest = volume
	return smallest
