class_name CarbineBoltAction
extends GunAction

const BOLT_PATH := "Visual/Corpo/JanelaEjecao"
const HANDLE_PATH := "Visual/Corpo/Alavanca"
const CYCLE_TRAVEL_META := "curso"
const CHECK_TRAVEL_META := "conferencia"
const CYCLE_TIME := 0.06
const CASING := preload("res://contexts/weapons/models/ammo/cartridge_22.tscn")
const EJECT_POINT := Vector3(0.018, 0.004, -0.09)
const EJECT_SPEED := Vector3(2.2, 1.4, 0.4)


func cycle_time() -> float:
	return CYCLE_TIME


func update(model: Node3D, state: GunActionState) -> void:
	var bolt := model.get_node(BOLT_PATH) as Node3D
	var full_cycle_travel: float = bolt.get_meta(CYCLE_TRAVEL_META)
	var full_check_travel: float = bolt.get_meta(CHECK_TRAVEL_META)
	var cycle_travel := 0.0
	if state.is_cycling():
		cycle_travel = full_cycle_travel * state.cycle_swing()
	var check_travel := full_check_travel * chamber_open(state)
	var travel := maxf(cycle_travel, check_travel)
	_place_bolt(model, travel)
	show_chamber_round(model, travel, state.loaded_rounds)
	if should_eject(state, state.cycle_progress()):
		state.casing_ejected = true
		CasingEjector.eject(CASING, state.casing_parent, model, EJECT_POINT, EJECT_SPEED)


func reset(model: Node3D) -> void:
	_place_bolt(model, 0.0)
	show_chamber_round(model, 0.0, 0)


func _place_bolt(model: Node3D, travel: float) -> void:
	var bolt := model.get_node(BOLT_PATH) as Node3D
	bolt.position = Vector3(0.0, 0.0, travel)
	var handle := model.get_node(HANDLE_PATH) as Node3D
	handle.position = Vector3(0.0, 0.0, travel)
