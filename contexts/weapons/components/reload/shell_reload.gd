class_name ShellReload
extends RefCounted

const SHELL_PATH := "Visual/Corpo/CartuchoRecarga"
const TUBE_MOUTH_PATH := "Visual/Corpo/CartuchoCarga"
const REST_META := "rest_position"
const BELOW_WINDOW := Vector3(0.02, -0.14, 0.04)
const KEY_TIMES: Array[float] = [0.32, 0.5, 0.62, 0.72, 1.0]
const KEY_POSITIONS: Array[Vector3] = [
	Vector3(0.0, -0.085, -0.118),
	Vector3(0.0, -0.038, -0.118),
	Vector3(0.0, -0.027, -0.112),
	Vector3(0.0, -0.0165, -0.112),
	Vector3(0.0, -0.0165, -0.19),
]
const KEY_TILTS: Array[float] = [0.45, 0.45, 0.0, 0.0, 0.0]
const WINDOW_KEY := 1
const START_TILT := 1.1
const PUSH_START := 0.72
const LAY_DOWN_START := 0.62
const LAY_DOWN_LENGTH := 0.1
const THUMB_PRESS := Vector3(0.0, 0.004, 0.0)
const THUMB_SLIDE := Vector3(0.0, 0.0, -0.006)
const INSIDE_TUBE := Vector3(0.0, -0.0165, -0.19)

var _camera: Camera3D
var _model: Node3D
var _pose: GunReloadPose


func _init(camera: Camera3D, model: Node3D, pose: GunReloadPose) -> void:
	_camera = camera
	_model = model
	_pose = pose


static func stop(model: Node3D) -> void:
	var shell := model.get_node_or_null(SHELL_PATH) as Node3D
	if shell != null:
		shell.visible = false
	var tube_mouth := model.get_node_or_null(TUBE_MOUTH_PATH) as Node3D
	if tube_mouth != null and tube_mouth.has_meta(REST_META):
		tube_mouth.position = tube_mouth.get_meta(REST_META)


func add_steps(
	tween: Tween,
	turn_time: float,
	time_per_shell: float,
	shell_count: int,
	on_shell_click: Callable,
	on_shell_inside: Callable
) -> void:
	_remember_tube_mouth_rest()
	var push_time := time_per_shell * PUSH_START
	var slide_time := time_per_shell * (1.0 - PUSH_START)
	tween.tween_property(_pose, "turn", 1.0, turn_time)
	for shell_index: int in shell_count:
		var first_shell := shell_index == 0
		var push := tween.tween_method(_move_shell.bind(first_shell), 0.0, PUSH_START, push_time)
		push.set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(on_shell_click)
		var slide := tween.tween_method(_move_shell.bind(false), PUSH_START, 1.0, slide_time)
		slide.set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(on_shell_inside)
	tween.tween_callback(_finish)
	tween.tween_property(_pose, "turn", 0.0, turn_time)


func _remember_tube_mouth_rest() -> void:
	var tube_mouth := _model.get_node_or_null(TUBE_MOUTH_PATH) as Node3D
	if tube_mouth == null:
		return
	if not tube_mouth.has_meta(REST_META):
		tube_mouth.set_meta(REST_META, tube_mouth.position)


func _finish() -> void:
	_pose.offset = Vector3.ZERO
	stop(_model)


func _move_shell(progress: float, moves_tube_mouth: bool) -> void:
	var shell := _model.get_node(SHELL_PATH) as Node3D
	shell.position = _shell_position(shell.get_parent() as Node3D, progress)
	shell.rotation = Vector3(_shell_tilt(progress), 0.0, 0.0)
	shell.visible = progress < 0.99
	_pose.offset = _thumb_push(progress)
	if moves_tube_mouth:
		_move_tube_mouth_round(progress)


func _shell_position(parent: Node3D, progress: float) -> Vector3:
	var camera_transform := _camera.global_transform
	var window := parent.global_transform * KEY_POSITIONS[WINDOW_KEY]
	var window_seen_by_camera := camera_transform.affine_inverse() * window
	var hand_start := camera_transform * (window_seen_by_camera + BELOW_WINDOW)
	var shell_position := parent.global_transform.affine_inverse() * hand_start
	var previous_time := 0.0
	for key_index: int in KEY_TIMES.size():
		var segment := smoothstep(previous_time, KEY_TIMES[key_index], progress)
		shell_position = shell_position.lerp(KEY_POSITIONS[key_index], segment)
		previous_time = KEY_TIMES[key_index]
	return shell_position


func _shell_tilt(progress: float) -> float:
	var tilt := START_TILT
	var previous_time := 0.0
	for key_index: int in KEY_TIMES.size():
		var segment := smoothstep(previous_time, KEY_TIMES[key_index], progress)
		tilt = lerpf(tilt, KEY_TILTS[key_index], segment)
		previous_time = KEY_TIMES[key_index]
	return tilt


func _thumb_push(progress: float) -> Vector3:
	var lay_down := clampf((progress - LAY_DOWN_START) / LAY_DOWN_LENGTH, 0.0, 1.0)
	var push_forward := clampf((progress - PUSH_START) / (1.0 - PUSH_START), 0.0, 1.0)
	var press := sin(PI * lay_down)
	var slide := sin(PI * push_forward)
	var push_in_gun_space := THUMB_PRESS * press + THUMB_SLIDE * slide
	return _model.basis.orthonormalized() * push_in_gun_space


func _move_tube_mouth_round(progress: float) -> void:
	var tube_mouth := _model.get_node_or_null(TUBE_MOUTH_PATH) as Node3D
	if tube_mouth == null:
		return
	var rest: Vector3 = tube_mouth.get_meta(REST_META)
	var lifted := Vector3(rest.x, INSIDE_TUBE.y, rest.z)
	var raised := rest.lerp(lifted, smoothstep(0.0, 0.08, progress))
	tube_mouth.position = raised.lerp(INSIDE_TUBE, smoothstep(0.08, 0.3, progress))
