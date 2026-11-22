class_name MotelMaterials
extends RefCounted


static func build_palette() -> Dictionary:
	var palette: Dictionary = {}
	palette["stucco"] = _matte(Color(0.76, 0.67, 0.55), 0.92)
	palette["interior_wall"] = _matte(Color(0.86, 0.85, 0.81), 0.9)
	palette["ceiling"] = _matte(Color(0.92, 0.92, 0.9), 0.95)
	palette["trim"] = _matte(Color(0.88, 0.85, 0.78), 0.8)
	palette["roof"] = _matte(Color(0.32, 0.25, 0.2), 0.9)
	palette["concrete"] = _matte(Color(0.66, 0.64, 0.6), 0.92)
	palette["asphalt"] = _matte(Color(0.16, 0.17, 0.19), 0.95)
	palette["paint_white"] = _matte(Color(0.92, 0.92, 0.9), 0.7)
	palette["paint_yellow"] = _matte(Color(0.88, 0.72, 0.16), 0.7)
	palette["door_red"] = _matte(Color(0.64, 0.16, 0.15), 0.55)
	palette["door_frame"] = _matte(Color(0.24, 0.22, 0.2), 0.65)
	palette["metal_dark"] = _metallic(Color(0.18, 0.19, 0.21), 0.6, 0.45)
	palette["ac_unit"] = _matte(Color(0.78, 0.77, 0.72), 0.7)
	palette["ac_grille"] = _matte(Color(0.28, 0.29, 0.3), 0.8)
	palette["glass_dark"] = _glass(Color(0.12, 0.18, 0.22, 0.92), false)
	palette["glass_clear"] = _glass(Color(0.65, 0.78, 0.84, 0.28), true)
	palette["wood_dark"] = _matte(Color(0.34, 0.2, 0.12), 0.65)
	palette["bedspread"] = _matte(Color(0.36, 0.44, 0.31), 0.92)
	palette["pillow"] = _matte(Color(0.94, 0.94, 0.92), 0.9)
	palette["carpet"] = _matte(Color(0.28, 0.2, 0.18), 0.96)
	palette["tile_floor"] = _matte(Color(0.78, 0.75, 0.7), 0.45)
	palette["porcelain"] = _matte(Color(0.93, 0.94, 0.95), 0.25)
	palette["armchair"] = _matte(Color(0.45, 0.48, 0.42), 0.88)
	palette["tv_screen"] = _metallic(Color(0.06, 0.07, 0.08), 0.2, 0.15)
	palette["mirror"] = _metallic(Color(0.72, 0.78, 0.82), 0.92, 0.1)
	palette["pool_water"] = _water(Color(0.12, 0.62, 0.68, 0.88))
	palette["fence_white"] = _matte(Color(0.9, 0.9, 0.88), 0.65)
	palette["lounge_yellow"] = _matte(Color(0.88, 0.68, 0.18), 0.75)
	palette["foliage"] = _matte(Color(0.22, 0.38, 0.18), 0.9)
	palette["foliage_dark"] = _matte(Color(0.13, 0.24, 0.12), 0.94)
	palette["bark"] = _matte(Color(0.22, 0.15, 0.1), 0.95)
	palette["grass_ground"] = _matte(Color(0.25, 0.3, 0.19), 0.98)
	palette["sign_red"] = _emissive(Color(0.72, 0.14, 0.12), Color(0.95, 0.22, 0.14), 1.4)
	palette["sign_yellow"] = _emissive(Color(0.96, 0.82, 0.22), Color(1.0, 0.84, 0.28), 1.8)
	palette["sconce_glow"] = _emissive(Color(1.0, 0.88, 0.65), Color(1.0, 0.8, 0.45), 2.4)
	return palette


static func _matte(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material


static func _metallic(
	color: Color, metallic_value: float, roughness_value: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material


static func _glass(color: Color, is_transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.12
	material.metallic = 0.15
	if is_transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func _water(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.1
	material.metallic = 0.08
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func _emissive(albedo: Color, emission_color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.4
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = energy
	return material
