extends TestCase

const SLOPE_ANGLE := 0.314159
const WHEEL_HALF_WIDTH := 1.0
const WHEEL_HALF_BASE := 1.0


func test_flat_ground_points_straight_up() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, 0.0, 0.0)
	assert_true(probe.found_ground, "chao plano e encontrado")
	assert_near(probe.surface_normal.y, 1.0, 0.001, "normal do chao plano aponta para cima")
	assert_near(probe.center_height, 0.0, 0.001, "altura do centro no chao plano")


func test_slope_tilts_normal_backwards() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, SLOPE_ANGLE, 0.0)
	var expected_tilt := absf(probe.surface_normal.angle_to(Vector3.UP))
	assert_near(expected_tilt, SLOPE_ANGLE, 0.001, "inclinacao da normal e a da rampa")
	assert_true(probe.surface_normal.z > 0.0, "subir para -Z inclina a normal para tras")


func test_center_height_is_average_of_wheels() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, SLOPE_ANGLE, 2.0)
	var expected_height := 2.0
	assert_near(probe.center_height, expected_height, 0.001, "altura do centro e a media das rodas")


func test_wall_like_plane_is_rejected() -> void:
	var probe := GroundProbe.new()
	(
		probe
		. fit_plane(
			Vector3(-1.0, 0.0, -1.0),
			Vector3(-1.0, 5.0, -1.0),
			Vector3(-1.0, 0.0, 1.0),
			Vector3(-1.0, 5.0, 1.0),
		)
	)
	assert_true(not probe.found_ground, "plano vertical nao conta como chao")


func _fit_slope(probe: GroundProbe, angle: float, base_height: float) -> void:
	var rise_per_meter := tan(angle)
	var front_height := base_height + WHEEL_HALF_BASE * rise_per_meter
	var rear_height := base_height - WHEEL_HALF_BASE * rise_per_meter
	(
		probe
		. fit_plane(
			Vector3(-WHEEL_HALF_WIDTH, front_height, -WHEEL_HALF_BASE),
			Vector3(WHEEL_HALF_WIDTH, front_height, -WHEEL_HALF_BASE),
			Vector3(-WHEEL_HALF_WIDTH, rear_height, WHEEL_HALF_BASE),
			Vector3(WHEEL_HALF_WIDTH, rear_height, WHEEL_HALF_BASE),
		)
	)


func test_no_lift_when_wheels_rest_on_flat_ground() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, 0.0, 0.0)
	var lift := probe.required_lift(Transform3D.IDENTITY)
	assert_near(lift, 0.0, 0.001, "rodas apoiadas no chao nao precisam subir")


func test_lift_when_visual_is_below_ground() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, 0.0, 0.0)
	var sunken_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, -0.5, 0.0))
	var lift := probe.required_lift(sunken_transform)
	assert_near(lift, 0.5, 0.001, "visual 0.5 abaixo do chao sobe 0.5")


func test_lift_when_nose_points_down_into_ground() -> void:
	var probe := GroundProbe.new()
	_fit_slope(probe, 0.0, 0.0)
	var nose_down_basis := Basis(Vector3.RIGHT, deg_to_rad(-30.0))
	var lift := probe.required_lift(Transform3D(nose_down_basis, Vector3.ZERO))
	assert_true(lift > 0.3, "nariz para baixo enterra a roda da frente e pede lift")


func test_no_lift_without_ground() -> void:
	var probe := GroundProbe.new()
	var lift := probe.required_lift(Transform3D(Basis.IDENTITY, Vector3(0.0, -5.0, 0.0)))
	assert_near(lift, 0.0, 0.001, "sem chao encontrado nao levanta nada")


func test_three_wheels_on_flat_ground_find_ground() -> void:
	var probe := GroundProbe.new()
	probe.fit_plane_from_three(
		Vector3(-1.0, 2.0, -1.0), Vector3(1.0, 2.0, -1.0), Vector3(-1.0, 2.0, 1.0), Vector3.ZERO
	)
	assert_true(probe.found_ground, "tres rodas no chao bastam")
	assert_near(probe.surface_normal.y, 1.0, 0.001, "normal aponta para cima")
	assert_near(probe.center_height, 2.0, 0.001, "altura no centro do carro")


func test_three_wheels_on_slope_give_height_at_car_center() -> void:
	var probe := GroundProbe.new()
	var rise_per_meter := tan(SLOPE_ANGLE)
	(
		probe
		. fit_plane_from_three(
			Vector3(-1.0, rise_per_meter, -1.0),
			Vector3(1.0, rise_per_meter, -1.0),
			Vector3(1.0, -rise_per_meter, 1.0),
			Vector3.ZERO,
		)
	)
	assert_near(probe.center_height, 0.0, 0.001, "altura da rampa no centro do carro")
	var tilt := probe.surface_normal.angle_to(Vector3.UP)
	assert_near(tilt, SLOPE_ANGLE, 0.001, "inclinacao vem dos tres pontos")


func test_two_wheels_on_slope_edge_give_height_at_car_center() -> void:
	var probe := GroundProbe.new()
	var rise_per_meter := tan(SLOPE_ANGLE)
	var slope_up := Vector3(0.0, 1.0, rise_per_meter).normalized()
	var front_wheel := Vector3(1.0, rise_per_meter, -1.0)
	var rear_wheel := Vector3(1.0, -rise_per_meter, 1.0)
	var car_center := Vector3(0.0, 5.0, 0.0)
	probe.fit_plane_from_two(front_wheel, rear_wheel, slope_up * 2.0, car_center)
	assert_true(probe.found_ground, "duas rodas na borda da rampa bastam")
	assert_near(probe.center_height, 0.0, 0.001, "altura da rampa no centro do carro")
	var tilt := probe.surface_normal.angle_to(Vector3.UP)
	assert_near(tilt, SLOPE_ANGLE, 0.001, "inclinacao vem da normal que as rodas acharam")


func test_two_wheels_keep_plane_through_both_points() -> void:
	var probe := GroundProbe.new()
	var left_wheel := Vector3(-1.0, 0.0, 0.0)
	var right_wheel := Vector3(1.0, 0.4, 0.0)
	probe.fit_plane_from_two(left_wheel, right_wheel, Vector3.UP, Vector3.ZERO)
	var line_between_wheels := right_wheel - left_wheel
	var normal_across_line := probe.surface_normal.dot(line_between_wheels)
	assert_near(normal_across_line, 0.0, 0.001, "o plano passa pelas duas rodas")
	assert_near(probe.center_height, 0.2, 0.001, "altura no meio das duas rodas")


func test_two_wheels_are_not_enough_for_driving_slope() -> void:
	var probe := GroundProbe.new()
	probe.wheel_ground_names.assign(["Ramp", "Ramp"])
	var left_wheel := Vector3(-1.0, 0.0, 0.0)
	var right_wheel := Vector3(1.0, 0.0, 0.0)
	probe.fit_plane_from_two(left_wheel, right_wheel, Vector3.UP, Vector3.ZERO)
	assert_true(probe.found_ground, "duas rodas acham chao para o visual")
	var message := "duas rodas nao bastam para inclinar a velocidade do carro"
	assert_true(not probe.found_ground_under_most_wheels(), message)
