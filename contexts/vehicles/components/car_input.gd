class_name CarInput
extends RefCounted

var from_keyboard := true
var throttle := 0.0
var steering := 0.0
var handbraking := false


func read_keyboard() -> void:
	var forward := _key_amount(KEY_W, KEY_UP)
	var backward := _key_amount(KEY_S, KEY_DOWN)
	var left := _key_amount(KEY_A, KEY_LEFT)
	var right := _key_amount(KEY_D, KEY_RIGHT)
	throttle = forward - backward
	steering = left - right
	handbraking = Input.is_physical_key_pressed(KEY_SPACE)


func clear() -> void:
	throttle = 0.0
	steering = 0.0
	handbraking = false


func _key_amount(key: Key, alternative_key: Key) -> float:
	if Input.is_physical_key_pressed(key):
		return 1.0
	if Input.is_physical_key_pressed(alternative_key):
		return 1.0
	return 0.0
