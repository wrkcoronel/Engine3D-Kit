extends SceneTree

const ARENA_SCENE := "res://app/arena.tscn"
const GUN_PATH := "Player/Head/Camera/Gun"
const OUTPUT_FOLDER := "res://tools/weapons/animations/"
const WEAPON_FILES: Array[String] = ["pistol_1911", "boito_pump", "carbine_22", "hunting_rifle"]
const FPS := 30
const SETTLE_SECONDS := 0.6
const AFTER_SHOT_SECONDS := 0.5
const HOLD_CHECK_SECONDS := 1.2
const TAIL_SECONDS := 0.2
const LONGEST_SECONDS := 8.0
const PRECISION := 0.00001
const VISIBLE_INDEX := 12


class HeldCheckKey:
	extends AmmoCheck

	func update(
		delta: float, reload_key_down: bool, _check_key_down: bool, allowed: bool, return_fast: bool
	) -> void:
		super.update(delta, reload_key_down, true, allowed, return_fast)


func _initialize() -> void:
	_record_all()


func _record_all() -> void:
	var arena := (load(ARENA_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(arena)
	await _wait(SETTLE_SECONDS)
	var gun := arena.get_node(GUN_PATH) as Node3D
	for weapon_index: int in WEAPON_FILES.size():
		var recording: Dictionary = await _record_weapon(gun, weapon_index)
		_save(recording, WEAPON_FILES[weapon_index])
	arena.queue_free()
	await process_frame
	quit()


func _record_weapon(gun: Node3D, weapon_index: int) -> Dictionary:
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	weapon_switch.equip(weapon_index)
	await _wait(SETTLE_SECONDS)
	var model := weapon_switch.hand.model
	var animations: Array[Dictionary] = []
	animations.append(await _record_shot(gun, model))
	animations.append(await _record_reload(gun, model, "recarga"))
	_empty_the_weapon(gun)
	animations.append(await _record_reload(gun, model, "recarga_vazia"))
	animations.append(await _record_chamber_check(gun, model))
	animations.append(await _record_magazine_check(gun, model))
	animations.append(await _record_holster(gun, model))
	animations.append(await _record_draw(gun, model, weapon_index))
	_drop_still_nodes(animations)
	return {"fps": FPS, "animations": animations}


func _record_shot(gun: Node3D, model: Node3D) -> Dictionary:
	var arsenal: GunArsenal = gun.get("_arsenal")
	var action_state: GunActionState = gun.get("_action_state")
	gun.call("_shoot", gun.get_viewport().get_camera_3d())
	var frames: Array[Dictionary] = []
	var shot_seconds := action_state.cycle_total + AFTER_SHOT_SECONDS
	shot_seconds = maxf(shot_seconds, arsenal.current_stats().fire_interval)
	await _sample_until(model, frames, shot_seconds, func() -> bool: return true)
	return {"name": "tiro", "frames": frames}


func _record_reload(gun: Node3D, model: Node3D, animation_name: String) -> Dictionary:
	var reloader: GunReloader = gun.get("_reloader")
	gun.call("_request_reload")
	var frames: Array[Dictionary] = []
	await _sample_until(model, frames, 0.0, func() -> bool: return not reloader.reloading)
	await _sample_until(model, frames, TAIL_SECONDS, func() -> bool: return true)
	return {"name": animation_name, "frames": frames}


func _empty_the_weapon(gun: Node3D) -> void:
	var arsenal: GunArsenal = gun.get("_arsenal")
	var action_state: GunActionState = gun.get("_action_state")
	arsenal.current_ammo().loaded = 0
	action_state.hammer_down = true


func _record_holster(gun: Node3D, model: Node3D) -> Dictionary:
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	var holster := weapon_switch.holster
	weapon_switch.put_away_weapon()
	var frames: Array[Dictionary] = []
	await _sample_until(model, frames, 0.1, func() -> bool: return holster.is_away())
	return {"name": "guardar", "frames": frames}


func _record_draw(gun: Node3D, model: Node3D, weapon_index: int) -> Dictionary:
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	var holster := weapon_switch.holster
	weapon_switch.switch_to(weapon_index)
	var frames: Array[Dictionary] = []
	await _sample_until(model, frames, 0.1, func() -> bool: return holster.amount == 0.0)
	return {"name": "sacar", "frames": frames}


func _record_chamber_check(gun: Node3D, model: Node3D) -> Dictionary:
	var check: AmmoCheck = gun.get("_check")
	check.start_chamber_check(false)
	var frames: Array[Dictionary] = []
	await _sample_until(model, frames, 0.1, func() -> bool: return check.amount == 0.0)
	return {"name": "conferir_camara", "frames": frames}


func _record_magazine_check(gun: Node3D, model: Node3D) -> Dictionary:
	var weapon_switch: GunWeaponSwitch = gun.get("_switch")
	var normal_check: AmmoCheck = gun.get("_check")
	var held_check := HeldCheckKey.new()
	_use_check(gun, weapon_switch, held_check)
	var frames: Array[Dictionary] = []
	await _sample_until(model, frames, HOLD_CHECK_SECONDS, func() -> bool: return true)
	normal_check.amount = held_check.amount
	_use_check(gun, weapon_switch, normal_check)
	await _sample_until(model, frames, 0.1, func() -> bool: return normal_check.amount == 0.0)
	return {"name": "conferir_pente", "frames": frames}


func _use_check(gun: Node3D, weapon_switch: GunWeaponSwitch, check: AmmoCheck) -> void:
	gun.set("_check", check)
	weapon_switch.set("_check", check)


func _sample_until(
	model: Node3D, frames: Array[Dictionary], least_seconds: float, finished: Callable
) -> void:
	var elapsed := 0.0
	var frame_time := 1.0 / FPS
	while elapsed < LONGEST_SECONDS:
		await process_frame
		frames.append(_sample(model))
		elapsed += frame_time
		var waited_enough := elapsed >= least_seconds
		if waited_enough and bool(finished.call()):
			return


func _sample(model: Node3D) -> Dictionary:
	var frame := {}
	frame["."] = _node_state(model)
	for child: Node in model.find_children("*", "Node3D", true, false):
		var node := child as Node3D
		frame[str(model.get_path_to(node))] = _node_state(node)
	return frame


func _node_state(node: Node3D) -> Array[float]:
	var local := node.transform
	var state: Array[float] = []
	for axis: Vector3 in [local.basis.x, local.basis.y, local.basis.z, local.origin]:
		state.append(snappedf(axis.x, PRECISION))
		state.append(snappedf(axis.y, PRECISION))
		state.append(snappedf(axis.z, PRECISION))
	state.append(float(node.visible))
	return state


func _drop_still_nodes(animations: Array[Dictionary]) -> void:
	var first_frame: Dictionary = (animations[0]["frames"] as Array)[0]
	var still_paths: Array[String] = []
	for path: String in first_frame.keys():
		if not _moves(animations, path, first_frame[path]):
			still_paths.append(path)
	for animation: Dictionary in animations:
		for frame: Dictionary in animation["frames"]:
			for path: String in still_paths:
				frame.erase(path)


func _moves(animations: Array[Dictionary], path: String, first_state: Array[float]) -> bool:
	for animation: Dictionary in animations:
		for frame: Dictionary in animation["frames"]:
			if frame[path] != first_state:
				return true
	return false


func _save(recording: Dictionary, weapon_file: String) -> void:
	var file_path := OUTPUT_FOLDER + weapon_file + "_animations.json"
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(recording))
	file.close()
	print("animacoes gravadas: ", file_path)


func _wait(seconds: float) -> void:
	var frame_count := ceili(seconds * FPS)
	for frame_number: int in frame_count:
		await process_frame
