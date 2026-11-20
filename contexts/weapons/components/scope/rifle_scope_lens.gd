extends MeshInstance3D

const IMAGE_PARAMETER := "imagem"
const SKY_PARAMETER := "ceu"
const DAYLIGHT_SKY := Color(0.45, 0.55, 0.7)

var _lens_material: ShaderMaterial

@onready var _objective: Node3D = $Objetiva
@onready var _image: SubViewport = $Imagem
@onready var _scope_camera: Camera3D = $Imagem/Camera
@onready var _lenses: MeshInstance3D = $Lentes


func _ready() -> void:
	_scope_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_lens_material = _lenses.material_override.duplicate() as ShaderMaterial
	_lens_material.set_shader_parameter(IMAGE_PARAMETER, _image.get_texture())
	_lenses.material_override = _lens_material


func _process(_delta: float) -> void:
	var in_view := is_visible_in_tree()
	_image.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if not in_view:
		return
	_image.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_scope_camera.global_transform = _objective.global_transform
	_lens_material.set_shader_parameter(SKY_PARAMETER, _sky_color())


func _sky_color() -> Color:
	var environment := get_world_3d().environment
	if environment == null:
		return DAYLIGHT_SKY
	return environment.background_color * environment.background_energy_multiplier
