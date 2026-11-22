extends TestCase

const STEP_TIME := 0.016
const STEPS := 120


func test_standing_still_does_not_move_the_flashlight() -> void:
	var sway := FlashlightSway.new()
	for step: int in STEPS:
		sway.update(STEP_TIME, 0.0, 0.0)
	var rest := Transform3D(Basis.IDENTITY, Vector3(-0.2, -0.18, -0.3))
	var result := sway.apply(rest, 1.0)
	assert_near(result.origin.distance_to(rest.origin), 0.0, 0.0001, "parada nao balanca")


func test_walking_swings_the_flashlight_back_and_forth() -> void:
	var sway := FlashlightSway.new()
	var rest := Transform3D(Basis.IDENTITY, Vector3(-0.2, -0.18, -0.3))
	var smallest_depth := 0.0
	var largest_depth := 0.0
	for step: int in 400:
		sway.update(STEP_TIME, 6.0, 0.0)
		var depth := sway.apply(rest, 1.0).origin.z - rest.origin.z
		smallest_depth = minf(smallest_depth, depth)
		largest_depth = maxf(largest_depth, depth)
	assert_true(smallest_depth < -0.005, "vai para a frente")
	assert_true(largest_depth > 0.005, "volta para tras")


func test_sprinting_lowers_and_tilts_the_flashlight_more_than_walking() -> void:
	var rest := Transform3D(Basis.IDENTITY, Vector3(-0.2, -0.18, -0.3))
	var walked := FlashlightSway.swayed_pose(rest, 0.0, 1.0, 0.0)
	var sprinted := FlashlightSway.swayed_pose(rest, 0.0, 0.0, 1.0)
	assert_true(sprinted.origin.y < walked.origin.y, "correndo fica mais baixa")
	var walked_tilt := walked.basis.z.distance_to(rest.basis.z)
	var sprinted_tilt := sprinted.basis.z.distance_to(rest.basis.z)
	assert_true(sprinted_tilt > walked_tilt, "correndo aponta mais para o chao")


func test_steadiness_zero_cancels_the_swing() -> void:
	var sway := FlashlightSway.new()
	var rest := Transform3D(Basis.IDENTITY, Vector3(-0.2, -0.18, -0.3))
	for step: int in STEPS:
		sway.update(STEP_TIME, 6.0, 1.0)
	var result := sway.apply(rest, 0.0)
	assert_near(result.origin.distance_to(rest.origin), 0.0, 0.0001, "sem balanco")
