class_name Car
extends RigidBody3D

const WHEEL_COUNT := 4
const STOPPED_SPEED := 0.5
const SPEED_FOR_HALF_STEER_ANGLE := 25.0
const MAX_CONTACTS_REPORTED := 8

@export var max_speed := 138.9
@export var reverse_max_speed := 12.0
@export var acceleration := 11.0
@export var braking := 12.0
@export var max_steer_angle_deg := 32.0
@export var steer_response := 4.0
@export var steer_return := 7.0
@export var air_drag := 0.4
@export var enter_distance := 4.0

var input := CarInput.new()
var _driver: CharacterBody3D
var _move_sign := 1.0
var _steering := CarSteering.new()
var _body_contacts: Array[CarBodyContact] = []
var _was_on_ground := true
var _front_wheels_spinning := false
var _telemetry := CarTelemetry.new()

@onready var _hud: Speedometer = $Speedometer
@onready var _cam: CarCamera = $Camera
@onready var _visual: Node3D = $Visual
@onready var _tire_fx: CarTireFx = $TireFx
@onready var _wheels: CarWheels = $Wheels
@onready var _suspension: CarSuspension = $Suspension
@onready var _tires: CarTires = $Tires


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = MAX_CONTACTS_REPORTED
	_tire_fx.setup(self, _visual)
	_wheels.setup($Visual/Model as Node3D)
	_hud.visible = false
	_cam.snap()


func _process(delta: float) -> void:
	if _driver == null:
		return
	var speed := linear_velocity.length()
	_hud.update_drive(delta, speed, _move_sign, input.handbraking, max_speed, reverse_max_speed)


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


func is_on_ground() -> bool:
	return _suspension.touching_count() > 0


func telemetry_frame() -> CarTelemetryFrame:
	return CarTelemetryFrame.from_car(self, input, _suspension, _body_contacts)


func _physics_process(delta: float) -> void:
	input.update(_driver != null)
	var forward_speed := linear_velocity.dot(-global_basis.z)
	_update_move_sign(forward_speed)
	var steer_angle := _steer_angle(forward_speed, delta)
	var space_state := get_world_3d().direct_space_state
	_suspension.sample(space_state, global_transform, get_rid(), delta)
	_apply_wheel_forces(steer_angle, forward_speed, delta)
	_apply_air_drag()
	_shake_camera_on_landing()
	_update_visuals(delta, steer_angle, forward_speed)
	_report_telemetry(delta)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_body_contacts = CarBodyContact.list_from(state)


func _update_move_sign(forward_speed: float) -> void:
	if absf(forward_speed) > STOPPED_SPEED:
		_move_sign = signf(forward_speed)


func _steer_angle(forward_speed: float, delta: float) -> float:
	var speed_ratio := absf(forward_speed) / max_speed
	var steering := _steering.smooth(
		input.steering, speed_ratio, steer_response, steer_return, delta
	)
	var max_angle := deg_to_rad(max_steer_angle_deg)
	return CarSteering.wheel_angle(steering, max_angle, forward_speed, SPEED_FOR_HALF_STEER_ANGLE)


func _apply_wheel_forces(steer_angle: float, car_forward_speed: float, delta: float) -> void:
	var mass_per_wheel := mass / WHEEL_COUNT
	_front_wheels_spinning = false
	for wheel_index: int in WHEEL_COUNT:
		var wheel := _suspension.wheels[wheel_index]
		if not wheel.touching:
			continue
		var command := _wheel_command(wheel_index, car_forward_speed)
		_apply_wheel_force(wheel_index, command, steer_angle, mass_per_wheel, delta)


func _apply_wheel_force(
	wheel_index: int,
	command: CarWheelCommand,
	steer_angle: float,
	mass_per_wheel: float,
	delta: float,
) -> void:
	var wheel := _suspension.wheels[wheel_index]
	var load := _suspension.load_on(wheel_index)
	var wheel_forward := _wheel_forward(wheel_index, steer_angle, wheel.normal)
	var wheel_right := wheel_forward.cross(wheel.normal)
	var contact_velocity := _velocity_at(wheel.point)
	var forward_speed := contact_velocity.dot(wheel_forward)
	var sideways_speed := contact_velocity.dot(wheel_right)
	var tire_force := _tires.force_on_ground(
		command, forward_speed, sideways_speed, load, mass_per_wheel, delta
	)
	var spring_push := global_basis.y * load
	var grip_push := wheel_forward * tire_force.x + wheel_right * tire_force.y
	apply_force(spring_push + grip_push, wheel.point - global_position)
	var front := CarSuspension.is_front(wheel_index)
	if front and _tires.is_slipping(command, forward_speed, sideways_speed, load):
		_front_wheels_spinning = true


func _wheel_forward(wheel_index: int, steer_angle: float, ground_normal: Vector3) -> Vector3:
	var forward := -global_basis.z
	if CarSuspension.is_front(wheel_index):
		forward = forward.rotated(global_basis.y, steer_angle)
	var forward_along_ground := forward - ground_normal * forward.dot(ground_normal)
	return forward_along_ground.normalized()


func _velocity_at(point: Vector3) -> Vector3:
	var center_of_mass_position := to_global(center_of_mass)
	var lever := point - center_of_mass_position
	return linear_velocity + angular_velocity.cross(lever)


func _wheel_velocities() -> Array[Vector3]:
	var velocities: Array[Vector3] = []
	var mounts := CarSuspension.mount_positions(_suspension.mount_height)
	for mount: Vector3 in mounts:
		velocities.append(_velocity_at(to_global(mount)))
	return velocities


func _wheel_command(wheel_index: int, car_forward_speed: float) -> CarWheelCommand:
	var command := CarWheelCommand.new()
	var front := CarSuspension.is_front(wheel_index)
	if _wants_brake(input.throttle, car_forward_speed):
		command.brake_force = mass * braking / WHEEL_COUNT
	if front:
		command.drive_force = _drive_force_per_front_wheel(input.throttle, car_forward_speed)
	if not front and input.handbraking:
		command.locked = true
	return command


func _wants_brake(throttle: float, forward_speed: float) -> bool:
	if throttle > 0.0:
		return forward_speed < -STOPPED_SPEED
	if throttle < 0.0:
		return forward_speed > STOPPED_SPEED
	return absf(forward_speed) < STOPPED_SPEED


func _drive_force_per_front_wheel(throttle: float, forward_speed: float) -> float:
	var full_force_per_wheel := mass * acceleration / 2.0
	if throttle > 0.0 and forward_speed >= -STOPPED_SPEED:
		var speed_fraction := clampf(forward_speed / max_speed, 0.0, 1.0)
		return full_force_per_wheel * (1.0 - speed_fraction)
	if throttle < 0.0 and forward_speed <= STOPPED_SPEED:
		var reverse_fraction := clampf(-forward_speed / reverse_max_speed, 0.0, 1.0)
		return -full_force_per_wheel * (1.0 - reverse_fraction)
	return 0.0


func _apply_air_drag() -> void:
	var speed := linear_velocity.length()
	apply_central_force(-linear_velocity * speed * air_drag)


func _shake_camera_on_landing() -> void:
	var on_ground := is_on_ground()
	var just_landed := on_ground and not _was_on_ground
	_was_on_ground = on_ground
	if not just_landed or _driver == null:
		return
	var fall_speed := -linear_velocity.y
	_cam.shake(CarCamera.shake_strength_for_fall(fall_speed))


func _update_visuals(delta: float, steer_angle: float, forward_speed: float) -> void:
	var rear_wheels_locked := input.handbraking
	var space_state := get_world_3d().direct_space_state
	var center_heights := _suspension.wheel_center_heights(
		space_state, global_transform, get_rid(), _wheel_velocities(), delta
	)
	_wheels.update(
		delta,
		forward_speed,
		steer_angle,
		rear_wheels_locked,
		_front_wheels_spinning,
		center_heights
	)
	var sideways_speed := linear_velocity.dot(global_basis.x)
	var speed := linear_velocity.length()
	_tire_fx.update(
		is_on_ground(), input.throttle, input.handbraking, sideways_speed, forward_speed, speed
	)
	if _driver:
		_cam.follow(delta)


func _report_telemetry(delta: float) -> void:
	if _driver == null:
		_telemetry.forget()
		return
	_telemetry.report(self, telemetry_frame(), delta)
