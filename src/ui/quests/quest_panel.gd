class_name QuestPanel
extends Control
## The quest log: a drawer sliding in from the left edge over WIDTH of the
## screen, opened with Q. Quests the player has taken on, newest last, each
## with who gave it, what it's about and its steps ticked off as they're
## done (an item step ticks while the item is carried); finished quests
## below, dimmed. Built in code in the inventory's style; placeholder style.

signal opened
signal closed

const WIDTH := 0.4
const SLIDE_SECONDS := 0.22
const BACKGROUND := InventoryPanel.BACKGROUND
const CARD := Color(0.13, 0.15, 0.2, 0.95)
const ACCENT := InventoryPanel.ACCENT
const TEXT := InventoryPanel.TEXT
const MUTED := InventoryPanel.MUTED
const DONE := Color(0.55, 0.85, 0.55)

var _inventory: Inventory
var _drawer: PanelContainer
var _list: VBoxContainer
var _open := false
var _reveal := 0.0
var _tween: Tween
var _shown_revision := -1
var _shown_carried := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer = PanelContainer.new()
	_drawer.name = "Drawer"
	_drawer.anchor_right = WIDTH
	_drawer.anchor_bottom = 1.0
	_drawer.add_theme_stylebox_override("panel", _box(BACKGROUND, 0, 28))
	add_child(_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	_drawer.add_child(column)
	column.add_child(_label(tr("Quests"), 44, ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_list)
	column.add_child(_label(tr("Q  close"), 24, MUTED))
	_set_reveal(0.0)
	resized.connect(func() -> void: _set_reveal(_reveal))


## Ticks item steps by what this inventory carries.
func bind(inventory: Inventory) -> void:
	_inventory = inventory


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
	_slide_to(0.0)
	closed.emit()


func finish_slide() -> void:
	if _tween and _tween.is_running():
		_tween.custom_step(SLIDE_SECONDS)


## Everything shown, as text, for tests.
func text() -> String:
	var lines: Array[String] = []
	for label in _list.find_children("*", "Label", true, false):
		lines.append((label as Label).text)
	return "\n".join(lines)


func _process(_delta: float) -> void:
	if not _open:
		return
	var carried := "" if _inventory == null else ",".join(_inventory.ids())
	if QuestLog.revision != _shown_revision or carried != _shown_carried:
		_refresh()


func _refresh() -> void:
	_shown_revision = QuestLog.revision
	_shown_carried = "" if _inventory == null else ",".join(_inventory.ids())
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var active := QuestLog.quests_in(QuestLog.ACTIVE)
	var done := QuestLog.quests_in(QuestLog.DONE)
	if active.is_empty() and done.is_empty():
		_list.add_child(_wrapped(tr("No quests yet. Talk to people you meet."), 26, MUTED))
		return
	for quest in active:
		_list.add_child(_card(quest, false))
	if not done.is_empty():
		_list.add_child(_label(tr("Completed"), 30, MUTED))
		for quest in done:
			_list.add_child(_card(quest, true))


func _card(quest: QuestData, finished: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(CARD, 10, 18))
	card.modulate.a = 0.6 if finished else 1.0
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	column.add_child(_wrapped(tr(quest.title), 34, DONE if finished else ACCENT))
	if not quest.giver.is_empty():
		column.add_child(_label(tr("From %s") % tr(quest.giver), 22, MUTED))
	if not finished:
		column.add_child(_wrapped(tr(quest.description), 24, TEXT))
	for step in quest.steps:
		var ticked := QuestLog.is_step_done(quest, step, _inventory)
		var line := "%s  %s" % ["[x]" if ticked else "[  ]", tr(step.text)]
		if not step.item.is_empty() and not finished:
			var have := mini(_inventory.total(step.item), step.amount) if _inventory else 0
			line += "  (%d/%d)" % [have, step.amount]
		column.add_child(_wrapped(line, 24, DONE if ticked else TEXT))
	return card


func _slide_to(target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_reveal, _reveal, target, SLIDE_SECONDS)


## 0 is hidden past the left edge, 1 fully open.
func _set_reveal(amount: float) -> void:
	_reveal = amount
	var shift := -(1.0 - amount) * size.x * WIDTH
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


func _wrapped(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _box(color: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box
