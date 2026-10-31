extends GutTest
## Props placed by hand: a design merges its Prop nodes into its sectors'
## meshes and collision when its content is built, so moving a prop in the
## scene moves it in the game.

const SCENE_PATH := "res://src/world/field/field.tscn"
const FixtureDesign := preload("res://tests/fixtures/fixture_design.gd")

var _world: Node
var _design: SectorDesign
var _rock: Prop


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	_design = FixtureDesign.add_to(_world, "PropPond", PackedStringArray(["F6"]))
	var holder := Node3D.new()
	holder.name = "Props"
	_design.add_child(holder)
	_rock = Prop.new()
	_rock.kind = PropLibrary.Kind.ROCK
	_rock.solid = true
	_rock.position = Vector3(51.0, 0.0, -51.0)
	holder.add_child(_rock)
	add_child(_world)


func after_all() -> void:
	_world.free()


func test_the_design_finds_its_props() -> void:
	assert_eq(_design.scene_props().size(), 1)


func test_props_are_merged_into_their_sectors_meshes() -> void:
	var content := _design.generate_content()
	assert_not_null(content.get_node_or_null("RocksF6"))
	assert_eq(_design.placed_props().size(), 0, "the code places none")
	content.free()


func test_moving_a_prop_moves_it_in_the_game() -> void:
	var before := _rock.position
	var spot := Vector2(58.0, -58.0)
	_rock.position = Vector3(spot.x, _design.height_at(spot), spot.y)
	var content := _design.generate_content()
	var box := (content.get_node("RocksF6") as MeshInstance3D).mesh.get_aabb()
	assert_true(box.grow(0.2).has_point(Vector3(spot.x, box.get_center().y, spot.y)), "merged where it stands now")
	assert_gt(content.find_children("*", "CollisionShape3D", true, false).size(), 1, "with its collision")
	content.free()
	_rock.position = before


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
