class_name CarEdgeSupport
extends RefCounted

const MAX_CENTER_GROUND_DROP := 1.0
const CENTER_BACK_ON_GROUND_DROP := 0.3
const HALF_CAR_LENGTH := 2.0
const CREST_LANDING_TOLERANCE := 0.1
const SLIDE_OFF_ACCELERATION := 6.0
const MAX_SLIDE_OFF_SPEED := 3.0

var hanging_off_edge := false


static func crest_launch_speed(gravity_strength: float) -> float:
	var time_to_drop_tolerance := sqrt(2.0 * CREST_LANDING_TOLERANCE / gravity_strength)
	return HALF_CAR_LENGTH / time_to_drop_tolerance


func update(on_floor: bool, center_ground_drop: float, touching_count: int) -> void:
	if hanging_off_edge:
		hanging_off_edge = _still_hanging(center_ground_drop, touching_count)
		return
	var center_over_void := center_ground_drop > MAX_CENTER_GROUND_DROP
	hanging_off_edge = on_floor and center_over_void


func motion_mode() -> CharacterBody3D.MotionMode:
	if hanging_off_edge:
		return CharacterBody3D.MOTION_MODE_FLOATING
	return CharacterBody3D.MOTION_MODE_GROUNDED


func should_snap_back(
	was_grounded: bool,
	on_floor_now: bool,
	center_ground_drop: float,
	speed: float,
	gravity_strength: float,
) -> bool:
	if not was_grounded:
		return false
	if on_floor_now:
		return false
	var center_over_ground := center_ground_drop <= MAX_CENTER_GROUND_DROP
	var too_slow_to_launch := speed < crest_launch_speed(gravity_strength)
	return center_over_ground and too_slow_to_launch


func _still_hanging(center_ground_drop: float, touching_count: int) -> bool:
	var slid_free := touching_count == 0
	var center_back_on_ground := center_ground_drop < CENTER_BACK_ON_GROUND_DROP
	if slid_free or center_back_on_ground:
		return false
	return true


static func contact_normals_of(car: CharacterBody3D) -> Array[Vector3]:
	var normals: Array[Vector3] = []
	for index: int in car.get_slide_collision_count():
		normals.append(car.get_slide_collision(index).get_normal())
	return normals


func slide_push(normals_touched: Array[Vector3], current_speed: float, delta: float) -> Vector3:
	if current_speed > MAX_SLIDE_OFF_SPEED:
		return Vector3.ZERO
	var combined_normal := Vector3.ZERO
	for normal: Vector3 in normals_touched:
		combined_normal += normal
	combined_normal.y = 0.0
	if combined_normal.length() < 0.01:
		return Vector3.ZERO
	return combined_normal.normalized() * SLIDE_OFF_ACCELERATION * delta
