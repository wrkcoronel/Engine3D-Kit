class_name CarCamera
extends Camera3D

@export var cam_distance := 6.5
@export var cam_height := 3.0
@export var cam_look_height := 1.2
@export var cam_yaw_smooth := 3.0
@export var cam_pos_smooth := 60.0
@export var cam_mouse_sens := 0.003
@export var cam_pitch_min_deg := -5.0
@export var cam_pitch_max_deg := 75.0
@export var cam_recenter_delay := 1.5
@export var cam_recenter_smooth := 3.0

var _look_yaw := 0.0
var _pitch := 0.0
var _idle := 0.0
var _cam_yaw := 0.0

@onready var _car: Node3D = get_parent()


func _ready() -> void:
	top_level = true


func snap() -> void:
	_update(0.0, true)


func follow(delta: float) -> void:
	_update(delta, false)


func add_look(relative: Vector2) -> void:
	_look_yaw -= relative.x * cam_mouse_sens
	_pitch = clampf(
		_pitch + relative.y * cam_mouse_sens,
		deg_to_rad(cam_pitch_min_deg),
		deg_to_rad(cam_pitch_max_deg)
	)
	_idle = 0.0


func _base_pitch() -> float:
	return atan2(cam_height, cam_distance)


func _update(delta: float, snapping: bool) -> void:
	var car_yaw := _car.rotation.y
	_cam_yaw = (
		car_yaw if snapping else lerp_angle(_cam_yaw, car_yaw, 1.0 - exp(-cam_yaw_smooth * delta))
	)
	if snapping:
		_look_yaw = 0.0
		_pitch = _base_pitch()
		_idle = 0.0
	else:
		_idle += delta
		if _idle > cam_recenter_delay:
			var k := 1.0 - exp(-cam_recenter_smooth * delta)
			_look_yaw = lerp_angle(_look_yaw, 0.0, k)
			_pitch = lerpf(_pitch, _base_pitch(), k)
	var dist := Vector2(cam_distance, cam_height).length()
	var offset := (
		Basis(Vector3.UP, _cam_yaw + _look_yaw)
		* Vector3(0.0, sin(_pitch) * dist, cos(_pitch) * dist)
	)
	var target := _car.global_position + offset
	global_position = (
		target if snapping else global_position.lerp(target, 1.0 - exp(-cam_pos_smooth * delta))
	)
	look_at(_car.global_position + Vector3.UP * cam_look_height)
