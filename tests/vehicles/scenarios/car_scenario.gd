class_name CarScenario
extends RefCounted

const RAMP_NEAR_START_Z := 2.0
const RAMP_FAR_END_Z := -50.0
const RAMP_LEFT_X := 5.0
const RAMP_RIGHT_X := 35.0
const WHEEL_NAMES: Array[String] = ["WheelFL", "WheelFR", "WheelBL", "WheelBR"]

var car: Car
var worst_wheel_sink := 0.0
var floor_changes_near_ramp := 0
var takeoff_climb_speed := 0.0

var _tree: SceneTree
var _wheels: Array[Node3D] = []
var _was_on_floor := true


static func hold_speed(target_speed: float) -> Callable:
	return func(driven_car: Car) -> void:
		driven_car.input.throttle = 0.0
		var below_target := driven_car.velocity.length() < target_speed
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
	car.reset_physics_interpolation()
	for wheel_name: String in WHEEL_NAMES:
		_wheels.append(car.get_node("Visual/Model/" + wheel_name) as Node3D)


func drive(ticks: int, controller: Callable) -> void:
	for tick_index: int in ticks:
		controller.call(car)
		await _tree.physics_frame
		_measure()


func _measure() -> void:
	var on_floor := car.is_on_floor()
	var floor_changed := on_floor != _was_on_floor
	if floor_changed and _near_ramp():
		floor_changes_near_ramp += 1
	var took_off := _was_on_floor and not on_floor
	if took_off:
		takeoff_climb_speed = maxf(takeoff_climb_speed, car.velocity.y)
	_was_on_floor = on_floor
	if on_floor:
		_measure_wheel_sink()


func _measure_wheel_sink() -> void:
	var space := car.get_world_3d().direct_space_state
	var excluded: Array[RID] = [car.get_rid()]
	for wheel: Node3D in _wheels:
		var ray_start := wheel.global_position + Vector3.UP
		var ray_end := wheel.global_position + Vector3.DOWN * 3.0
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0xFFFFFFFF, excluded)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var ground_height := (hit["position"] as Vector3).y
		var wheel_bottom := wheel.global_position.y - GroundProbe.WHEEL_RADIUS
		worst_wheel_sink = minf(worst_wheel_sink, wheel_bottom - ground_height)


func _near_ramp() -> bool:
	var position := car.global_position
	var inside_length := position.z < RAMP_NEAR_START_Z and position.z > RAMP_FAR_END_Z
	var inside_width := position.x > RAMP_LEFT_X and position.x < RAMP_RIGHT_X
	return inside_length and inside_width
