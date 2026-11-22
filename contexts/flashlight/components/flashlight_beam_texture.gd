class_name FlashlightBeamTexture
extends RefCounted

const SIZE := 128
const HOTSPOT_RADIUS_RATIO := 0.4
const HOTSPOT_SOFTNESS_RATIO := 0.3
const FALLOFF_START_RATIO := 0.5
const WARM_YELLOW := Color(1.0, 0.8, 0.3)
const WHITE := Color(1.0, 1.0, 1.0)


static func create() -> ImageTexture:
	var image := build_image(SIZE)
	return ImageTexture.create_from_image(image)


static func build_image(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var radius := float(size) / 2.0
	for pixel_y: int in size:
		for pixel_x: int in size:
			var pixel_center := Vector2(pixel_x, pixel_y) + Vector2(0.5, 0.5)
			var distance_ratio := pixel_center.distance_to(center) / radius
			image.set_pixel(pixel_x, pixel_y, color_at(distance_ratio))
	return image


static func color_at(distance_ratio: float) -> Color:
	var hotspot_end := HOTSPOT_RADIUS_RATIO + HOTSPOT_SOFTNESS_RATIO
	var white_amount := 1.0 - smoothstep(HOTSPOT_RADIUS_RATIO, hotspot_end, distance_ratio)
	var base_color := WARM_YELLOW.lerp(WHITE, white_amount)
	var brightness := 1.0 - smoothstep(FALLOFF_START_RATIO, 1.0, distance_ratio)
	return Color(
		base_color.r * brightness, base_color.g * brightness, base_color.b * brightness, 1.0
	)
