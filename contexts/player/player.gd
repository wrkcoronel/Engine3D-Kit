## JOGADOR: so movimento. WASD, pulo (Espaco), correr (Shift + W), agachar (Ctrl ou C, segurando)
## e deslizar (agachar enquanto corre). Olhar = components/mouse_look.gd,
## inclinacao da cabeca = components/head_lean.gd, arma = contexts/weapons/gun.tscn.
extends CharacterBody3D

const WALK_SPEED := 6.0
const SPRINT_SPEED := 10.0
const CROUCH_SPEED := 3.0
const SLIDE_SPEED := 13.0
## Quanto o deslize perde de velocidade por segundo.
const SLIDE_DECEL := 8.0

const JUMP_VELOCITY := 6.0
const GRAVITY_MULT := 2.2
## Cai mais rapido do que sobe, o que da peso ao pulo.
const FALL_MULT := 1.3

## Altura maxima de degrau que o jogador sobe sozinho (corpo caido, pedacos, meio-fio).
const STEP_HEIGHT := 0.45

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
## Altura da cabeca (local, a partir do centro do corpo) em pe e agachado.
const STAND_EYE := 0.7
const CROUCH_EYE := 0.1

## Lidos pela arma (gun.gd): correndo, ela aponta pro ceu.
var is_sprinting := false
var is_sliding := false

var _crouching := false
var _crouch_t := 0.0 # 0 = em pe, 1 = agachado (suavizado)
var _slide_dir := Vector3.ZERO
var _slide_speed := 0.0

@onready var _collision: CollisionShape3D = $Collision
@onready var _shape: CapsuleShape3D = _collision.shape
@onready var _head: HeadLean = $Head

func _unhandled_input(event: InputEvent) -> void:
	# agachar correndo = deslizar
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_CTRL or event.keycode == KEY_C) \
			and is_sprinting and not is_sliding and is_on_floor():
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		_slide_dir = flat.normalized() if flat.length() > 0.1 else -global_basis.z
		_slide_speed = SLIDE_SPEED
		is_sliding = true

func _process(delta: float) -> void:
	# agachar: o corpo encolhe (pes no mesmo lugar) e a cabeca desce, suave
	_crouch_t = lerpf(_crouch_t, 1.0 if _crouching else 0.0, 1.0 - exp(-12.0 * delta))
	_shape.height = lerpf(STAND_HEIGHT, CROUCH_HEIGHT, _crouch_t)
	_collision.position.y = -(STAND_HEIGHT - _shape.height) / 2.0
	var eye := lerpf(STAND_EYE, CROUCH_EYE, _crouch_t)
	_head.position.y = eye
	_head.rest_position.y = eye # o cover usa a altura sem inclinacao

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var crouch_held := Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C)
	var aiming := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	# --- agachar: so levanta se tiver espaco em cima ---
	if crouch_held:
		_crouching = true
	elif _crouching and _can_stand():
		_crouching = false

	# --- deslize termina ao soltar o agachar ou quando perde a velocidade ---
	if is_sliding and (not crouch_held or _slide_speed <= CROUCH_SPEED + 0.5):
		is_sliding = false

	# --- correr: Shift + W, no chao, em pe, sem mirar ---
	is_sprinting = Input.is_physical_key_pressed(KEY_SHIFT) and input.y < 0.0 \
		and is_on_floor() and not _crouching and not aiming

	# --- gravidade e pulo (nao pula agachado) ---
	if not is_on_floor():
		var mult := GRAVITY_MULT * (FALL_MULT if velocity.y < 0.0 else 1.0)
		velocity += get_gravity() * mult * delta
	elif Input.is_physical_key_pressed(KEY_SPACE) and not _crouching:
		velocity.y = JUMP_VELOCITY

	# --- movimento horizontal ---
	if is_sliding:
		# deslizando: direcao travada, so perde velocidade
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

## Degrau automatico: se algo baixo (ate STEP_HEIGHT) barra o caminho, e tem espaco em cima,
## o jogador sobe nele em vez de bater e parar. E o que deixa andar por cima do inimigo caido.
func _step_up() -> void:
	if not is_on_floor():
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() < 0.1:
		return
	var ahead := flat.normalized() * 0.15
	if not test_move(global_transform, ahead):
		return # caminho livre, nao tem degrau
	var raised := global_transform.translated(Vector3.UP * STEP_HEIGHT)
	if test_move(global_transform, Vector3.UP * STEP_HEIGHT) or test_move(raised, ahead):
		return # sem espaco em cima, ou e parede alta
	# desce da altura maxima ate encontrar o topo do degrau, e sobe so o necessario
	var landing := KinematicCollision3D.new()
	if test_move(raised.translated(ahead), Vector3.DOWN * STEP_HEIGHT, landing) and landing.get_normal().y > 0.7:
		global_position.y += STEP_HEIGHT + landing.get_travel().y

func _can_stand() -> bool:
	return not test_move(global_transform, Vector3.UP * (STAND_HEIGHT - CROUCH_HEIGHT))
