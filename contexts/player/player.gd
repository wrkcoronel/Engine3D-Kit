extends CharacterBody3D

const WALK_SPEED := 6.0
const SPRINT_SPEED := 10.0
const CROUCH_SPEED := 3.0
const SLIDE_SPEED := 13.0
const SLIDE_DECEL := 8.0

const JUMP_VELOCITY := 6.0
const GRAVITY_MULT := 2.2
const FALL_MULT := 1.3

const STEP_HEIGHT := 0.45

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const STAND_EYE := 0.7
const CROUCH_EYE := 0.1

var is_sprinting := false
var is_sliding := false

var _crouching := false
var _crouch_t := 0.0
var _slide_dir := Vector3.ZERO
var _slide_speed := 0.0
var _telemetry := PlayerTelemetry.new()

@onready var _collision: CollisionShape3D = $Collision
@onready var _shape: CapsuleShape3D = _collision.shape
@onready var _head: HeadLean = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _mouse_look: MouseLook = $MouseLook
@onready var _rig: PlayerRig = $Rig


func _ready() -> void:
	_rig.body = self
	_rig.camera = _camera
	_rig.collision = _collision
	_head.bind(_rig)
	_mouse_look.bind(self, _head, _rig)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if (
		key
		and key.pressed
		and not key.echo
		and (key.keycode == KEY_CTRL or key.keycode == KEY_C)
		and is_sprinting
		and not is_sliding
		and is_on_floor()
	):
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		_slide_dir = flat.normalized() if flat.length() > 0.1 else -global_basis.z
		_slide_speed = SLIDE_SPEED
		is_sliding = true


func _process(delta: float) -> void:
	_crouch_t = lerpf(_crouch_t, 1.0 if _crouching else 0.0, 1.0 - exp(-12.0 * delta))
	_shape.height = lerpf(STAND_HEIGHT, CROUCH_HEIGHT, _crouch_t)
	_collision.position.y = -(STAND_HEIGHT - _shape.height) / 2.0
	var eye := lerpf(STAND_EYE, CROUCH_EYE, _crouch_t)
	_head.position.y = eye
	_head.rest_position.y = eye


func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var crouch_held := (
		Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C)
	)
	var aiming := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if crouch_held:
		_crouching = true
	elif _crouching and _can_stand():
		_crouching = false

	if is_sliding and (not crouch_held or _slide_speed <= CROUCH_SPEED + 0.5):
		is_sliding = false

	is_sprinting = (
		Input.is_physical_key_pressed(KEY_SHIFT)
		and input.y < 0.0
		and is_on_floor()
		and not _crouching
		and not aiming
	)
	_rig.is_sprinting = is_sprinting

	if not is_on_floor():
		var mult := GRAVITY_MULT * (FALL_MULT if velocity.y < 0.0 else 1.0)
		velocity += get_gravity() * mult * delta
	elif Input.is_physical_key_pressed(KEY_SPACE) and not _crouching:
		velocity.y = JUMP_VELOCITY

	if is_sliding:
		_slide_speed = move_toward(_slide_speed, CROUCH_SPEED, SLIDE_DECEL * delta)
		velocity.x = _slide_dir.x * _slide_speed
		velocity.z = _slide_dir.z * _slide_speed
	else:
		var speed := WALK_SPEED
		if _crouching:
			speed = CROUCH_SPEED
		elif is_sprinting:
			speed = SPRINT_SPEED
		var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	_step_up()
	move_and_slide()
	_report_telemetry(delta)


func _report_telemetry(delta: float) -> void:
	var on_floor := is_on_floor()
	var state_text := PlayerTelemetry.describe(
		global_position, velocity, on_floor, is_sprinting, is_sliding, _crouching
	)
	_telemetry.report(self, delta, velocity.y, on_floor, is_sliding, state_text)


func _step_up() -> void:
	if not is_on_floor():
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() < 0.1:
		return
	var ahead := flat.normalized() * 0.15
	if not test_move(global_transform, ahead):
		return
	var raised := global_transform.translated(Vector3.UP * STEP_HEIGHT)
	if test_move(global_transform, Vector3.UP * STEP_HEIGHT) or test_move(raised, ahead):
		return
	var landing := KinematicCollision3D.new()
	if (
		test_move(raised.translated(ahead), Vector3.DOWN * STEP_HEIGHT, landing)
		and landing.get_normal().y > 0.7
	):
		global_position.y += STEP_HEIGHT + landing.get_travel().y


func _can_stand() -> bool:
	return not test_move(global_transform, Vector3.UP * (STAND_HEIGHT - CROUCH_HEIGHT))
