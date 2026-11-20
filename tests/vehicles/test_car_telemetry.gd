extends TestCase

const FRAME_TIME := 1.0 / 60.0
const FLOOR_NAME := "World/Floor"
const RAMP_NAME := "Ramps/Ramp1"


func test_first_frame_has_no_events() -> void:
	var telemetry := CarTelemetry.new()
	var events := telemetry.events_for(_frame_on_floor(Vector3.ZERO), FRAME_TIME)
	assert_eq(events.size(), 0, "sem frame anterior nao ha o que comparar")


func test_steady_driving_has_no_events() -> void:
	var telemetry := CarTelemetry.new()
	var velocity := Vector3(0.0, 0.0, -20.0)
	telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	var events := telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	assert_eq(events.size(), 0, "andando reto no chao nao gera evento")


func test_short_air_time_is_flagged_as_possible_bump() -> void:
	var telemetry := CarTelemetry.new()
	var velocity := Vector3(0.0, 0.0, -20.0)
	telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	var takeoff_events := telemetry.events_for(_frame_in_air(velocity), FRAME_TIME)
	var landing_events := telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	assert_true(_has_event(takeoff_events, "SAIU DO CHAO"), "registra a decolagem")
	assert_true(_has_event(landing_events, "PERDEU O CHAO RAPIDO"), "avisa do quique curto")


func test_long_jump_is_not_flagged_as_bump() -> void:
	var telemetry := CarTelemetry.new()
	var velocity := Vector3(0.0, 0.0, -20.0)
	telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	for frame_index: int in 60:
		telemetry.events_for(_frame_in_air(velocity), FRAME_TIME)
	var landing_events := telemetry.events_for(_frame_on_floor(velocity), FRAME_TIME)
	assert_true(_has_event(landing_events, "voltou ao chao"), "registra o pouso")
	assert_true(not _has_event(landing_events, "PERDEU O CHAO RAPIDO"), "pulo longo nao e quique")


func test_vertical_kick_on_floor_is_a_bump() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -20.0)), FRAME_TIME)
	var events := telemetry.events_for(_frame_on_floor(Vector3(0.0, 3.0, -20.0)), FRAME_TIME)
	assert_true(_has_event(events, "SOLAVANCO"), "subir 3 m/s de uma vez no chao e solavanco")


func test_sudden_speed_loss_is_reported() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -20.0)), FRAME_TIME)
	var events := telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -10.0)), FRAME_TIME)
	assert_true(_has_event(events, "FREOU DE REPENTE"), "perder 10 m/s em um frame e anormal")


func test_normal_braking_is_not_reported() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -20.0)), FRAME_TIME)
	var events := telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -19.3)), FRAME_TIME)
	assert_true(not _has_event(events, "FREOU DE REPENTE"), "freio normal nao e avisado")


func test_ground_change_is_reported() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3.ZERO), FRAME_TIME)
	var frame_on_ramp := _frame_on_floor(Vector3.ZERO)
	frame_on_ramp.wheel_ground_names = [FLOOR_NAME, FLOOR_NAME, RAMP_NAME, RAMP_NAME]
	var events := telemetry.events_for(frame_on_ramp, FRAME_TIME)
	assert_true(_has_event(events, RAMP_NAME), "avisa quando as rodas chegam na rampa")


func test_new_contact_is_reported_once() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3.ZERO), FRAME_TIME)
	var touching_wall := _frame_on_floor(Vector3.ZERO)
	touching_wall.contacts = ["World/Wall normal (0.00, 0.00, 1.00)"]
	touching_wall.contact_points = [Vector3.ZERO]
	var first_events := telemetry.events_for(touching_wall, FRAME_TIME)
	var second_events := telemetry.events_for(touching_wall, FRAME_TIME)
	assert_true(_has_event(first_events, "encostou em World/Wall"), "avisa o primeiro toque")
	assert_eq(second_events.size(), 0, "nao repete enquanto continua encostado")


func test_forget_starts_over() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -20.0)), FRAME_TIME)
	telemetry.forget()
	var events := telemetry.events_for(_frame_in_air(Vector3.ZERO), FRAME_TIME)
	assert_eq(events.size(), 0, "depois de sair do carro nao compara com o frame velho")


func test_describe_shows_speed_and_wheels() -> void:
	var text := _frame_on_floor(Vector3(0.0, 0.0, -10.0)).describe()
	assert_true(text.contains("36 km/h"), "mostra a velocidade em km/h")
	assert_true(text.contains("rodas sobre chao 4/4"), "mostra quantas rodas tocam o chao")


func _frame_on_floor(velocity: Vector3) -> CarTelemetryFrame:
	var frame := CarTelemetryFrame.new(Vector3.ZERO, velocity, CarInput.new())
	frame.on_floor = true
	frame.wheel_ground_names = [FLOOR_NAME, FLOOR_NAME, FLOOR_NAME, FLOOR_NAME]
	frame.wheel_ground_heights = [0.0, 0.0, 0.0, 0.0]
	return frame


func _frame_in_air(velocity: Vector3) -> CarTelemetryFrame:
	var frame := _frame_on_floor(velocity)
	frame.on_floor = false
	return frame


func _has_event(events: Array[String], text: String) -> bool:
	for event: String in events:
		if event.contains(text):
			return true
	return false


func test_sudden_stop_lists_contacts() -> void:
	var telemetry := CarTelemetry.new()
	telemetry.events_for(_frame_on_floor(Vector3(0.0, 0.0, -20.0)), FRAME_TIME)
	var crashed := _frame_on_floor(Vector3.ZERO)
	crashed.contact_names = ["Buildings/Building7"]
	var events := telemetry.events_for(crashed, FRAME_TIME)
	assert_true(_has_event(events, "contatos: [Buildings/Building7]"), "diz em que bateu")
