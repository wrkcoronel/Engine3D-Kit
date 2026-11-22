extends TestCase

const RIFLE_SCENE := "res://contexts/weapons/models/hunting_rifle/hunting_rifle.tscn"
const SCOPE_CAMERA_PATH := "Visual/Luneta/Imagem/Camera"
const WORLD_LAYER := 1


func test_scope_camera_sees_the_world_and_the_car() -> void:
	var rifle := (load(RIFLE_SCENE) as PackedScene).instantiate()
	var scope_camera := rifle.get_node(SCOPE_CAMERA_PATH) as Camera3D
	var sees_world := (scope_camera.cull_mask & WORLD_LAYER) != 0
	var sees_car := (scope_camera.cull_mask & CarTireFx.NOT_SEEN_BY_DECALS_LAYER) != 0
	assert_true(sees_world, "luneta ve o mundo")
	assert_true(sees_car, "luneta ve o carro")
	rifle.free()
