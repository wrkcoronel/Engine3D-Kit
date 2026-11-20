extends TestCase

const MAX_ANGLE := 0.5
const FRAME_TIME := 1.0 / 60.0


func test_wheel_angle_is_full_when_stopped() -> void:
	var angle := CarSteering.wheel_angle(1.0, MAX_ANGLE, 0.0, 25.0)
	assert_near(angle, MAX_ANGLE, 0.0001, "parado o volante vira tudo")


func test_wheel_angle_halves_at_the_half_angle_speed() -> void:
	var angle := CarSteering.wheel_angle(1.0, MAX_ANGLE, 25.0, 25.0)
	assert_near(angle, MAX_ANGLE / 2.0, 0.0001, "rapido o volante vira menos")


func test_steering_moves_toward_input_gradually() -> void:
	var steering := CarSteering.new()
	steering.wheel_position = 0.1
	var after_one_frame := steering.smooth(1.0, 0.0, 4.0, 7.0, FRAME_TIME)
	assert_near(after_one_frame, 0.1 + 4.0 * FRAME_TIME, 0.0001, "o volante gira aos poucos")


func test_steering_returns_faster_than_it_turns() -> void:
	var steering := CarSteering.new()
	steering.wheel_position = 0.5
	var after_release := steering.smooth(0.0, 0.0, 4.0, 7.0, FRAME_TIME)
	assert_near(after_release, 0.5 - 7.0 * FRAME_TIME, 0.0001, "soltando ele volta mais rapido")
