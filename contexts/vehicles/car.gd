## CARRO arcade: E perto dele entra, E dentro sai.
## W/S (ou setas) acelera, freia e da re. A/D (ou setas) vira. Espaco = freio de mao (derrapa).
## Enquanto dirige, o jogador fica desligado (invisivel, sem processamento) e a camera do carro assume.
extends CharacterBody3D

## Velocidade maxima em m/s. 138.9 m/s = 500 km/h no velocimetro.
@export var max_speed := 138.9
@export var reverse_max_speed := 12.0
## Aceleracao inicial (m/s2). Ela cai conforme a velocidade sobe (ver accel_falloff),
## entao 0-100 km/h e rapido e os ultimos km/h ate 500 demoram bastante (~40 s para 95%).
@export var acceleration := 11.0
## Quanto a aceleracao cai perto da velocidade maxima. 0 = constante, 1 = vai a zero no limite.
## Maior = demora mais para chegar a 500.
@export_range(0.0, 1.0) var accel_falloff := 1.0
## Aceleracao ao frear (apertar o sentido contrario ao movimento).
@export var braking := 45.0
## Desaceleracao quando solta o acelerador.
@export var friction := 6.0
## Distancia entre eixos (m). Maior = curvas mais abertas, carro mais "comprido".
@export var wheelbase := 2.8
## Angulo maximo das rodas dianteiras (graus) com o volante todo virado.
@export var max_steer_angle_deg := 32.0
## Limite de aderencia lateral (m/s2). ~10 = 1 g. Em velocidade alta o carro nao consegue virar
## mais que isso: o raio da curva cresce com a velocidade ao quadrado, como na vida real.
@export var max_lat_accel := 11.0
## Quao rapido o volante vira ate o fim ao segurar A/D (unidades/s; 1 = fim de curso). Cai em alta velocidade.
@export var steer_response := 4.0
## Quao rapido o volante volta ao centro ao soltar A/D (ou ao inverter o lado).
@export var steer_return := 7.0
## Distancia maxima (do centro do carro) para entrar.
@export var enter_distance := 4.0

@export_group("Freio de mao / Derrapagem")
## Aderencia normal: quanto mais alto, mais rapido o carro "cola" na direcao do volante.
@export var grip := 20.0
## Perda de velocidade ao curvar: cada m/s de velocidade lateral "virada" pelos pneus custa
## esse tanto de velocidade total. 0 = curva sem perda, maior = curvar freia mais.
@export var corner_scrub := 0.25
## Aderencia com o freio de mao: baixa, entao a traseira escorrega de lado.
@export var drift_grip := 2.5
## Rapidez com que a aderencia cai ao puxar o freio de mao (maior = a traseira solta mais rapido).
@export var drift_grip_loss := 10.0
## Rapidez com que a aderencia volta ao soltar (menor = o carro continua derrapando por mais tempo).
@export var drift_grip_recover := 2.5
## Giro extra do volante durante a derrapagem (1.0 = dobro).
@export var drift_steer_boost := 0.8
## Quanto o freio de mao freia o carro (m/s por segundo): atrito dos pneus travados.
@export var handbrake_decel := 8.0
## Abaixo dessa velocidade (m/s) a aderencia volta ao normal e o carro para de deslizar suave.
@export var drift_full_speed := 12.0

## Velocidade lateral (m/s) a partir da qual os pneus soltam fumaca.
@export var smoke_slip_speed := 3.0
## Distancia (m) entre um trecho de marca de pneu e o proximo.
@export var skid_step := 0.4
## Largura da marca de cada pneu (m).
@export var skid_width := 0.35
## Maximo de trechos de marca no mundo; ao passar disso as mais antigas somem.
@export var max_skid_marks := 400
## Velocidade (m/s) em que a fumaca chega ao maximo (volume, tamanho e densidade). 50 m/s = 180 km/h.
@export var smoke_full_speed := 50.0

@export_group("Velocimetro")
## Converte a velocidade do jogo (m/s) para o numero mostrado em km/h. 3.6 = km/h real.
@export var speedo_scale := 3.6
## Quantas marchas o painel mostra (so visual).
@export var gears := 5

@export_group("Camera")
@export var cam_distance := 6.5
@export var cam_height := 3.0
## Altura do ponto que a camera olha, acima do carro.
@export var cam_look_height := 1.2
## Quanto menor, mais devagar a camera acompanha a curva do carro.
@export var cam_yaw_smooth := 3.0
## Suavizacao da posicao (esconde tremidas da fisica).
@export var cam_pos_smooth := 60.0
## Mouse: gira a camera ao redor do carro.
@export var cam_mouse_sens := 0.003
@export var cam_pitch_min_deg := -5.0
@export var cam_pitch_max_deg := 75.0
## Segundos sem mexer o mouse ate a camera voltar pra tras do carro.
@export var cam_recenter_delay := 1.5
@export var cam_recenter_smooth := 3.0

@export_group("Inclinacao do carro")
## Quao rapido o carro acompanha a inclinacao do chao (rampa).
@export var tilt_smooth_ground := 14.0
## Quao rapido ele inclina no ar, seguindo a trajetoria.
@export var tilt_smooth_air := 5.0

var _driver: Node3D
var _look_yaw := 0.0 # giro da camera feito pelo mouse, alem de seguir o carro
var _pitch := 0.0 # elevacao da camera (rad)
var _idle := 0.0
## Velocidade real do carro no mundo (plano horizontal). Separada da direcao em que o carro aponta:
## e essa diferenca que cria a derrapagem.
var _vel := Vector3.ZERO
## +1 = o carro anda pra frente, -1 = de re. Estavel: so muda quando ha velocidade clara.
var _move_sign := 1.0
var _cam_yaw := 0.0
var _rpm := 0.0
var _handbraking := false
var _steer_wheel := 0.0 # posicao do volante, -1 a 1 (suavizada)
var _grip_cur := 20.0 # aderencia lateral atual (cai no freio de mao, volta devagar)
var _smoke: Array[CPUParticles3D] = [] # fumaca dos pneus traseiros
var _skid_root: Node3D
var _skid_tex: GradientTexture2D
var _skid_decals: Array[Decal] = [] # pool de marcas de pneu
var _skid_next := 0
var _skid_last: Array = [null, null] # ultimo ponto marcado de cada roda traseira (null = sem marca em curso)

@onready var _hud: Speedometer = $Speedometer
@onready var _camera: Camera3D = $Camera
@onready var _visual: Node3D = $Visual

## Cria um emissor de fumaca de pneu na posicao dada (dentro do Visual, entao acompanha a inclinacao).
## As particulas ficam no mundo (local_coords = false): deixam um rastro atras do carro.
func _make_tire_smoke(pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.emitting = false
	p.amount = 120
	p.lifetime = 1.4
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0.0, 0.6, 0.0) # sobe devagar, como fumaca
	p.damping_min = 0.5
	p.damping_max = 1.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.8))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.85, 0.85, 0.85, 0.55), Color(0.6, 0.6, 0.6, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = fade
	# bolinha macia (circulo com borda difusa) em vez de quadrado
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var soft := Gradient.new()
	soft.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	soft.offsets = PackedFloat32Array([0.0, 1.0])
	tex.gradient = soft
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	quad.material = mat
	p.mesh = quad
	_visual.add_child(p)
	return p

func _ready() -> void:
	# gruda no chao ao passar de plano para rampa (e vice-versa), mas nao ao subir: no topo da rampa ele decola
	floor_snap_length = 0.4
	# o carro vai para a camada visual 2 pra os Decals das marcas de pneu (camada 1) nao o pintarem
	for c in _visual.get_children():
		if c is MeshInstance3D:
			c.layers = 2
	_smoke = [_make_tire_smoke(Vector3(-1.05, 0.1, 1.3)), _make_tire_smoke(Vector3(1.05, 0.1, 1.3))]
	_hud.visible = false # so aparece enquanto o jogador dirige
	# a camera nao herda a rotacao do carro; ela se posiciona sozinha em _update_camera
	_camera.top_level = true
	_cam_yaw = rotation.y
	_update_camera(0.0, true)

func _process(delta: float) -> void:
	_tilt_visual(delta)
	if _driver:
		_update_camera(delta, false)
		_update_hud(delta)

## Marcha e rotacao sao so visuais (o carro nao tem cambio): a velocidade e dividida em faixas,
## e a rotacao sobe dentro de cada faixa e cai ao "trocar" de marcha.
func _update_hud(delta: float) -> void:
	var speed := _vel.length()
	var gear := "N"
	var target_rpm := 0.15
	if speed >= 0.5:
		if _move_sign < 0.0:
			gear = "R"
			target_rpm = 0.2 + 0.6 * clampf(speed / reverse_max_speed, 0.0, 1.0)
		else:
			var g := clampi(int(speed / max_speed * gears) + 1, 1, gears)
			var within := clampf(speed / max_speed * gears - (g - 1), 0.0, 1.0)
			gear = str(g)
			target_rpm = 0.35 + 0.65 * within
	_rpm = lerpf(_rpm, target_rpm, 1.0 - exp(-12.0 * delta))
	_hud.update_hud(speed * speedo_scale, _rpm, gear, _handbraking)

## Inclina so o visual (corpo e rodas): no chao acompanha a rampa, no ar segue a trajetoria.
## A colisao continua reta, so a aparencia inclina.
func _tilt_visual(delta: float) -> void:
	var fwd := -global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var up := Vector3.UP
	var nose := fwd
	var rate := tilt_smooth_air
	if is_on_floor():
		up = get_floor_normal()
		nose = (fwd - up * fwd.dot(up)).normalized()
		rate = tilt_smooth_ground
	else:
		var h := Vector2(velocity.x, velocity.z).length()
		if h > 2.0:
			nose = (fwd * h + Vector3.UP * velocity.y).normalized()
			up = (Vector3.UP - nose * Vector3.UP.dot(nose)).normalized()
	var z := -nose
	var target := Basis(up.cross(z), up, z).get_rotation_quaternion()
	var current := _visual.global_basis.get_rotation_quaternion()
	_visual.global_basis = Basis(current.slerp(target, 1.0 - exp(-rate * delta)))

func _base_pitch() -> float:
	return atan2(cam_height, cam_distance)

## Camera orbitando o carro. O angulo base alcanca o do carro aos poucos (nas curvas o carro
## "gira" na tela em vez de a tela girar junto); o mouse soma um giro livre por cima disso.
## Parado o mouse por um tempo, a camera volta pra tras do carro.
func _update_camera(delta: float, snap: bool) -> void:
	_cam_yaw = rotation.y if snap else lerp_angle(_cam_yaw, rotation.y, 1.0 - exp(-cam_yaw_smooth * delta))
	if snap:
		_look_yaw = 0.0
		_pitch = _base_pitch()
		_idle = 0.0
	else:
		_idle += delta
		if _idle > cam_recenter_delay:
			var k := 1.0 - exp(-cam_recenter_smooth * delta)
			_look_yaw = lerp_angle(_look_yaw, 0.0, k)
			_pitch = lerpf(_pitch, _base_pitch(), k)
	var dist := Vector2(cam_distance, cam_height).length()
	var offset := Basis(Vector3.UP, _cam_yaw + _look_yaw) * Vector3(0.0, sin(_pitch) * dist, cos(_pitch) * dist)
	var target := global_position + offset
	_camera.global_position = target if snap else _camera.global_position.lerp(target, 1.0 - exp(-cam_pos_smooth * delta))
	_camera.look_at(global_position + Vector3.UP * cam_look_height)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if _driver:
			_exit()
		else:
			_try_enter()
	elif _driver == null:
		return
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_yaw -= event.relative.x * cam_mouse_sens
		_pitch = clampf(_pitch + event.relative.y * cam_mouse_sens, deg_to_rad(cam_pitch_min_deg), deg_to_rad(cam_pitch_max_deg))
		_idle = 0.0
	# o jogador (que cuida do mouse) esta desligado, entao o carro solta/prende o mouse
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _try_enter() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null or global_position.distance_to(player.global_position) > enter_distance:
		return
	_driver = player
	_update_camera(0.0, true) # comeca atras do carro, sem "voar" ate la
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	player.get_node("Collision").set_deferred("disabled", true)
	_camera.make_current()
	_hud.visible = true

func _exit() -> void:
	var player := _driver
	_driver = null
	_hud.visible = false
	# sai pela esquerda do carro, olhando pra mesma direcao
	player.global_position = global_position - global_basis.x * 2.2 + Vector3.UP * 0.3
	player.rotation.y = rotation.y
	player.velocity = Vector3.ZERO
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.visible = true
	player.get_node("Collision").set_deferred("disabled", false)
	player.get_node("Head/Camera").make_current()

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	var handbraking := false
	if _driver:
		# W/S ou setas = acelerar/freiar-re, A/D ou setas = virar, Espaco = freio de mao
		throttle = _axis(KEY_W, KEY_UP) - _axis(KEY_S, KEY_DOWN)
		steer = _axis(KEY_A, KEY_LEFT) - _axis(KEY_D, KEY_RIGHT)
		handbraking = Input.is_physical_key_pressed(KEY_SPACE)

	_handbraking = handbraking
	# no ar (salto de rampa) os pneus nao tocam o chao: sem acelerar, sem virar, sem aderencia
	var grounded := is_on_floor()

	# --- volante progressivo: o valor sobe/desce aos poucos em vez de saltar entre -1, 0 e 1 ---
	# Em alta velocidade o volante responde mais devagar (mais estavel); ao soltar, volta ao centro rapido.
	var speed_ratio := clampf(_vel.length() / max_speed, 0.0, 1.0)
	var steer_rate_in := lerpf(steer_response, steer_response * 0.4, speed_ratio)
	var wheel_rate := steer_return if steer == 0.0 or signf(steer) != signf(_steer_wheel) else steer_rate_in
	_steer_wheel = move_toward(_steer_wheel, steer, wheel_rate * delta)
	steer = _steer_wheel

	var forward := -global_basis.z
	var total := _vel.length()

	# --- sentido de marcha (+1 frente, -1 re). So muda quando ha velocidade clara ao longo do carro;
	# senao, deslizando de lado, o sinal oscilava perto de zero e o volante invertia sozinho (travadas) ---
	var fs0 := _vel.dot(forward)
	if absf(fs0) > 1.5:
		_move_sign = signf(fs0)

	# --- direcao (modelo de bicicleta): giro = velocidade / distancia_entre_eixos * tan(angulo das rodas) ---
	# Parado nao vira; de re o giro inverte sozinho. O giro e limitado pela aderencia lateral
	# (max_lat_accel): em alta velocidade o carro faz curvas largas, mesmo com o volante todo virado.
	# derrapando (aderencia baixa) o carro fica de lado e a velocidade "pra frente" some; ai o giro usa a
	# velocidade total, senao o carro travava de lado sem conseguir girar/corrigir
	var drift_amt := clampf(1.0 - _grip_cur / grip, 0.0, 1.0)
	var v_yaw := _move_sign * lerpf(absf(fs0), total, drift_amt)
	var boost := 1.0 + drift_steer_boost * drift_amt
	var yaw := v_yaw / wheelbase * tan(deg_to_rad(max_steer_angle_deg) * steer) * boost
	var yaw_cap := max_lat_accel * boost / maxf(absf(v_yaw), 1.0)
	yaw = clampf(yaw, -yaw_cap, yaw_cap)
	if grounded:
		rotate_y(yaw * delta)
	# quanto da aderencia ja esta sendo usada pra curvar (0 a 1): sobra menos pra acelerar
	var lat_load := clampf(absf(yaw * v_yaw) / max_lat_accel, 0.0, 1.0)
	var traction := maxf(sqrt(1.0 - lat_load * lat_load), 0.35)

	# --- separa a velocidade em: ao longo do carro (fs) e de lado (lat) ---
	# Como o carro girou e _vel nao, aparece velocidade lateral: e a derrapagem.
	forward = -global_basis.z
	var right := global_basis.x
	var fs := _vel.dot(forward)
	var lat := _vel.dot(right)

	# --- acelerador / freio / re (padrao de carro) ---
	# W: acelera (ou freia se estiver indo de re). S: freia (ou da re se estiver parado/de re).
	# (vale tambem com o freio de mao: da pra acelerar pra manter/prolongar a derrapagem)
	# a aceleracao diminui com a velocidade (resistencia do ar): so vale pra frente
	var fwd_taper := 1.0 - accel_falloff * clampf(fs / max_speed, 0.0, 1.0)
	if grounded:
		if throttle > 0.0:
			fs += (braking if fs < -0.5 else acceleration * fwd_taper * traction) * delta
		elif throttle < 0.0:
			fs -= (braking if fs > 0.5 else acceleration) * delta
		else:
			fs = move_toward(fs, 0.0, friction * delta)
	# --- rampa: a gravidade puxa o carro ladeira abaixo. Subindo desacelera, descendo acelera.
	# (parado e sem acelerar o carro fica no lugar: o freio de estacionamento segura) ---
	var floor_n := get_floor_normal() if grounded else Vector3.UP
	var tilt := Quaternion(Vector3.UP, floor_n) # gira o plano horizontal para o plano do chao
	if grounded and (throttle != 0.0 or absf(fs) > 0.3):
		var slope_pitch := (tilt * forward).y # >0 = carro apontando morro acima
		fs -= absf(get_gravity().y) * 2.0 * slope_pitch * delta
	fs = clampf(fs, -reverse_max_speed, max_speed)

	# --- aderencia dos pneus: mata a velocidade lateral ---
	# Com o freio de mao a aderencia cai (traseira escorrega), mas volta aos poucos
	# conforme o carro perde velocidade, assim ele para de deslizar de forma suave.
	# A aderencia atual (_grip_cur) CAI rapido ao puxar o freio de mao e VOLTA devagar ao soltar:
	# assim o carro continua deslizando um tempo depois de soltar e vai "pegando" aos poucos, sem tranco.
	var grip_target := grip
	if handbraking:
		grip_target = lerpf(drift_grip, grip, clampf(1.0 - total / drift_full_speed, 0.0, 1.0))
	var grip_rate := drift_grip_loss if grip_target < _grip_cur else drift_grip_recover
	_grip_cur = lerpf(_grip_cur, grip_target, 1.0 - exp(-grip_rate * delta))
	var new_lat := lat * exp(-_grip_cur * delta) if grounded else lat
	# os pneus "viram" a direcao do carro: a velocidade lateral some, mas o carro NUNCA ganha velocidade
	# com isso. A velocidade total se mantem menos uma perda proporcional ao que foi virado.
	var killed := absf(lat) - absf(new_lat)
	var mag := maxf(sqrt(fs * fs + lat * lat) - killed * corner_scrub, 0.0)
	fs = signf(fs) * sqrt(maxf(mag * mag - new_lat * new_lat, 0.0))
	_vel = (forward * fs + right * new_lat).limit_length(max_speed)

	# --- freio de mao: atrito dos pneus travados (~0,8 g), bem menor que antes, pra dar pra derrapar ---
	if handbraking and grounded:
		_vel = _vel.move_toward(Vector3.ZERO, handbrake_decel * delta)
	elif throttle == 0.0 and _vel.length() < 0.15 and grounded:
		_vel = Vector3.ZERO # evita ficar "rastejando" parado

	# --- movimento ---
	if grounded:
		# no chao: a velocidade segue a superficie (girada para o plano da rampa, mesmo modulo),
		# entao subir a rampa nao "come" velocidade como acontecia quando o motor so deslizava o carro
		velocity = tilt * _vel
	else:
		# no ar: trajetoria balistica, so a gravidade age (a velocidade vertical vem do fim da rampa)
		var vy := velocity.y
		velocity = _vel
		velocity.y = vy + get_gravity().y * 2.0 * delta
	move_and_slide()

	# bateu na parede? usamos a velocidade real, que ja foi cortada pela colisao.
	# No chao guardamos a velocidade ao longo da superficie (so a direcao e horizontal).
	var hv := Vector3(velocity.x, 0.0, velocity.z)
	if is_on_floor() and hv.length() > 0.01:
		_vel = hv.normalized() * velocity.length()
	else:
		_vel = hv

	# --- fumaca de pneu cantando: 0 (nada) a 1 (nuvem densa), pelo que for mais forte entre: ---
	# derrapagem de verdade (deslizando de lado / freio de mao), arrancada (pneu patinando saindo parado)
	# e freada forte em alta velocidade. Curva normal NAO solta fumaca: o pneu so canta quando escorrega.
	var smoke := 0.0
	if grounded:
		smoke = clampf((absf(lat) - smoke_slip_speed) / 8.0, 0.0, 1.0) # derrapagem: quanto mais de lado, mais fumaca
		if handbraking and total > 5.0:
			smoke = maxf(smoke, 0.7)
		if throttle > 0.0 and fs0 > -0.5 and total < 8.0:
			smoke = maxf(smoke, 0.6 * (1.0 - total / 8.0) + 0.2) # arrancada patinando
		var hard_braking := (throttle > 0.0 and fs0 < -20.0) or (throttle < 0.0 and fs0 > 20.0)
		if hard_braking:
			smoke = maxf(smoke, clampf((absf(fs0) - 20.0) / 60.0, 0.0, 0.5)) # freada forte, so em velocidade alta
	var slip_amt := smoke # quanto o pneu esta cantando (sem o fator velocidade): usado nas marcas no chao
	_update_skids(slip_amt)
	# a quantidade de fumaca acompanha a velocidade: devagar sai pouca, rapido sai uma nuvem grande
	var speed_k := clampf(total / smoke_full_speed, 0.0, 1.0)
	smoke *= lerpf(0.3, 1.0, speed_k)
	for s in _smoke:
		s.emitting = smoke > 0.06
		# mais intensidade/velocidade = fumaca mais densa (opaca), em bolas maiores, mais rapida e em maior volume
		s.color = Color(1.0, 1.0, 1.0, lerpf(0.3, 1.0, smoke))
		s.scale_amount_min = lerpf(0.6, 1.8, smoke)
		s.scale_amount_max = lerpf(1.0, 3.0, smoke)
		s.speed_scale = lerpf(0.9, 2.4, speed_k) # emite mais particulas por segundo
		s.initial_velocity_max = lerpf(1.2, 4.0, speed_k)

## MARCAS DE PNEU: enquanto o pneu canta (amount > 0.25), cada roda traseira deixa um trecho escuro no chao
## a cada skid_step metros. Sao Decals (projetados no chao, entao seguem rampas) num pool: ao encher,
## as marcas mais antigas sao reaproveitadas.
func _update_skids(amount: float) -> void:
	var marking := amount > 0.25
	var space := get_world_3d().direct_space_state
	for i in _smoke.size():
		if not marking:
			_skid_last[i] = null
			continue
		var from := _smoke[i].global_position + Vector3.UP * 0.5
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.5, 1, [get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			_skid_last[i] = null
			continue
		var p: Vector3 = hit.position
		var n: Vector3 = hit.normal
		if _skid_last[i] == null:
			_skid_last[i] = p
			continue
		var last: Vector3 = _skid_last[i]
		var seg := p - last
		var seg_len := seg.length()
		if seg_len > 4.0: # teleporte/salto: nao liga um ponto ao outro
			_skid_last[i] = p
			continue
		if seg_len < skid_step:
			continue
		var dir := (seg - n * seg.dot(n)).normalized()
		var d := _next_skid_decal()
		d.size = Vector3(skid_width, 0.3, seg_len * 1.25)
		d.modulate = Color(1.0, 1.0, 1.0, lerpf(0.45, 0.95, amount))
		d.global_transform = Transform3D(Basis(n.cross(dir), n, dir), (p + last) * 0.5 + n * 0.02)
		_skid_last[i] = p

func _next_skid_decal() -> Decal:
	if _skid_root == null:
		_skid_root = Node3D.new()
		_skid_root.top_level = true # fica no mundo, nao anda junto com o carro
		add_child(_skid_root)
		# textura: faixa escura com bordas suaves (transparente nas laterais)
		var fade := Gradient.new()
		fade.colors = PackedColorArray([Color(0.02, 0.02, 0.02, 0.0), Color(0.02, 0.02, 0.02, 1.0), Color(0.02, 0.02, 0.02, 0.0)])
		fade.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		_skid_tex = GradientTexture2D.new()
		_skid_tex.gradient = fade
		_skid_tex.width = 32
		_skid_tex.height = 8
		_skid_tex.fill_from = Vector2(0.0, 0.0)
		_skid_tex.fill_to = Vector2(1.0, 0.0)
	if _skid_decals.size() < max_skid_marks:
		var d := Decal.new()
		d.texture_albedo = _skid_tex
		d.cull_mask = 1 # so marca o cenario (camada 1); o carro fica na camada 2 e nao e marcado
		_skid_root.add_child(d)
		_skid_decals.append(d)
		return d
	_skid_next = (_skid_next + 1) % max_skid_marks
	return _skid_decals[_skid_next]

func _axis(key: Key, alt: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(key) or Input.is_physical_key_pressed(alt) else 0.0
