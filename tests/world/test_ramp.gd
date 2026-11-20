extends TestCase

const RAMP_SCENE := "res://contexts/world/props/ramp.tscn"
const TOLERANCE := 0.005
const TRANSITION_START_Z := 2.0
const TRANSITION_TOP_LEFT_LOW := 6
const TRANSITION_TOP_LEFT_HIGH := 2
const RAMP_SLOPE := 0.32492


func test_transition_starts_flush_with_floor() -> void:
	var low_corner := _transition_corners()[TRANSITION_TOP_LEFT_LOW]
	assert_near(low_corner.y, 0.0, TOLERANCE, "a transicao comeca na altura do chao")
	assert_near(low_corner.z, TRANSITION_START_Z, TOLERANCE, "a transicao comeca 2 m antes")


func test_transition_ends_on_ramp_surface() -> void:
	var high_corner := _transition_corners()[TRANSITION_TOP_LEFT_HIGH]
	var ramp_height_there := -high_corner.z * RAMP_SLOPE
	assert_near(high_corner.y, ramp_height_there, TOLERANCE, "a transicao termina sobre a rampa")


func test_ramp_low_edge_is_at_floor() -> void:
	var ramp_corners := _shape_corners("Collision")
	var top_left_low := ramp_corners[TRANSITION_TOP_LEFT_LOW]
	assert_near(top_left_low.y, 0.0, TOLERANCE, "a borda baixa da rampa fica no chao")
	assert_near(top_left_low.z, 0.0, TOLERANCE, "a borda baixa da rampa fica em z = 0")


func _transition_corners() -> Array[Vector3]:
	return _shape_corners("TransitionCollision")


func _shape_corners(node_name: String) -> Array[Vector3]:
	var ramp := (load(RAMP_SCENE) as PackedScene).instantiate()
	spawn(ramp)
	var shape_node := ramp.get_node(node_name) as CollisionShape3D
	var box := shape_node.shape as BoxShape3D
	return BoxEdges.corners(box.size, shape_node.transform)
