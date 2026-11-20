class_name CarScenario
extends RefCounted

const RAMP_NEAR_START_Z := 2.0
const RAMP_FAR_END_Z := -50.0
const RAMP_LEFT_X := 5.0
const RAMP_RIGHT_X := 35.0
const WHEEL_NAMES: Array[String] = ["WheelFL", "WheelFR", "WheelBL", "WheelBR"]

var car: Car
var worst_wheel_sink := 0.0
var worst_wheel_float := 0.0
var floor_changes_near_ramp := 0
var takeoff_climb_speed := 0.0
var telemetry := CarTelemetry.new()
var events: Array[String] = []
var ramp_touch_kmh := -1.0
var worst_fall_visual_turn_degrees := 0.0
var worst_roll_degrees := 0.0

var _tree: SceneTree
var _wheels: Array[Node3D] = []
var _was_on_floor := true
var _ticks_driven := 0
var _visual: Node3D
var _last_visual_rotation := Quaternion.IDENTITY


static func hold_speed(target_speed: float) -> Callable:
	return func(driven_car: Car) -> void:
		driven_car.input.throttle = 0.0
		var below_target := driven_car.linear_velocity.length() < target_speed
		if below_target:
			driven_car.input.throttle = 1.0


func start(test: TestCase, position: Vector3, yaw_degrees: float) -> void:
	_tree = test.tree
	var main := (load("res://app/main.tscn") as PackedScene).instantiate()
	test.spawn(main)
	car = main.get_node("Car") as Car
	car.input.from_keyboard = false
	car.global_position = position
	car.rotation.y = deg_to_rad(yaw_degrees)
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
	car.reset_physics_interpolation()
	_visual = car.get_node("Visual") as Node3D
	telemetry.detail.enabled = TelemetryDetailWindow.asked_on_command_line()
	for wheel_name: String in WHEEL_NAMES:
		_wheels.append(car.get_node("Visual/Model/" + wheel_name) as Node3D)


func launch(speed: float) -> void:
	car.linear_velocity = -car.global_basis.z * speed


func drive(ticks: int, controller: Callable) -> void:
	for tick_index: int in ticks:
		controller.call(car)
		await _tree.physics_frame
		_measure()


func settle(ticks: int) -> void:
	await drive(ticks, func(driven_car: Car) -> void: driven_car.input.clear())
	events.clear()
	worst_fall_visual_turn_degrees = 0.0
	worst_wheel_float = 0.0
	worst_roll_degrees = 0.0
	telemetry.forget()


func events_containing(text: String) -> Array[String]:
	var matching: Array[String] = []
	for event: String in events:
		if event.contains(text):
			matching.append(event)
	return matching


func print_events(label: String) -> void:
	print("--- telemetria do cenario ", label, " (", events.size(), " linhas) ---")
	for event: String in events:
		print(event)


func _record_telemetry() -> void:
	var frame := car.telemetry_frame()
	var not_measured_yet := ramp_touch_kmh < 0.0
	var touching_ramp := frame.ground_summary().contains("Ramps/")
	if not_measured_yet and touching_ramp:
		ramp_touch_kmh = frame.speed_kmh()
	var delta := car.get_physics_process_delta_time()
	var time_text := "[%6.2fs] " % (_ticks_driven * delta)
	for event: String in telemetry.events_for(frame, delta):
		events.append(time_text + event)


func _measure() -> void:
	_ticks_driven += 1
	_record_telemetry()
	_measure_visual_turn()
	var on_floor := car.is_on_ground()
	var floor_changed := on_floor != _was_on_floor
	if floor_changed and _near_ramp():
		floor_changes_near_ramp += 1
	var took_off := _was_on_floor and not on_floor
	if took_off:
		takeoff_climb_speed = maxf(takeoff_climb_speed, car.linear_velocity.y)
	_was_on_floor = on_floor
	_measure_roll()
	if on_floor:
		_measure_wheel_sink()


func _measure_wheel_sink() -> void:
	var space := car.get_world_3d().direct_space_state
	var excluded: Array[RID] = [car.get_rid()]
	var lowest_wheel_gap := INF
	for wheel: Node3D in _wheels:
		var ray_start := wheel.global_position + Vector3.UP
		var ray_end := wheel.global_position + Vector3.DOWN * 3.0
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0xFFFFFFFF, excluded)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var ground_height := (hit["position"] as Vector3).y
		var wheel_bottom := wheel.global_position.y - CarSuspension.WHEEL_RADIUS
		var wheel_gap := wheel_bottom - ground_height
		worst_wheel_sink = minf(worst_wheel_sink, wheel_gap)
		lowest_wheel_gap = minf(lowest_wheel_gap, wheel_gap)
	if lowest_wheel_gap < INF:
		worst_wheel_float = maxf(worst_wheel_float, lowest_wheel_gap)


func _near_ramp() -> bool:
	var position := car.global_position
	var inside_length := position.z < RAMP_NEAR_START_Z and position.z > RAMP_FAR_END_Z
	var inside_width := position.x > RAMP_LEFT_X and position.x < RAMP_RIGHT_X
	return inside_length and inside_width


func _measure_visual_turn() -> void:
	var rotation_now := _visual.global_basis.get_rotation_quaternion()
	var turn_radians := _last_visual_rotation.angle_to(rotation_now)
	_last_visual_rotation = rotation_now
	var falling_or_landing := not _was_on_floor or not car.is_on_ground()
	if not falling_or_landing:
		return
	var turn_degrees := rad_to_deg(turn_radians)
	worst_fall_visual_turn_degrees = maxf(worst_fall_visual_turn_degrees, turn_degrees)


func _measure_roll() -> void:
	var right_side_rise := clampf(absf(car.global_basis.x.y), 0.0, 1.0)
	var side_tilt_degrees := rad_to_deg(asin(right_side_rise))
	worst_roll_degrees = maxf(worst_roll_degrees, side_tilt_degrees)
