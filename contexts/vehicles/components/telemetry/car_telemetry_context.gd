class_name CarTelemetryContext
extends RefCounted

const PREFIX := "   > "


static func normal_change_degrees(previous_normal: Vector3, current_normal: Vector3) -> float:
	return rad_to_deg(previous_normal.angle_to(current_normal))


static func lines_for(frame: CarTelemetryFrame, previous_floor_normal: Vector3) -> Array[String]:
	var lines: Array[String] = []
	lines.append(PREFIX + _motion_text(frame))
	lines.append(PREFIX + _normal_text(frame, previous_floor_normal))
	lines.append(PREFIX + _center_text(frame))
	for wheel_index: int in frame.wheels.size():
		lines.append(PREFIX + frame.wheels[wheel_index].describe(wheel_index))
	for contact_detail: String in frame.contact_details:
		lines.append(PREFIX + "contato: " + contact_detail)
	return lines


static func _motion_text(frame: CarTelemetryFrame) -> String:
	var position_text := "posicao " + TelemetryLog.format_vector(frame.position)
	var velocity_text := "velocidade " + TelemetryLog.format_vector(frame.velocity)
	var floor_text := "no chao: nao"
	if frame.on_floor:
		floor_text = "no chao: sim"
	return (
		"%s | %s (%.0f km/h) | %s" % [position_text, velocity_text, frame.speed_kmh(), floor_text]
	)


static func _normal_text(frame: CarTelemetryFrame, previous_floor_normal: Vector3) -> String:
	var was_in_air := previous_floor_normal.is_zero_approx()
	var is_in_air := frame.floor_normal.is_zero_approx()
	if was_in_air or is_in_air:
		var after_text := TelemetryLog.format_vector(frame.floor_normal)
		return (
			"normal do chao: no frame anterior ou neste o carro estava no ar (agora %s)"
			% after_text
		)
	var change := normal_change_degrees(previous_floor_normal, frame.floor_normal)
	var before := TelemetryLog.format_vector(previous_floor_normal)
	var after := TelemetryLog.format_vector(frame.floor_normal)
	return "normal do chao antes %s agora %s, mudou %.1f graus" % [before, after, change]


static func _center_text(frame: CarTelemetryFrame) -> String:
	if is_inf(frame.center_ground_drop):
		return "centro do carro: nenhum chao ate 1.5 m abaixo"
	return "centro do carro: chao %.2f m abaixo da base" % frame.center_ground_drop
