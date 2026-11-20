class_name RifleBoltAction
extends GunAction

const HANDLE_PATH := "Visual/Corpo/AlavancaFerrolho"
const OPEN_ACTION_PATH := "Visual/Corpo/AcaoAberta"
const CLOSED_BOLT_PATH := "Visual/Corpo/JanelaFerrolho"
const CHECK_MARKER := "Conferencia"
const CHAMBER_FRACTION_META := "recuo_camara"
const ROUND_PREFIX := "Cartucho"
const LIFT_ANGLE := deg_to_rad(75.0)
const PULL_DISTANCE := 0.05
const HANDLE_PIVOT := Vector3(0.0, 0.008, 0.0)
const OPEN_ENOUGH_TO_SEE := 0.3
const CYCLE_TIME := 0.9
const WAIT_AFTER_SHOT := 0.15
const CASING := preload("res://contexts/weapons/models/ammo/cartridge_308.tscn")
const EJECT_POINT := Vector3(0.018, 0.012, -0.11)
const EJECT_SPEED := Vector3(1.1, 0.9, 0.35)


func cycle_time() -> float:
	return CYCLE_TIME


func update(model: Node3D, state: GunActionState) -> void:
	var lift := smoothstep(0.0, 0.5, state.inspect_amount)
	var pull := smoothstep(0.4, 0.9, state.inspect_amount)
	if state.checking_chamber:
		var marker := model.get_node(CHECK_MARKER)
		var chamber_fraction: float = marker.get_meta(CHAMBER_FRACTION_META, 1.0)
		pull *= chamber_fraction
	if state.is_cycling():
		var hand_time := _hand_time(state)
		lift = maxf(lift, _cycle_lift(hand_time))
		pull = maxf(pull, _cycle_pull(hand_time))
		if should_eject(state, hand_time):
			state.casing_ejected = true
			CasingEjector.eject(CASING, state.casing_parent, model, EJECT_POINT, EJECT_SPEED)
	_place_handle(model, lift, pull)
	_show_open_action(model, pull, state.loaded_rounds)


func reset(model: Node3D) -> void:
	_place_handle(model, 0.0, 0.0)
	_show_open_action(model, 0.0, 0)


func _hand_time(state: GunActionState) -> float:
	var elapsed := state.cycle_total - state.cycle_left - WAIT_AFTER_SHOT
	var hand_duration := state.cycle_total - WAIT_AFTER_SHOT
	return elapsed / hand_duration


func _cycle_lift(hand_time: float) -> float:
	var raising := smoothstep(0.0, 0.22, hand_time)
	var lowering := smoothstep(0.8, 1.0, hand_time)
	return raising * (1.0 - lowering)


func _cycle_pull(hand_time: float) -> float:
	var pulling := smoothstep(0.22, 0.5, hand_time)
	var pushing := smoothstep(0.55, 0.8, hand_time)
	return pulling * (1.0 - pushing)


func _place_handle(model: Node3D, lift: float, pull: float) -> void:
	var pulled := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, PULL_DISTANCE * pull))
	var to_pivot := Transform3D(Basis.IDENTITY, HANDLE_PIVOT)
	var lifted := Transform3D(Basis(Vector3.BACK, LIFT_ANGLE * lift), Vector3.ZERO)
	var from_pivot := Transform3D(Basis.IDENTITY, -HANDLE_PIVOT)
	var handle := model.get_node(HANDLE_PATH) as Node3D
	handle.transform = pulled * to_pivot * lifted * from_pivot


func _show_open_action(model: Node3D, pull: float, loaded_rounds: int) -> void:
	var open_action := model.get_node(OPEN_ACTION_PATH) as Node3D
	open_action.visible = pull > OPEN_ENOUGH_TO_SEE
	var closed_bolt := model.get_node(CLOSED_BOLT_PATH) as Node3D
	closed_bolt.visible = not open_action.visible
	var round_index := 0
	for child: Node in open_action.get_children():
		if not child.name.begins_with(ROUND_PREFIX):
			continue
		(child as Node3D).visible = round_index < loaded_rounds
		round_index += 1
