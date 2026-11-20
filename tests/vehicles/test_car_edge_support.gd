extends TestCase

const GAME_GRAVITY := 19.6


func test_supported_car_stays_grounded_mode() -> void:
	var edge := CarEdgeSupport.new()
	edge.update(true, 0.1, 1)
	assert_true(not edge.hanging_off_edge, "com chao embaixo do centro nao esta pendurado")
	assert_eq(edge.motion_mode(), CharacterBody3D.MOTION_MODE_GROUNDED, "modo normal")


func test_center_over_void_starts_sliding_off() -> void:
	var edge := CarEdgeSupport.new()
	edge.update(true, INF, 1)
	assert_true(edge.hanging_off_edge, "no chao com o centro sobre o vazio esta pendurado")
	assert_eq(edge.motion_mode(), CharacterBody3D.MOTION_MODE_FLOATING, "escorrega flutuando")


func test_flying_car_is_not_hanging() -> void:
	var edge := CarEdgeSupport.new()
	edge.update(false, INF, 0)
	assert_true(not edge.hanging_off_edge, "no ar nao esta pendurado")


func test_stops_hanging_when_free_of_the_edge() -> void:
	var edge := CarEdgeSupport.new()
	edge.update(true, INF, 1)
	edge.update(false, INF, 0)
	assert_true(not edge.hanging_off_edge, "sem encostar em nada volta ao modo normal")


func test_keeps_hanging_while_touching_edge() -> void:
	var edge := CarEdgeSupport.new()
	edge.update(true, INF, 1)
	edge.update(false, 0.8, 1)
	assert_true(edge.hanging_off_edge, "encostando na quina com o centro alto continua")


func test_crest_launch_speed_is_about_71_kmh() -> void:
	var speed := CarEdgeSupport.crest_launch_speed(GAME_GRAVITY)
	assert_near(speed, 19.80, 0.01, "abaixo de ~71 km/h o carro nao decola do topo")


func test_slow_car_snaps_back_while_center_over_ramp() -> void:
	var edge := CarEdgeSupport.new()
	var snaps := edge.should_snap_back(true, false, 0.5, 9.0, GAME_GRAVITY)
	assert_true(snaps, "devagar, com o centro sobre a rampa, volta para o chao")


func test_fast_car_launches_from_crest() -> void:
	var edge := CarEdgeSupport.new()
	var snaps := edge.should_snap_back(true, false, 0.5, 30.0, GAME_GRAVITY)
	assert_true(not snaps, "rapido decola do topo")


func test_no_snap_with_center_over_void() -> void:
	var edge := CarEdgeSupport.new()
	var snaps := edge.should_snap_back(true, false, INF, 5.0, GAME_GRAVITY)
	assert_true(not snaps, "com o centro sobre o vazio nao puxa de volta")


func test_pushes_along_the_edge_normal_without_lift() -> void:
	var edge := CarEdgeSupport.new()
	var normals_touched: Array[Vector3] = [Vector3(0.6, 0.8, 0.0)]
	var push := edge.slide_push(normals_touched, 0.0, 0.5)
	assert_near(push.x, CarEdgeSupport.SLIDE_OFF_ACCELERATION * 0.5, 0.001, "empurra para fora")
	assert_eq(push.y, 0.0, "empurrao e horizontal")


func test_no_push_when_already_sliding_fast() -> void:
	var edge := CarEdgeSupport.new()
	var normals_touched: Array[Vector3] = [Vector3(0.6, 0.8, 0.0)]
	var push := edge.slide_push(normals_touched, 10.0, 0.5)
	assert_eq(push, Vector3.ZERO, "rapido nao precisa de empurrao")


func test_no_push_on_flat_ground_contact() -> void:
	var edge := CarEdgeSupport.new()
	var normals_touched: Array[Vector3] = [Vector3.UP]
	var push := edge.slide_push(normals_touched, 0.0, 0.5)
	assert_eq(push, Vector3.ZERO, "apoio plano nao empurra para lado nenhum")
