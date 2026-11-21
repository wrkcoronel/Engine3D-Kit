class_name SmokePuffTexture
extends RefCounted

const SIZE := 96
const NOISE_FREQUENCY := 0.035
const NOISE_OCTAVES := 4
const EDGE_FADE_START := 0.25
const MIN_CLOUDINESS := 0.3
const CLOUDINESS_RANGE := 0.35
const BASE_CLOUDINESS := 0.65


static func create(random_seed: int) -> ImageTexture:
	var image := build_image(SIZE, random_seed)
	return ImageTexture.create_from_image(image)


static func build_image(size: int, random_seed: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = random_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = NOISE_OCTAVES
	noise.frequency = NOISE_FREQUENCY * float(SIZE) / float(size)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var radius := float(size) / 2.0
	for pixel_y: int in size:
		for pixel_x: int in size:
			var pixel_center := Vector2(pixel_x, pixel_y) + Vector2(0.5, 0.5)
			var distance_ratio := pixel_center.distance_to(center) / radius
			var noise_value := noise.get_noise_2d(pixel_x, pixel_y)
			var alpha := alpha_at(distance_ratio, noise_value)
			image.set_pixel(pixel_x, pixel_y, Color(1.0, 1.0, 1.0, alpha))
	return image


static func alpha_at(distance_ratio: float, noise_value: float) -> float:
	var falloff := 1.0 - smoothstep(EDGE_FADE_START, 1.0, distance_ratio)
	var cloudiness := BASE_CLOUDINESS + CLOUDINESS_RANGE * noise_value
	return clampf(falloff * cloudiness, 0.0, 1.0)
