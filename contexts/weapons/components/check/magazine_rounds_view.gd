class_name MagazineRoundsView
extends RefCounted

const EMPTY_HOLE := preload("res://contexts/weapons/models/ammo/materials/furo_vazio.tres")
const FULL_MATERIAL_META := "full_material"
const HOLE_GROUPS := "Furos*"
const TUBE_MOUTH_ROUND := "CartuchoCarga"
const TOP_ROUND := "CartuchoTopo"
const FOLLOWER := "Seguidor"
const WINDOW_ROUNDS := "FurosJanela"
const ALWAYS_VISIBLE_META := "fixo"
const MAGAZINE_OUT_AT := 0.85


static func prepare(model: Node3D) -> void:
	for hole: MeshInstance3D in _holes(model):
		hole.set_meta(FULL_MATERIAL_META, hole.material_override)


static func update(
	model: Node3D, magazine_rounds: int, check_marker: Marker3D, amount: float
) -> void:
	_paint_holes(model, magazine_rounds)
	_place_follower(model, magazine_rounds)
	_show_tube_mouth_round(model, magazine_rounds)
	var pulled_out := smoothstep(0.0, 0.3, amount) > MAGAZINE_OUT_AT
	var magazine_out := AmmoCheckPose.holds_magazine(check_marker) and pulled_out
	var magazine_marker := model.get_node_or_null(MagazineInHand.MAGAZINE_MARKER_PATH)
	if magazine_marker == null:
		return
	_show_magazine_details(magazine_marker.get_parent(), magazine_rounds, magazine_out)


static func hide_magazine_details(model: Node3D) -> void:
	var magazine_marker := model.get_node_or_null(MagazineInHand.MAGAZINE_MARKER_PATH)
	if magazine_marker == null:
		return
	_show_magazine_details(magazine_marker.get_parent(), 0, false)


static func _holes(model: Node3D) -> Array[MeshInstance3D]:
	var holes: Array[MeshInstance3D] = []
	for group: Node in model.find_children(HOLE_GROUPS, "Node3D", true, false):
		for hole: Node in group.get_children():
			holes.append(hole as MeshInstance3D)
	return holes


static func _paint_holes(model: Node3D, magazine_rounds: int) -> void:
	for group: Node in model.find_children(HOLE_GROUPS, "Node3D", true, false):
		var hole_index := 0
		for hole: Node in group.get_children():
			var mesh := hole as MeshInstance3D
			mesh.material_override = EMPTY_HOLE
			if hole_index < magazine_rounds:
				mesh.material_override = mesh.get_meta(FULL_MATERIAL_META)
			hole_index += 1


static func _place_follower(model: Node3D, magazine_rounds: int) -> void:
	var follower := model.find_child(FOLLOWER, true, false) as Node3D
	var window := model.find_child(WINDOW_ROUNDS, true, false) as Node3D
	if follower == null or window == null:
		return
	var rounds := window.get_children()
	var last_round := (rounds[-1] as Node3D).position
	var one_round_step := last_round - (rounds[-2] as Node3D).position
	var spot := last_round + one_round_step
	if magazine_rounds < rounds.size():
		spot = (rounds[magazine_rounds] as Node3D).position
	follower.position = Vector3(follower.position.x, spot.y, spot.z)


static func _show_tube_mouth_round(model: Node3D, magazine_rounds: int) -> void:
	var tube_mouth := model.find_child(TUBE_MOUTH_ROUND, true, false) as Node3D
	if tube_mouth == null:
		return
	tube_mouth.visible = magazine_rounds > 0


static func _show_magazine_details(
	magazine: Node, magazine_rounds: int, magazine_out: bool
) -> void:
	for detail: Node in magazine.get_children():
		if not _hides_inside_grip(detail):
			continue
		var visible_detail := magazine_out
		if detail.name == TOP_ROUND:
			visible_detail = magazine_out and magazine_rounds > 0
		(detail as Node3D).visible = visible_detail


static func _hides_inside_grip(detail: Node) -> bool:
	if not detail is Node3D:
		return false
	if detail is Marker3D:
		return false
	return not detail.has_meta(ALWAYS_VISIBLE_META)
