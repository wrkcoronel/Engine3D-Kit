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
var roll_degrees := 0.0


func _init(car_position: Vector3, car_velocity: Vector3, car_input: CarInput) -> void:
	position = car_position
	velocity = car_velocity
	throttle = car_input.throttle
	steering = car_input.steering
	handbraking = car_input.handbraking


static func from_car(
	car: RigidBody3D,
	car_input: CarInput,
	suspension: CarSuspension,
	body_contacts: Array[CarBodyContact],
) -> CarTelemetryFrame:
	var frame := CarTelemetryFrame.new(car.global_position, car.linear_velocity, car_input)
	frame.read_wheels(suspension.wheels)
	frame.roll_degrees = rad_to_deg(car.global_basis.y.angle_to(Vector3.UP))
	for body_contact: CarBodyContact in body_contacts:
		frame.read_contact(body_contact)
	return frame


func read_wheels(suspension_wheels: Array[WheelGround]) -> void:
	var normals_sum := Vector3.ZERO
	for wheel: WheelGround in suspension_wheels:
		wheels.append(_copy_of(wheel))
		if not wheel.touching:
			continue
		wheel_ground_names.append(wheel.ground_name)
		wheel_ground_heights.append(wheel.point.y)
		normals_sum += wheel.normal
	on_floor = not wheel_ground_names.is_empty()
	floor_normal = Vector3.ZERO
	if on_floor:
		floor_normal = normals_sum.normalized()


func read_contact(body_contact: CarBodyContact) -> void:
	if body_contact.collider == null:
		return
	var rounded_normal := body_contact.normal.snapped(Vector3.ONE * 0.1)
	var contact_name := TelemetryLog.describe_node(body_contact.collider)
	var contact := "%s normal %s" % [contact_name, TelemetryLog.format_vector(rounded_normal)]
	if contacts.has(contact):
		return
	contacts.append(contact)
	contact_points.append(body_contact.point)
	contact_details.append(_describe_contact(body_contact))
	if not contact_names.has(contact_name):
		contact_names.append(contact_name)


func _describe_contact(body_contact: CarBodyContact) -> String:
	var collider := body_contact.collider
	var shape_node := body_contact.shape_node
	var point := body_contact.point
	return CollisionDescription.describe_contact(collider, shape_node, point, body_contact.normal)


func _copy_of(wheel: WheelGround) -> WheelGround:
	var copy := WheelGround.new()
	copy.touching = wheel.touching
	copy.ground_name = wheel.ground_name
	copy.point = wheel.point
	copy.normal = wheel.normal
	copy.gap = wheel.gap
	copy.spring_length = wheel.spring_length
	copy.compression = wheel.compression
	copy.compression_speed = wheel.compression_speed
	return copy


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
