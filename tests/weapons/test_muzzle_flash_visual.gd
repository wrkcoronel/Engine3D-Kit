extends TestCase


func test_star_is_hottest_in_the_center_and_fades_out() -> void:
	var spikes := MuzzleFlashTextures.random_spikes(1)
	var center := MuzzleFlashTextures.star_intensity(Vector2(0.001, 0.0), spikes)
	var edge := MuzzleFlashTextures.star_intensity(Vector2(0.99, 0.99), spikes)
	assert_near(center, 1.0, 0.01, "centro no maximo")
	assert_true(edge < 0.05, "borda quase apagada")


func test_star_reaches_farther_along_a_spike_than_between_spikes() -> void:
	var spikes: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(PI, 1.0)]
	var along_spike := MuzzleFlashTextures.star_intensity(Vector2(0.5, 0.0), spikes)
	var between_spikes := MuzzleFlashTextures.star_intensity(Vector2(0.0, 0.5), spikes)
	assert_true(along_spike > between_spikes * 2.0, "o raio aparece na direcao do espinho")


func test_flame_is_white_hot_in_the_middle_and_orange_at_the_edge() -> void:
	var hot := MuzzleFlashTextures.flame_color(1.0)
	var cool := MuzzleFlashTextures.flame_color(0.2)
	assert_true(hot.b > cool.b, "miolo mais claro que a ponta")
	assert_true(cool.r > cool.b, "ponta alaranjada")
	assert_near(cool.a, 0.2, 0.001, "intensidade vira transparencia")


func test_spikes_are_repeatable_and_vary_by_seed() -> void:
	assert_eq(
		MuzzleFlashTextures.random_spikes(4), MuzzleFlashTextures.random_spikes(4), "mesma semente"
	)
	assert_true(
		MuzzleFlashTextures.random_spikes(4) != MuzzleFlashTextures.random_spikes(5),
		"outra semente"
	)


func test_variants_are_cached() -> void:
	var first := MuzzleFlashTextures.star_variants()
	var second := MuzzleFlashTextures.star_variants()
	assert_eq(first.size(), MuzzleFlashTextures.VARIANT_COUNT, "quantidade de variacoes")
	assert_true(first[0] == second[0], "mesma textura reaproveitada")


func test_flash_shows_only_while_flashing_and_has_no_sphere() -> void:
	var visual := MuzzleFlashVisual.new()
	spawn(visual)
	assert_true(not visual.is_flashing(), "comeca apagado")
	visual.burst()
	visual.set_flashing(true)
	assert_true(visual.is_flashing(), "aceso no tiro")
	for child: Node in visual.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			assert_true(not (mesh_instance.mesh is SphereMesh), "sem bola")
	visual.set_flashing(false)
	assert_true(not visual.is_flashing(), "apaga depois")


func test_smoke_is_one_shot_and_survives_flash_hiding() -> void:
	var visual := MuzzleFlashVisual.new()
	spawn(visual)
	visual.burst()
	visual.set_flashing(false)
	var smoke := visual.get_child(2) as CPUParticles3D
	assert_true(smoke.one_shot, "fumaca de um disparo")
	assert_true(smoke.emitting, "fumaca continua depois do clarao apagar")
	assert_true(visual.visible, "o no do cano continua visivel")
