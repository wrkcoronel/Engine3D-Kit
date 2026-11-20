class_name CarSuspension
extends Node

const WHEEL_RADIUS := 0.29
const HALF_WIDTH := 0.70
const HALF_WHEELBASE := 1.235
const FRONT_LEFT := 0
const FRONT_RIGHT := 1
const REAR_LEFT := 2
const REAR_RIGHT := 3

@export var mount_height := 0.64
@export var max_spring_length := 0.45
@export var min_spring_length := 0.05
@export var stiffness := 24500.0
@export var damping := 2500.0
@export var bump_stop_compression := 0.28
@export var bump_stop_stiffness := 150000.0
@export var anti_roll_stiffness := 8000.0

var wheels: Array[WheelGround] = []


static func spring_force(
	compression: float, compression_speed: float, spring_stiffness: float, spring_damping: float
) -> float:
	var spring_push := compression * spring_stiffness
	var damper_push := compression_speed * spring_damping
	return maxf(spring_push + damper_push, 0.0)


static func bump_stop_force(
	compression: float, stop_compression: float, stop_stiffness: float
) -> float:
	var compression_into_stop := maxf(compression - stop_compression, 0.0)
	return compression_into_stop * stop_stiffness


static func anti_roll_force(
	compression_this_side: float, compression_other_side: float, bar_stiffness: float
) -> float:
	var compression_difference := compression_this_side - compression_other_side
	return compression_difference * bar_stiffness


static func is_front(wheel_index: int) -> bool:
	return wheel_index == FRONT_LEFT or wheel_index == FRONT_RIGHT


static func mount_positions(height: float) -> Array[Vector3]:
	return [
		Vector3(-HALF_WIDTH, height, -HALF_WHEELBASE),
		Vector3(HALF_WIDTH, height, -HALF_WHEELBASE),
		Vector3(-HALF_WIDTH, height, HALF_WHEELBASE),
		Vector3(HALF_WIDTH, height, HALF_WHEELBASE),
	]


func _ready() -> void:
	for wheel_index: int in 4:
		var wheel := WheelGround.new()
		wheel.spring_length = max_spring_length
		wheels.append(wheel)


func sample(
	space_state: PhysicsDirectSpaceState3D, car_transform: Transform3D, car_body: RID, delta: float
) -> void:
	var mounts := mount_positions(mount_height)
	for wheel_index: int in wheels.size():
		var mount_point := car_transform * mounts[wheel_index]
		var hit := _cast_wheel_ray(space_state, mount_point, car_transform.basis.y, car_body)
		_update_wheel(wheels[wheel_index], hit, mount_point, car_transform.origin, delta)


func load_on(wheel_index: int) -> float:
	var wheel := wheels[wheel_index]
	if not wheel.touching:
		return 0.0
	var spring_push := spring_force(wheel.compression, wheel.compression_speed, stiffness, damping)
	spring_push += bump_stop_force(wheel.compression, bump_stop_compression, bump_stop_stiffness)
	var other_side := wheels[_other_side_of(wheel_index)]
	var bar_push := anti_roll_force(wheel.compression, other_side.compression, anti_roll_stiffness)
	return maxf(spring_push + bar_push, 0.0)


func touching_count() -> int:
	var count := 0
	for wheel: WheelGround in wheels:
		if wheel.touching:
			count += 1
	return count


func average_ground_normal() -> Vector3:
	var normals_sum := Vector3.ZERO
	for wheel: WheelGround in wheels:
		if wheel.touching:
			normals_sum += wheel.normal
	if normals_sum.is_zero_approx():
		return Vector3.ZERO
	return normals_sum.normalized()


func wheel_center_heights(
	space_state: PhysicsDirectSpaceState3D,
	car_transform: Transform3D,
	car_body: RID,
	wheel_velocities: Array[Vector3],
	delta: float,
) -> Array[float]:
	var center_heights: Array[float] = []
	var mounts := mount_positions(mount_height)
	var car_up := car_transform.basis.y
	for wheel_index: int in wheels.size():
		var mount_now := car_transform * mounts[wheel_index]
		var mount_after_step := mount_now + wheel_velocities[wheel_index] * delta
		var hit := _cast_wheel_ray(space_state, mount_after_step, car_up, car_body)
		var length_after_step := max_spring_length
		if not hit.is_empty():
			var ground_after_step := hit["position"] as Vector3
			length_after_step = mount_after_step.distance_to(ground_after_step) - WHEEL_RADIUS
		var visible_length := clampf(length_after_step, min_spring_length, max_spring_length)
		center_heights.append(mount_height - visible_length)
	return center_heights


func _cast_wheel_ray(
	space_state: PhysicsDirectSpaceState3D, mount_point: Vector3, car_up: Vector3, car_body: RID
) -> Dictionary:
	var ray_length := max_spring_length + WHEEL_RADIUS
	var ray_end := mount_point - car_up * ray_length
	var excluded_bodies: Array[RID] = [car_body]
	var query := PhysicsRayQueryParameters3D.create(
		mount_point, ray_end, 0xFFFFFFFF, excluded_bodies
	)
	return space_state.intersect_ray(query)


func _update_wheel(
	wheel: WheelGround, hit: Dictionary, mount_point: Vector3, car_origin: Vector3, delta: float
) -> void:
	var previous_length := wheel.spring_length
	wheel.touching = not hit.is_empty()
	wheel.spring_length = max_spring_length
	wheel.length_to_ground = max_spring_length
	wheel.ground_name = "nada"
	wheel.gap = INF
	if wheel.touching:
		_read_hit(wheel, hit, mount_point, car_origin)
	wheel.compression = max_spring_length - wheel.spring_length
	wheel.compression_speed = (previous_length - wheel.spring_length) / delta


func _read_hit(
	wheel: WheelGround, hit: Dictionary, mount_point: Vector3, car_origin: Vector3
) -> void:
	wheel.point = hit["position"] as Vector3
	wheel.normal = hit["normal"] as Vector3
	wheel.ground_name = _ground_name_of(hit["collider"] as Node)
	wheel.gap = car_origin.y - wheel.point.y
	var distance_to_ground := mount_point.distance_to(wheel.point)
	wheel.length_to_ground = distance_to_ground - WHEEL_RADIUS
	var spring_range_length := clampf(wheel.length_to_ground, min_spring_length, max_spring_length)
	wheel.spring_length = spring_range_length


func _ground_name_of(ground: Node) -> String:
	if ground == null:
		return "?"
	return TelemetryLog.describe_node(ground)


func _other_side_of(wheel_index: int) -> int:
	if wheel_index == FRONT_LEFT:
		return FRONT_RIGHT
	if wheel_index == FRONT_RIGHT:
		return FRONT_LEFT
	if wheel_index == REAR_LEFT:
		return REAR_RIGHT
	return REAR_LEFT
