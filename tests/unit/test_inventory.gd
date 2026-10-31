extends GutTest
## Inventory: 4 x 6 slots, filled from the first empty one.

const PEBBLE := preload("res://tests/fixtures/items/pebble.tres")


func test_has_four_columns_and_six_rows() -> void:
	var inventory := Inventory.new()
	assert_eq(Inventory.COLUMNS, 4)
	assert_eq(Inventory.ROWS, 6)
	assert_eq(inventory.capacity(), 24)
	assert_eq(inventory.count(), 0)


func test_items_fill_the_first_empty_slot() -> void:
	var inventory := Inventory.new()
	watch_signals(inventory)
	assert_true(inventory.add(PEBBLE))
	assert_signal_emitted(inventory, "changed")
	assert_eq(inventory.item_at(0), PEBBLE)
	assert_true(inventory.has(&"pebble"))
	inventory.add(PEBBLE)
	inventory.remove_at(0)
	inventory.add(PEBBLE)
	assert_eq(inventory.item_at(0), PEBBLE, "a freed slot is reused first")
	assert_eq(inventory.count(), 2)


func test_refuses_items_when_full() -> void:
	var inventory := Inventory.new()
	for k in inventory.capacity():
		assert_true(inventory.add(PEBBLE))
	assert_true(inventory.is_full())
	assert_false(inventory.add(PEBBLE))


func test_stackable_items_share_a_slot() -> void:
	var inventory := Inventory.new()
	var berry := preload("res://tests/fixtures/items/berry.tres")
	for k in berry.stack_size + 1:
		assert_true(inventory.add(berry))
	assert_eq(inventory.amount_at(0), berry.stack_size)
	assert_eq(inventory.amount_at(1), 1, "a full stack starts another")
	assert_eq(inventory.total(&"berry"), berry.stack_size + 1)
	inventory.add(PEBBLE)
	inventory.add(PEBBLE)
	assert_eq(inventory.amount_at(2), 1, "pebbles don't stack")
	assert_eq(inventory.amount_at(3), 1)


func test_a_full_inventory_still_takes_items_its_stacks_have_room_for() -> void:
	var inventory := Inventory.new()
	var berry := preload("res://tests/fixtures/items/berry.tres")
	inventory.add(berry)
	for k in inventory.capacity() - 1:
		inventory.add(PEBBLE)
	assert_true(inventory.is_full())
	assert_false(inventory.can_add(PEBBLE))
	assert_true(inventory.can_add(berry))
