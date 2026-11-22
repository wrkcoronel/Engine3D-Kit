class_name MotelBoundary
extends Node3D

const PLAYABLE_BOUNDS := Rect2(-42.0, -30.0, 88.0, 66.0)
const WARNING_MARGIN := 3.2
const WALL_HEIGHT := 12.0
const WALL_THICKNESS := 2.0
const HOLD_SECONDS := 1.4
const FADE_SPEED := 3.5
const WARNING_TEXT := "Não tenho motivos para ir para cá."

var _label: Label
var _hold_timer := 0.0
var _alpha := 0.0


func _ready() -> void:
	_build_invisible_walls()
	_build_warning_hud()


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var local_position := to_local(camera.global_position)
	if is_near_boundary(local_position, PLAYABLE_BOUNDS, WARNING_MARGIN):
		_hold_timer = HOLD_SECONDS
	elif _hold_timer > 0.0:
		_hold_timer = maxf(0.0, _hold_timer - delta)

	var target_alpha := 0.0
	if _hold_timer > 0.0:
		target_alpha = 1.0
	_alpha = move_toward(_alpha, target_alpha, FADE_SPEED * delta)
	_label.modulate.a = _alpha
	_label.visible = _alpha > 0.01


static func is_near_boundary(world_position: Vector3, bounds: Rect2, margin: float) -> bool:
	var near_west := world_position.x <= bounds.position.x + margin
	var near_east := world_position.x >= bounds.end.x - margin
	var near_north := world_position.z <= bounds.position.y + margin
	var near_south := world_position.z >= bounds.end.y - margin
	if near_west or near_east:
		return true
	return near_north or near_south


func _build_invisible_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "BoundaryWalls"
	add_child(body)

	var half_t := WALL_THICKNESS * 0.5
	var center_x := PLAYABLE_BOUNDS.position.x + PLAYABLE_BOUNDS.size.x * 0.5
	var center_z := PLAYABLE_BOUNDS.position.y + PLAYABLE_BOUNDS.size.y * 0.5
	var span_x := PLAYABLE_BOUNDS.size.x + WALL_THICKNESS * 2.0
	var span_z := PLAYABLE_BOUNDS.size.y + WALL_THICKNESS * 2.0
	var mid_y := WALL_HEIGHT * 0.5

	_add_wall(
		body,
		Vector3(PLAYABLE_BOUNDS.position.x - half_t, mid_y, center_z),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, span_z)
	)
	_add_wall(
		body,
		Vector3(PLAYABLE_BOUNDS.end.x + half_t, mid_y, center_z),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, span_z)
	)
	_add_wall(
		body,
		Vector3(center_x, mid_y, PLAYABLE_BOUNDS.position.y - half_t),
		Vector3(span_x, WALL_HEIGHT, WALL_THICKNESS)
	)
	_add_wall(
		body,
		Vector3(center_x, mid_y, PLAYABLE_BOUNDS.end.y + half_t),
		Vector3(span_x, WALL_HEIGHT, WALL_THICKNESS)
	)


func _add_wall(body: StaticBody3D, wall_center: Vector3, wall_size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = wall_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = wall_center
	body.add_child(collision)


func _build_warning_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BoundaryHud"
	layer.layer = 10
	add_child(layer)

	_label = Label.new()
	_label.text = WARNING_TEXT
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -120.0
	_label.offset_bottom = -70.0
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07, 0.92))
	_label.add_theme_constant_override("outline_size", 6)
	_label.modulate.a = 0.0
	_label.visible = false
	layer.add_child(_label)
