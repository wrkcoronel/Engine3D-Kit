class_name CarTelemetry
extends RefCounted

const SOURCE := "carro"
const BUMP_VERTICAL_SPEED_CHANGE := 2.0
const SUDDEN_DECELERATION := 100.0
const SHORT_AIR_TIME := 0.25
const HANGING_CENTER_DROP := 1.0
const HANG_TOLERANCE := 0.05

var detail := TelemetryDetailWindow.new()
var longest_edge_slide_time := 0.0

var _has_previous := false
var _was_on_floor := true
var _previous_velocity := Vector3.ZERO
var _previous_floor_normal := Vector3.UP
var _previous_ground := ""
var _previous_wheels_on_ground := 0
var _previous_contacts: Array[String] = []
var _touched_colliders: Array[String] = []
var _air_time := 0.0
var _hanging := false
var _hang_time := 0.0
var _sliding_off_edge := false
var _edge_slide_time := 0.0


func _init() -> void:
	detail.enabled = TelemetryDetailWindow.asked_on_command_line()


func report(from: Node, frame: CarTelemetryFrame, delta: float) -> void:
	detail.enabled = Telemetry.wants_detail(from)
	for event: String in events_for(frame, delta):
		Telemetry.record(from, SOURCE, event)
	Telemetry.sample(from, SOURCE, frame.describe())


func forget() -> void:
	_has_previous = false
	_air_time = 0.0
	_hanging = false
	_hang_time = 0.0
	_touched_colliders.clear()
	detail.clear()


func events_for(frame: CarTelemetryFrame, delta: float) -> Array[String]:
	var events: Array[String] = []
	if _has_previous:
		var anomalies: Array[String] = []
		_check_air(frame, delta, events, anomalies)
		_check_bump(frame, anomalies)
		_check_speed_loss(frame, delta, anomalies)
		_check_hanging(frame, delta, events, anomalies)
		_check_edge_slide(frame, delta, events)
		_check_ground_change(frame, events)
		_check_new_contacts(frame, events)
		_add_anomalies(frame, anomalies, events)
	events.append_array(detail.push_frame(frame.describe()))
	_remember(frame)
	return events


func _add_anomalies(
	frame: CarTelemetryFrame, anomalies: Array[String], events: Array[String]
) -> void:
	if anomalies.is_empty():
		return
	events.append_array(detail.anomaly_happened())
	events.append_array(anomalies)
	events.append_array(CarTelemetryContext.lines_for(frame, _previous_floor_normal))


func _check_air(
	frame: CarTelemetryFrame, delta: float, events: Array[String], anomalies: Array[String]
) -> void:
	var took_off := _was_on_floor and not frame.on_floor
	var landed := not _was_on_floor and frame.on_floor
	if not frame.on_floor:
		_air_time += delta
	if took_off:
		var climb_text := "%+.2f m/s" % frame.velocity.y
		var where := TelemetryLog.format_vector(frame.position)
		events.append("SAIU DO CHAO subindo a %s em %s" % [climb_text, where])
	if not landed:
		return
	var lost_ground_briefly := _air_time < SHORT_AIR_TIME
	if lost_ground_briefly:
		anomalies.append(_landing_message() + " -> PERDEU O CHAO RAPIDO")
	else:
		events.append(_landing_message())
	_air_time = 0.0


func _landing_message() -> String:
	var fall_speed := -_previous_velocity.y
	var air_text := "%.2f s no ar" % _air_time
	var fall_text := "caindo a %.2f m/s" % fall_speed
	return "voltou ao chao depois de %s, %s" % [air_text, fall_text]


func _check_bump(frame: CarTelemetryFrame, anomalies: Array[String]) -> void:
	var stayed_on_floor := _was_on_floor and frame.on_floor
	if not stayed_on_floor:
		return
	var vertical_speed_change := frame.velocity.y - _previous_velocity.y
	if absf(vertical_speed_change) < BUMP_VERTICAL_SPEED_CHANGE:
		return
	var before := "%+.2f" % _previous_velocity.y
	var after := "%+.2f" % frame.velocity.y
	var change := "velocidade vertical foi de %s para %s m/s" % [before, after]
	var jump := "salto de %.2f m/s" % absf(vertical_speed_change)
	anomalies.append("SOLAVANCO: %s (%s)" % [change, jump])


func _check_speed_loss(frame: CarTelemetryFrame, delta: float, anomalies: Array[String]) -> void:
	if delta <= 0.0:
		return
	var previous_horizontal := Vector3(_previous_velocity.x, 0.0, _previous_velocity.z)
	var previous_kmh := previous_horizontal.length() * CarTelemetryFrame.KMH_PER_METER_PER_SECOND
	var speed_lost := previous_horizontal.length() - frame.horizontal_speed()
	var deceleration := speed_lost / delta
	if deceleration < SUDDEN_DECELERATION:
		return
	var change := "%.0f -> %.0f km/h" % [previous_kmh, frame.speed_kmh()]
	var touching := ", ".join(PackedStringArray(frame.contact_names))
	anomalies.append("FREOU DE REPENTE: %s em um frame, contatos: [%s]" % [change, touching])


func _check_hanging(
	frame: CarTelemetryFrame, delta: float, events: Array[String], anomalies: Array[String]
) -> void:
	var hanging_now := frame.on_floor and frame.center_ground_drop > HANGING_CENTER_DROP
	var was_reported := _hang_time > HANG_TOLERANCE
	if hanging_now:
		_hang_time += delta
	var reported_now := _hang_time > HANG_TOLERANCE
	if hanging_now and reported_now and not was_reported:
		anomalies.append("PENDURADO NA BORDA: apoiado no chao com o centro sobre o vazio")
	if _hanging and not hanging_now:
		events.append("saiu da borda depois de %.2f s pendurado" % _hang_time)
		_hang_time = 0.0
	_hanging = hanging_now


func _check_edge_slide(frame: CarTelemetryFrame, delta: float, events: Array[String]) -> void:
	if frame.sliding_off_edge:
		_edge_slide_time += delta
		longest_edge_slide_time = maxf(longest_edge_slide_time, _edge_slide_time)
	if frame.sliding_off_edge and not _sliding_off_edge:
		var where := TelemetryLog.format_vector(frame.position)
		events.append("ESCORREGANDO DA BORDA: centro sobre o vazio em %s" % where)
	if _sliding_off_edge and not frame.sliding_off_edge:
		events.append("soltou da borda depois de %.2f s escorregando" % _edge_slide_time)
		_edge_slide_time = 0.0
	_sliding_off_edge = frame.sliding_off_edge


func _check_ground_change(frame: CarTelemetryFrame, events: Array[String]) -> void:
	var ground := frame.ground_summary()
	var wheels := frame.wheels_on_ground()
	var same_ground := ground == _previous_ground
	var same_wheels := wheels == _previous_wheels_on_ground
	if same_ground and same_wheels:
		return
	var before := "%d rodas em %s" % [_previous_wheels_on_ground, _previous_ground]
	var after := "%d rodas em %s" % [wheels, ground]
	events.append("chao sob as rodas mudou: %s -> %s" % [before, after])


func _check_new_contacts(frame: CarTelemetryFrame, events: Array[String]) -> void:
	for index: int in frame.contacts.size():
		var contact := frame.contacts[index]
		if _previous_contacts.has(contact):
			continue
		var point := TelemetryLog.format_vector(frame.contact_points[index])
		events.append("encostou em %s no ponto %s" % [contact, point])
		_describe_first_touch(frame, index, events)


func _describe_first_touch(frame: CarTelemetryFrame, index: int, events: Array[String]) -> void:
	if index >= frame.contact_details.size():
		return
	var collider_name := frame.contacts[index].get_slice(" normal", 0)
	if _touched_colliders.has(collider_name):
		return
	_touched_colliders.append(collider_name)
	events.append(CarTelemetryContext.PREFIX + "primeiro toque: " + frame.contact_details[index])


func _remember(frame: CarTelemetryFrame) -> void:
	_has_previous = true
	_was_on_floor = frame.on_floor
	_previous_velocity = frame.velocity
	_previous_floor_normal = frame.floor_normal
	_previous_ground = frame.ground_summary()
	_previous_wheels_on_ground = frame.wheels_on_ground()
	_previous_contacts = frame.contacts.duplicate()
