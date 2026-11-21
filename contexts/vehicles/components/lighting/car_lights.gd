class_name CarLights
extends Node

const TOGGLE_KEY := KEY_L
const TELEMETRY_SOURCE := "carro"
const BRAKING_MIN_SPEED := 0.5

var _headlights := CarHeadlights.new()
var _taillights := CarTaillights.new()
var _driver_present := false


static func is_braking(throttle: float, handbraking: bool, forward_speed: float) -> bool:
	if handbraking:
		return true
	var pressing_reverse := throttle < 0.0
	var rolling_forward := forward_speed > BRAKING_MIN_SPEED
	return pressing_reverse and rolling_forward


func setup(car_body: Node3D, model: Node3D) -> void:
	_headlights.setup(car_body, model)
	_taillights.setup(car_body, model)


func set_driver_present(present: bool) -> void:
	_driver_present = present


func beam_mode() -> CarBeamMode.Mode:
	return _headlights.mode


func update(braking: bool) -> void:
	_taillights.update(_headlights.is_on(), braking)


func handle_key(key: InputEventKey) -> void:
	if not _driver_present:
		return
	if not key.pressed or key.echo:
		return
	if key.keycode != TOGGLE_KEY:
		return
	_headlights.cycle()
	Telemetry.record(self, TELEMETRY_SOURCE, CarBeamMode.label(_headlights.mode))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	handle_key(key)
