extends GutTest
## Inventory: 4 x 6 slots, filled from the first empty one.

const CORNFLOWER := preload("res://data/items/cornflower.tres")


func test_has_four_columns_and_six_rows() -> void:
	var inventory := Inventory.new()
	assert_eq(Inventory.COLUMNS, 4)
	assert_eq(Inventory.ROWS, 6)
	assert_eq(inventory.capacity(), 24)
	assert_eq(inventory.count(), 0)


func test_items_fill_the_first_empty_slot() -> void:
	var inventory := Inventory.new()
	watch_signals(inventory)
	assert_true(inventory.add(CORNFLOWER))
	assert_signal_emitted(inventory, "changed")
	assert_eq(inventory.item_at(0), CORNFLOWER)
	assert_true(inventory.has(&"cornflower"))
	inventory.add(CORNFLOWER)
	inventory.remove_at(0)
	inventory.add(CORNFLOWER)
	assert_eq(inventory.item_at(0), CORNFLOWER, "a freed slot is reused first")
	assert_eq(inventory.count(), 2)


func test_refuses_items_when_full() -> void:
	var inventory := Inventory.new()
	for k in inventory.capacity():
		assert_true(inventory.add(CORNFLOWER))
	assert_true(inventory.is_full())
	assert_false(inventory.add(CORNFLOWER))


func test_the_cornflower_has_basic_info() -> void:
	assert_eq(CORNFLOWER.display_name, "Cornflower")
	assert_false(CORNFLOWER.description.is_empty())
	assert_gt(CORNFLOWER.facts.size(), 2)
	assert_not_null(CORNFLOWER.model)
