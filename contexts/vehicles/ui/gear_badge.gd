class_name GearBadge
extends Control

const FONT_SIZE := 40
const FONT_EMBOLDEN := 0.5
const MANUAL_COLOR := Color(1.0, 0.1, 0.1, 1.0)
const AUTO_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_COLOR := Color(0.0, 0.0, 0.0, 1.0)

var gear_text := "N":
	set(new_text):
		gear_text = new_text
		queue_redraw()

var manual := true:
	set(new_manual):
		manual = new_manual
		queue_redraw()

var _font := ItalicFont.create(FONT_EMBOLDEN)


static func background_color(is_manual: bool) -> Color:
	if is_manual:
		return MANUAL_COLOR
	return AUTO_COLOR


func _draw() -> void:
	var background := Rect2(Vector2.ZERO, size)
	draw_rect(background, background_color(manual))
	_draw_gear_text()


func _draw_gear_text() -> void:
	var text_size := _font.get_string_size(gear_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var ascent := _font.get_ascent(FONT_SIZE)
	var descent := _font.get_descent(FONT_SIZE)
	var text_left := (size.x - text_size.x) / 2.0
	var text_top := (size.y - (ascent + descent)) / 2.0
	var baseline := Vector2(text_left, text_top + ascent)
	draw_string(_font, baseline, gear_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
