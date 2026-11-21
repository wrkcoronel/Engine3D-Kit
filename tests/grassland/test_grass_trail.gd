extends TestCase


func test_footprint_is_a_rectangle_around_the_vehicle_in_map_pixels() -> void:
	var vehicle_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0))
	var corners := GrassTrail.footprint_in_map(
		vehicle_transform, Vector2(1.0, 2.0), 0.0, Vector2(-20.0, -20.0), 40.0, 400
	)
	assert_eq(corners.size(), 4, "quatro cantos")
	assert_eq(corners[0], Vector2(190.0, 180.0), "canto de tras a esquerda")
	assert_eq(corners[2], Vector2(210.0, 220.0), "canto da frente a direita")


func test_footprint_includes_padding() -> void:
	var corners := GrassTrail.footprint_in_map(
		Transform3D.IDENTITY, Vector2(1.0, 2.0), 1.0, Vector2(-20.0, -20.0), 40.0, 400
	)
	assert_eq(corners[0], Vector2(180.0, 170.0), "folga aumenta o retangulo")


func test_footprint_follows_vehicle_rotation() -> void:
	var quarter_turn := Basis(Vector3.UP, PI / 2.0)
	var corners := GrassTrail.footprint_in_map(
		Transform3D(quarter_turn, Vector3.ZERO),
		Vector2(1.0, 2.0),
		0.0,
		Vector2(-20.0, -20.0),
		40.0,
		400
	)
	var width := absf(corners[2].x - corners[0].x)
	assert_near(width, 40.0, 0.01, "o lado comprido agora fica no eixo x")


func test_footprint_follows_the_window_origin() -> void:
	var vehicle_transform := Transform3D(Basis.IDENTITY, Vector3(100.0, 0.0, 50.0))
	var corners := GrassTrail.footprint_in_map(
		vehicle_transform, Vector2(1.0, 2.0), 0.0, Vector2(80.0, 30.0), 40.0, 400
	)
	assert_eq(corners[0], Vector2(190.0, 180.0), "janela deslocada, mesmo lugar no mapa")


func test_clear_all_asks_for_a_fresh_map() -> void:
	var trail := GrassTrail.new()
	trail.setup(64, 25.5)
	spawn(trail)
	trail.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	trail.clear_all()
	assert_eq(trail.render_target_clear_mode, SubViewport.CLEAR_MODE_ONCE, "limpa uma vez")


func test_fade_happens_once_per_interval() -> void:
	var trail := GrassTrail.new()
	trail.setup(64, 25.5)
	spawn(trail)
	var fades := 0
	for frame_index: int in 600:
		trail.advance(0.1)
		if trail.fade_is_due():
			fades += 1
	assert_eq(fades, 300, "60 s com uma apagada a cada 0.2 s")
