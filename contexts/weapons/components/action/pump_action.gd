class_name PumpAction
extends GunAction

const PUMP_PATH := "Visual/Bomba"
const BOLT_PATH := "Visual/Corpo/Ferrolho"
const CHAMBER_MARKER := "ConferenciaCamara"
const CHAMBER_TRAVEL_META := "recuo_ferrolho"
const TUBE_CHECK_TRAVEL := 0.025


func update(model: Node3D, state: GunActionState) -> void:
	var chamber_travel := _chamber_travel(model, state)
	var tube_travel := 0.0
	if not state.checking_chamber:
		tube_travel = TUBE_CHECK_TRAVEL * smoothstep(0.3, 0.9, state.inspect_amount)
	var pump_travel := maxf(tube_travel, chamber_travel)
	_place(model, pump_travel, chamber_travel)
	show_chamber_round(model, chamber_travel, state.loaded_rounds)


func reset(model: Node3D) -> void:
	_place(model, 0.0, 0.0)
	show_chamber_round(model, 0.0, 0)


func _chamber_travel(model: Node3D, state: GunActionState) -> float:
	var marker := model.get_node(CHAMBER_MARKER)
	var full_travel: float = marker.get_meta(CHAMBER_TRAVEL_META)
	return full_travel * chamber_open(state)


func _place(model: Node3D, pump_travel: float, bolt_travel: float) -> void:
	var pump := model.get_node(PUMP_PATH) as Node3D
	pump.position = Vector3(0.0, 0.0, pump_travel)
	var bolt := model.get_node(BOLT_PATH) as Node3D
	bolt.position = Vector3(0.0, 0.0, bolt_travel)
