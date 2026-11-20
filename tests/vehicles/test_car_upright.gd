extends TestCase


func test_standing_car_is_not_flipped() -> void:
	assert_true(not CarUpright.is_flipped(Basis.IDENTITY), "em pe nao esta capotado")


func test_upside_down_car_is_flipped() -> void:
	var upside_down := Basis(Vector3.FORWARD, PI)
	assert_true(CarUpright.is_flipped(upside_down), "de cabeca para baixo esta capotado")


func test_car_on_its_side_is_flipped() -> void:
	var on_side := Basis(Vector3.FORWARD, PI / 2.0)
	assert_true(CarUpright.is_flipped(on_side), "deitado de lado esta capotado")


func test_fast_car_cannot_upright() -> void:
	var upside_down := Basis(Vector3.FORWARD, PI)
	var fast := CarUpright.MAX_SPEED + 1.0
	assert_true(not CarUpright.can_upright(upside_down, fast), "andando rapido nao desvira")


func test_upright_keeps_heading_and_lifts() -> void:
	var heading := Basis(Vector3.UP, 0.7)
	var rolled := heading * Basis(Vector3.FORWARD, PI)
	var start := Transform3D(rolled, Vector3(3.0, 0.5, -2.0))
	var standing := CarUpright.upright_transform(start)
	var standing_up := standing.basis.y
	assert_near(
		standing_up.dot(Vector3.UP), 1.0, 0.001, "depois de desvirar o teto aponta para cima"
	)
	var lift := standing.origin.y - start.origin.y
	assert_near(lift, CarUpright.LIFT, 0.001, "sobe um pouco para nao nascer dentro do chao")
	var forward_before := -heading.z
	var forward_after := -standing.basis.z
	assert_near(
		forward_after.dot(forward_before), 1.0, 0.001, "continua apontando para o mesmo lado"
	)
