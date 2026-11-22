extends TestCase

const ENTITY_SCENE := "res://contexts/entity/entity.tscn"
const MAIN_SCENE := "res://app/main.tscn"
const TRACER_SCENE := "res://contexts/weapons/effects/tracer.tscn"
const IMPACT_SCENE := "res://contexts/weapons/effects/impact.tscn"


func test_entity_scene_loads_and_reacts_to_weapon_hit() -> void:
	var entity := (load(ENTITY_SCENE) as PackedScene).instantiate() as SpectralEntity
	entity.random_seed = 42
	spawn(entity)
	await tree.process_frame
	assert_true(entity.has_node("Body"), "tem corpo espectral")
	assert_true(entity.has_node("ScreenFx"), "tem efeito de confusao na tela")
	assert_true(entity.has_node("Audio"), "tem audio procedural 3D")
	assert_eq(entity.current_mode(), EntityState.Mode.STARE, "comeca observando")

	entity.call("take_hit", {"position": Vector3.ZERO}, Vector3.FORWARD, 25.0)
	assert_eq(entity.current_mode(), EntityState.Mode.VANISHED, "some ao receber tiro")


func test_main_includes_the_spectral_entity() -> void:
	var scene := (load(MAIN_SCENE) as PackedScene).instantiate() as Node3D
	var grass := scene.get_node("World/Grass") as GrassField
	grass.chunks_per_frame = 0
	grass.first_frame_chunks = 0
	spawn(scene)
	assert_true(scene.has_node("Entity"), "cena Main inclui a entidade espectral")


func test_gun_shooter_shot_hits_entity_and_makes_it_vanish() -> void:
	var entity := (load(ENTITY_SCENE) as PackedScene).instantiate() as SpectralEntity
	entity.random_seed = 42
	entity.position = Vector3(0.0, 0.0, -8.0)
	spawn(entity)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.2, 0.0)
	spawn(camera)
	camera.make_current()

	var muzzle := Node3D.new()
	muzzle.position = Vector3(0.0, 1.2, -0.5)
	spawn(muzzle)

	var shooter := GunShooter.new()
	shooter.tracer_scene = load(TRACER_SCENE) as PackedScene
	shooter.impact_scene = load(IMPACT_SCENE) as PackedScene
	spawn(shooter)

	var stats := WeaponStats.new()
	stats.spread_aimed = 0.0
	stats.damage = 30.0

	await tree.physics_frame
	await tree.physics_frame
	shooter.fire_pellet(camera, muzzle, camera.global_basis, true, stats)
	assert_eq(
		entity.current_mode(),
		EntityState.Mode.VANISHED,
		"tiro real do GunShooter faz a entidade sumir"
	)
