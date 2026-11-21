class_name MuzzleFlashTextures
extends RefCounted

const SIZE := 64
const SPIKE_COUNT := 7
const VARIANT_COUNT := 3
const SPIKE_WIDTH := 0.075
const MIN_SPIKE_LENGTH := 0.45
const CORE_SHARPNESS := 18.0
const HALO_SHARPNESS := 4.0
const HALO_STRENGTH := 0.35
const GLOW_SHARPNESS := 3.5
const HOT_COLOR := Color(1.0, 0.95, 0.7)
const COOL_COLOR := Color(1.0, 0.35, 0.05)

static var _star_variants: Array[ImageTexture] = []
static var _glow: ImageTexture
static var _puff: ImageTexture


static func star_variants() -> Array[ImageTexture]:
	if _star_variants.is_empty():
		for variant_index: int in VARIANT_COUNT:
			_star_variants.append(_build_star(variant_index))
	return _star_variants


static func glow() -> ImageTexture:
	if _glow == null:
		_glow = _build_radial(GLOW_SHARPNESS, true)
	return _glow


static func puff() -> ImageTexture:
	if _puff == null:
		_puff = _build_radial(2.5, false)
	return _puff


static func random_spikes(random_seed: int) -> Array[Vector2]:
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var spikes: Array[Vector2] = []
	for spike_index: int in SPIKE_COUNT:
		var angle := random.randf() * TAU
		var length := random.randf_range(MIN_SPIKE_LENGTH, 1.0)
		spikes.append(Vector2(angle, length))
	return spikes


static func star_intensity(offset: Vector2, spikes: Array[Vector2]) -> float:
	var distance := offset.length()
	var core := exp(-distance * distance * CORE_SHARPNESS)
	var halo := HALO_STRENGTH * exp(-distance * distance * HALO_SHARPNESS)
	var strongest_spike := 0.0
	var angle := offset.angle()
	for spike: Vector2 in spikes:
		var angle_difference := angle_difference(angle, spike.x)
		var alignment := exp(
			-(angle_difference * angle_difference) / (2.0 * SPIKE_WIDTH * SPIKE_WIDTH)
		)
		var reach := clampf(1.0 - distance / spike.y, 0.0, 1.0)
		strongest_spike = maxf(strongest_spike, alignment * pow(reach, 1.5))
	return clampf(core + halo + strongest_spike, 0.0, 1.0)


static func flame_color(intensity: float) -> Color:
	var heat := intensity * intensity
	var color := COOL_COLOR.lerp(HOT_COLOR, heat)
	return Color(color, intensity)


static func _build_star(variant_index: int) -> ImageTexture:
	var spikes := random_spikes(100 + variant_index)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for pixel_y: int in SIZE:
		for pixel_x: int in SIZE:
			var offset := _pixel_offset(pixel_x, pixel_y)
			image.set_pixel(pixel_x, pixel_y, flame_color(star_intensity(offset, spikes)))
	return ImageTexture.create_from_image(image)


static func _build_radial(sharpness: float, warm: bool) -> ImageTexture:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for pixel_y: int in SIZE:
		for pixel_x: int in SIZE:
			var offset := _pixel_offset(pixel_x, pixel_y)
			var edge_fade := 1.0 - smoothstep(0.7, 1.0, offset.length())
			var alpha := exp(-offset.length_squared() * sharpness) * edge_fade
			var color := Color(1.0, 1.0, 1.0, alpha)
			if warm:
				color = Color(HOT_COLOR, alpha)
			image.set_pixel(pixel_x, pixel_y, color)
	return ImageTexture.create_from_image(image)


static func _pixel_offset(pixel_x: int, pixel_y: int) -> Vector2:
	var half_size := float(SIZE) / 2.0
	var centered := Vector2(pixel_x, pixel_y) + Vector2(0.5, 0.5) - Vector2(half_size, half_size)
	return centered / half_size
