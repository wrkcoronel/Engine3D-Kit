class_name PauseMenuStyle
extends RefCounted

const BACKDROP_SHADER_PATH := "res://contexts/pause_menu/materials/pause_backdrop.gdshader"
const FOOTER_COLOR := Color(0.0, 0.0, 0.0, 0.0)
const DIVIDER_COLOR := Color(0.76, 0.79, 0.82, 0.24)
const TEXT_BRIGHT := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.69, 0.73, 0.88)
const TEXT_HINT := Color(0.78, 0.80, 0.84, 0.90)


static func ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial"])
	return font


static func backdrop_material() -> ShaderMaterial:
	var shader := load(BACKDROP_SHADER_PATH) as Shader
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("settings_mode", 0.0)
	return material


static func empty_box(pad_x: float = 0.0, pad_y: float = 6.0) -> StyleBoxEmpty:
	var box := StyleBoxEmpty.new()
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


static func apply_title_style(label: Label) -> void:
	label.add_theme_font_override("font", ui_font())
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", TEXT_BRIGHT)


static func apply_menu_button_style(button: Button) -> void:
	button.custom_minimum_size = Vector2(200.0, 36.0)
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", ui_font())
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	button.add_theme_color_override("font_pressed_color", TEXT_BRIGHT)
	var clean_box := empty_box(2.0, 4.0)
	button.add_theme_stylebox_override("normal", clean_box)
	button.add_theme_stylebox_override("hover", clean_box)
	button.add_theme_stylebox_override("pressed", clean_box)
	button.add_theme_stylebox_override("focus", clean_box)


static func apply_arrow_button_style(button: Button) -> void:
	button.custom_minimum_size = Vector2(28.0, 28.0)
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", ui_font())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	button.add_theme_color_override("font_pressed_color", TEXT_BRIGHT)
	var clean_box := empty_box(4.0, 2.0)
	button.add_theme_stylebox_override("normal", clean_box)
	button.add_theme_stylebox_override("hover", clean_box)
	button.add_theme_stylebox_override("pressed", clean_box)
	button.add_theme_stylebox_override("focus", clean_box)


static func apply_row_label_style(label: Label, bright: bool) -> void:
	label.add_theme_font_override("font", ui_font())
	label.add_theme_font_size_override("font_size", 17)
	if bright:
		label.add_theme_color_override("font_color", TEXT_BRIGHT)
	else:
		label.add_theme_color_override("font_color", TEXT_MUTED)


static func apply_footer_style(label: Label) -> void:
	label.add_theme_font_override("font", ui_font())
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", TEXT_HINT)


static func make_divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = DIVIDER_COLOR
	line.custom_minimum_size = Vector2(0.0, 1.0)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
