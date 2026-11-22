extends TestCase


func test_smoke_texture_is_opaque_in_center_and_transparent_at_edge() -> void:
	var image := MuzzleSmokeTexture.build_image(48, 409)
	var center := image.get_pixel(24, 24)
	var corner := image.get_pixel(0, 0)
	assert_true(center.a > 0.35, "centro da nuvem tem opacidade")
	assert_near(corner.a, 0.0, 0.01, "borda da textura some totalmente")


func test_smoke_texture_is_cached() -> void:
	var first := MuzzleSmokeTexture.get_texture()
	var second := MuzzleSmokeTexture.get_texture()
	assert_true(first == second, "reaproveita a mesma textura de fumaca")


func test_smoke_emitter_uses_lit_rotating_puffs() -> void:
	var emitter := MuzzleSmoke.create()
	spawn(emitter)
	var quad := emitter.mesh as QuadMesh
	var material := quad.material as StandardMaterial3D
	assert_eq(
		material.shading_mode,
		BaseMaterial3D.SHADING_MODE_PER_PIXEL,
		"fumaca recebe luz da cena e do clarao"
	)
	assert_true(material.proximity_fade_enabled, "fumaca suaviza perto do cano e paredes")
	assert_true(emitter.angular_velocity_max > 0.0, "particulas giram ao subir")
	assert_true(emitter.amount >= 6, "nuvem composta por varias particulas")
