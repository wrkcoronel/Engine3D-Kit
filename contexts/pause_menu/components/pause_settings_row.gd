class_name PauseSettingsRow
extends PanelContainer

signal stepped(delta: int)
signal activated
signal hovered(description: String)

const VALUE_AREA_WIDTH := 240.0

var _description := ""
var _is_selector := false
var _is_disabled := false
var _name_label: Label
var _value_label: Label
var _prev_button: Button
var _next_button: Button


func setup_selector(option_name: String, initial_value: String, description: String) -> void:
	_is_selector = true
	_description = description
	_build_row(option_name, initial_value)


func setup_action(option_name: String, action_text: String, description: String) -> void:
	_is_selector = false
	_description = description
	_build_row(option_name, action_text)


func set_value_text(text: String) -> void:
	if _value_label != null:
		_value_label.text = text


func set_row_disabled(disabled: bool) -> void:
	_is_disabled = disabled
	if _prev_button != null:
		_prev_button.disabled = disabled
	if _next_button != null:
		_next_button.disabled = disabled
	var alpha := 0.42 if disabled else 1.0
	modulate = Color(1.0, 1.0, 1.0, alpha)


func _build_row(option_name: String, value_text: String) -> void:
	add_theme_stylebox_override("panel", PauseMenuStyle.empty_box(8.0, 11.0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	var layout := HBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	_name_label = Label.new()
	_name_label.text = option_name
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseMenuStyle.apply_row_label_style(_name_label, false)
	layout.add_child(_name_label)

	var right_box := HBoxContainer.new()
	right_box.custom_minimum_size = Vector2(VALUE_AREA_WIDTH, 0.0)
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_box.add_theme_constant_override("separation", 8)
	layout.add_child(right_box)

	if _is_selector:
		_prev_button = Button.new()
		_prev_button.text = "<"
		PauseMenuStyle.apply_arrow_button_style(_prev_button)
		_prev_button.pressed.connect(_on_prev_pressed)
		_prev_button.mouse_entered.connect(_on_mouse_entered)
		right_box.add_child(_prev_button)

	_value_label = Label.new()
	_value_label.text = value_text
	_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseMenuStyle.apply_row_label_style(_value_label, false)
	right_box.add_child(_value_label)

	_next_button = Button.new()
	_next_button.text = ">"
	PauseMenuStyle.apply_arrow_button_style(_next_button)
	_next_button.pressed.connect(_on_next_pressed)
	_next_button.mouse_entered.connect(_on_mouse_entered)
	right_box.add_child(_next_button)


func _on_mouse_entered() -> void:
	if _is_disabled:
		return
	PauseMenuStyle.apply_row_label_style(_name_label, true)
	PauseMenuStyle.apply_row_label_style(_value_label, true)
	hovered.emit(_description)


func _on_mouse_exited() -> void:
	PauseMenuStyle.apply_row_label_style(_name_label, false)
	PauseMenuStyle.apply_row_label_style(_value_label, false)


func _on_gui_input(event: InputEvent) -> void:
	if _is_disabled:
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if _is_selector:
		stepped.emit(1)
	else:
		activated.emit()


func _on_prev_pressed() -> void:
	if _is_disabled:
		return
	stepped.emit(-1)


func _on_next_pressed() -> void:
	if _is_disabled:
		return
	if _is_selector:
		stepped.emit(1)
	else:
		activated.emit()
