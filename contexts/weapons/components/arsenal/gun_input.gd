class_name GunInput
extends RefCounted

enum Command { NONE, HOLSTER, RELOAD, SELECT, NEXT, PREVIOUS }

const RELOAD_KEY := KEY_R
const CHECK_KEY := KEY_V
const HOLSTER_KEY := KEY_Q
const WEAPON_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4]
const NO_SELECTION := -1

var command := Command.NONE
var selected_index := NO_SELECTION


func read(event: InputEvent) -> void:
	command = Command.NONE
	selected_index = NO_SELECTION
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		_read_key(key.physical_keycode)
	var button := event as InputEventMouseButton
	if button and button.pressed:
		_read_wheel(button.button_index)


func _read_key(keycode: Key) -> void:
	if keycode == HOLSTER_KEY:
		command = Command.HOLSTER
		return
	if keycode == RELOAD_KEY:
		command = Command.RELOAD
		return
	selected_index = WEAPON_KEYS.find(keycode)
	if selected_index != NO_SELECTION:
		command = Command.SELECT


func _read_wheel(button: MouseButton) -> void:
	if button == MOUSE_BUTTON_WHEEL_UP:
		command = Command.NEXT
	elif button == MOUSE_BUTTON_WHEEL_DOWN:
		command = Command.PREVIOUS
