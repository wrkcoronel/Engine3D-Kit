class_name MuzzleFlashVisual
extends Node3D

const SIZE_JITTER := 0.25
const GLOW_RATIO := 0.55

@export var flash_size := 0.26

var _star: MeshInstance3D
var _glow: MeshInstance3D
var _smoke: CPUParticles3D
var _star_material: StandardMaterial3D
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	_star_material = _create_material(MuzzleFlashTextures.star_variants()[0])
	_star = _create_billboard(_star_material, flash_size)
	var glow_material := _create_material(MuzzleFlashTextures.glow())
	_glow = _create_billboard(glow_material, flash_size * GLOW_RATIO)
	_smoke = MuzzleSmoke.create()
	add_child(_star)
	add_child(_glow)
	add_child(_smoke)
	set_flashing(false)


func burst() -> void:
	var variants := MuzzleFlashTextures.star_variants()
	_star_material.albedo_texture = variants[_random.randi() % variants.size()]
	var size_scale := 1.0 + _random.randf_range(-SIZE_JITTER, SIZE_JITTER)
	var mirror := 1.0
	if _random.randf() < 0.5:
		mirror = -1.0
	_star.scale = Vector3(size_scale * mirror, size_scale, size_scale)
	_smoke.restart()


func set_flashing(flashing: bool) -> void:
	_star.visible = flashing
	_glow.visible = flashing


func is_flashing() -> bool:
	return _star.visible


func _create_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.albedo_texture = texture
	material.disable_receive_shadows = true
	return material


func _create_billboard(material: StandardMaterial3D, size: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
