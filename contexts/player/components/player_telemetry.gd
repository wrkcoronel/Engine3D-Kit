class_name PlayerTelemetry
extends RefCounted

const SOURCE := "jogador"
const JUMP_MIN_CLIMB_SPEED := 0.5

var _has_previous := false
var _was_on_floor := true
var _was_sliding := false
var _previous_vertical_speed := 0.0
var _air_time := 0.0


static func describe(
	position: Vector3,
	velocity: Vector3,
	on_floor: bool,
	sprinting: bool,
	sliding: bool,
	crouching: bool,
) -> String:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var parts: PackedStringArray = []
	parts.append("posicao " + TelemetryLog.format_vector(position))
	parts.append("%.1f m/s" % horizontal_velocity.length())
	parts.append("velocidade vertical %+.2f m/s" % velocity.y)
	parts.append(_floor_text(on_floor))
	parts.append(_posture_text(sprinting, sliding, crouching))
	return " | ".join(parts)


static func _floor_text(on_floor: bool) -> String:
	if on_floor:
		return "no chao"
	return "NO AR"


static func _posture_text(sprinting: bool, sliding: bool, crouching: bool) -> String:
	if sliding:
		return "deslizando"
	if crouching:
		return "agachado"
	if sprinting:
		return "correndo"
	return "andando"


func report(
	from: Node,
	delta: float,
	vertical_speed: float,
	on_floor: bool,
	sliding: bool,
	state_text: String,
) -> void:
	for event: String in events_for(delta, vertical_speed, on_floor, sliding):
		Telemetry.record(from, SOURCE, event)
	Telemetry.sample(from, SOURCE, state_text)


func events_for(
	delta: float, vertical_speed: float, on_floor: bool, sliding: bool
) -> Array[String]:
	var events: Array[String] = []
	if _has_previous:
		_check_air(delta, vertical_speed, on_floor, events)
		_check_slide(sliding, events)
	_has_previous = true
	_was_on_floor = on_floor
	_was_sliding = sliding
	_previous_vertical_speed = vertical_speed
	return events


func _check_air(delta: float, vertical_speed: float, on_floor: bool, events: Array[String]) -> void:
	var left_floor := _was_on_floor and not on_floor
	var landed := not _was_on_floor and on_floor
	if not on_floor:
		_air_time += delta
	if left_floor:
		events.append(_left_floor_message(vertical_speed))
	if landed:
		var fall_speed := -_previous_vertical_speed
		var air_text := "%.2f s no ar" % _air_time
		events.append("pousou depois de %s, caindo a %.2f m/s" % [air_text, fall_speed])
		_air_time = 0.0


func _left_floor_message(vertical_speed: float) -> String:
	if vertical_speed > JUMP_MIN_CLIMB_SPEED:
		return "pulou (subindo a %.2f m/s)" % vertical_speed
	return "saiu do chao sem pular (caiu de uma borda?)"


func _check_slide(sliding: bool, events: Array[String]) -> void:
	if sliding and not _was_sliding:
		events.append("comecou a deslizar")
	if _was_sliding and not sliding:
		events.append("parou de deslizar")
