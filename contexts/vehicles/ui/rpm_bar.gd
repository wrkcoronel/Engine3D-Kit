class_name RpmBar
extends Control

const SHIFT_START_FRACTION := 0.88
const FILL_SMOOTHING := 12.0

const TRACK_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const TRACK_SHIFT_COLOR := Color(1.0, 0.2, 0.2, 0.4)
const FILL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const FILL_SHIFT_COLOR := Color(1.0, 0.2, 0.2, 1.0)

var target_rpm := 0.0
var redline_rpm := 6800.0

var _shown_rpm := 0.0


static func fill_fraction(rpm: float, redline: float) -> float:
	if redline <= 0.0:
		return 0.0
	return clampf(rpm / redline, 0.0, 1.0)


static func white_fraction(fill: float) -> float:
	return minf(fill, SHIFT_START_FRACTION)


static func red_fraction(fill: float) -> float:
	return maxf(fill - SHIFT_START_FRACTION, 0.0)


func _process(delta: float) -> void:
	var follow := 1.0 - exp(-FILL_SMOOTHING * delta)
	_shown_rpm = lerpf(_shown_rpm, target_rpm, follow)
	queue_redraw()


func _draw() -> void:
	var fill := fill_fraction(_shown_rpm, redline_rpm)
	_draw_track()
	_draw_fill(fill)


func _draw_track() -> void:
	var shift_start_x := size.x * SHIFT_START_FRACTION
	var normal_rect := Rect2(0.0, 0.0, shift_start_x, size.y)
	var shift_rect := Rect2(shift_start_x, 0.0, size.x - shift_start_x, size.y)
	draw_rect(normal_rect, TRACK_COLOR)
	draw_rect(shift_rect, TRACK_SHIFT_COLOR)


func _draw_fill(fill: float) -> void:
	var white_width := size.x * white_fraction(fill)
	var red_width := size.x * red_fraction(fill)
	var red_start_x := size.x * SHIFT_START_FRACTION
	var white_rect := Rect2(0.0, 0.0, white_width, size.y)
	var red_rect := Rect2(red_start_x, 0.0, red_width, size.y)
	draw_rect(white_rect, FILL_COLOR)
	draw_rect(red_rect, FILL_SHIFT_COLOR)
