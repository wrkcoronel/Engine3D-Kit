class_name TachometerDial
extends Control

const START_ANGLE := deg_to_rad(135.0)
const SWEEP_ANGLE := deg_to_rad(270.0)
const RPM_PER_NUMBER := 1000.0
const RPM_PER_SMALL_MARK := 500.0
const NEEDLE_SMOOTHING := 18.0
const ARC_POINTS := 64
const FACE_COLOR := Color(0.03, 0.03, 0.05, 0.72)
const RIM_COLOR := Color(1.0, 1.0, 1.0, 0.25)
const MARK_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const SMALL_MARK_COLOR := Color(1.0, 1.0, 1.0, 0.45)
const REDLINE_COLOR := Color(1.0, 0.12, 0.1, 0.9)
const RPM_FILL_COLOR := Color(1.0, 0.55, 0.1, 0.55)
const NEEDLE_COLOR := Color(1.0, 0.3, 0.12, 1.0)
const NUMBER_FONT_SIZE := 18
const HUB_SIZE := 0.2
const HUB_COLOR := Color(0.08, 0.08, 0.1, 1.0)

var target_rpm := 0.0
var max_rpm := 8000.0
var redline_rpm := 6800.0

var _needle_rpm := 0.0


static func fraction_of_dial(rpm: float, dial_max_rpm: float) -> float:
	return clampf(rpm / dial_max_rpm, 0.0, 1.0)


static func angle_for(fraction: float) -> float:
	return START_ANGLE + SWEEP_ANGLE * fraction


static func dial_max_for(redline: float) -> float:
	var numbers_up_to_redline := ceilf(redline / RPM_PER_NUMBER)
	return (numbers_up_to_redline + 1.0) * RPM_PER_NUMBER


func _process(delta: float) -> void:
	var follow := 1.0 - exp(-NEEDLE_SMOOTHING * delta)
	_needle_rpm = lerpf(_needle_rpm, target_rpm, follow)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center, radius, FACE_COLOR)
	draw_arc(center, radius - 2.0, 0.0, TAU, ARC_POINTS, RIM_COLOR, 2.0, true)
	_draw_redline_zone(center, radius)
	_draw_rpm_fill(center, radius)
	_draw_marks(center, radius)
	_draw_needle(center, radius)


func _draw_redline_zone(center: Vector2, radius: float) -> void:
	var start := angle_for(fraction_of_dial(redline_rpm, max_rpm))
	var end := angle_for(1.0)
	draw_arc(center, radius * 0.86, start, end, ARC_POINTS, REDLINE_COLOR, 10.0, true)


func _draw_rpm_fill(center: Vector2, radius: float) -> void:
	var needle_fraction := fraction_of_dial(_needle_rpm, max_rpm)
	if needle_fraction <= 0.0:
		return
	var end := angle_for(needle_fraction)
	draw_arc(center, radius * 0.94, START_ANGLE, end, ARC_POINTS, RPM_FILL_COLOR, 6.0, true)


func _draw_marks(center: Vector2, radius: float) -> void:
	var mark_count := int(max_rpm / RPM_PER_SMALL_MARK)
	for mark_index: int in mark_count + 1:
		var mark_rpm := mark_index * RPM_PER_SMALL_MARK
		var direction := Vector2.from_angle(angle_for(fraction_of_dial(mark_rpm, max_rpm)))
		var is_number_mark := fmod(mark_rpm, RPM_PER_NUMBER) == 0.0
		if is_number_mark:
			_draw_number_mark(center, radius, direction, mark_rpm)
		else:
			var small_start := center + direction * radius * 0.84
			var small_end := center + direction * radius * 0.9
			draw_line(small_start, small_end, SMALL_MARK_COLOR, 2.0, true)


func _draw_number_mark(center: Vector2, radius: float, direction: Vector2, mark_rpm: float) -> void:
	var mark_start := center + direction * radius * 0.78
	var mark_end := center + direction * radius * 0.9
	draw_line(mark_start, mark_end, MARK_COLOR, 3.0, true)
	var number_text := str(int(mark_rpm / RPM_PER_NUMBER))
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(
		number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE
	)
	var number_center := center + direction * radius * 0.66
	var baseline := number_center + Vector2(-text_size.x / 2.0, text_size.y / 3.0)
	draw_string(
		font, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, MARK_COLOR
	)


func _draw_needle(center: Vector2, radius: float) -> void:
	var needle_fraction := fraction_of_dial(_needle_rpm, max_rpm)
	var direction := Vector2.from_angle(angle_for(needle_fraction))
	var hub_radius := radius * HUB_SIZE
	var needle_start := center + direction * hub_radius
	var tip := center + direction * radius * 0.92
	draw_line(needle_start, tip, NEEDLE_COLOR, 4.0, true)
	draw_circle(center, hub_radius, HUB_COLOR)
	draw_arc(center, hub_radius, 0.0, TAU, ARC_POINTS, NEEDLE_COLOR, 3.0, true)
