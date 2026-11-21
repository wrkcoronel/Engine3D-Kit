class_name CarSmoke
extends RefCounted

const TIRE_ANCHORS: Array[Vector3] = [Vector3(-0.70, 0.05, 1.235), Vector3(0.70, 0.05, 1.235)]
const EXHAUST_ANCHOR := Vector3(0.42, 0.22, 2.0)
const PUFF_TEXTURE_SEED := 11
const TRAIL_PULL := 0.04
const MAX_PULL_SPEED := 30.0
const MIN_SMOKE_TO_EMIT := 0.06
const IDLE_EXHAUST_STRENGTH := 0.15

var _visual: Node3D
var _tire_smoke: Array[CPUParticles3D] = []
var _exhaust_smoke: CPUParticles3D


static func trailing_direction(car_velocity: Vector3) -> Vector3:
	var limited_velocity := car_velocity.limit_length(MAX_PULL_SPEED)
	var pull := -limited_velocity * TRAIL_PULL
	return (Vector3.UP + pull).normalized()


func setup(visual: Node3D, wind_velocity: Vector3) -> void:
	_visual = visual
	var puff_texture := SmokePuffTexture.create(PUFF_TEXTURE_SEED)
	var material := SmokeEmitters.create_material(puff_texture)
	for anchor: Vector3 in TIRE_ANCHORS:
		var tire_emitter := SmokeEmitters.create_tire_smoke(material, wind_velocity)
		tire_emitter.position = anchor
		visual.add_child(tire_emitter)
		_tire_smoke.append(tire_emitter)
	_exhaust_smoke = SmokeEmitters.create_exhaust_smoke(material, wind_velocity)
	_exhaust_smoke.position = EXHAUST_ANCHOR
	visual.add_child(_exhaust_smoke)


func tire_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for emitter: CPUParticles3D in _tire_smoke:
		positions.append(emitter.global_position)
	return positions


func update_tires(smoke_amount: float, speed_ratio: float, car_velocity: Vector3) -> void:
	var local_velocity := _visual.global_basis.inverse() * car_velocity
	var direction := trailing_direction(local_velocity)
	for emitter: CPUParticles3D in _tire_smoke:
		emitter.emitting = smoke_amount > MIN_SMOKE_TO_EMIT
		emitter.direction = direction
		emitter.color = Color(1.0, 1.0, 1.0, lerpf(0.3, 1.0, smoke_amount))
		emitter.scale_amount_min = lerpf(0.6, 1.8, smoke_amount)
		emitter.scale_amount_max = lerpf(1.0, 3.0, smoke_amount)
		emitter.speed_scale = lerpf(0.9, 2.4, speed_ratio)
		emitter.initial_velocity_max = lerpf(1.2, 4.0, speed_ratio)


func update_exhaust(engine_running: bool, throttle: float) -> void:
	_exhaust_smoke.emitting = engine_running
	var strength := lerpf(IDLE_EXHAUST_STRENGTH, 1.0, clampf(throttle, 0.0, 1.0))
	_exhaust_smoke.color = Color(1.0, 1.0, 1.0, lerpf(0.4, 1.0, strength))
	_exhaust_smoke.scale_amount_max = lerpf(1.0, 2.0, strength)
	_exhaust_smoke.initial_velocity_max = lerpf(1.2, 3.0, strength)
	_exhaust_smoke.speed_scale = lerpf(0.8, 1.6, strength)
