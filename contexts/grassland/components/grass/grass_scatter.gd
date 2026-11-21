class_name GrassScatter
extends RefCounted

const MIN_WIDTH_SCALE := 0.85
const MAX_WIDTH_SCALE := 1.25
const NOISE_CONTRAST := 1.6
const HEIGHT_JITTER := 0.06


static func create_height_noise(random_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = random_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	return noise


static func height_scale_at(
	noise_value: float, height_range: Vector2, random_jitter: float
) -> float:
	var contrasted_value := clampf(noise_value * NOISE_CONTRAST, -1.0, 1.0)
	var height_fraction := (contrasted_value + 1.0) / 2.0
	var height_scale := lerpf(height_range.x, height_range.y, height_fraction)
	var jittered_scale := height_scale + random_jitter
	return clampf(jittered_scale, height_range.x, height_range.y)


static func chunk_transforms(
	chunk_corner: Vector2,
	chunk_size: float,
	clump_count: int,
	height_noise: FastNoiseLite,
	height_range: Vector2,
	random: RandomNumberGenerator
) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for clump_index: int in clump_count:
		var ground_x := chunk_corner.x + random.randf() * chunk_size
		var ground_z := chunk_corner.y + random.randf() * chunk_size
		var noise_value := height_noise.get_noise_2d(ground_x, ground_z)
		var random_jitter := random.randf_range(-HEIGHT_JITTER, HEIGHT_JITTER)
		var height_scale := height_scale_at(noise_value, height_range, random_jitter)
		var width_scale := random.randf_range(MIN_WIDTH_SCALE, MAX_WIDTH_SCALE)
		var yaw_angle := random.randf() * TAU
		var clump_scale := Vector3(width_scale, height_scale, width_scale)
		var clump_basis := Basis(Vector3.UP, yaw_angle).scaled(clump_scale)
		var clump_position := Vector3(ground_x, 0.0, ground_z)
		transforms.append(Transform3D(clump_basis, clump_position))
	return transforms
