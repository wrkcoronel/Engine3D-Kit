extends TestCase


func test_ramp_target_places_player_in_front_of_ramp_facing_it() -> void:
	var ramp_transform := Transform3D(Basis.IDENTITY, Vector3(20.0, 0.0, -8.59))
	var target := WorldTeleporter.ramp_target_transform(ramp_transform, false)
	assert_near(target.origin.x, 20.0, 0.01, "x alinhado com a rampa")
	assert_near(target.origin.y, WorldTeleporter.PLAYER_GROUND_HEIGHT, 0.01, "altura do jogador")
	assert_near(
		target.origin.z,
		-8.59 + WorldTeleporter.RAMP_APPROACH_DISTANCE,
		0.01,
		"fica antes da base baixa da rampa"
	)
	assert_near(target.basis.z.z, 1.0, 0.01, "olha para -Z da rampa")


func test_ramp_target_respects_ramp_rotation() -> void:
	var rotated_basis := Basis(Vector3.UP, PI * 0.5)
	var ramp_transform := Transform3D(rotated_basis, Vector3(60.0, 0.0, 110.0))
	var target := WorldTeleporter.ramp_target_transform(ramp_transform, true)
	assert_near(
		target.origin.x,
		60.0 + WorldTeleporter.RAMP_APPROACH_DISTANCE,
		0.05,
		"recua no eixo +Z local da rampa girada"
	)
	assert_near(target.origin.y, WorldTeleporter.VEHICLE_GROUND_HEIGHT, 0.01, "altura do carro")
	assert_near(target.origin.z, 110.0, 0.05, "mantem z da rampa girada")


func test_motel_target_places_player_and_vehicle_in_courtyard() -> void:
	var motel_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 175.0))
	var player_target := WorldTeleporter.motel_target_transform(motel_transform, false)
	var vehicle_target := WorldTeleporter.motel_target_transform(motel_transform, true)
	assert_near(player_target.origin.x, 0.5, 0.01, "x do jogador no motel")
	assert_near(player_target.origin.y, 1.0, 0.01, "y do jogador no motel")
	assert_near(player_target.origin.z, 179.5, 0.01, "z do jogador no motel")
	assert_near(vehicle_target.origin.x, 4.5, 0.01, "x do carro no motel")
	assert_near(vehicle_target.origin.y, 0.2, 0.01, "y do carro no motel")
	assert_near(vehicle_target.origin.z, 182.0, 0.01, "z do carro no motel")


func test_bring_car_places_vehicle_ahead_of_player() -> void:
	var player_transform := Transform3D(Basis.IDENTITY, Vector3(10.0, 1.0, 20.0))
	var target := WorldTeleporter.bring_car_target_transform(player_transform)
	assert_near(target.origin.x, 10.0, 0.01, "carro alinhado no x do jogador")
	assert_near(target.origin.y, WorldTeleporter.VEHICLE_GROUND_HEIGHT, 0.01, "carro no chao")
	assert_near(
		target.origin.z,
		20.0 - WorldTeleporter.BRING_CAR_DISTANCE,
		0.01,
		"carro aparece na frente do jogador"
	)


func test_go_to_car_places_player_beside_vehicle() -> void:
	var car_transform := Transform3D(Basis.IDENTITY, Vector3(30.0, 0.2, -15.0))
	var target := WorldTeleporter.go_to_car_target_transform(car_transform)
	assert_near(
		target.origin.x,
		30.0 - WorldTeleporter.GO_TO_CAR_SIDE_DISTANCE,
		0.01,
		"jogador aparece ao lado esquerdo do carro"
	)
	assert_near(target.origin.y, WorldTeleporter.PLAYER_GROUND_HEIGHT, 0.01, "jogador no chao")
	assert_near(target.origin.z, -15.0, 0.01, "jogador alinhado no z do carro")
