extends GutTest
## The cornflower in B1 can be picked up into the inventory, which opens with
## I from the right edge over 40% of the screen, freezes the hero, and shows
## the flower's model and info when its slot is clicked.

const SCENE_PATH := "res://src/world/field/field.tscn"
const MeadowDesign := preload("res://src/world/field/sectors/b1_cornflower/b1_cornflower.gd")

var _world: Node3D
var _player: Player
var _panel: InventoryPanel


func before_all() -> void:
	_world = (load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	add_child(_world)
	_player = _world.get_node("Player") as Player
	_panel = (_world.get_node("Hud") as Hud).inventory_panel()


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_world.free()


func test_1_the_cornflower_grows_in_b1() -> void:
	var pickup := _world.get_node("Sectors/B1Cornflower/Content/Cornflower") as ItemPickup
	assert_eq(pickup.item.id, &"cornflower")
	assert_eq(SectorMap.name_of(SectorMap.cell_at(pickup.global_position)), "B1")


func test_2_walking_up_and_pressing_e_picks_it_up() -> void:
	watch_signals(_player)
	var flower := MeadowDesign.FLOWER_AT
	_player.global_position = Vector3(flower.x, 0.3, flower.y + 0.8)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(8)
	assert_signal_emitted_with_parameters(_player, "prompt_changed", ["[E]  Pick up Cornflower"])
	_player.interact()
	await wait_process_frames(2)
	assert_true(_player.inventory.has(&"cornflower"))
	assert_null(_world.get_node_or_null("Sectors/B1Cornflower/Content/Cornflower"), "gone from the meadow")


func test_3_i_opens_the_inventory_from_the_right_over_40_percent() -> void:
	_press("inventory")
	var drawer := _panel.get_node("Drawer") as Control
	var screen := _panel.get_viewport_rect().size
	await wait_process_frames(2)
	_panel.finish_slide()
	assert_true(_panel.is_open())
	assert_false(_player.input_enabled, "the hero stands still")
	assert_almost_eq(drawer.size.x / screen.x, 0.4, 0.01)
	assert_almost_eq(drawer.get_global_rect().end.x, screen.x, 1.0, "against the right edge")
	assert_eq(_panel.slot_count(), 24)


func test_4_clicking_the_flower_shows_its_info() -> void:
	_panel.select(0)
	await wait_process_frames(2)
	assert_eq(_panel.viewed_item().id, &"cornflower")
	var text := _panel.viewer_text()
	assert_string_contains(text, "Cornflower")
	assert_string_contains(text, "Wildflower")
	assert_true((_panel.get_node("Viewer") as Control).visible)


func test_5_i_closes_it_again() -> void:
	_press("inventory")
	var drawer := _panel.get_node("Drawer") as Control
	await wait_process_frames(2)
	_panel.finish_slide()
	assert_false(_panel.is_open())
	assert_true(_player.input_enabled)
	assert_false((_panel.get_node("Viewer") as Control).visible)
	assert_false(drawer.visible, "slid away")


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(1)
