class_name GunSway
extends Node

@export var sway_amount := 0.0015
@export var sway_max := 0.08
@export var sway_smooth := 10.0
@export var bob_amount := Vector2(0.012, 0.01)
@export var bob_speed := 9.0

var pos := Vector3.ZERO
var rot := Vector3.ZERO

var _mouse_delta := Vector2.ZERO
var _sway := Vector2.ZERO
var _bob_t := 0.0
var _bob_amp := 0.0


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += motion.relative


func update(delta: float, body: CharacterBody3D, steady: float) -> void:
	var target := (_mouse_delta * sway_amount).limit_length(sway_max) * steady
	_mouse_delta = Vector2.ZERO
	_sway = _sway.lerp(target, 1.0 - exp(-sway_smooth * delta))

	var speed := 0.0
	if body and body.is_on_floor():
		speed = Vector2(body.velocity.x, body.velocity.z).length()
	_bob_amp = lerpf(_bob_amp, clampf(speed / 6.0, 0.0, 1.0), 1.0 - exp(-8.0 * delta))
	_bob_t += delta * bob_speed * _bob_amp
	var bob := (
		Vector3(cos(_bob_t) * bob_amount.x, absf(sin(_bob_t)) * bob_amount.y, 0.0)
		* _bob_amp
		* steady
	)

	pos = bob + Vector3(-_sway.x * 0.5, _sway.y * 0.5, 0.0)
	rot = Vector3(-_sway.y, -_sway.x, -_sway.x * 0.5)
