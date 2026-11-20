extends TestCase


func test_center_shot_goes_straight() -> void:
	var direction := WeaponSpread.direction(Basis.IDENTITY, 0.1, 1.0, 0.0)
	assert_near(direction.dot(Vector3.FORWARD), 1.0, 0.0001, "sem desvio vai reto")


func test_edge_shot_stays_inside_cone() -> void:
	var spread := 0.05
	var direction := WeaponSpread.direction(Basis.IDENTITY, spread, 2.0, 1.0)
	var angle := direction.angle_to(Vector3.FORWARD)
	assert_near(angle, atan(spread), 0.0001, "na borda o desvio e o da arma")


func test_spread_follows_the_aim() -> void:
	var turned := Basis(Vector3.UP, PI / 2.0)
	var direction := WeaponSpread.direction(turned, 0.0, 0.0, 0.0)
	assert_near(direction.dot(-turned.z), 1.0, 0.0001, "atira para onde a mira aponta")
