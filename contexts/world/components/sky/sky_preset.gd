class_name SkyPreset
extends RefCounted

var label := ""
var sun_elevation_degrees := 40.0
var sun_azimuth_degrees := 20.0
var light_color := Color.WHITE
var light_energy := 1.0
var shadow_distance := 150.0

var zenith_color := Color.BLACK
var horizon_color := Color.BLACK
var glow_color := Color.BLACK
var glow_strength := 0.0
var star_brightness := 0.0
var disc_color := Color.WHITE
var disc_radius := 0.035
var disc_brightness := 4.0
var disc_halo_brightness := 0.3
var disc_halo_falloff := 14.0
var disc_craters := 0.0

var ambient_color := Color.WHITE
var ambient_energy := 0.5
var fog_color := Color.WHITE
var fog_density := 0.005
var volumetric_density := 0.0
var volumetric_albedo := Color.WHITE
var exposure := 1.0
var glow_intensity := 0.8

var soil_color := Color.BLACK
var straw_color := Color.BLACK
var straw_dark_color := Color.BLACK


func sun_direction() -> Vector3:
	var elevation := deg_to_rad(sun_elevation_degrees)
	var azimuth := deg_to_rad(sun_azimuth_degrees)
	var horizontal := cos(elevation)
	return Vector3(sin(azimuth) * horizontal, sin(elevation), -cos(azimuth) * horizontal)
