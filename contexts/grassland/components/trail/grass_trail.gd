class_name GrassTrail
extends SubViewport

const CORNER_SIGNS: Array[Vector2] = [
	Vector2(-1.0, -1.0),
	Vector2(1.0, -1.0),
	Vector2(1.0, 1.0),
	Vector2(-1.0, 1.0),
]
const LEVELS_PER_FADE := 2
const TOTAL_LEVELS := 255

var _fade := ColorRect.new()
var _stamp := Polygon2D.new()
var _fade_interval := 1.0
var _seconds_since_fade := 0.0


static func footprint_in_map(
	vehicle_transform: Transform3D,
	half_size: Vector2,
	padding: float,
	window_origin: Vector2,
	window_size: float,
	map_resolution: int
) -> PackedVector2Array:
	var pixels_per_meter := float(map_resolution) / window_size
	var corners := PackedVector2Array()
	for corner_sign: Vector2 in CORNER_SIGNS:
		var local_x := corner_sign.x * (half_size.x + padding)
		var local_z := corner_sign.y * (half_size.y + padding)
		var world_corner := vehicle_transform * Vector3(local_x, 0.0, local_z)
		var map_x := (world_corner.x - window_origin.x) * pixels_per_meter
		var map_y := (world_corner.z - window_origin.y) * pixels_per_meter
		corners.append(Vector2(map_x, map_y))
	return corners


func setup(map_resolution: int, recovery_seconds: float) -> void:
	size = Vector2i(map_resolution, map_resolution)
	render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_fade_interval = recovery_seconds * float(LEVELS_PER_FADE) / float(TOTAL_LEVELS)
	_setup_fade(map_resolution)
	_stamp.color = Color.WHITE
	add_child(_fade)
	add_child(_stamp)


func advance(delta: float) -> void:
	_seconds_since_fade = minf(_seconds_since_fade + delta, _fade_interval * 2.0)
	_fade.visible = _seconds_since_fade >= _fade_interval
	if _fade.visible:
		_seconds_since_fade -= _fade_interval


func stamp(footprint: PackedVector2Array) -> void:
	_stamp.polygon = footprint


func clear_all() -> void:
	render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE


func clear_stamp() -> void:
	_stamp.polygon = PackedVector2Array()


func fade_is_due() -> bool:
	return _fade.visible


func _setup_fade(map_resolution: int) -> void:
	var fade_amount := float(LEVELS_PER_FADE) / float(TOTAL_LEVELS)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	_fade.material = material
	_fade.color = Color(fade_amount, fade_amount, fade_amount, 1.0)
	_fade.size = Vector2(map_resolution, map_resolution)
	_fade.visible = false
