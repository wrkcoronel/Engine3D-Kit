extends TestCase

const WALL_FRONT_DISTANCE := 4.5


func test_returns_distance_to_wall() -> void:
	var world := await _make_world_with_wall(1)
	var distance := RayUtil.dist(world, Vector3.ZERO, Vector3.FORWARD, 20.0)
	assert_near(distance, WALL_FRONT_DISTANCE, 0.01, "distancia ate a parede")


func test_returns_minus_one_when_looking_away_from_wall() -> void:
	var world := await _make_world_with_wall(1)
	var distance := RayUtil.dist(world, Vector3.ZERO, Vector3.BACK, 20.0)
	assert_eq(distance, -1.0, "raio apontando para longe da parede")


func test_returns_minus_one_when_wall_is_beyond_ray_length() -> void:
	var world := await _make_world_with_wall(1)
	var distance := RayUtil.dist(world, Vector3.ZERO, Vector3.FORWARD, 3.0)
	assert_eq(distance, -1.0, "parede mais longe que o alcance do raio")


func test_ignores_objects_outside_layer_1() -> void:
	var world := await _make_world_with_wall(2)
	var distance := RayUtil.dist(world, Vector3.ZERO, Vector3.FORWARD, 20.0)
	assert_eq(distance, -1.0, "parede na layer 2 nao conta como mundo")


func _make_world_with_wall(layer: int) -> World3D:
	var container := Node3D.new()
	spawn(container)

	var wall := StaticBody3D.new()
	wall.collision_layer = layer
	wall.position = Vector3(0.0, 0.0, -5.0)
	container.add_child(wall)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 1.0)
	shape.shape = box
	wall.add_child(shape)

	await tree.physics_frame
	await tree.physics_frame
	return container.get_world_3d()
