@tool
extends PanelContainer
## The sculpting tools beside the 3D view: which brush, how big, how strong, how
## soft. Editor tooling, so its text isn't translated.

const TOOL_NAMES: Array[String] = ["Raise", "Lower", "Smooth", "Flatten", "Restore"]

var brush: SculptBrush

var _tool_buttons: Array[Button] = []
var _size_slider: HSlider
var _size_label: Label
var _strength_slider: HSlider
var _strength_label: Label
var _softness_slider: HSlider
var _softness_label: Label


func _init(the_brush: SculptBrush) -> void:
	brush = the_brush
	custom_minimum_size = Vector2(190.0, 0.0)
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "Sculpt terrain"
	box.add_child(title)
	var group := ButtonGroup.new()
	for k in TOOL_NAMES.size():
		var button := Button.new()
		button.text = "%d  %s" % [k + 1, TOOL_NAMES[k]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_pick_tool.bind(k))
		box.add_child(button)
		_tool_buttons.append(button)
	_size_label = Label.new()
	box.add_child(_size_label)
	_size_slider = _slider(box, SculptBrush.MIN_RADIUS, SculptBrush.MAX_RADIUS, 0.5)
	_strength_label = Label.new()
	box.add_child(_strength_label)
	_strength_slider = _slider(box, 0.25, 20.0, 0.25)
	_softness_label = Label.new()
	box.add_child(_softness_label)
	_softness_slider = _slider(box, 0.0, 1.0, 0.05)
	var hints := Label.new()
	hints.text = "Left drag: sculpt\nShift: raise <-> lower\nCtrl + wheel or [ ]: size\nCtrl + Z: undo\nSaved after every stroke"
	hints.add_theme_font_size_override(&"font_size", 12)
	hints.modulate = Color(1.0, 1.0, 1.0, 0.7)
	box.add_child(hints)
	refresh()


## Shows the brush as it is now.
func refresh() -> void:
	_tool_buttons[brush.tool].set_pressed_no_signal(true)
	_size_slider.set_value_no_signal(brush.radius)
	_strength_slider.set_value_no_signal(brush.strength)
	_softness_slider.set_value_no_signal(brush.softness)
	_size_label.text = "Size: %.1f m" % (brush.radius * 2.0)
	_strength_label.text = "Strength: %.2f m/s" % brush.strength
	_softness_label.text = "Softness: %d%%" % roundi(brush.softness * 100.0)


func _slider(box: VBoxContainer, low: float, high: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value_changed.connect(_read_sliders.unbind(1))
	box.add_child(slider)
	return slider


func _pick_tool(k: int) -> void:
	brush.tool = k as SculptBrush.Tool
	refresh()


func _read_sliders() -> void:
	brush.radius = _size_slider.value
	brush.strength = _strength_slider.value
	brush.softness = _softness_slider.value
	refresh()
