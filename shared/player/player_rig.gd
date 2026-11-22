class_name PlayerRig
extends Node

const GROUP := "player_rig"

var body: CharacterBody3D
var camera: Camera3D
var collision: CollisionShape3D
var eye_rest_position := Vector3.ZERO
var lean_distance := 0.0
var lean := 0.0
var look_sensitivity_scale := 1.0
var is_sprinting := false


static func find(tree: SceneTree) -> PlayerRig:
	return tree.get_first_node_in_group(GROUP) as PlayerRig


static func find_or_create(tree: SceneTree, fallback_parent: Node) -> PlayerRig:
	var existing := find(tree)
	if existing != null:
		return existing
	var empty_rig := PlayerRig.new()
	fallback_parent.add_child(empty_rig)
	return empty_rig


func _enter_tree() -> void:
	add_to_group(GROUP)


func is_ready() -> bool:
	return body != null
