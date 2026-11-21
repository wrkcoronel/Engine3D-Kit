class_name SkyApplier
extends RefCounted


static func apply(
	preset: SkyPreset,
	environment: Environment,
	sun: DirectionalLight3D,
	ground_material: ShaderMaterial
) -> void:
	_apply_sun(preset, sun)
	_apply_sky(preset, environment.sky.sky_material as ShaderMaterial)
	_apply_environment(preset, environment)
	_apply_ground(preset, ground_material)


static func _apply_sun(preset: SkyPreset, sun: DirectionalLight3D) -> void:
	var shining_direction := -preset.sun_direction()
	sun.transform.basis = Basis.looking_at(shining_direction, Vector3.UP)
	sun.light_color = preset.light_color
	sun.light_energy = preset.light_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = preset.shadow_distance


static func _apply_sky(preset: SkyPreset, sky_material: ShaderMaterial) -> void:
	sky_material.set_shader_parameter("zenith_color", preset.zenith_color)
	sky_material.set_shader_parameter("horizon_color", preset.horizon_color)
	sky_material.set_shader_parameter("glow_color", preset.glow_color)
	sky_material.set_shader_parameter("glow_strength", preset.glow_strength)
	sky_material.set_shader_parameter("star_brightness", preset.star_brightness)
	sky_material.set_shader_parameter("disc_color", preset.disc_color)
	sky_material.set_shader_parameter("disc_radius", preset.disc_radius)
	sky_material.set_shader_parameter("disc_brightness", preset.disc_brightness)
	sky_material.set_shader_parameter("disc_halo_brightness", preset.disc_halo_brightness)
	sky_material.set_shader_parameter("disc_halo_falloff", preset.disc_halo_falloff)
	sky_material.set_shader_parameter("disc_craters", preset.disc_craters)


static func _apply_environment(preset: SkyPreset, environment: Environment) -> void:
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = preset.ambient_color
	environment.ambient_light_energy = preset.ambient_energy
	environment.tonemap_exposure = preset.exposure
	environment.glow_enabled = true
	environment.glow_intensity = preset.glow_intensity
	environment.fog_enabled = true
	environment.fog_light_color = preset.fog_color
	environment.fog_density = preset.fog_density
	environment.fog_sky_affect = 0.0
	environment.volumetric_fog_enabled = preset.volumetric_density > 0.0
	environment.volumetric_fog_density = preset.volumetric_density
	environment.volumetric_fog_albedo = preset.volumetric_albedo
	environment.volumetric_fog_anisotropy = 0.7
	environment.volumetric_fog_length = 60.0
	environment.volumetric_fog_sky_affect = 0.0


static func _apply_ground(preset: SkyPreset, ground_material: ShaderMaterial) -> void:
	ground_material.set_shader_parameter("soil_color", preset.soil_color)
	ground_material.set_shader_parameter("straw_color", preset.straw_color)
	ground_material.set_shader_parameter("straw_dark_color", preset.straw_dark_color)
