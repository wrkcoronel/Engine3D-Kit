class_name SkyPresets
extends RefCounted


static func dark() -> SkyPreset:
	var sky := SkyPreset.new()
	sky.label = "escuro"
	sky.sun_elevation_degrees = 40.0
	sky.sun_azimuth_degrees = 20.0
	sky.light_color = Color(0.6, 0.72, 1.0)
	sky.light_energy = 0.1
	sky.shadow_distance = 60.0
	sky.zenith_color = Color(0.0, 0.001, 0.004)
	sky.horizon_color = Color(0.003, 0.006, 0.014)
	sky.star_brightness = 1.4
	sky.disc_color = Color(0.8, 0.88, 1.0)
	sky.disc_radius = 0.035
	sky.disc_brightness = 0.8
	sky.disc_halo_brightness = 0.08
	sky.disc_craters = 1.0
	sky.ambient_color = Color(0.1, 0.14, 0.3)
	sky.ambient_energy = 0.05
	sky.fog_color = Color(0.005, 0.008, 0.02)
	sky.fog_density = 0.04
	sky.volumetric_density = 0.015
	sky.volumetric_albedo = Color(0.55, 0.65, 1.0)
	sky.exposure = 0.8
	sky.glow_intensity = 0.5
	sky.soil_color = Color(0.02, 0.025, 0.015)
	sky.straw_color = Color(0.06, 0.05, 0.025)
	sky.straw_dark_color = Color(0.03, 0.03, 0.015)
	return sky
