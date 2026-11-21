extends TestCase


func test_center_is_deeper_than_the_rim() -> void:
	var center_height := BulletHoleTexture.height_at(0.0)
	var rim_height := BulletHoleTexture.height_at(BulletHoleTexture.RIM_RADIUS)
	assert_true(center_height < 0.0, "o centro afunda")
	assert_true(rim_height > 0.0, "a borda levanta")


func test_outside_the_hole_is_flat_and_transparent() -> void:
	assert_near(BulletHoleTexture.height_at(1.2), 0.0, 0.0001, "fora do furo nao tem relevo")
	assert_near(BulletHoleTexture.color_at(1.2).a, 0.0, 0.0001, "fora do furo e transparente")


func test_center_is_black_and_opaque() -> void:
	var center_color := BulletHoleTexture.color_at(0.0)
	assert_near(center_color.a, 1.0, 0.0001, "centro opaco")
	assert_true(center_color.v < 0.05, "centro escuro")


func test_textures_are_built_with_the_expected_size() -> void:
	assert_eq(BulletHoleTexture.albedo().get_width(), BulletHoleTexture.TEXTURE_SIZE, "cor")
	assert_eq(BulletHoleTexture.normal().get_width(), BulletHoleTexture.TEXTURE_SIZE, "normal")
