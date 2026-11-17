extends CharacterBody3D

const GRAVITY_MULTIPLIER := 2.0
const MIN_TRACTION := 0.35
const DIRECTION_CHANGE_SPEED := 1.5

@export var max_speed := 138.9
@export var reverse_max_speed := 12.0
@export var acceleration := 11.0
@export_range(0.0, 1.0) var accel_falloff := 1.0
@export var braking := 45.0
@export var friction := 6.0
@export var wheelbase := 2.8
@export var max_steer_angle_deg := 32.0
@export var max_lat_accel := 11.0
@export var steer_response := 4.0
@export var steer_return := 7.0
@export var enter_distance := 4.0

@export_group("Derrapagem")
@export var drift_steer_boost := 0.8

var _driver: CharacterBody3D
var _vel := Vector3.ZERO
var _move_sign := 1.0
var _handbraking := false
var _steer_wheel := 0.0

@onready var _hud: Speedometer = $Speedometer
@onready var _cam: CarCamera = $Camera
@onready var _visual: Node3D = $Visual
@onready var _tires: CarTireFx = $TireFx
@onready var _tilt: CarTilt = $Tilt
@onready var _grip: CarGrip = $Grip


func _ready() -> void:
	floor_snap_length = 0.4
	_tires.setup(self, _visual)
	_hud.visible = false
	_cam.snap()


func _process(delta: float) -> void:
	_tilt.update(delta, self, _visual)
	if _driver:
		_cam.follow(delta)
		_hud.update_drive(
			delta, _vel.length(), _move_sign, _handbraking, max_speed, reverse_max_speed
		)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var motion := event as InputEventMouseMotion
	var button := event as InputEventMouseButton
	if key and key.pressed and not key.echo and key.keycode == KEY_E:
		if _driver:
			_exit()
		else:
			_try_enter()
	elif _driver == null:
		return
	elif motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam.add_look(motion.relative)
	elif key and key.pressed and key.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif button and button.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _try_enter() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null or global_position.distance_to(player.global_position) > enter_distance:
		return
	_driver = player
	_cam.snap()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	player.get_node("Collision").set_deferred("disabled", true)
	_cam.make_current()
	_hud.visible = true


func _exit() -> void:
	var player := _driver
	_driver = null
	_hud.visible = false
	player.global_position = global_position - global_basis.x * 2.2 + Vector3.UP * 0.3
	player.rotation.y = rotation.y
	player.velocity = Vector3.ZERO
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.visible = true
	player.get_node("Collision").set_deferred("disabled", false)
	player.get_node("Head/Camera").make_current()


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer_input := 0.0
	var handbraking := false
	if _driver:
		throttle = _axis(KEY_W, KEY_UP) - _axis(KEY_S, KEY_DOWN)
		steer_input = _axis(KEY_A, KEY_LEFT) - _axis(KEY_D, KEY_RIGHT)
		handbraking = Input.is_physical_key_pressed(KEY_SPACE)
	_handbraking = handbraking

	var grounded := is_on_floor()

	var steering := _smooth_steering(steer_input, delta)

	var total_speed := _vel.length()
	var forward_speed_before_turn := _vel.dot(-global_basis.z)
	_update_move_sign(forward_speed_before_turn)

	var traction := _turn(steering, forward_speed_before_turn, total_speed, grounded, delta)

	var forward := -global_basis.z
	var right := global_basis.x
	var forward_speed := _vel.dot(forward)
	var sideways_speed := _vel.dot(right)

	var slope_rotation := Quaternion(Vector3.UP, get_floor_normal() if grounded else Vector3.UP)

	forward_speed = _apply_throttle(forward_speed, throttle, traction, grounded, delta)
	forward_speed = _apply_slope(forward_speed, forward, slope_rotation, throttle, grounded, delta)
	forward_speed = clampf(forward_speed, -reverse_max_speed, max_speed)

	_grip.update(handbraking, total_speed, delta)
	_vel = (
		_grip
		. apply_to_velocity(forward_speed, sideways_speed, forward, right, grounded, delta)
		. limit_length(max_speed)
	)
	_vel = _grip.apply_handbrake_or_rest(_vel, throttle, handbraking, grounded, delta)

	_move(slope_rotation, grounded, delta)

	_tires.update(
		grounded, throttle, handbraking, sideways_speed, forward_speed_before_turn, total_speed
	)


func _smooth_steering(steer_input: float, delta: float) -> float:
	var speed_ratio := clampf(_vel.length() / max_speed, 0.0, 1.0)
	var rate_toward_input := lerpf(steer_response, steer_response * 0.4, speed_ratio)
	var returning_to_center := steer_input == 0.0 or signf(steer_input) != signf(_steer_wheel)
	var wheel_rate := steer_return if returning_to_center else rate_toward_input
	_steer_wheel = move_toward(_steer_wheel, steer_input, wheel_rate * delta)
	return _steer_wheel


func _update_move_sign(forward_speed: float) -> void:
	if absf(forward_speed) > DIRECTION_CHANGE_SPEED:
		_move_sign = signf(forward_speed)


func _turn(
	steering: float,
	forward_speed_before_turn: float,
	total_speed: float,
	grounded: bool,
	delta: float,
) -> float:
	var drift_amount := _grip.drift_amount()
	var steering_speed := (
		_move_sign * lerpf(absf(forward_speed_before_turn), total_speed, drift_amount)
	)
	var drift_steer_multiplier := 1.0 + drift_steer_boost * drift_amount

	var wheel_angle := deg_to_rad(max_steer_angle_deg) * steering
	var turn_rate := steering_speed / wheelbase * tan(wheel_angle) * drift_steer_multiplier
	var turn_rate_limit := max_lat_accel * drift_steer_multiplier / maxf(absf(steering_speed), 1.0)
	turn_rate = clampf(turn_rate, -turn_rate_limit, turn_rate_limit)
	if grounded:
		rotate_y(turn_rate * delta)

	var grip_used := clampf(absf(turn_rate * steering_speed) / max_lat_accel, 0.0, 1.0)
	return maxf(sqrt(1.0 - grip_used * grip_used), MIN_TRACTION)


func _apply_throttle(
	forward_speed: float, throttle: float, traction: float, grounded: bool, delta: float
) -> float:
	if not grounded:
		return forward_speed

	if throttle > 0.0:
		var taper := 1.0 - accel_falloff * clampf(forward_speed / max_speed, 0.0, 1.0)
		var push := braking if forward_speed < -0.5 else acceleration * taper * traction
		return forward_speed + push * delta
	if throttle < 0.0:
		var pull := braking if forward_speed > 0.5 else acceleration
		return forward_speed - pull * delta
	return move_toward(forward_speed, 0.0, friction * delta)


func _apply_slope(
	forward_speed: float,
	forward: Vector3,
	slope_rotation: Quaternion,
	throttle: float,
	grounded: bool,
	delta: float,
) -> float:
	var at_rest := throttle == 0.0 and absf(forward_speed) <= 0.3
	if not grounded or at_rest:
		return forward_speed
	var uphill_amount := (slope_rotation * forward).y
	return forward_speed - absf(get_gravity().y) * GRAVITY_MULTIPLIER * uphill_amount * delta


func _move(slope_rotation: Quaternion, grounded: bool, delta: float) -> void:
	if grounded:
		velocity = slope_rotation * _vel
	else:
		var vertical_speed := velocity.y
		velocity = _vel
		velocity.y = vertical_speed + get_gravity().y * GRAVITY_MULTIPLIER * delta
	move_and_slide()

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if is_on_floor() and horizontal_velocity.length() > 0.01:
		_vel = horizontal_velocity.normalized() * velocity.length()
	else:
		_vel = horizontal_velocity


func _axis(key: Key, alt: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(key) or Input.is_physical_key_pressed(alt) else 0.0
