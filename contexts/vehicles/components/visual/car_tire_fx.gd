class_name CarTireFx
extends Node

const NOT_SEEN_BY_DECALS_LAYER := 2

@export var wind_velocity := Vector3(1.0, 0.0, 0.4)

var _car: PhysicsBody3D
var _smoke := CarSmoke.new()
var _skid_marks := CarSkidMarks.new()


func setup(car: PhysicsBody3D, visual: Node3D) -> void:
	_car = car
	_hide_from_skid_marks(visual)
	_smoke.setup(visual, wind_velocity)
	_skid_marks.setup(self, car)


func update(
	grounded: bool,
	throttle: float,
	handbraking: bool,
	sideways_speed: float,
	forward_speed: float,
	car_velocity: Vector3,
	engine_running: bool
) -> void:
	var total_speed := car_velocity.length()
	var slip := TireSlipSmoke.slip_amount(
		grounded, throttle, handbraking, sideways_speed, forward_speed, total_speed
	)
	var burnout := TireSlipSmoke.burnout_amount(
		grounded, throttle, handbraking, forward_speed, total_speed
	)
	var smoke_amount := TireSlipSmoke.visible_amount(slip, burnout, total_speed)
	var space_state := _car.get_world_3d().direct_space_state
	_skid_marks.update(_smoke.tire_positions(), slip, space_state)
	_smoke.update_tires(smoke_amount, TireSlipSmoke.speed_ratio(total_speed), car_velocity)
	_smoke.update_exhaust(engine_running, throttle)


func _hide_from_skid_marks(node: Node) -> void:
	for child: Node in node.get_children():
		var mesh := child as MeshInstance3D
		if mesh:
			mesh.layers = NOT_SEEN_BY_DECALS_LAYER
		_hide_from_skid_marks(child)
