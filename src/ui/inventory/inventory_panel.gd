class_name InventoryPanel
extends Control
## The inventory: a drawer sliding in from the right edge over WIDTH of the
## screen, with the slots in a grid. Clicking a filled slot opens the viewer
## on the left, where the item turns in 3D (drag to turn it) above its name,
## description and facts. Built in code; placeholder style.

signal opened
signal closed

## The drawer's share of the screen's width.
const WIDTH := 0.4
const SLIDE_SECONDS := 0.22
const BACKGROUND := Color(0.08, 0.09, 0.12, 0.88)
const SLOT := Color(0.16, 0.18, 0.23, 0.95)
const SLOT_HOVER := Color(0.22, 0.25, 0.32, 0.95)
const ACCENT := Color(0.75, 0.95, 1.0)
const TEXT := Color(0.92, 0.93, 0.95)
const MUTED := Color(0.65, 0.68, 0.74)

var _inventory: Inventory
var _drawer: PanelContainer
var _grid: GridContainer
var _count: Label
var _slots: Array[Button] = []
var _thumbnails: Array[ItemPreview] = []
var _viewer: PanelContainer
var _preview: ItemPreview
var _name: Label
var _description: Label
var _facts: GridContainer
var _selected := -1
var _open := false
var _reveal := 0.0
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_drawer()
	_build_viewer()
	_set_reveal(0.0)
	resized.connect(_layout)
	_layout()


## Shows this inventory's items and follows its changes.
func bind(inventory: Inventory) -> void:
	_inventory = inventory
	_inventory.changed.connect(_refresh)
	_refresh()


func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	_open = true
	_refresh()
	_slide_to(1.0)
	opened.emit()


func close() -> void:
	if not _open:
		return
	_open = false
	_show_viewer(-1)
	_slide_to(0.0)
	closed.emit()


## Jumps a running slide to its end, for tests and screenshots.
func finish_slide() -> void:
	if _tween and _tween.is_running():
		_tween.custom_step(SLIDE_SECONDS)


## Opens the viewer on a slot's item; nothing happens for an empty slot.
func select(slot: int) -> void:
	if _inventory and _inventory.item_at(slot):
		_show_viewer(slot)


func viewed_item() -> ItemData:
	return _inventory.item_at(_selected) if _selected >= 0 else null


func viewer_text() -> String:
	var lines: Array[String] = [_name.text, _description.text]
	for label in _facts.get_children():
		lines.append((label as Label).text)
	return "\n".join(lines)


func slot_count() -> int:
	return _slots.size()


func _build_drawer() -> void:
	_drawer = PanelContainer.new()
	_drawer.name = "Drawer"
	_drawer.anchor_left = 1.0 - WIDTH
	_drawer.anchor_right = 1.0
	_drawer.anchor_bottom = 1.0
	_drawer.add_theme_stylebox_override("panel", _box(BACKGROUND, 0, 28))
	add_child(_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	_drawer.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("Inventory", 44, ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count = _label("", 28, MUTED)
	header.add_child(_count)
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(centre)
	_grid = GridContainer.new()
	_grid.columns = Inventory.COLUMNS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	centre.add_child(_grid)
	for slot in Inventory.COLUMNS * Inventory.ROWS:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _box(SLOT, 10, 6))
		button.add_theme_stylebox_override("hover", _box(SLOT_HOVER, 10, 6))
		button.add_theme_stylebox_override("pressed", _box(SLOT_HOVER, 10, 6))
		button.pressed.connect(select.bind(slot))
		var thumbnail := ItemPreview.new()
		thumbnail.spin_speed = 0.0
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		thumbnail.offset_left = 6.0
		thumbnail.offset_top = 6.0
		thumbnail.offset_right = -6.0
		thumbnail.offset_bottom = -6.0
		button.add_child(thumbnail)
		_grid.add_child(button)
		_slots.append(button)
		_thumbnails.append(thumbnail)
	column.add_child(_label("Click an item to look at it    I  close", 24, MUTED))


func _build_viewer() -> void:
	_viewer = PanelContainer.new()
	_viewer.name = "Viewer"
	_viewer.anchor_left = 0.08
	_viewer.anchor_right = 1.0 - WIDTH - 0.04
	_viewer.anchor_top = 0.1
	_viewer.anchor_bottom = 0.9
	_viewer.add_theme_stylebox_override("panel", _box(BACKGROUND, 14, 28))
	_viewer.visible = false
	add_child(_viewer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_viewer.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_name = _label("", 44, ACCENT)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name)
	var close_button := Button.new()
	close_button.text = "  x  "
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.add_theme_stylebox_override("normal", _box(SLOT, 8, 4))
	close_button.add_theme_stylebox_override("hover", _box(SLOT_HOVER, 8, 4))
	close_button.pressed.connect(_show_viewer.bind(-1))
	header.add_child(close_button)
	_preview = ItemPreview.new()
	_preview.draggable = true
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.custom_minimum_size = Vector2(0.0, 300.0)
	column.add_child(_preview)
	column.add_child(_label("Drag to turn it", 22, MUTED))
	_description = _label("", 28, TEXT)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_description)
	_facts = GridContainer.new()
	_facts.columns = 2
	_facts.add_theme_constant_override("h_separation", 24)
	_facts.add_theme_constant_override("v_separation", 6)
	column.add_child(_facts)


func _show_viewer(slot: int) -> void:
	_selected = slot
	for k in _slots.size():
		_slots[k].add_theme_stylebox_override("normal", _box(SLOT_HOVER if k == slot else SLOT, 10, 6))
	var item := viewed_item()
	_viewer.visible = item != null
	_preview.show_item(item)
	if item == null:
		return
	_name.text = item.display_name
	_description.text = item.description
	for child in _facts.get_children():
		child.queue_free()
		_facts.remove_child(child)
	for label: String in item.facts:
		_facts.add_child(_label(label, 26, MUTED))
		_facts.add_child(_label(item.facts[label], 26, TEXT))


func _refresh() -> void:
	if _inventory == null:
		return
	_count.text = "%d / %d" % [_inventory.count(), _inventory.capacity()]
	for slot in _slots.size():
		var item := _inventory.item_at(slot)
		if _thumbnails[slot].item() != item:
			_thumbnails[slot].show_item(item)
		_slots[slot].tooltip_text = item.display_name if item else ""
	if _selected >= 0 and viewed_item() == null:
		_show_viewer(-1)


## Square slots as large as the drawer allows.
func _layout() -> void:
	var drawer_size := Vector2(size.x * WIDTH, size.y)
	var across := (drawer_size.x - 56.0 - 12.0 * (Inventory.COLUMNS - 1)) / Inventory.COLUMNS
	var down := (drawer_size.y - 200.0 - 12.0 * (Inventory.ROWS - 1)) / Inventory.ROWS
	var side := floorf(maxf(24.0, minf(across, down)))
	for button in _slots:
		button.custom_minimum_size = Vector2(side, side)
	_set_reveal(_reveal)


func _slide_to(target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_reveal, _reveal, target, SLIDE_SECONDS)


## 0 is hidden past the right edge, 1 fully open.
func _set_reveal(amount: float) -> void:
	_reveal = amount
	var shift := (1.0 - amount) * size.x * WIDTH
	_drawer.offset_left = shift
	_drawer.offset_right = shift
	_drawer.modulate.a = clampf(amount * 1.5, 0.0, 1.0)
	_drawer.visible = amount > 0.0


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _box(color: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box
