extends GutTest
## Props placed by hand: a design merges its Prop nodes into its sectors'
## meshes and collision when its content is built, so moving a prop in the
## scene moves it in the game. The A1-A3 stream's rocks and bushes are props.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _stream: SectorDesign


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_stream = _world.get_node("Sectors/A1A3Stream") as SectorDesign


func after_all() -> void:
	_world.free()


func test_the_streams_rocks_and_bushes_are_props_in_the_scene() -> void:
	assert_true(_stream.props_frozen)
	var props := _stream.scene_props()
	assert_gt(props.size(), 50)
	var kinds := {}
	for prop in props:
		kinds[prop.kind] = true
	assert_true(kinds.has(PropLibrary.Kind.ROCK))
	assert_true(kinds.has(PropLibrary.Kind.BUSH))


func test_props_are_merged_into_each_sectors_meshes() -> void:
	var content := _stream.generate_content()
	for sector: String in ["A1", "A2", "A3"]:
		assert_not_null(content.get_node_or_null("Rocks" + sector), "rocks in " + sector)
		assert_not_null(content.get_node_or_null("Bushes" + sector), "bushes in " + sector)
	assert_eq(_stream.placed_props().size(), 0, "frozen: the code places none")
	content.free()


func test_moving_a_prop_moves_it_in_the_game() -> void:
	var rock: Prop = null
	for prop in _stream.scene_props():
		if prop.kind == PropLibrary.Kind.ROCK and prop.solid:
			rock = prop
			break
	assert_not_null(rock)
	var before := rock.position
	var spot := _dry_spot_in_a2()
	rock.position = Vector3(spot.x, _stream.height_at(spot), spot.y)
	var content := _stream.generate_content()
	var box := (content.get_node("RocksA2") as MeshInstance3D).mesh.get_aabb()
	assert_true(box.grow(0.2).has_point(Vector3(spot.x, box.get_center().y, spot.y)), "merged into A2's rocks where it was moved")
	var bodies := content.find_children("*", "CollisionShape3D", true, false)
	var solid_there := bodies.any(func(node: Node) -> bool: return (node as CollisionShape3D).shape is SphereShape3D and Vector2((node as Node3D).position.x, (node as Node3D).position.z).distance_to(spot) < 0.1)
	assert_true(solid_there, "with its collision")
	content.free()
	rock.position = before


## A spot of dry grass in A2 away from the stream and its props.
func _dry_spot_in_a2() -> Vector2:
	for k in 200:
		var xz := Vector2(1.5 + (k % 10) * 0.75, -11.5 - (k / 10) * 0.35)
		if _stream.is_dry(xz, 0.3):
			return xz
	return Vector2(5.0, -15.0)


func test_the_library_builds_each_prop_the_same_every_time() -> void:
	for kind: PropLibrary.Kind in [PropLibrary.Kind.BUSH, PropLibrary.Kind.ROCK, PropLibrary.Kind.ROUND_TREE, PropLibrary.Kind.PINE]:
		var a := NatureKit.Batch.new()
		var b := NatureKit.Batch.new()
		PropLibrary.add_to(a, kind, 3, Transform3D())
		PropLibrary.add_to(b, kind, 3, Transform3D())
		assert_gt(a.vertices.size(), 30)
		assert_eq(a.vertices, b.vertices)
	assert_eq(PropLibrary.collider(PropLibrary.Kind.BUSH, Transform3D()), [], "bushes are never solid")
	assert_almost_eq(PropLibrary.room(PropLibrary.Kind.ROCK, Transform3D().scaled(Vector3.ONE * 2.0)), 1.24, 0.001)
