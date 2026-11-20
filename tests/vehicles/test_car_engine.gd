extends TestCase

const IDLE := 900.0
const PEAK := 4000.0
const REDLINE := 6800.0
const FRAME_TIME := 1.0 / 60.0


func test_torque_is_strongest_at_peak_rpm() -> void:
	var at_peak := CarEngine.torque_fraction_at(PEAK, IDLE, PEAK, REDLINE)
	var at_idle := CarEngine.torque_fraction_at(IDLE, IDLE, PEAK, REDLINE)
	var near_redline := CarEngine.torque_fraction_at(REDLINE, IDLE, PEAK, REDLINE)
	assert_near(at_peak, 1.0, 0.001, "o motor tem a forca maxima no pico")
	assert_true(at_idle < at_peak, "em marcha lenta tem menos forca")
	assert_true(near_redline < at_peak, "perto do corte tem menos forca")


func test_limiter_cuts_torque_past_redline() -> void:
	var past_redline := CarEngine.torque_fraction_at(REDLINE + 100.0, IDLE, PEAK, REDLINE)
	assert_eq(past_redline, 0.0, "passou do corte, o motor nao empurra")


func test_rpm_follows_wheel_speed_and_ratio() -> void:
	var wheel_turns_once_per_second := TAU * CarSuspension.WHEEL_RADIUS
	var rpm := CarEngine.engine_rpm_for(wheel_turns_once_per_second, 2.0)
	assert_near(rpm, 120.0, 0.01, "roda a 60 rpm com relacao 2 deixa o motor em 120 rpm")


func test_first_gear_pushes_harder_than_top_gear() -> void:
	var engine := CarEngine.new()
	var first_gear_force := CarEngine.wheel_force_from(100.0, engine.gear_ratios[0], 1.0)
	var top_gear_force := CarEngine.wheel_force_from(100.0, engine.gear_ratios[4], 1.0)
	assert_true(first_gear_force > top_gear_force * 4.0, "a primeira marcha multiplica a forca")
	engine.free()


func test_shifts_up_past_shift_rpm() -> void:
	var engine := CarEngine.new()
	var speed_past_shift := _speed_for_rpm(engine, engine.shift_up_rpm + 200.0)
	engine.update(1.0, speed_past_shift, FRAME_TIME)
	assert_eq(engine.gear, 2, "passou da rotacao de troca, sobe a marcha")
	assert_eq(engine.drive_force(), 0.0, "durante a troca o motor nao empurra")
	engine.free()


func test_reverse_when_braking_from_stop() -> void:
	var engine := CarEngine.new()
	engine.update(-1.0, 0.0, FRAME_TIME)
	assert_eq(engine.gear, CarEngine.REVERSE, "parado e segurando S, engata a re")
	assert_true(engine.drive_force() < 0.0, "de re o motor empurra para tras")
	assert_eq(engine.gear_text(), "R", "o painel mostra R")
	engine.free()


func test_braking_while_moving_forward_does_not_reverse() -> void:
	var engine := CarEngine.new()
	engine.update(-1.0, 10.0, FRAME_TIME)
	assert_eq(engine.gear, CarEngine.FIRST, "andando para frente, S freia em vez de engatar a re")
	assert_eq(engine.drive_force(), 0.0, "e o motor nao empurra")
	engine.free()


func _speed_for_rpm(engine: CarEngine, target_rpm: float) -> float:
	var rpm_at_one_meter_per_second := CarEngine.engine_rpm_for(1.0, engine.total_ratio())
	return target_rpm / rpm_at_one_meter_per_second
