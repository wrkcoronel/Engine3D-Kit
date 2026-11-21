class_name GunMuzzleFlash
extends RefCounted

const FLASH_TIME := 0.03
const LIGHT_TIME := 0.07
const BASE_ENERGY_META := "base_energy"

var _flash: MuzzleFlashVisual
var _light: OmniLight3D
var _base_energy := 0.0
var _flash_left := 0.0
var _light_left := 0.0
var _just_fired := false


func attach(flash: MuzzleFlashVisual, light: OmniLight3D) -> void:
	_flash = flash
	_light = light
	if not light.has_meta(BASE_ENERGY_META):
		light.set_meta(BASE_ENERGY_META, light.light_energy)
	_base_energy = light.get_meta(BASE_ENERGY_META)
	hide()


func fire() -> void:
	_flash_left = FLASH_TIME
	_light_left = LIGHT_TIME
	_just_fired = true
	_flash.burst()
	_flash.set_flashing(true)
	_light.visible = true
	_light.light_energy = _base_energy


func update(delta: float) -> void:
	if _just_fired:
		_just_fired = false
	else:
		_flash_left = maxf(0.0, _flash_left - delta)
		_light_left = maxf(0.0, _light_left - delta)
	var flashing := _flash_left > 0.0
	_flash.set_flashing(flashing)
	var light_fade := _light_left / LIGHT_TIME
	_light.visible = flashing or light_fade > 0.0
	_light.light_energy = _base_energy * light_fade * light_fade


func hide() -> void:
	_flash_left = 0.0
	_light_left = 0.0
	_just_fired = false
	_flash.set_flashing(false)
	_light.visible = false
