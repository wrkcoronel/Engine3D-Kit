class_name SpectralEntity
extends StaticBody3D

@export var roam_bounds := Rect2(-38.0, -26.0, 80.0, 58.0)
@export var random_seed := 0

var _brain := EntityBrain.new()
var _random := RandomNumberGenerator.new()
var _enabled := true
var _body: EntityBody
var _screen_fx: EntityScreenFx
var _audio: EntityAudio
var _hit_collision: CollisionShape3D


func _ready() -> void:
	if random_seed != 0:
		_random.seed = random_seed
	else:
		_random.randomize()
	_body = $Body as EntityBody
	_screen_fx = $ScreenFx as EntityScreenFx
	_audio = $Audio as EntityAudio
	_hit_collision = $HitCollision as CollisionShape3D
	_brain.mode = EntityState.Mode.STARE
	_brain.mode_timer = 6.5


func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var target_pos := camera.global_position
	var flat_to_target := Vector3(
		target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z
	)
	var distance := flat_to_target.length()
	var is_looking := _is_camera_looking_at_entity(camera)

	_brain.advance(delta, distance, is_looking, _random)
	if _brain.wants_relocate:
		_relocate_around(camera)
	if _brain.triggered_glitch_flash:
		var flash_strength := 0.55
		if _brain.triggered_attack_strike:
			flash_strength = 1.0
		_screen_fx.trigger_flash(flash_strength)
		_audio.trigger_burst(flash_strength)

	_move_toward_target(delta, flat_to_target, distance)
	_face_target(flat_to_target)
	_update_presentation(delta, distance, is_looking)


func take_hit(_hit: Dictionary, _direction: Vector3, _damage: float) -> void:
	if not _enabled:
		return
	_brain.react_to_hit(_random)
	if _brain.triggered_glitch_flash:
		_screen_fx.trigger_flash(0.75)
		_audio.trigger_burst(0.9)


func set_entity_enabled(enabled: bool) -> void:
	_enabled = enabled
	visible = enabled
	set_physics_process(enabled)
	if _hit_collision != null:
		_hit_collision.disabled = not enabled
	if enabled:
		if _audio != null:
			_audio.resume()
		return
	if _body != null:
		_body.hide_immediately()
	if _screen_fx != null:
		_screen_fx.clear_effect()
	if _audio != null:
		_audio.silence()


func is_entity_enabled() -> bool:
	return _enabled


func current_mode() -> EntityState.Mode:
	return _brain.mode


func _is_camera_looking_at_entity(camera: Camera3D) -> bool:
	var entity_eye := global_position + Vector3(0.0, 1.8, 0.0)
	var to_entity := (entity_eye - camera.global_position).normalized()
	var camera_forward := -camera.global_basis.z.normalized()
	return camera_forward.dot(to_entity) >= EntityState.LOOK_DOT_THRESHOLD


func _relocate_around(camera: Camera3D) -> void:
	var forward := -camera.global_basis.z
	var prefer_behind := _random.randf() < 0.72
	var spot := EntityRelocator.pick_spot(
		camera.global_position, forward, prefer_behind, roam_bounds, _random
	)
	global_position = spot


func _move_toward_target(delta: float, flat_to_target: Vector3, distance: float) -> void:
	var speed := _brain.move_speed()
	if speed <= 0.0 or distance < 0.2:
		return
	var direction := flat_to_target / distance
	global_position += direction * speed * delta
	global_position.y = 0.0


func _face_target(flat_to_target: Vector3) -> void:
	if flat_to_target.length_squared() < 0.001:
		return
	var yaw := atan2(-flat_to_target.x, -flat_to_target.z)
	rotation.y = yaw


func _update_presentation(delta: float, distance: float, is_looking: bool) -> void:
	var is_present := _brain.mode != EntityState.Mode.VANISHED
	var is_attacking := _brain.mode == EntityState.Mode.ATTACK
	var glitch := _brain.glitch_intensity(distance, is_looking)

	_hit_collision.disabled = not is_present
	_body.update_visual(delta, glitch, is_present, is_attacking)

	var screen_distortion := 0.0
	if is_present:
		var near_factor := clampf(1.0 - distance / 20.0, 0.0, 1.0)
		var look_bonus := 0.0
		if is_looking:
			look_bonus = 0.25
		if is_attacking:
			look_bonus = 0.55
		screen_distortion = clampf(near_factor * 0.45 + look_bonus, 0.0, 0.85)
	_screen_fx.update_effect(delta, screen_distortion)

	var audio_level := 0.0
	if is_present:
		audio_level = clampf(1.0 - distance / 26.0, 0.12, 1.0)
		if is_attacking:
			audio_level = 1.0
	_audio.update_sound(delta, audio_level)
