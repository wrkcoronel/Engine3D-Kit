class_name EntityScreenFx
extends CanvasLayer

const SCREEN_FX_SHADER_PATH := "res://contexts/entity/materials/entity_screen_fx.gdshader"

var _material: ShaderMaterial
var _overlay: ColorRect
var _distortion := 0.0
var _flash := 0.0


func _ready() -> void:
	layer = 9
	var shader := load(SCREEN_FX_SHADER_PATH) as Shader
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("distortion_amount", 0.0)
	_material.set_shader_parameter("flash_amount", 0.0)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.material = _material
	_overlay.visible = false
	add_child(_overlay)


func trigger_flash(strength: float) -> void:
	_flash = maxf(_flash, clampf(strength, 0.0, 1.0))


func update_effect(delta: float, target_distortion: float) -> void:
	_distortion = move_toward(_distortion, clampf(target_distortion, 0.0, 1.0), 2.8 * delta)
	_flash = move_toward(_flash, 0.0, 2.4 * delta)
	var is_active := _distortion > 0.01 or _flash > 0.01
	_overlay.visible = is_active
	if not is_active:
		return
	_material.set_shader_parameter("distortion_amount", _distortion)
	_material.set_shader_parameter("flash_amount", _flash)


func clear_effect() -> void:
	_distortion = 0.0
	_flash = 0.0
	if _overlay != null:
		_overlay.visible = false
	if _material != null:
		_material.set_shader_parameter("distortion_amount", 0.0)
		_material.set_shader_parameter("flash_amount", 0.0)
