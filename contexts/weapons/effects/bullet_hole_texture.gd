class_name BulletHoleTexture
extends RefCounted

const TEXTURE_SIZE := 128
const DEPTH_STRENGTH := 5.0
const DEEP_CENTER_RADIUS := 0.2
const RIM_RADIUS := 0.36
const RIM_HEIGHT := 0.35

static var _albedo: ImageTexture
static var _normal: ImageTexture


static func albedo() -> ImageTexture:
	if _albedo == null:
		_build_textures()
	return _albedo


static func normal() -> ImageTexture:
	if _normal == null:
		_build_textures()
	return _normal


static func edge_scale(angle: float) -> float:
	var wide_wobble := 0.12 * sin(angle * 3.0 + 1.3)
	var small_wobble := 0.08 * sin(angle * 7.0 + 0.4)
	return 1.0 + wide_wobble + small_wobble


static func height_at(normalized_radius: float) -> float:
	if normalized_radius >= 1.0:
		return 0.0
	if normalized_radius < DEEP_CENTER_RADIUS:
		return -1.0
	if normalized_radius < RIM_RADIUS:
		var climb := inverse_lerp(DEEP_CENTER_RADIUS, RIM_RADIUS, normalized_radius)
		return lerpf(-1.0, RIM_HEIGHT, smoothstep(0.0, 1.0, climb))
	var fall := inverse_lerp(RIM_RADIUS, 1.0, normalized_radius)
	return lerpf(RIM_HEIGHT, 0.0, smoothstep(0.0, 1.0, fall))


static func color_at(normalized_radius: float) -> Color:
	if normalized_radius >= 1.0:
		return Color(0.0, 0.0, 0.0, 0.0)
	if normalized_radius < 0.28:
		return Color(0.01, 0.01, 0.01, 1.0)
	if normalized_radius < 0.6:
		var fade := inverse_lerp(0.28, 0.6, normalized_radius)
		return Color(0.02, 0.02, 0.02, 1.0).lerp(Color(0.12, 0.11, 0.1, 0.8), fade)
	var scorch_fade := inverse_lerp(0.6, 1.0, normalized_radius)
	return Color(0.12, 0.11, 0.1, 0.8).lerp(Color(0.15, 0.14, 0.12, 0.0), scorch_fade)


static func _normalized_radius(pixel_x: int, pixel_y: int) -> float:
	var half_size := TEXTURE_SIZE / 2.0
	var from_center := Vector2(pixel_x + 0.5 - half_size, pixel_y + 0.5 - half_size)
	var radius := from_center.length() / half_size
	return radius / edge_scale(from_center.angle())


static func _build_textures() -> void:
	var heights := PackedFloat32Array()
	var albedo_image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for pixel_y: int in TEXTURE_SIZE:
		for pixel_x: int in TEXTURE_SIZE:
			var normalized_radius := _normalized_radius(pixel_x, pixel_y)
			heights.append(height_at(normalized_radius))
			albedo_image.set_pixel(pixel_x, pixel_y, color_at(normalized_radius))
	_albedo = ImageTexture.create_from_image(albedo_image)
	_normal = ImageTexture.create_from_image(_normal_image(heights))


static func _normal_image(heights: PackedFloat32Array) -> Image:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for pixel_y: int in TEXTURE_SIZE:
		for pixel_x: int in TEXTURE_SIZE:
			var slope_x := _height_step(heights, pixel_x, pixel_y, 1, 0)
			var slope_y := _height_step(heights, pixel_x, pixel_y, 0, 1)
			var surface_normal := Vector3(-slope_x, slope_y, 1.0 / DEPTH_STRENGTH).normalized()
			var encoded := surface_normal * 0.5 + Vector3(0.5, 0.5, 0.5)
			image.set_pixel(pixel_x, pixel_y, Color(encoded.x, encoded.y, encoded.z, 1.0))
	return image


static func _height_step(
	heights: PackedFloat32Array, pixel_x: int, pixel_y: int, step_x: int, step_y: int
) -> float:
	var before_x := clampi(pixel_x - step_x, 0, TEXTURE_SIZE - 1)
	var before_y := clampi(pixel_y - step_y, 0, TEXTURE_SIZE - 1)
	var after_x := clampi(pixel_x + step_x, 0, TEXTURE_SIZE - 1)
	var after_y := clampi(pixel_y + step_y, 0, TEXTURE_SIZE - 1)
	var before := heights[before_y * TEXTURE_SIZE + before_x]
	var after := heights[after_y * TEXTURE_SIZE + after_x]
	return after - before
