extends TestCase

const MAIN_SCENE := "res://app/main.tscn"
const MOTEL_SCENE := "res://contexts/motel/motel_environment.tscn"


func test_main_loads_motel_entity_player_car_and_flashlight() -> void:
	var scene := _spawn_main()
	assert_true(scene.has_node("MotelEnvironment"), "tem o ambiente do motel no main")
	assert_true(scene.has_node("World"), "tem o mundo com rampas e predios")
	assert_true(scene.has_node("Entity"), "tem a entidade espectral")
	assert_true(scene.has_node("Player"), "tem o jogador")
	assert_true(scene.has_node("Car"), "tem o carro")
	assert_true(scene.has_node("Flashlight"), "tem a lanterna")
	assert_true(scene.has_node("Telemetry"), "tem telemetria")


func test_all_five_open_doorways_are_walkable_and_closed_rooms_block() -> void:
	var scene := _spawn_main()
	var origin := (scene.get_node("MotelEnvironment") as Node3D).global_position
	await tree.physics_frame
	await tree.physics_frame
	var space_state := scene.get_world_3d().direct_space_state

	var main_start_x := MotelConstants.main_room_start_x(MotelConstants.OPEN_ROOM_INDEX)
	var main_door_x := main_start_x + 0.35 + MotelConstants.DOOR_WIDTH * 0.65
	_assert_ray_clear(
		space_state,
		origin + Vector3(main_door_x, 1.1, -8.5),
		origin + Vector3(main_door_x, 1.1, -11.5),
		"quarto 103"
	)
	var floor_two_y := MotelConstants.STORY_STEP + 1.1
	_assert_ray_clear(
		space_state,
		origin + Vector3(main_door_x, floor_two_y, -8.5),
		origin + Vector3(main_door_x, floor_two_y, -11.5),
		"quarto 203"
	)

	var west_start_z := MotelConstants.west_room_start_z(MotelConstants.OPEN_WEST_ROOM_INDEX)
	var west_door_z := west_start_z + 0.35 + MotelConstants.DOOR_WIDTH * 0.65
	_assert_ray_clear(
		space_state,
		origin + Vector3(-10.5, 1.1, west_door_z),
		origin + Vector3(-13.5, 1.1, west_door_z),
		"quarto 107"
	)
	_assert_ray_clear(
		space_state,
		origin + Vector3(-10.5, floor_two_y, west_door_z),
		origin + Vector3(-13.5, floor_two_y, west_door_z),
		"quarto 207"
	)

	var office_door_offset := 0.55 + MotelConstants.RECEPTION_DOOR_WIDTH * 0.65
	var office_door_x := MotelConstants.RECEPTION_START_X + office_door_offset
	_assert_ray_clear(
		space_state,
		origin + Vector3(office_door_x, 1.1, -7.5),
		origin + Vector3(office_door_x, 1.1, -10.8),
		"recepcao aberta"
	)

	var closed_x := MotelConstants.main_room_start_x(1) + 1.0
	var closed_query := PhysicsRayQueryParameters3D.create(
		origin + Vector3(closed_x, 1.1, -8.5), origin + Vector3(closed_x, 1.1, -11.5)
	)
	var closed_hit := space_state.intersect_ray(closed_query)
	assert_true(not closed_hit.is_empty(), "quarto fechado 102 bloqueia passagem")


func test_second_floor_balcony_rooms_and_stairs_have_solid_floors() -> void:
	var scene := _spawn_main()
	var origin := (scene.get_node("MotelEnvironment") as Node3D).global_position
	await tree.physics_frame
	await tree.physics_frame
	var space_state := scene.get_world_3d().direct_space_state

	_assert_floor_at(
		space_state, origin + Vector3(0.0, 4.5, -8.8), MotelConstants.STORY_STEP, "sacada"
	)
	_assert_floor_at(
		space_state, origin + Vector3(-0.5, 4.5, -12.5), MotelConstants.STORY_STEP, "piso 203"
	)
	_assert_floor_at(
		space_state, origin + Vector3(-14.5, 4.5, -1.0), MotelConstants.STORY_STEP, "piso 207"
	)

	var stair_x := (MotelConstants.WEST_WING_FRONT_X + MotelConstants.WEST_WALKWAY_FRONT_X) * 0.5
	var stair_mid_z := (MotelConstants.STAIR_START_Z + MotelConstants.STAIR_END_Z) * 0.5
	var stair_query := PhysicsRayQueryParameters3D.create(
		origin + Vector3(stair_x, 3.5, stair_mid_z), origin + Vector3(stair_x, 0.1, stair_mid_z)
	)
	var stair_hit := space_state.intersect_ray(stair_query)
	assert_true(not stair_hit.is_empty(), "escada externa tem rampa solida")
	if not stair_hit.is_empty():
		var stair_point := stair_hit["position"] as Vector3
		var expected_y := MotelConstants.STORY_STEP * 0.5
		assert_near(stair_point.y, expected_y, 0.15, "meio da escada na altura correta")


func test_invisible_boundary_walls_block_leaving_when_enabled() -> void:
	var env := (load(MOTEL_SCENE) as PackedScene).instantiate() as Node3D
	var motel := env.get_node("Motel") as Motel
	motel.enable_boundary = true
	spawn(env)
	await tree.physics_frame
	await tree.physics_frame
	var space_state := env.get_world_3d().direct_space_state
	var east_limit := MotelBoundary.PLAYABLE_BOUNDS.end.x
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(east_limit - 3.0, 1.5, 26.0), Vector3(east_limit + 4.0, 1.5, 26.0)
	)
	var hit := space_state.intersect_ray(query)
	assert_true(not hit.is_empty(), "parede invisivel bloqueia saida pela rua")


func _assert_ray_clear(
	space_state: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, label: String
) -> void:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space_state.intersect_ray(query)
	assert_true(hit.is_empty(), "passagem livre em: %s" % label)


func _assert_floor_at(
	space_state: PhysicsDirectSpaceState3D, origin: Vector3, expected_y: float, label: String
) -> void:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0.0, -2.5, 0.0))
	var hit := space_state.intersect_ray(query)
	assert_true(not hit.is_empty(), "piso solido em: %s" % label)
	if not hit.is_empty():
		var point := hit["position"] as Vector3
		assert_near(point.y, expected_y, 0.05, "altura do piso em: %s" % label)


func _spawn_main() -> Node3D:
	var packed := load(MAIN_SCENE) as PackedScene
	var scene := packed.instantiate() as Node3D
	var grass := scene.get_node("World/Grass") as GrassField
	grass.chunks_per_frame = 0
	grass.first_frame_chunks = 0
	spawn(scene)
	return scene
