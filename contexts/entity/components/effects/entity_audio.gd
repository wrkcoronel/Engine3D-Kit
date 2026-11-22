class_name EntityAudio
extends AudioStreamPlayer3D

const SAMPLE_RATE := 22050.0

var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _lfo_phase := 0.0
var _burst := 0.0
var _intensity := 0.0
var _noise_seed := 1337


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.12
	stream = generator
	max_distance = 34.0
	unit_size = 6.0
	volume_db = -8.0
	if DisplayServer.get_name() != "headless":
		play()
		_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _exit_tree() -> void:
	stop()
	_playback = null


func trigger_burst(strength: float) -> void:
	_burst = maxf(_burst, clampf(strength, 0.0, 1.0))


func silence() -> void:
	_intensity = 0.0
	_burst = 0.0
	stop()
	_playback = null


func resume() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not playing:
		play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func update_sound(delta: float, target_intensity: float) -> void:
	_intensity = move_toward(_intensity, clampf(target_intensity, 0.0, 1.0), 3.0 * delta)
	_burst = move_toward(_burst, 0.0, 2.2 * delta)
	if _playback == null:
		return
	var frames_available := _playback.get_frames_available()
	if frames_available <= 0:
		return
	var level := clampf(_intensity * 0.45 + _burst * 0.85, 0.0, 1.0)
	for frame_index: int in range(frames_available):
		var sample := _next_sample(level)
		_playback.push_frame(Vector2(sample, sample))


func _next_sample(level: float) -> float:
	if level <= 0.005:
		return 0.0
	_lfo_phase += 2.6 / SAMPLE_RATE
	var base_freq := 54.0 + sin(_lfo_phase * TAU) * 9.0 + _burst * 85.0
	_phase = fmod(_phase + base_freq / SAMPLE_RATE, 1.0)
	var drone := sin(_phase * TAU) * 0.55 + sin(_phase * TAU * 1.5) * 0.25
	var static_noise := _next_noise() * (0.28 + _burst * 0.7)
	return clampf((drone + static_noise) * level * 0.65, -0.95, 0.95)


func _next_noise() -> float:
	_noise_seed = (_noise_seed * 1103515245 + 12345) & 0x7fffffff
	return (float(_noise_seed) / float(0x7fffffff)) * 2.0 - 1.0
