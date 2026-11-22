class_name EntityBody
extends Node3D

const SPECTRAL_SHADER_PATH := "res://contexts/entity/materials/entity_spectral.gdshader"

var _main_material: ShaderMaterial
var _echo_material: ShaderMaterial
var _head_pivot: Node3D
var _echo_root: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _eye_left: MeshInstance3D
var _eye_right: MeshInstance3D
var _phase := 0.0
var _visibility := 0.0


func _ready() -> void:
	var shader := load(SPECTRAL_SHADER_PATH) as Shader
	_main_material = ShaderMaterial.new()
	_main_material.shader = shader
	_main_material.set_shader_parameter("blur_strength", 0.015)

	_echo_material = ShaderMaterial.new()
	_echo_material.shader = shader
	_echo_material.set_shader_parameter("blur_strength", 0.028)
	_echo_material.set_shader_parameter("core_color", Color(0.06, 0.07, 0.1, 1.0))

	_build_humanoid(self, _main_material, true)
	_echo_root = Node3D.new()
	_echo_root.name = "GhostEcho"
	add_child(_echo_root)
	_build_humanoid(_echo_root, _echo_material, false)
	_build_eye_glints()


func update_visual(
	delta: float, glitch_intensity: float, should_be_visible: bool, is_attacking: bool
) -> void:
	_phase += delta
	var target_vis := 0.0
	if should_be_visible:
		target_vis = 1.0
	var fade_rate := 4.5
	if not should_be_visible:
		fade_rate = 9.0
	_visibility = move_toward(_visibility, target_vis, fade_rate * delta)
	visible = _visibility > 0.01

	_main_material.set_shader_parameter("glitch_intensity", glitch_intensity)
	_main_material.set_shader_parameter("visibility_amount", _visibility)
	_echo_material.set_shader_parameter(
		"glitch_intensity", clampf(glitch_intensity + 0.25, 0.0, 1.0)
	)
	_echo_material.set_shader_parameter("visibility_amount", _visibility * 0.42)

	var drift_x := sin(_phase * 2.3) * (0.14 + glitch_intensity * 0.22)
	var drift_z := cos(_phase * 1.9) * (0.1 + glitch_intensity * 0.16)
	_echo_root.position = Vector3(drift_x, sin(_phase * 3.7) * 0.04, drift_z)

	var tilt_z := sin(_phase * 1.4) * 0.22
	var twitch_x := sin(_phase * 19.0) * 0.08 * glitch_intensity
	if is_attacking:
		tilt_z = sin(_phase * 11.0) * 0.35
	_head_pivot.rotation = Vector3(twitch_x, 0.0, tilt_z)

	var arm_raise := 0.08
	if is_attacking:
		arm_raise = -0.95
	var arm_sway := sin(_phase * 2.6) * 0.07
	_left_arm.rotation = Vector3(arm_raise + arm_sway, 0.0, 0.12)
	_right_arm.rotation = Vector3(arm_raise - arm_sway, 0.0, -0.12)

	var eye_flicker := sin(_phase * 17.0) * sin(_phase * 5.3) > -0.2
	var show_eyes := should_be_visible and eye_flicker and _visibility > 0.4
	_eye_left.visible = show_eyes
	_eye_right.visible = show_eyes


func hide_immediately() -> void:
	_visibility = 0.0
	visible = false
	if _eye_left != null:
		_eye_left.visible = false
	if _eye_right != null:
		_eye_right.visible = false


func _build_humanoid(root: Node3D, material: ShaderMaterial, keep_refs: bool) -> void:
	_add_capsule(root, Vector3(0.0, 1.38, 0.0), 0.2, 0.72, material)
	_add_capsule(root, Vector3(0.0, 1.72, 0.0), 0.16, 0.42, material, Vector3(0.0, 0.0, PI * 0.5))
	_add_capsule(root, Vector3(-0.14, 0.56, 0.0), 0.095, 1.12, material)
	_add_capsule(root, Vector3(0.14, 0.56, 0.0), 0.095, 1.12, material)

	var head_node := Node3D.new()
	head_node.position = Vector3(0.0, 1.88, 0.0)
	root.add_child(head_node)
	var head_mesh := _add_sphere(head_node, Vector3(0.0, 0.19, 0.0), 0.165, material)
	head_mesh.scale = Vector3(0.92, 1.28, 0.96)

	var left_shoulder := Node3D.new()
	left_shoulder.position = Vector3(-0.32, 1.68, 0.0)
	root.add_child(left_shoulder)
	_add_capsule(left_shoulder, Vector3(0.0, -0.52, 0.0), 0.072, 1.06, material)

	var right_shoulder := Node3D.new()
	right_shoulder.position = Vector3(0.32, 1.68, 0.0)
	root.add_child(right_shoulder)
	_add_capsule(right_shoulder, Vector3(0.0, -0.52, 0.0), 0.072, 1.06, material)

	if keep_refs:
		_head_pivot = head_node
		_left_arm = left_shoulder
		_right_arm = right_shoulder


func _build_eye_glints() -> void:
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.85, 0.9, 1.0)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.75, 0.84, 1.0)
	eye_mat.emission_energy_multiplier = 1.35
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_eye_left = _add_sphere(_head_pivot, Vector3(-0.055, 0.21, -0.145), 0.016, eye_mat)
	_eye_right = _add_sphere(_head_pivot, Vector3(0.055, 0.21, -0.145), 0.016, eye_mat)


func _add_capsule(
	parent: Node3D,
	offset: Vector3,
	radius: float,
	height: float,
	material: Material,
	rot: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = offset
	instance.rotation = rot
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D, offset: Vector3, radius: float, material: Material
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = offset
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance
