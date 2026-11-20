class_name SpeedReadout
extends Control

const DIGIT_COUNT := 3
const MAX_SPEED := 999
const FONT_SIZE := 76
const FONT_EMBOLDEN := 0.5
const PADDING_COLOR := Color(0.45, 0.47, 0.52, 1.0)
const DIGIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var speed_kmh := 0:
	set(new_speed):
		speed_kmh = clampi(new_speed, 0, MAX_SPEED)
		queue_redraw()

var _font := ItalicFont.create(FONT_EMBOLDEN)


static func shown_text(kmh: int) -> String:
	var clamped_speed := clampi(kmh, 0, MAX_SPEED)
	return str(clamped_speed)


static func padding_text(kmh: int) -> String:
	var shown_length := shown_text(kmh).length()
	var padding_length := maxi(DIGIT_COUNT - shown_length, 0)
	return "0".repeat(padding_length)


func _draw() -> void:
	var padding := padding_text(speed_kmh)
	var shown := shown_text(speed_kmh)
	var full_width := _text_width(padding + shown)
	var padding_width := _text_width(padding)
	var left_edge := size.x - full_width
	var baseline_y := _font.get_ascent(FONT_SIZE)
	var padding_position := Vector2(left_edge, baseline_y)
	var shown_position := Vector2(left_edge + padding_width, baseline_y)
	_draw_text(padding_position, padding, PADDING_COLOR)
	_draw_text(shown_position, shown, DIGIT_COLOR)


func _draw_text(text_position: Vector2, text: String, color: Color) -> void:
	draw_string(_font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _text_width(text: String) -> float:
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	return text_size.x
