extends TestCase


func test_hole_faces_the_surface_normal() -> void:
	var wall_normal := Vector3(1.0, 0.0, 0.0)
	var hit_position := Vector3(2.0, 1.0, 3.0)
	var placed := BulletHole.hole_transform(hit_position, wall_normal)
	assert_near(placed.basis.y.dot(wall_normal), 1.0, 0.0001, "o furo projeta contra a parede")
	assert_near(placed.origin.distance_to(hit_position), 0.0, 0.0001, "fica onde bateu")


func test_hole_on_floor_keeps_a_valid_basis() -> void:
	var placed := BulletHole.hole_transform(Vector3.ZERO, Vector3.UP)
	assert_near(placed.basis.y.dot(Vector3.UP), 1.0, 0.0001, "no chao aponta para cima")
	assert_near(placed.basis.x.length(), 1.0, 0.0001, "base sem deformar")
