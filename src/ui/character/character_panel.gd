class_name CharacterPanel
extends Control
## The hero at a glance: a drawer sliding down from the top edge over HEIGHT of
## the screen, opened with C. Built in code in the inventory's style; placeholder
## style.

signal opened
signal closed

const HEIGHT := 0.4
const SLIDE_SECONDS := 0.22
const BACKGROUND := InventoryPanel.BACKGROUND
const ACCENT := InventoryPanel.ACCENT
const TEXT := InventoryPanel.TEXT
const MUTED := InventoryPanel.MUTED

var _player: Player
var _drawer: PanelContainer
var _level: Label
var _hp: Label
var _open := false
var _reveal := 0.0
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer = PanelContainer.new()
	_drawer.name = "Drawer"
	_drawer.anchor_right = 1.0
	_drawer.anchor_bottom = HEIGHT
	var box := StyleBoxFlat.new()
	box.bg_color = BACKGROUND
	box.set_content_margin_all(28)
	_drawer.add_theme_stylebox_override("panel", box)
	add_child(_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	_drawer.add_child(column)
	column.add_child(_label(tr("Character"), 44, ACCENT))
	_level = _label("", 32, TEXT)
	column.add_child(_level)
	_hp = _label("", 32, TEXT)
	column.add_child(_hp)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	column.add_child(_label(tr("C  close"), 24, MUTED))
	_set_reveal(0.0)
	resized.connect(func() -> void: _set_reveal(_reveal))


func bind(player: Player) -> void:
	_player = player


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
	return "%s\n%s" % [_level.text, _hp.text]


func _process(_delta: float) -> void:
	if _open:
		_refresh()


func _refresh() -> void:
	if _player == null:
		return
	_level.text = tr("Hero Level: %d") % _player.level
	_hp.text = tr("HP: %d/%d") % [_player.hp, _player.max_hp]


func _slide_to(target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_reveal, _reveal, target, SLIDE_SECONDS)


## 0 is hidden past the top edge, 1 fully open.
func _set_reveal(amount: float) -> void:
	_reveal = amount
	var shift := -(1.0 - amount) * size.y * HEIGHT
	_drawer.offset_top = shift
	_drawer.offset_bottom = shift
	_drawer.modulate.a = clampf(amount * 1.5, 0.0, 1.0)
	_drawer.visible = amount > 0.0


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
