extends TestCase


func test_relocator_picks_point_within_bounds_and_expected_distance() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 21
	var bounds := Rect2(-38.0, -26.0, 80.0, 58.0)
	var target := Vector3(0.0, 1.0, 4.0)

	for attempt: int in range(12):
		var spot := EntityRelocator.pick_spot(target, Vector3.FORWARD, true, bounds, random)
		assert_eq(spot.y, 0.0, "nasce no nivel do chao")
		assert_true(bounds.has_point(Vector2(spot.x, spot.z)), "fica dentro dos limites do mapa")
		var flat_dist := Vector2(spot.x - target.x, spot.z - target.z).length()
		assert_true(flat_dist >= EntityRelocator.MIN_SPAWN_DISTANCE - 0.1, "nao nasce colado")
		assert_true(flat_dist <= EntityRelocator.MAX_SPAWN_DISTANCE + 0.1, "nao nasce longe demais")
