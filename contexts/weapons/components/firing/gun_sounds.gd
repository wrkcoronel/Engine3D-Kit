class_name GunSounds
extends Node

const PITCH_VARIATION := 0.04

@onready var reload: AudioStreamPlayer = $Reload
@onready var empty_click: AudioStreamPlayer = $EmptyClick
@onready var switch: AudioStreamPlayer = $Switch
@onready var shell_in: AudioStreamPlayer = $ShellIn


static func play_shot(shot_sound: AudioStreamPlayer) -> void:
	var lowest_pitch := 1.0 - PITCH_VARIATION
	var highest_pitch := 1.0 + PITCH_VARIATION
	shot_sound.pitch_scale = randf_range(lowest_pitch, highest_pitch)
	shot_sound.play()
