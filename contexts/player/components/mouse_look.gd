class_name MouseLook
extends Node

const SENS := 0.002

var sensitivity_scale := 1.0

@onready var _body: CharacterBody3D = get_parent()
@onready var _head: Node3D = _body.get_node("Head")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	var key := event as InputEventKey
	var button := event as InputEventMouseButton
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := SENS * sensitivity_scale
		_body.rotate_y(-motion.relative.x * sensitivity)
		_head.rotation.x = clamp(
			_head.rotation.x - motion.relative.y * sensitivity, deg_to_rad(-89), deg_to_rad(89)
		)
	elif key and key.pressed and key.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif button and button.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
