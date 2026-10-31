extends GutTest
## The world follows what was sculpted: the ground's height, the streamed
## tiles and their collision, designed sectors, and rays finding the ground.

const SCENE_PATH := "res://src/world/field/field.tscn"

var _world: Node
var _terrain: FieldTerrain
var _hill_top: float


func before_all() -> void:
	TerrainSculpt.start_empty()
	FieldWorld.configure()
	# A hill on open ground, in the chunks detailed around the start in A1.
	var brush := SculptBrush.new()
	brush.radius = 10.0
	brush.strength = 6.0
	brush.apply(Vector2(150.0, -50.0), 1.0)
	_world = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(_world)
	_hill_top = WorldShape.base_height(Vector2(150.0, -50.0)) + 6.0
	_terrain = _world.call("terrain") as FieldTerrain


func after_all() -> void:
	_world.free()
	TerrainSculpt.start_empty()


func test_the_terrain_answers_with_the_sculpted_height() -> void:
	assert_almost_eq(_terrain.height_at(Vector2(150.0, -50.0)), _hill_top, 0.01)


func test_the_streamed_ground_stands_on_it() -> void:
	await wait_physics_frames(3)
	var space := (_world as Node3D).get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(150.0, 40.0, -50.0), Vector3(150.0, -40.0, -50.0))
	var hit := space.intersect_ray(query)
	assert_false(hit.is_empty(), "there is ground under the hill")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, _hill_top, 0.05)


func test_a_ray_finds_the_hill_from_the_side() -> void:
	var height := _hill_top - 3.0
	var hit := _terrain.ground_hit(Vector3(115.0, height, -50.0), Vector3.RIGHT, 100.0)
	assert_ne(hit, Vector3.INF)
	assert_between(hit.x, 138.0, 150.0, "it stops on the near slope")
	assert_almost_eq(_terrain.height_at(Vector2(hit.x, hit.z)), hit.y, 0.01)


func test_a_ray_going_up_or_starting_below_finds_nothing() -> void:
	assert_eq(_terrain.ground_hit(Vector3(115.0, 30.0, -50.0), Vector3.UP, 100.0), Vector3.INF)
	assert_eq(_terrain.ground_hit(Vector3(115.0, -30.0, -50.0), Vector3.RIGHT, 100.0), Vector3.INF)


func test_reshaping_a_tile_moves_what_the_brush_touched_at_once() -> void:
	var body := StaticBody3D.new()
	add_child_autofree(body)
	var holder := Node3D.new()
	add_child_autofree(holder)
	holder.global_position = Vector3(150.0, 0.0, -150.0)
	var chunks := TerrainChunks.new()
	chunks.body = body
	chunks.focus = holder
	chunks.height = WorldShape.height
	chunks.material = FieldTerrain.ground_material()
	chunks.editable = true
	chunks.view_regions = 1
	add_child_autofree(chunks)
	chunks.build_now()
	var brush := SculptBrush.new()
	brush.radius = 5.0
	brush.strength = 3.0
	chunks.reshape(brush.apply(Vector2(150.0, -150.0), 1.0))
	var tile := body.get_node_or_null("Tile_1_1_0") as MeshInstance3D
	assert_not_null(tile)
	var vertices: PackedVector3Array = (tile.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var risen := -INF
	var off_elsewhere := 0.0
	for vertex in vertices:
		var xz := Vector2(vertex.x, vertex.z)
		var from_middle := xz.distance_to(Vector2(150.0, -150.0))
		# Skirts hang below the edges; only look at the ground's own triangles.
		if vertex.x <= 100.0 or vertex.x >= 200.0 or vertex.z >= -100.0 or vertex.z <= -200.0:
			continue
		if from_middle < 1.0:
			risen = maxf(risen, vertex.y - WorldShape.base_height(xz))
		off_elsewhere = maxf(off_elsewhere, absf(vertex.y - WorldShape.height(xz)))
	assert_gt(risen, 2.0, "the middle rose straight away")
	assert_almost_eq(off_elsewhere, 0.0, 0.01, "every vertex sits on the current height")
