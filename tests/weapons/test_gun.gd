extends TestCase

const ARENA_SCENE := "res://app/arena.tscn"
const GUN_PATH := "Player/Head/Camera/Gun"
const WEAPON_COUNT := 4


func _spawn_gun() -> Node3D:
	var arena := (load(ARENA_SCENE) as PackedScene).instantiate() as Node3D
	spawn(arena)
	await tree.process_frame
	await tree.process_frame
	return arena.get_node(GUN_PATH) as Node3D


func _wait(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func test_every_weapon_shoots_and_reloads() -> void:
	var gun: Node3D = await _spawn_gun()
	var arsenal: GunArsenal = gun.get("_arsenal")
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	var cam := gun.get_viewport().get_camera_3d()
	for weapon_index: int in WEAPON_COUNT:
		weapon_switch.equip(weapon_index)
		await _wait(0.3)
		var ammo := arsenal.current_ammo()
		var before := ammo.loaded
		gun.call("_shoot", cam)
		assert_eq(ammo.loaded, before - 1, "arma %d gastou uma bala" % weapon_index)
		await _wait(1.3)
		gun.call("_request_reload")
		var reload_time := arsenal.current_stats().reload_time
		var shells_time := arsenal.current_stats().shell_reload_time * 2.0
		await _wait(reload_time + shells_time + 0.3)
		assert_true(ammo.is_full(), "arma %d ficou cheia depois de recarregar" % weapon_index)


func test_number_keys_switch_through_all_weapons() -> void:
	var gun: Node3D = await _spawn_gun()
	var arsenal: GunArsenal = gun.get("_arsenal")
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	for weapon_index: int in [3, 2, 1, 0]:
		weapon_switch.select(weapon_index)
		await _wait(0.9)
		assert_eq(arsenal.current_index, weapon_index, "trocou para a arma %d" % weapon_index)
		var model := weapon_switch.hand.model
		assert_true(model.visible, "a arma %d aparece na mao" % weapon_index)


func test_chamber_check_opens_the_pistol_slide() -> void:
	var gun: Node3D = await _spawn_gun()
	var check: AmmoCheck = gun.get("_check")
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	check.start_chamber_check(false)
	await _wait(1.0)
	var slide := weapon_switch.hand.model.get_node(PistolSlideAction.SLIDE_PATH) as Node3D
	assert_true(slide.position.z > 0.02, "a corredica recua para mostrar a camara")
	await _wait(AmmoCheck.CHAMBER_CHECK_TIME + 0.5)
	assert_near(slide.position.z, 0.0, 0.002, "depois ela fecha")
