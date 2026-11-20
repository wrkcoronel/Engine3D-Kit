extends TestCase

const LOAD := 2500.0
const MASS_PER_WHEEL := 250.0
const FRAME_TIME := 1.0 / 60.0


func test_friction_limit_caps_the_force() -> void:
	var limited := CarTires.limit_to_friction(Vector2(3000.0, 4000.0), 2500.0)
	assert_near(limited.length(), 2500.0, 0.01, "a forca total nao passa do atrito")
	assert_near(limited.x / limited.y, 0.75, 0.001, "a direcao da forca nao muda")


func test_sideways_grip_never_reverses_the_slide() -> void:
	var tires := CarTires.new()
	var command := CarWheelCommand.new()
	var slow_slide := 0.01
	var push := tires.force_on_ground(command, 0.0, slow_slide, LOAD, MASS_PER_WHEEL, FRAME_TIME)
	var force_that_stops_slide := MASS_PER_WHEEL * slow_slide / FRAME_TIME
	assert_true(push.y < 0.0, "o pneu empurra contra o deslize")
	assert_true(absf(push.y) <= force_that_stops_slide + 0.01, "e no maximo o que para o deslize")
	tires.free()


func test_brake_stops_without_pushing_backwards() -> void:
	var tires := CarTires.new()
	var command := CarWheelCommand.new()
	command.brake_force = 5000.0
	var almost_stopped := 0.1
	var push := tires.force_on_ground(
		command, almost_stopped, 0.0, LOAD, MASS_PER_WHEEL, FRAME_TIME
	)
	var force_that_stops := -MASS_PER_WHEEL * almost_stopped / FRAME_TIME
	assert_near(push.x, force_that_stops, 0.01, "quase parado o freio so para, nao da re")
	tires.free()


func test_locked_wheel_slides_with_less_grip() -> void:
	var tires := CarTires.new()
	var command := CarWheelCommand.new()
	command.locked = true
	var push := tires.force_on_ground(command, 20.0, 5.0, LOAD, MASS_PER_WHEEL, FRAME_TIME)
	var sliding_limit := tires.sliding_friction * LOAD
	assert_near(push.length(), sliding_limit, 0.01, "roda travada desliza com atrito menor")
	tires.free()


func test_too_much_drive_force_spins_the_wheel() -> void:
	var tires := CarTires.new()
	var command := CarWheelCommand.new()
	command.drive_force = 5500.0
	var push := tires.force_on_ground(command, 0.0, 0.0, LOAD, MASS_PER_WHEEL, FRAME_TIME)
	assert_near(push.x, tires.peak_friction * LOAD, 0.01, "o chao so devolve o atrito maximo")
	assert_true(tires.is_slipping(command, 0.0, 0.0, LOAD), "e a roda patina")
	tires.free()


func test_gentle_drive_force_does_not_spin() -> void:
	var tires := CarTires.new()
	var command := CarWheelCommand.new()
	command.drive_force = 1000.0
	assert_true(not tires.is_slipping(command, 10.0, 0.0, LOAD), "acelerar de leve nao patina")
	tires.free()
