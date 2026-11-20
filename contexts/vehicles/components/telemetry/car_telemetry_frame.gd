class_name CarTelemetryFrame
extends RefCounted

const KMH_PER_METER_PER_SECOND := 3.6
const WHEEL_COUNT := 4

var position := Vector3.ZERO
var velocity := Vector3.ZERO
var throttle := 0.0
var steering := 0.0
var handbraking := false
var on_floor := false
var floor_normal := Vector3.UP
var wheel_ground_names: Array[String] = []
var wheel_ground_heights: Array[float] = []
var contacts: Array[String] = []
var contact_points: Array[Vector3] = []
var contact_names: Array[String] = []
var contact_details: Array[String] = []
var wheels: Array[WheelGround] = []
var center_ground_drop := 0.0
var sliding_off_edge := false


func _init(car_position: Vector3, car_velocity: Vector3, car_input: CarInput) -> void:
	position = car_position
	velocity = car_velocity
	throttle = car_input.throttle
	steering = car_input.steering
	handbraking = car_input.handbraking


static func from_car(
	car: CharacterBody3D, car_input: CarInput, probe: GroundProbe, edge_support: CarEdgeSupport
) -> CarTelemetryFrame:
	var frame := CarTelemetryFrame.new(car.global_position, car.velocity, car_input)
	frame.read_floor(car.is_on_floor(), car.get_floor_normal(), probe)
	frame.sliding_off_edge = edge_support.hanging_off_edge
	for index: int in car.get_slide_collision_count():
		frame.read_collision(car.get_slide_collision(index))
	return frame


func read_floor(car_on_floor: bool, car_floor_normal: Vector3, probe: GroundProbe) -> void:
	on_floor = car_on_floor
	floor_normal = car_floor_normal
	wheel_ground_names = probe.wheel_ground_names.duplicate()
	wheel_ground_heights = probe.wheel_ground_heights.duplicate()
	wheels = probe.wheels.duplicate()
	center_ground_drop = probe.center_ground_drop


func read_collision(collision: KinematicCollision3D) -> void:
	var collider := collision.get_collider() as Node
	if collider == null:
		return
	var rounded_normal := collision.get_normal().snapped(Vector3.ONE * 0.1)
	var contact_name := TelemetryLog.describe_node(collider)
	var contact := "%s normal %s" % [contact_name, TelemetryLog.format_vector(rounded_normal)]
	if contacts.has(contact):
		return
	contacts.append(contact)
	contact_points.append(collision.get_position())
	contact_details.append(CollisionDescription.describe(collision))
	if not contact_names.has(contact_name):
		contact_names.append(contact_name)


func touches_name_starting_with(prefix: String) -> bool:
	for contact_name: String in contact_names:
		if contact_name.begins_with(prefix):
			return true
	return false


func horizontal_speed() -> float:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	return horizontal_velocity.length()


func speed_kmh() -> float:
	return horizontal_speed() * KMH_PER_METER_PER_SECOND


func wheels_on_ground() -> int:
	return wheel_ground_names.size()


func ground_summary() -> String:
	var unique_names: Array[String] = []
	for ground_name: String in wheel_ground_names:
		if not unique_names.has(ground_name):
			unique_names.append(ground_name)
	if unique_names.is_empty():
		return "nada"
	return " + ".join(PackedStringArray(unique_names))


func describe() -> String:
	var parts: PackedStringArray = []
	parts.append("posicao " + TelemetryLog.format_vector(position))
	parts.append("%.0f km/h" % speed_kmh())
	parts.append("velocidade vertical %+.2f m/s" % velocity.y)
	parts.append(_floor_text())
	parts.append(_wheels_text())
	parts.append(_controls_text())
	if not contacts.is_empty():
		parts.append("encostando em: " + ", ".join(PackedStringArray(contacts)))
	return " | ".join(parts)


func _floor_text() -> String:
	if not on_floor:
		return "NO AR"
	return "no chao, normal " + TelemetryLog.format_vector(floor_normal)


func _wheels_text() -> String:
	var heights: PackedStringArray = []
	for height: float in wheel_ground_heights:
		heights.append("%.2f" % height)
	var count_text := "rodas sobre chao %d/%d" % [wheels_on_ground(), WHEEL_COUNT]
	var ground_text := "(%s)" % ground_summary()
	var heights_text := "alturas " + " ".join(heights)
	return " ".join(PackedStringArray([count_text, ground_text, heights_text]))


func _controls_text() -> String:
	var handbrake_text := "nao"
	if handbraking:
		handbrake_text = "sim"
	return "acelerador %+.1f volante %+.1f freio de mao %s" % [throttle, steering, handbrake_text]
