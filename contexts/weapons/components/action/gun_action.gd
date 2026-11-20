class_name GunAction
extends RefCounted

const CHAMBER_ROUND_PATH := "Visual/Corpo/CartuchoCamara"
const VISIBLE_TRAVEL := 0.004
const EJECT_AT_CYCLE := 0.5


func prepare(_model: Node3D) -> void:
	pass


func cycle_time() -> float:
	return 0.0


func update(_model: Node3D, _state: GunActionState) -> void:
	pass


func reset(_model: Node3D) -> void:
	pass


func chamber_open(state: GunActionState) -> float:
	if not state.checking_chamber:
		return 0.0
	return smoothstep(0.3, 0.9, state.inspect_amount)


static func should_eject(state: GunActionState, progress: float) -> bool:
	if not state.is_cycling():
		return false
	if state.casing_ejected:
		return false
	return progress >= EJECT_AT_CYCLE


static func show_chamber_round(model: Node3D, travel: float, loaded_rounds: int) -> void:
	var chamber_round := model.get_node_or_null(CHAMBER_ROUND_PATH) as Node3D
	if chamber_round == null:
		return
	var opened_enough := travel > VISIBLE_TRAVEL
	chamber_round.visible = opened_enough and loaded_rounds > 0
