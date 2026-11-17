class_name GroundProbe
extends RefCounted

const RAY_START_HEIGHT := 1.5
const RAY_LENGTH := 3.0
const WHEEL_RADIUS := 0.4
const MIN_FLOOR_NORMAL_HEIGHT := 0.1

var half_width := 1.05
var half_wheelbase := 1.3

var found_ground := false
var surface_normal := Vector3.UP
var center_point := Vector3.ZERO
var center_height := 0.0


func sample(
	space_state: PhysicsDirectSpaceState3D, car_transform: Transform3D, car_body: RID
) -> void:
	found_ground = false
	var ground_points: Array[Vector3] = []
	for wheel_local_position: Vector3 in _wheel_center_positions():
		var hit := _wheel_ground_hit(space_state, car_transform, car_body, wheel_local_position)
		if not hit.is_empty():
			ground_points.append(hit["position"] as Vector3)
	if ground_points.size() == 4:
		fit_plane(ground_points[0], ground_points[1], ground_points[2], ground_points[3])
		return
	if ground_points.size() == 3:
		fit_plane_from_three(
			ground_points[0], ground_points[1], ground_points[2], car_transform.origin
		)


func _wheel_ground_hit(
	space_state: PhysicsDirectSpaceState3D,
	car_transform: Transform3D,
	car_body: RID,
	wheel_local_position: Vector3,
) -> Dictionary:
	var wheel_at_car_base := Vector3(wheel_local_position.x, 0.0, wheel_local_position.z)
	var wheel_position := car_transform * wheel_at_car_base
	var ray_start := wheel_position + Vector3.UP * RAY_START_HEIGHT
	var ray_end := ray_start + Vector3.DOWN * RAY_LENGTH
	var excluded_bodies: Array[RID] = [car_body]
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 0xFFFFFFFF, excluded_bodies)
	return space_state.intersect_ray(query)


func fit_plane(
	front_left: Vector3, front_right: Vector3, rear_left: Vector3, rear_right: Vector3
) -> void:
	var diagonal_from_rear_right := front_left - rear_right
	var diagonal_from_rear_left := front_right - rear_left
	var plane_normal := diagonal_from_rear_left.cross(diagonal_from_rear_right).normalized()
	var center_of_wheels := (front_left + front_right + rear_left + rear_right) / 4.0
	_store_plane(plane_normal, front_left, center_of_wheels)


func fit_plane_from_three(
	first_point: Vector3, second_point: Vector3, third_point: Vector3, car_center: Vector3
) -> void:
	var first_edge := second_point - first_point
	var second_edge := third_point - first_point
	var plane_normal := first_edge.cross(second_edge).normalized()
	if plane_normal.y < 0.0:
		plane_normal = -plane_normal
	_store_plane(plane_normal, first_point, car_center)


func _store_plane(plane_normal: Vector3, point_on_plane: Vector3, center: Vector3) -> void:
	if plane_normal.y <= MIN_FLOOR_NORMAL_HEIGHT:
		return
	surface_normal = plane_normal
	center_point = point_on_plane
	var height_at_center := _ground_height_at(center)
	center_point = Vector3(center.x, height_at_center, center.z)
	center_height = height_at_center
	found_ground = true


func required_lift(visual_transform: Transform3D) -> float:
	if not found_ground:
		return 0.0
	var lift := 0.0
	for wheel_local_position: Vector3 in _wheel_center_positions():
		var wheel_center := visual_transform * wheel_local_position
		var wheel_bottom_height := wheel_center.y - WHEEL_RADIUS
		var ground_height := _ground_height_at(wheel_center)
		lift = maxf(lift, ground_height - wheel_bottom_height)
	return lift


func _wheel_center_positions() -> Array[Vector3]:
	return [
		Vector3(-half_width, WHEEL_RADIUS, -half_wheelbase),
		Vector3(half_width, WHEEL_RADIUS, -half_wheelbase),
		Vector3(-half_width, WHEEL_RADIUS, half_wheelbase),
		Vector3(half_width, WHEEL_RADIUS, half_wheelbase),
	]


func _ground_height_at(point: Vector3) -> float:
	var offset := point - center_point
	var horizontal_rise := surface_normal.x * offset.x + surface_normal.z * offset.z
	return center_point.y - horizontal_rise / surface_normal.y
