extends Node3D

@export var impact_scene: PackedScene
@export var fire_rate := 0.15
@export var shoot_range := 100.0
@export var damage := 10.0
@export var block_fire_above := 0.5

@export_group("Dispersao (balas tortas)")
@export var spread_hip_deg := 3.0
@export var spread_aim_deg := 0.5

var _rest_pos: Vector3
var _cooldown := 0.0
var _body: CharacterBody3D
var _head: HeadLean

@onready var wall: GunWallAvoid = $WallAvoid
@onready var cover: GunCoverPeek = $CoverPeek
@onready var aim: GunAim = $Aim
@onready var sway: GunSway = $Sway
@onready var recoil: GunRecoil = $Recoil
@onready var sprint: GunSprint = $Sprint


func _ready() -> void:
	_rest_pos = position
	_body = owner as CharacterBody3D
	_head = _body.get_node("Head")


func _process(delta: float) -> void:
	_cooldown -= delta
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var wants_aim := captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var cam := get_viewport().get_camera_3d()

	wall.update(delta, cam)
	cover.update(delta, _body, _head, wants_aim, wall.check_distance)
	sprint.update(delta, bool(_body.get("is_sprinting")))
	var wall_eff := wall.amount * (1.0 - absf(cover.amount)) * (1.0 - sprint.amount)
	aim.update(delta, cam, wants_aim and wall_eff < 0.3)
	var steady := aim.steady()
	sway.update(delta, _body, steady)
	recoil.update(delta)

	position = (
		_rest_pos.lerp(aim.aim_position, aim.amount)
		+ wall.pos(wall_eff)
		+ sprint.pos(sprint.amount)
		+ sway.pos
		+ recoil.pos(steady)
	)
	rotation = wall.rot(wall_eff) + sprint.rot(sprint.amount) + sway.rot + recoil.rot(steady)

	if (
		_cooldown <= 0.0
		and wall_eff < block_fire_above
		and sprint.amount < 0.5
		and captured
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	):
		_cooldown = fire_rate
		shoot(cam)


func _spread_direction(cam: Camera3D) -> Vector3:
	var spread := deg_to_rad(lerpf(spread_hip_deg, spread_aim_deg, aim.amount))
	var angle := randf() * TAU
	var radius := sqrt(randf()) * tan(spread)
	var camera_basis := cam.global_basis
	return (
		(
			-camera_basis.z
			+ camera_basis.x * cos(angle) * radius
			+ camera_basis.y * sin(angle) * radius
		)
		. normalized()
	)


func shoot(cam: Camera3D) -> void:
	recoil.fire()
	var from := cam.global_position
	var dir := _spread_direction(cam)
	var to := from + dir * shoot_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target: Object = hit.collider
	if target.has_method("take_hit"):
		target.take_hit(hit, dir, damage)
		return
	var impact: Node3D = impact_scene.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = hit.position
