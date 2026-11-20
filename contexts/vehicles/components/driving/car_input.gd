class_name CarInput
extends RefCounted

var from_keyboard := true
var throttle := 0.0
var steering := 0.0
var handbraking := false
var wants_upright := false
var shift_up_pressed := false
var shift_down_pressed := false
var gearbox_mode_pressed := false

var _shift_up_held := false
var _shift_down_held := false
var _gearbox_mode_held := false
var _scroll_shift_up_pending := false
var _scroll_shift_down_pending := false


func read_keyboard() -> void:
	var forward := _key_amount(KEY_W, KEY_UP)
	var backward := _key_amount(KEY_S, KEY_DOWN)
	var left := _key_amount(KEY_A, KEY_LEFT)
	var right := _key_amount(KEY_D, KEY_RIGHT)
	throttle = forward - backward
	steering = left - right
	handbraking = Input.is_physical_key_pressed(KEY_SPACE)
	wants_upright = Input.is_physical_key_pressed(KEY_R)
	_read_gear_keys()


func update(has_driver: bool) -> void:
	if not from_keyboard:
		return
	if has_driver:
		read_keyboard()
		return
	clear()


func clear() -> void:
	throttle = 0.0
	steering = 0.0
	handbraking = false
	wants_upright = false
	shift_up_pressed = false
	shift_down_pressed = false
	gearbox_mode_pressed = false
	_scroll_shift_up_pending = false
	_scroll_shift_down_pending = false


func register_scroll(button_index: MouseButton) -> void:
	if button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll_shift_up_pending = true
	if button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll_shift_down_pending = true


func _key_amount(key: Key, alternative_key: Key) -> float:
	if Input.is_physical_key_pressed(key):
		return 1.0
	if Input.is_physical_key_pressed(alternative_key):
		return 1.0
	return 0.0


func _read_gear_keys() -> void:
	var shift_up_held_now := Input.is_physical_key_pressed(KEY_SHIFT)
	var shift_down_held_now := Input.is_physical_key_pressed(KEY_CTRL)
	var gearbox_mode_held_now := Input.is_physical_key_pressed(KEY_M)
	shift_up_pressed = _shift_up_just_pressed(shift_up_held_now)
	shift_down_pressed = _shift_down_just_pressed(shift_down_held_now)
	gearbox_mode_pressed = gearbox_mode_held_now and not _gearbox_mode_held
	_shift_up_held = shift_up_held_now
	_shift_down_held = shift_down_held_now
	_gearbox_mode_held = gearbox_mode_held_now
	_scroll_shift_up_pending = false
	_scroll_shift_down_pending = false


func _shift_up_just_pressed(held_now: bool) -> bool:
	if _scroll_shift_up_pending:
		return true
	return held_now and not _shift_up_held


func _shift_down_just_pressed(held_now: bool) -> bool:
	if _scroll_shift_down_pending:
		return true
	return held_now and not _shift_down_held
