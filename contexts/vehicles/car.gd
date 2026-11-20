class_name Car
extends CharacterBody3D

const GRAVITY_MULTIPLIER := 2.0
const MIN_TRACTION := 0.35
const DIRECTION_CHANGE_SPEED := 1.5
const GROUND_STICK_SPEED := 1.0

@export var max_speed := 138.9
@export var reverse_max_speed := 12.0
@export var acceleration := 11.0
@export_range(0.0, 1.0) var accel_falloff := 1.0
@export var braking := 45.0
@export var friction := 6.0
@export var wheelbase := 2.47
@export var max_steer_angle_deg := 32.0
@export var max_lat_accel := 11.0
@export var steer_response := 4.0
@export var steer_return := 7.0
@export var enter_distance := 4.0

@export_group("Derrapagem")
@export var drift_steer_boost := 0.8

var input := CarInput.new()
var _driver: CharacterBody3D
var _vel := Vector3.ZERO
var _move_sign := 1.0
var _handbraking := false
var _steer_wheel := 0.0
var _ground_probe := GroundProbe.new()
var _edge_support := CarEdgeSupport.new()
var _telemetry := CarTelemetry.new()

@onready var _hud: Speedometer = $Speedometer
@onready var _cam: CarCamera = $Camera
@onready var _visual: Node3D = $Visual
@onready var _tires: CarTireFx = $TireFx
@onready var _tilt: CarTilt = $Tilt
@onready var _grip: CarGrip = $Grip
@onready var _wheels: CarWheels = $Wheels
@onready var _body_lean: CarBodyLean = $BodyLean
@onready var _chassis: Node3D = $Visual/Model/Chassis


func _ready() -> void:
	floor_snap_length = 0.4
	_tires.setup(self, _visual)
	_wheels.setup($Visual/Model as Node3D)
	_body_lean.setup(_chassis)
	_hud.visible = false
	_cam.snap()


func _process(delta: float) -> void:
	if _driver:
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
	var player := CarSeat.find_player_near(get_tree(), global_position, enter_distance)
	if player == null:
		return
	_driver = player
	CarSeat.hide_player(player)
	_cam.snap()
	_cam.make_current()
	_hud.visible = true


func _exit() -> void:
	var player := _driver
	_driver = null
	_hud.visible = false
	CarSeat.place_player_beside(player, global_transform)


func _physics_process(delta: float) -> void:
	input.update(_driver != null)
	var throttle := input.throttle
	var steer_input := input.steering
	var handbraking := input.handbraking
	_handbraking = handbraking

	var on_floor_before := is_on_floor()
	var touching_count := get_slide_collision_count()
	_edge_support.update(on_floor_before, _ground_probe.center_ground_drop, touching_count)
	motion_mode = _edge_support.motion_mode()
	var grounded := on_floor_before and not _edge_support.hanging_off_edge

	var steering := _smooth_steering(steer_input, delta)

	var total_speed := _vel.length()
	var forward_speed_before_turn := _vel.dot(-global_basis.z)
	_update_move_sign(forward_speed_before_turn)

	var traction := _turn(steering, forward_speed_before_turn, total_speed, grounded, delta)

	var forward := -global_basis.z
	var right := global_basis.x
	var forward_speed := _vel.dot(forward)
	var sideways_speed := _vel.dot(right)

	var slope_rotation := Quaternion(Vector3.UP, _slope_normal(grounded))

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
	if _edge_support.hanging_off_edge:
		var normals_touched := CarEdgeSupport.contact_normals_of(self)
		_vel += _edge_support.slide_push(normals_touched, _vel.length(), delta)

	var fall_speed := -velocity.y
	_move(slope_rotation, grounded, delta)
	var just_landed := not grounded and is_on_floor()
	if just_landed:
		_on_landed(fall_speed)
	_update_visuals(delta)
	_update_wheels_and_body(delta, steering, throttle, handbraking)

	_tires.update(
		grounded, throttle, handbraking, sideways_speed, forward_speed_before_turn, total_speed
	)
	_report_telemetry(delta)


func _report_telemetry(delta: float) -> void:
	if _driver == null:
		_telemetry.forget()
		return
	_telemetry.report(self, telemetry_frame(), delta)


func telemetry_frame() -> CarTelemetryFrame:
	return CarTelemetryFrame.from_car(self, input, _ground_probe, _edge_support)


func _on_landed(fall_speed: float) -> void:
	_body_lean.land(fall_speed)
	if _driver == null:
		return
	_cam.shake(CarCamera.shake_strength_for_fall(fall_speed))


func _update_wheels_and_body(
	delta: float, steering: float, throttle: float, handbraking: bool
) -> void:
	var grounded := is_on_floor()
	var burning_out := CarGrip.is_burnout(throttle, handbraking, grounded, _vel.length())
	var rear_wheels_locked := handbraking and not burning_out
	var steer_angle := deg_to_rad(max_steer_angle_deg) * steering
	var forward_speed := _vel.dot(-global_basis.z)
	_wheels.update(delta, forward_speed, steer_angle, rear_wheels_locked, burning_out)
	_body_lean.update(delta, _vel, global_basis, grounded, _chassis)


func _update_visuals(delta: float) -> void:
	_ground_probe.sample(get_world_3d().direct_space_state, global_transform, get_rid())
	_tilt.update(delta, self, _visual, _ground_probe)
	if _driver:
		_cam.follow(delta)


func _slope_normal(grounded: bool) -> Vector3:
	if not grounded:
		return Vector3.UP
	if _ground_probe.found_ground_under_most_wheels():
		return _ground_probe.surface_normal
	return get_floor_normal()


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


func _snap_back_onto_ramp(was_grounded: bool) -> void:
	var gravity_strength := absf(get_gravity().y) * GRAVITY_MULTIPLIER
	var center_drop := _ground_probe.center_ground_drop
	var on_floor_now := is_on_floor()
	var speed := _vel.length()
	var edge := _edge_support
	if edge.should_snap_back(was_grounded, on_floor_now, center_drop, speed, gravity_strength):
		apply_floor_snap()


func _move(slope_rotation: Quaternion, grounded: bool, delta: float) -> void:
	if grounded:
		velocity = slope_rotation * _vel
		var climbing := velocity.y > 0.0
		if climbing:
			var slope_normal := slope_rotation * Vector3.UP
			var stick_speed := minf(GROUND_STICK_SPEED, velocity.y / slope_normal.y)
			velocity -= slope_normal * stick_speed
	else:
		var vertical_speed := velocity.y
		velocity = _vel
		velocity.y = vertical_speed + get_gravity().y * GRAVITY_MULTIPLIER * delta
	move_and_slide()
	if not is_on_floor():
		velocity.y = CarFall.limited_vertical_speed(velocity.y, get_real_velocity().y)
	_snap_back_onto_ramp(grounded)
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if is_on_floor() and horizontal_velocity.length() > 0.01:
		_vel = horizontal_velocity.normalized() * velocity.length()
	else:
		_vel = horizontal_velocity
