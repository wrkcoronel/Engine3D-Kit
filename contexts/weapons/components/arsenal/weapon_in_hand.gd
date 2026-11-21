class_name WeaponInHand
extends RefCounted

const MUZZLE_FLASH_PATH := "Efeitos/Clarao"
const MUZZLE_LIGHT_PATH := "Efeitos/LuzDisparo"
const MAGAZINE_PATH := "Visual/Carregador"
const SHOT_SOUND_NODE := "ShotSound"

var model: Node3D
var magazine: Node3D
var rest_position := Vector3.ZERO
var rest_rotation := Vector3.ZERO
var magazine_rest := Vector3.ZERO


func is_holding() -> bool:
	return model != null


func take_out(new_model: Node3D, flash: GunMuzzleFlash, reloader: GunReloader) -> void:
	model = new_model
	model.visible = true
	rest_position = model.position
	rest_rotation = model.rotation
	magazine = model.get_node(MAGAZINE_PATH) as Node3D
	magazine_rest = magazine.position
	var muzzle_light := model.get_node(MUZZLE_LIGHT_PATH) as OmniLight3D
	var flash_visual := model.get_node(MUZZLE_FLASH_PATH) as MuzzleFlashVisual
	flash.attach(flash_visual, muzzle_light)
	reloader.attach(model, magazine, magazine_rest)


func put_away(action: GunAction, flash: GunMuzzleFlash, reloader: GunReloader) -> void:
	reloader.cancel()
	MagazineRoundsView.hide_magazine_details(model)
	action.reset(model)
	model.position = rest_position
	model.rotation = rest_rotation
	magazine.position = magazine_rest
	flash.hide()
	model.visible = false


func muzzle() -> Node3D:
	return model.get_node(MUZZLE_FLASH_PATH) as Node3D


func shot_sound() -> AudioStreamPlayer:
	return model.get_node(SHOT_SOUND_NODE) as AudioStreamPlayer
