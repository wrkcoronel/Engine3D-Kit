class_name MouseLook
extends Node

const SENS := 0.002

var _body: CharacterBody3D
var _head: Node3D
var _rig: PlayerRig


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func bind(body: CharacterBody3D, head: Node3D, rig: PlayerRig) -> void:
	_body = body
	_head = head
	_rig = rig


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	var key := event as InputEventKey
	var button := event as InputEventMouseButton
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(motion.relative)
	elif key and key.pressed and key.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif button and button.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _turn(relative: Vector2) -> void:
	if _body == null:
		return
	var sensitivity := SENS * _rig.look_sensitivity_scale
	_body.rotate_y(-relative.x * sensitivity)
	var pitch := _head.rotation.x - relative.y * sensitivity
	_head.rotation.x = clampf(pitch, deg_to_rad(-89), deg_to_rad(89))
