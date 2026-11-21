extends TestCase


func test_standing_car_smoke_goes_straight_up() -> void:
	var direction := CarSmoke.trailing_direction(Vector3.ZERO)
	assert_eq(direction, Vector3.UP, "parado sobe reto")


func test_moving_car_pulls_smoke_backward() -> void:
	var moving_forward := Vector3(0.0, 0.0, -20.0)
	var direction := CarSmoke.trailing_direction(moving_forward)
	assert_true(direction.z > 0.1, "fumaca vai para tras")
	assert_true(direction.y > 0.0, "e ainda sobe")


func test_pull_stops_growing_at_max_speed() -> void:
	var fast := CarSmoke.trailing_direction(Vector3(0.0, 0.0, -30.0))
	var absurd := CarSmoke.trailing_direction(Vector3(0.0, 0.0, -300.0))
	assert_near(fast.z, absurd.z, 0.001, "limite de velocidade")


func test_setup_adds_two_tire_emitters_and_one_exhaust() -> void:
	var visual := _make_visual()
	var smoke := _make_smoke(visual)
	assert_eq(visual.get_child_count(), 3, "dois pneus e um escapamento")
	assert_eq(smoke.tire_positions().size(), 2, "duas posicoes de pneu")


func test_tire_smoke_emits_only_above_threshold() -> void:
	var visual := _make_visual()
	var smoke := _make_smoke(visual)
	var tire_emitter := visual.get_child(0) as CPUParticles3D
	smoke.update_tires(0.0, 0.0, Vector3.ZERO)
	assert_true(not tire_emitter.emitting, "sem derrapar nao fuma")
	smoke.update_tires(1.0, 1.0, Vector3.ZERO)
	assert_true(tire_emitter.emitting, "derrapando fuma")


func test_exhaust_smokes_only_with_engine_running() -> void:
	var visual := _make_visual()
	var smoke := _make_smoke(visual)
	var exhaust := visual.get_child(2) as CPUParticles3D
	smoke.update_exhaust(false, 1.0)
	assert_true(not exhaust.emitting, "motor desligado")
	smoke.update_exhaust(true, 0.0)
	assert_true(exhaust.emitting, "motor ligado")


func test_smoke_material_is_lit_and_soft() -> void:
	var visual := _make_visual()
	_make_smoke(visual)
	var emitter := visual.get_child(0) as CPUParticles3D
	var quad := emitter.mesh as QuadMesh
	var material := quad.material as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_PER_PIXEL, "recebe luz")
	assert_true(material.proximity_fade_enabled, "suaviza perto do chao")


func _make_visual() -> Node3D:
	var visual := Node3D.new()
	spawn(visual)
	return visual


func _make_smoke(visual: Node3D) -> CarSmoke:
	var smoke := CarSmoke.new()
	smoke.setup(visual, Vector3(1.0, 0.0, 0.4))
	return smoke
