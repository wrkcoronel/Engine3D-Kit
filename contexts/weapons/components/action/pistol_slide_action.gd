class_name PistolSlideAction
extends GunAction

const SLIDE_PATH := "Visual/Corpo"
const BARREL_PATH := "Visual/Cano"
const CHAMBER_HOOD_PATH := "Visual/Corpo/Camara"
const PISTOL_ROUND_PATH := "Visual/CartuchoCamara"
const HAMMER_PATH := "Visual/Armacao/Martelo"
const CHAMBER_MARKER := "ConferenciaCamara"
const CHAMBER_TRAVEL_META := "recuo_ferrolho"
const REST_META := "rest_transform"
const CYCLE_TIME := 0.07
const SLIDE_TRAVEL := 0.035
const BARREL_TRAVEL := 0.0025
const BARREL_UNLOCKED_AT := 0.008
const BARREL_TILT := 0.02
const BARREL_PIVOT := Vector3(0.0, 0.02, -0.145)
const HAMMER_PIN := Vector3(0.0, 0.007, 0.031)
const HAMMER_FALL := deg_to_rad(-38.0)
const CASING := preload("res://contexts/weapons/models/ammo/cartridge_45.tscn")
const EJECT_POINT := Vector3(0.016, 0.022, -0.02)
const EJECT_SPEED := Vector3(2.0, 1.7, 0.5)


func prepare(model: Node3D) -> void:
	var pistol_round := model.get_node(PISTOL_ROUND_PATH) as Node3D
	pistol_round.set_meta(REST_META, pistol_round.transform)


func cycle_time() -> float:
	return CYCLE_TIME


func chamber_open(state: GunActionState) -> float:
	if not state.checking_chamber:
		return 0.0
	return smoothstep(0.8, 0.99, state.inspect_amount)


func update(model: Node3D, state: GunActionState) -> void:
	var cock := _cock_hammer(state)
	var check_travel := _check_travel(model, state)
	var slide_travel := check_travel
	if state.is_cycling():
		slide_travel = maxf(slide_travel, SLIDE_TRAVEL * state.cycle_swing())
		if should_eject(state, state.cycle_progress()):
			state.casing_ejected = true
			CasingEjector.eject(CASING, state.casing_parent, model, EJECT_POINT, EJECT_SPEED)
	_place_slide(model, check_travel, slide_travel)
	_place_hammer(model, _hammer_fall(state, cock, slide_travel))
	var pistol_round := model.get_node(PISTOL_ROUND_PATH) as Node3D
	var opened_enough := slide_travel > VISIBLE_TRAVEL
	pistol_round.visible = opened_enough and state.loaded_rounds > 0


func reset(model: Node3D) -> void:
	_place_slide(model, 0.0, 0.0)
	(model.get_node(PISTOL_ROUND_PATH) as Node3D).visible = false


func _cock_hammer(state: GunActionState) -> float:
	if not state.checking_chamber:
		return 0.0
	if not state.hammer_down:
		return 0.0
	var cock := smoothstep(0.05, 0.3, state.inspect_amount)
	if cock >= 1.0:
		state.hammer_down = false
	return cock


func _check_travel(model: Node3D, state: GunActionState) -> float:
	if state.hammer_down:
		return 0.0
	var marker := model.get_node(CHAMBER_MARKER)
	var full_travel: float = marker.get_meta(CHAMBER_TRAVEL_META)
	return full_travel * chamber_open(state)


func _hammer_fall(state: GunActionState, cock: float, slide_travel: float) -> float:
	if state.is_cycling():
		return 1.0 - smoothstep(0.006, 0.02, slide_travel)
	if state.hammer_down:
		return 1.0 - cock
	return 0.0


func _place_slide(model: Node3D, check_travel: float, slide_travel: float) -> void:
	(model.get_node(SLIDE_PATH) as Node3D).position = Vector3(0.0, 0.0, slide_travel)
	var barrel_with_slide := minf(check_travel, BARREL_TRAVEL)
	var unlock := smoothstep(BARREL_TRAVEL, BARREL_UNLOCKED_AT, check_travel)
	var barrel := _barrel_transform(barrel_with_slide, unlock)
	(model.get_node(BARREL_PATH) as Node3D).transform = barrel
	var undo_slide := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -slide_travel))
	(model.get_node(CHAMBER_HOOD_PATH) as Node3D).transform = undo_slide * barrel
	var pistol_round := model.get_node(PISTOL_ROUND_PATH) as Node3D
	var round_rest: Transform3D = pistol_round.get_meta(REST_META)
	var extractor_offset := Vector3(0.0, 0.0, check_travel - barrel_with_slide)
	var extractor_pull := Transform3D(Basis.IDENTITY, extractor_offset)
	pistol_round.transform = extractor_pull * barrel * round_rest


func _barrel_transform(travel: float, unlock: float) -> Transform3D:
	var moved := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, travel))
	var to_pivot := Transform3D(Basis.IDENTITY, BARREL_PIVOT)
	var tilted := Transform3D(Basis(Vector3.RIGHT, BARREL_TILT * unlock), Vector3.ZERO)
	var from_pivot := Transform3D(Basis.IDENTITY, -BARREL_PIVOT)
	return moved * to_pivot * tilted * from_pivot


func _place_hammer(model: Node3D, fall: float) -> void:
	var to_pin := Transform3D(Basis.IDENTITY, HAMMER_PIN)
	var turned := Transform3D(Basis(Vector3.RIGHT, HAMMER_FALL * fall), Vector3.ZERO)
	var from_pin := Transform3D(Basis.IDENTITY, -HAMMER_PIN)
	(model.get_node(HAMMER_PATH) as Node3D).transform = to_pin * turned * from_pin
