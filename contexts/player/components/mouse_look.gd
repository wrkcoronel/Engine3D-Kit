## OLHAR: mouse gira o corpo (yaw) e a cabeca (pitch). Esc solta o mouse, clique prende.
class_name MouseLook
extends Node

const SENS := 0.002

@onready var _body: CharacterBody3D = get_parent()
@onready var _head: Node3D = _body.get_node("Head")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_body.rotate_y(-event.relative.x * SENS)
		_head.rotation.x = clamp(_head.rotation.x - event.relative.y * SENS, deg_to_rad(-89), deg_to_rad(89))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
