@tool
extends PanelContainer
## The painting tools beside the 3D view, the Sculpt tab's sister: which surface,
## how big, how strong, how soft. Editor tooling, so its text isn't translated.

const SWATCH_SIZE := 16
const ERASE_KEY := "0"

var brush: PaintBrush

var _buttons: Array[Button] = []
var _erase_button: Button
var _size_slider: HSlider
var _size_label: Label
var _strength_slider: HSlider
var _strength_label: Label
var _softness_slider: HSlider
var _softness_label: Label


func _init(the_brush: PaintBrush) -> void:
	brush = the_brush
	custom_minimum_size = Vector2(190.0, 0.0)
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "Paint ground"
	box.add_child(title)
	var group := ButtonGroup.new()
	for k in TerrainPaint.LAYERS:
		var button := _tool_button(box, group, "%d  %s" % [k + 1, TerrainPaint.NAMES[k]], k)
		button.icon = _swatch(TerrainPaint.SWATCHES[k])
		_buttons.append(button)
	_erase_button = _tool_button(box, group, "%s  Erase" % ERASE_KEY, TerrainPaint.ERASE)
	_size_label = Label.new()
	box.add_child(_size_label)
	_size_slider = _slider(box, PaintBrush.MIN_RADIUS, PaintBrush.MAX_RADIUS, 0.5)
	_strength_label = Label.new()
	box.add_child(_strength_label)
	_strength_slider = _slider(box, 0.25, 12.0, 0.25)
	_softness_label = Label.new()
	box.add_child(_softness_label)
	_softness_slider = _slider(box, 0.0, 1.0, 0.05)
	var hints := Label.new()
	hints.text = "Left drag: paint\nShift: erase\nCtrl + wheel or [ ]: size\nCtrl + Z: undo\nSaved after every stroke"
	hints.add_theme_font_size_override(&"font_size", 12)
	hints.modulate = Color(1.0, 1.0, 1.0, 0.7)
	box.add_child(hints)
	refresh()


## Shows the brush as it is now.
func refresh() -> void:
	var picked := _erase_button if brush.surface == TerrainPaint.ERASE else _buttons[brush.surface]
	picked.set_pressed_no_signal(true)
	_size_slider.set_value_no_signal(brush.radius)
	_strength_slider.set_value_no_signal(brush.strength)
	_softness_slider.set_value_no_signal(brush.softness)
	_size_label.text = "Size: %.1f m" % (brush.radius * 2.0)
	_strength_label.text = "Strength: %.2f /s" % brush.strength
	_softness_label.text = "Softness: %d%%" % roundi(brush.softness * 100.0)


func _tool_button(box: VBoxContainer, group: ButtonGroup, text: String, surface: int) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.button_group = group
	button.pressed.connect(_pick.bind(surface))
	box.add_child(button)
	return button


func _swatch(color: Color) -> ImageTexture:
	var image := Image.create_empty(SWATCH_SIZE, SWATCH_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _slider(box: VBoxContainer, low: float, high: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value_changed.connect(_read_sliders.unbind(1))
	box.add_child(slider)
	return slider


func _pick(surface: int) -> void:
	brush.surface = surface
	refresh()


func _read_sliders() -> void:
	brush.radius = _size_slider.value
	brush.strength = _strength_slider.value
	brush.softness = _softness_slider.value
	refresh()
