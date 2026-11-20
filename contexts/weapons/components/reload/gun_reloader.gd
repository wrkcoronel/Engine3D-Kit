class_name GunReloader
extends RefCounted

const INTERRUPT_RETURN_TIME := 0.1
const SOUND_LENGTH := 1.5

var reloading := false
var pose := GunReloadPose.new()

var _tween: Tween
var _model: Node3D
var _magazine: Node3D
var _magazine_rest := Vector3.ZERO


func attach(model: Node3D, magazine: Node3D, magazine_rest: Vector3) -> void:
	_model = model
	_magazine = magazine
	_magazine_rest = magazine_rest


func start(
	tween: Tween,
	stats: WeaponStats,
	ammo: WeaponAmmo,
	camera: Camera3D,
	sounds: GunSounds,
	on_finished: Callable
) -> void:
	_kill_tween()
	reloading = true
	_tween = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stats.loads_shell_by_shell():
		var shells := ShellReload.new(camera, _model, pose)
		var shell_count := maxi(1, ammo.missing_rounds())
		var turn_time := stats.reload_time * 0.5
		var click := sounds.shell_in.play
		shells.add_steps(
			tween, turn_time, stats.shell_reload_time, shell_count, click, ammo.load_one
		)
	else:
		sounds.reload.pitch_scale = SOUND_LENGTH / stats.reload_time
		sounds.reload.play()
		MagazineReload.add_steps(tween, pose, _magazine, _magazine_rest, stats.reload_time)
	tween.tween_callback(_finish.bind(ammo, sounds, on_finished))


func interrupt(tween: Tween) -> void:
	_kill_tween()
	reloading = false
	_tween = tween
	tween.set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pose, "offset", Vector3.ZERO, INTERRUPT_RETURN_TIME)
	tween.tween_property(pose, "rotation", Vector3.ZERO, INTERRUPT_RETURN_TIME)
	tween.tween_property(pose, "turn", 0.0, INTERRUPT_RETURN_TIME)
	tween.tween_property(_magazine, "position", _magazine_rest, INTERRUPT_RETURN_TIME)
	ShellReload.stop(_model)


func cancel() -> void:
	_kill_tween()
	reloading = false
	pose.clear()
	if _model == null:
		return
	_magazine.position = _magazine_rest
	ShellReload.stop(_model)


func _finish(ammo: WeaponAmmo, sounds: GunSounds, on_finished: Callable) -> void:
	ammo.reload_all()
	reloading = false
	sounds.reload.stop()
	on_finished.call()


func _kill_tween() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
