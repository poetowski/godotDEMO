class_name ItemPreview
extends SubViewportContainer
## An item's model in a little world of its own, lit and framed to fill the
## view: turning slowly, and turned by dragging when `draggable`. Used for
## inventory slots and the item viewer.

## Radians per second the model turns by itself.
@export var spin_speed: float = 0.5
@export var draggable: bool = false

var _viewport: SubViewport
var _pivot: Node3D
var _camera: Camera3D
var _item: ItemData


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.78, 0.85)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	var world := WorldEnvironment.new()
	world.environment = environment
	_viewport.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.6, 0.0)
	sun.light_energy = 1.2
	_viewport.add_child(sun)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	_camera = Camera3D.new()
	_camera.fov = 35.0
	_viewport.add_child(_camera)


func _process(delta: float) -> void:
	if _item and spin_speed != 0.0:
		_pivot.rotate_y(spin_speed * delta)


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if draggable and motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_pivot.rotate_y(motion.relative.x * 0.01)
		accept_event()


## Shows an item's model, or nothing for null.
func show_item(item: ItemData) -> void:
	_item = item
	for child in _pivot.get_children():
		child.queue_free()
	if item == null or item.model == null:
		return
	var model := item.model.instantiate() as Node3D
	_pivot.add_child(model)
	_pivot.rotation = Vector3(0.0, 0.6, 0.0)
	var bounds := _bounds(model)
	model.position = -bounds.get_center()
	var size := maxf(bounds.size.y, maxf(bounds.size.x, bounds.size.z))
	var distance := size * 0.5 / tan(deg_to_rad(_camera.fov * 0.5)) * 1.25
	_camera.position = Vector3(0.0, size * 0.18, distance)
	_camera.look_at(Vector3.ZERO)


func item() -> ItemData:
	return _item


## The box around every mesh under a node, in the node's space.
func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var mesh := node as MeshInstance3D
		if mesh and mesh.mesh:
			var local := root.global_transform.affine_inverse() * mesh.global_transform * mesh.mesh.get_aabb() if mesh.is_inside_tree() else mesh.transform * mesh.mesh.get_aabb()
			box = local if first else box.merge(local)
			first = false
	return box
