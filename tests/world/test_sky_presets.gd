extends TestCase

const WORLD_SCENE := "res://contexts/world/world.tscn"


func test_dark_sky_has_almost_no_light_and_shows_stars() -> void:
	var dark := SkyPresets.dark()
	assert_true(dark.light_energy < 0.3, "luz da lua fraca")
	assert_true(dark.ambient_energy < 0.1, "quase sem luz ambiente")
	assert_true(dark.star_brightness > 0.0, "tem estrelas")
	assert_eq(dark.label, "escuro", "nome")


func test_moon_is_high_and_ahead_of_the_player() -> void:
	var direction := SkyPresets.dark().sun_direction()
	assert_near(direction.length(), 1.0, 0.001, "vetor unitario")
	assert_true(direction.y > 0.5, "lua alta")
	assert_true(direction.z < 0.0, "lua na frente do jogador (-Z)")


func test_azimuth_zero_points_to_minus_z() -> void:
	var preset := SkyPresets.dark()
	preset.sun_azimuth_degrees = 0.0
	assert_true(preset.sun_direction().z < 0.0, "azimute zero fica em -Z")


func test_world_applies_the_dark_sky_to_light_fog_and_ground() -> void:
	var world := (load(WORLD_SCENE) as PackedScene).instantiate() as Node3D
	var grass := world.get_node("Grass") as GrassField
	grass.chunks_per_frame = 0
	grass.first_frame_chunks = 0
	spawn(world)
	await tree.process_frame
	var sun := world.get_node("Sun") as DirectionalLight3D
	assert_near(sun.light_energy, SkyPresets.dark().light_energy, 0.001, "energia da lua")
	var light_toward_ground := -sun.global_basis.z
	assert_true(light_toward_ground.y < 0.0, "a luz vem de cima")
	var environment := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_eq(environment.fog_light_color, SkyPresets.dark().fog_color, "neblina escura")
	assert_true(environment.volumetric_fog_enabled, "neblina volumetrica ligada")
	var ground := (world.get_node("WorldSky") as WorldSky).ground_material
	var soil := ground.get_shader_parameter("soil_color") as Color
	assert_eq(soil, SkyPresets.dark().soil_color, "chao escuro")
