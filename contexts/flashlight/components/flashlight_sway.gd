class_name FlashlightSway
extends RefCounted

const FULL_WALK_SPEED := 6.0
const AMOUNT_SMOOTHNESS := 8.0
const WALK_FREQUENCY := 6.0
const SPRINT_FREQUENCY := 9.0
const WALK_SWING := Vector3(0.012, 0.01, 0.02)
const WALK_TWIST := Vector3(0.04, 0.05, 0.04)
const SPRINT_SHIFT := Vector3(0.0, -0.035, 0.03)
const SPRINT_PITCH := -0.22
const SPRINT_SWING := Vector3(0.03, 0.025, 0.06)
const SPRINT_TWIST := Vector3(0.1, 0.16, 0.12)

var walk_amount := 0.0
var sprint_amount := 0.0

var _phase := 0.0


static func swayed_pose(
	pose_in_camera: Transform3D, phase: float, walk_weight: float, sprint_weight: float
) -> Transform3D:
	var forward_back := sin(phase)
	var lift := absf(cos(phase)) - 0.5
	var walk_shift := Vector3(
		forward_back * WALK_SWING.x, lift * WALK_SWING.y, -forward_back * WALK_SWING.z
	)
	var sprint_shift := SPRINT_SHIFT
	sprint_shift += Vector3(
		forward_back * SPRINT_SWING.x, lift * SPRINT_SWING.y, -forward_back * SPRINT_SWING.z
	)
	var walk_twist := Vector3(
		lift * WALK_TWIST.x, -forward_back * WALK_TWIST.y, forward_back * WALK_TWIST.z
	)
	var sprint_twist := Vector3(
		SPRINT_PITCH + lift * SPRINT_TWIST.x,
		-forward_back * SPRINT_TWIST.y,
		forward_back * SPRINT_TWIST.z
	)
	var total_shift := walk_shift * walk_weight + sprint_shift * sprint_weight
	var total_twist := walk_twist * walk_weight + sprint_twist * sprint_weight
	var swayed_basis := Basis.from_euler(total_twist) * pose_in_camera.basis
	var swayed_origin := pose_in_camera.origin + total_shift
	return Transform3D(swayed_basis, swayed_origin)


func update(delta: float, ground_speed: float, sprint_target: float) -> void:
	var smoothing := 1.0 - exp(-AMOUNT_SMOOTHNESS * delta)
	var walk_target := clampf(ground_speed / FULL_WALK_SPEED, 0.0, 1.0)
	walk_amount = lerpf(walk_amount, walk_target, smoothing)
	sprint_amount = lerpf(sprint_amount, sprint_target, smoothing)
	var frequency := lerpf(WALK_FREQUENCY, SPRINT_FREQUENCY, sprint_amount)
	_phase += delta * frequency * walk_amount


func apply(pose_in_camera: Transform3D, steadiness: float) -> Transform3D:
	var walk_weight := walk_amount * (1.0 - sprint_amount) * steadiness
	var sprint_weight := sprint_amount * steadiness
	return swayed_pose(pose_in_camera, _phase, walk_weight, sprint_weight)
